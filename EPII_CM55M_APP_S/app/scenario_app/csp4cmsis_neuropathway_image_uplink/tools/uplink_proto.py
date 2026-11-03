"""Uplink protocol: the console's text lines and binary image frames, shared by
uplink_rx.py and uplink_gui.py.

    A5 5A 'I' 'M' | type u8 | reserved u8 | seq u16 | length u32 |
    body (length bytes) | CRC32 of body (u32), all little-endian.
Type 1 (image): body = frame index u32, score i8, window id u32, JPEG.

Session ties the pieces together: it splits the byte stream into text lines
and frames (FrameParser), keeps the run's statistics (Stats), optionally
records the run (Recorder: JPEGs, windows.csv, images.csv, console.log) and
hands every line, image and message to the caller's callbacks. Replay feeds
recorded lines and images into the same Session.

Port handling: the board's USB bridge (WCH CH343) resets the WE2 on a rising
edge of RTS, which Linux raises in open() unless the port's stored baud rate
is B0. park() leaves the port at B0 so that the next open() does not reset
the board; unpark() restores the baud rate for the flasher.
"""
import csv
import io
import pathlib
import re
import struct
import termios
import time
import zlib
from collections import namedtuple

MAGIC = b"\xa5\x5aIM"
HEADER = struct.Struct("<4sBBHI")
IMAGE_META = struct.Struct("<IbI")
MAX_BODY = 1 << 17
WINDOW_LINE = re.compile(rb"^Window (\d+): frames (\d+)-(\d+) best (\d+|-) score (-?\d+|-) merged (\d+) failed (\d+)")
SCORES = re.compile(rb" p((?: -?\d+){2,20}) n((?: -?\d+){2,20})\s*$")
WINDOW_Y = re.compile(rb" y (\d+\.\d) clip (\d+\.\d\d)")
WINDOW_FILTER = re.compile(rb" above (\d+) sent ([01]) suppressed (\d+) lost (\d+)")
SCORES_LINE = re.compile(rb"^Scores (\d+) (\d+):((?: -?\d+/-?\d+)*)\s*$")
MODEL_LINE = re.compile(r"^Inference: output tensor type (\d+) scale (\S+) zero point (-?\d+)")
APPLIED_LINE = re.compile(r"^(Camera|Inference): (\w+)=(-?\d+) applied at frame (\d+)")
APPLY_FAILED_LINE = re.compile(r"^(Camera|Inference): (\w+) write FAILED at frame (\d+), still (\d+)")
SETTINGS_LINE = re.compile(r"^Camera: again=(\d+) dgain=(\d+) exposure=(\d+) framelen=(\d+) window=(\d+)"
                           r"(?: threshold=(-?\d+) k=(\d+))?")
COMMAND_LINE = re.compile(r"^Command: (.*)")
SETTING_NAMES = ("again", "dgain", "exposure", "framelen", "window", "threshold", "k")
STACK_LINE = re.compile(rb"^(\w+): (\d+)/(\d+) bytes used")
IMAGE_LOG = re.compile(r"^\[image seq (\d+) window (\d+) frame (\d+) score (-?\d+) (\d+) bytes -> (\S+)\]$")
RESYNC_S = 2.0
UPLINK_WINDOW = 20
BOOT_BANNER = b"1st BL Modem"
EOI_ERROR = b"Uplink: frame"
RX_PREFIX = "# "

SCORE_SCALE = 1 / 256
SCORE_ZERO_POINT = -128

Window = namedtuple("Window", "window first last best score merged failed p n y clip above sent suppressed lost",
                    defaults=(None,) * 6)


def probability(score):
    return (score - SCORE_ZERO_POINT) * SCORE_SCALE


def score_at(prob):
    return prob / SCORE_SCALE + SCORE_ZERO_POINT


def open_port(port, baud):
    import serial
    s = serial.Serial()
    s.port = port
    s.baudrate = baud
    s.timeout = 0.2
    s.dtr = False
    s.rts = False
    s.open()
    return s


def park(s):
    attrs = termios.tcgetattr(s.fd)
    attrs[4] = attrs[5] = termios.B0
    termios.tcsetattr(s.fd, termios.TCSANOW, attrs)
    s.close()


def unpark(port, baud):
    open_port(port, baud).close()


def list_ports():
    from serial.tools import list_ports as lp
    return sorted(p.device for p in lp.comports())


def decode_ok(data):
    try:
        from PIL import Image
    except ImportError:
        return None
    try:
        with Image.open(io.BytesIO(data)) as im:
            im.load()
        return True
    except Exception:
        return False


def markers_ok(jpeg):
    return jpeg[:2] == b"\xff\xd8" and jpeg[-2:] == b"\xff\xd9"


def parse_window(line):
    m = WINDOW_LINE.match(line)
    if not m:
        return None
    best = None if m.group(4) == b"-" else int(m.group(4))
    score = None if m.group(5) == b"-" else int(m.group(5))
    sc = SCORES.search(line)
    p = [int(v) for v in sc.group(1).split()] if sc else None
    n = [int(v) for v in sc.group(2).split()] if sc else None
    yc = WINDOW_Y.search(line)
    fl = WINDOW_FILTER.search(line)
    return Window(int(m.group(1)), int(m.group(2)), int(m.group(3)), best, score,
                  int(m.group(6)), int(m.group(7)), p, n,
                  float(yc.group(1)) if yc else None, float(yc.group(2)) if yc else None,
                  *([int(v) for v in fl.groups()] if fl else [None] * 4))


def parse_scores(line):
    m = SCORES_LINE.match(line)
    if not m:
        return None
    pairs = [tuple(int(v) for v in t.split(b"/")) for t in m.group(3).split()]
    if len(pairs) != int(m.group(2)):
        return None
    return int(m.group(1)), pairs


def parse_applied(text):
    m = APPLIED_LINE.match(text)
    if m:
        return m.group(2), int(m.group(3)), int(m.group(4)), True
    m = APPLY_FAILED_LINE.match(text)
    if m:
        return m.group(2), int(m.group(4)), int(m.group(3)), False
    return None


def parse_settings(text):
    m = SETTINGS_LINE.match(text)
    return {k: int(v) for k, v in zip(SETTING_NAMES, m.groups()) if v is not None} if m else None


def window_text(w):
    s = f"Window {w.window}: frames {w.first}-{w.last} "
    s += "best - score -" if w.best is None else f"best {w.best} score {w.score}"
    s += f" merged {w.merged} failed {w.failed}"
    if w.y is not None:
        s += f" y {w.y:.1f} clip {w.clip:.2f}"
    if w.sent is not None:
        s += f" above {w.above} sent {w.sent} suppressed {w.suppressed} lost {w.lost}"
    if w.p is not None:
        s += " p " + " ".join(map(str, w.p)) + " n " + " ".join(map(str, w.n))
    return s


def parse_stack(line):
    m = STACK_LINE.match(line)
    return (m.group(1).decode(), int(m.group(2)), int(m.group(3))) if m else None


def image_text(seq, window, index, score, size, name):
    return f"[image seq {seq} window {window} frame {index} score {score} {size} bytes -> {name}]"


class FrameParser:
    """Splits the byte stream into text chunks and binary frames. feed() takes
    the receive buffer, removes what it has consumed and yields events:
    ("text", bytes), ("bad_length",), ("crc", seq), ("seq_gap", last, seq),
    ("bad_type", seq) and ("image", seq, window, index, score, jpeg)."""

    def __init__(self):
        self.last_seq = None

    def reset(self):
        self.last_seq = None

    def feed(self, buf):
        while True:
            i = buf.find(MAGIC)
            if i < 0:
                cut = buf.rfind(b"\n") + 1
                if cut:
                    yield ("text", bytes(buf[:cut]))
                    del buf[:cut]
                return
            if i:
                yield ("text", bytes(buf[:i]))
                del buf[:i]
            if len(buf) < HEADER.size:
                return
            _, ftype, _, seq, length = HEADER.unpack_from(buf)
            if length > MAX_BODY or length < IMAGE_META.size:
                del buf[:1]
                yield ("bad_length",)
                continue
            total = HEADER.size + length + 4
            if len(buf) < total:
                return
            body = bytes(buf[HEADER.size:HEADER.size + length])
            (crc,) = struct.unpack_from("<I", buf, HEADER.size + length)
            if zlib.crc32(body) != crc:
                del buf[:1]
                yield ("crc", seq)
                continue
            del buf[:total]
            if self.last_seq is not None and seq != (self.last_seq + 1) & 0xFFFF:
                yield ("seq_gap", self.last_seq, seq)
            self.last_seq = seq
            if ftype != 1:
                yield ("bad_type", seq)
                continue
            index, score, window = IMAGE_META.unpack_from(body)
            yield ("image", seq, window, index, score, body[IMAGE_META.size:])


class Stats:
    def __init__(self, say=print, clock=time.monotonic):
        self.say = say
        self.clock = clock
        self.t0 = clock()
        self.images = 0
        self.crc_errors = 0
        self.bad_frames = 0
        self.seq_gaps = 0
        self.decode_failures = 0
        self.eoi_errors = 0
        self.resets = 0
        self.first_frame = None
        self.last_frame = None
        self.text_lines = 0
        self.windows = 0
        self.window_gaps = 0
        self.windows_merged = 0
        self.lines_merged = 0
        self.inference_failures = 0
        self.not_best = 0
        self.last_window_end = None
        self.expect = None
        self.stacks = {}
        self.resync_until = self.t0 + RESYNC_S
        self.resync_losses = 0
        self.pauses = []
        self.scored = 0
        self.score_gaps = 0
        self.score_lines = 0
        self.max_batch = 0
        self.next_score = None
        self.scores_lost = 0
        self.windows_sent = 0
        self.suppressed = 0
        self.frames_above = 0

    def resyncing(self, now):
        return now < self.resync_until

    def resync(self, now):
        self.last_window_end = None
        self.expect = None
        self.next_score = None
        self.resync_until = now + RESYNC_S

    def scores(self, first, pairs, now):
        self.score_lines += 1
        self.scored += len(pairs)
        self.max_batch = max(self.max_batch, len(pairs))
        if self.next_score is not None and first != self.next_score:
            self.score_gaps += 1
            self.say(f"!! score gap: expected frame {self.next_score}, line starts at {first}")
        self.next_score = first + len(pairs)

    def window_line(self, w, now):
        self.windows += w.merged + 1
        self.windows_merged += w.merged
        self.lines_merged += w.merged > 0
        self.inference_failures += w.failed
        if self.last_window_end is not None and w.first != self.last_window_end + 1:
            self.window_gaps += 1
            self.say(f"!! window gap: previous window ended at frame {self.last_window_end}, next starts at {w.first}")
        if self.expect is not None:
            self.not_best += 1
            self.say(f"!! no image for the window line ending at frame {self.expect[3]}")
        self.last_window_end = w.last
        if w.sent is not None:
            self.windows_sent += w.sent
            self.suppressed = w.suppressed
            self.frames_above += w.above
            if w.lost != self.scores_lost:
                if w.lost > self.scores_lost:
                    self.say(f"!! {w.lost - self.scores_lost} scores lost on the board (batch full)")
                self.scores_lost = w.lost
        image_due = w.best is not None and (w.sent is None or w.sent == 1)
        self.expect = (w.window, w.best, w.score, w.last) if image_due else None
        self.frame_line(w.last, now)

    def image(self, window, index, score, now):
        if self.expect is None:
            if not self.resyncing(now):
                self.not_best += 1
                self.say(f"!! image of frame {index} without a window line naming it")
            return
        if self.expect[:3] != (window, index, score):
            self.not_best += 1
            self.say(f"!! image (window {window}, frame {index}, score {score}) is not the best of its "
                     f"window line (window {self.expect[0]}, frame {self.expect[1]}, score {self.expect[2]})")
        self.expect = None

    def frame_line(self, index, now):
        if self.first_frame is None:
            self.first_frame = (index, now)
        self.last_frame = (index, now)

    def fps(self):
        if self.first_frame is None or self.last_frame[1] <= self.first_frame[1]:
            return None
        return (self.last_frame[0] - self.first_frame[0]) / (self.last_frame[1] - self.first_frame[1])

    def elapsed(self):
        return self.clock() - self.t0

    def summary(self):
        fps = self.fps()
        elapsed = self.elapsed()
        lines = [
            f"elapsed {elapsed:.0f} s, text lines {self.text_lines}",
            f"images {self.images} ({self.images / elapsed:.2f}/s), CRC errors {self.crc_errors}, "
            f"bad frames {self.bad_frames}, seq gaps {self.seq_gaps}, decode failures {self.decode_failures}, "
            f"EOI errors reported by the board {self.eoi_errors}",
            f"windows {self.windows}, window gaps {self.window_gaps}, windows merged {self.windows_merged} "
            f"(in {self.lines_merged} lines), images not the window's best {self.not_best}, "
            f"inference failures {self.inference_failures}, resync losses {self.resync_losses}",
            f"board resets seen {self.resets}",
        ]
        if self.score_lines:
            lines.append(f"scores: {self.scored} frames in {self.score_lines} lines, gaps {self.score_gaps}, "
                         f"max batch {self.max_batch}, lost on the board {self.scores_lost}; windows sent "
                         f"{self.windows_sent}, suppressed {self.suppressed}, frames >= T {self.frames_above}")
        for start, end, f0, f1 in self.pauses:
            if f0 is not None and f1 is not None and end > start:
                lines.append(f"paused {end - start:.0f} s: frames {f0}..{f1} across the pause, "
                             f"{(f1 - f0) / (end - start):.2f} frames/s (approximate)")
        if self.stacks:
            lines.append("last stack lines: " + ", ".join(f"{k} {u}/{a}" for k, (u, a) in self.stacks.items()))
        if fps is not None:
            lines.append(f"frame rate {fps:.2f} frames/s over frames {self.first_frame[0]}..{self.last_frame[0]}")
        return "\n".join(lines)

    def passed(self):
        return ((self.images > 0 or self.windows_sent == 0 and self.score_lines > 0) and self.crc_errors == 0 and self.bad_frames == 0 and self.seq_gaps == 0
                and self.decode_failures == 0 and self.eoi_errors == 0 and self.resets == 0
                and self.window_gaps == 0 and self.inference_failures == 0 and self.not_best == 0
                and self.score_gaps == 0 and self.scores_lost == 0
                and self.first_frame is not None and self.first_frame[0] >= UPLINK_WINDOW)


def pad(values):
    return [str(v) for v in values] + [""] * (UPLINK_WINDOW - len(values))


class Recorder:
    """Writes a run to a folder: the JPEGs, windows.csv, images.csv and
    console.log (one line per text line, image and receiver message, each
    prefixed with the seconds since the start; receiver messages also with
    RX_PREFIX), which uplink_gui.py --replay plays back."""

    def __init__(self, out, t0, console=True):
        self.out = pathlib.Path(out)
        self.out.mkdir(parents=True, exist_ok=True)
        self.t0 = t0
        self.windows_file = open(self.out / "windows.csv", "w", newline="")
        self.windows_csv = csv.writer(self.windows_file)
        self.windows_csv.writerow(["window", "first", "last", "best", "best_score", "merged", "failed", "t_pc"]
                                  + [f"p{k}" for k in range(UPLINK_WINDOW)]
                                  + [f"n{k}" for k in range(UPLINK_WINDOW)] + ["y_mean", "clip_pct",
                                                                               "above", "sent", "suppressed", "lost"])
        self.images_file = open(self.out / "images.csv", "w", newline="")
        self.images_csv = csv.writer(self.images_file)
        self.images_csv.writerow(["window", "frame", "score", "seq", "file", "bytes", "decoded"])
        self.console_file = open(self.out / "console.log", "w") if console else None
        self.scores_file = open(self.out / "scores.csv", "w", newline="")
        self.scores_csv = csv.writer(self.scores_file)
        self.scores_csv.writerow(["frame", "person", "no_person", "t_pc", "batch"])

    def window(self, w, now):
        self.windows_csv.writerow([w.window, w.first, w.last, "" if w.best is None else w.best,
                                   "" if w.score is None else w.score, w.merged, w.failed, f"{now - self.t0:.2f}"]
                                  + (pad(w.p) + pad(w.n) if w.p is not None else [""] * (2 * UPLINK_WINDOW))
                                  + ["" if w.y is None else f"{w.y:.1f}", "" if w.clip is None else f"{w.clip:.2f}"]
                                  + ["" if v is None else v for v in (w.above, w.sent, w.suppressed, w.lost)])

    def scores(self, first, pairs, now):
        for k, (pp, nn) in enumerate(pairs):
            self.scores_csv.writerow([first + k, pp, nn, f"{now - self.t0:.2f}", len(pairs)])

    def image_path(self, window, index, seq):
        return self.out / f"w{window:06d}_f{index:07d}_s{seq:05d}.jpg"

    def image(self, path, window, index, score, seq, jpeg, ok):
        path.write_bytes(jpeg)
        self.images_csv.writerow([window, index, score, seq, path.name, len(jpeg), "" if ok is None else int(ok)])

    def console(self, text, now, rx=False):
        if self.console_file:
            self.console_file.write(f"{now - self.t0:10.3f} {RX_PREFIX if rx else ''}{text}\n")

    def flush(self):
        for f in (self.windows_file, self.images_file, self.console_file, self.scores_file):
            if f:
                f.flush()

    def close(self):
        for f in (self.windows_file, self.images_file, self.console_file, self.scores_file):
            if f:
                f.close()


class Session:
    """One receiving run. Callbacks (all optional):
        on_text(line_str, now)        every text line from the board
        on_message(text, now)         a receiver message (errors start with "!!")
        on_window(Window, now)        after the line has been counted
        on_image(path_or_None, window, index, score, seq, jpeg, ok, now)
    """

    def __init__(self, stats, recorder=None, on_text=None, on_message=None, on_window=None, on_image=None,
                 out=None, on_scores=None):
        self.st = stats
        self.rec = recorder
        self.out = pathlib.Path(out) if out else (recorder.out if recorder else None)
        self.parser = FrameParser()
        self.on_text = on_text
        self.on_message = on_message
        self.on_window = on_window
        self.on_image = on_image
        self.on_scores = on_scores
        stats.say = self.message

    def message(self, text, now=None):
        now = self.st.clock() if now is None else now
        if self.rec:
            self.rec.console(text, now, rx=True)
        if self.on_message:
            self.on_message(text, now)

    def resync(self, now):
        self.parser.reset()
        self.st.resync(now)

    def feed(self, buf, now):
        st = self.st
        for ev in self.parser.feed(buf):
            kind = ev[0]
            if kind == "text":
                self.text(ev[1], now)
            elif kind == "bad_length":
                if st.resyncing(now):
                    st.resync_losses += 1
                else:
                    st.bad_frames += 1
            elif kind == "crc":
                if st.resyncing(now):
                    st.resync_losses += 1
                    continue
                st.crc_errors += 1
                self.message(f"!! CRC error in frame seq {ev[1]}", now)
            elif kind == "seq_gap":
                st.seq_gaps += 1
                self.message(f"!! seq gap: {ev[1]} -> {ev[2]}", now)
            elif kind == "bad_type":
                st.bad_frames += 1
            elif kind == "image":
                self.image(*ev[1:], now)

    def text(self, chunk, now):
        for raw in chunk.split(b"\n"):
            line = raw.rstrip(b"\r")
            if line:
                self.line(line, now)

    def line(self, line, now):
        st = self.st
        st.text_lines += 1
        if BOOT_BANNER in line:
            st.resets += 1
        if line.startswith(EOI_ERROR):
            st.eoi_errors += 1
        w = parse_window(line)
        if w:
            st.window_line(w, now)
            if self.rec:
                self.rec.window(w, now)
        s = parse_stack(line)
        if s:
            st.stacks[s[0]] = (s[1], s[2])
        sc = parse_scores(line)
        if sc:
            st.scores(sc[0], sc[1], now)
            if self.rec:
                self.rec.scores(sc[0], sc[1], now)
            if self.on_scores:
                self.on_scores(sc[0], sc[1], now)
        text = line.decode("ascii", "replace")
        if self.rec:
            self.rec.console(text, now)
        if self.on_text:
            self.on_text(text, now)
        if w and self.on_window:
            self.on_window(w, now)
        return w

    def image(self, seq, window, index, score, jpeg, now, path=None):
        st = self.st
        st.images += 1
        st.image(window, index, score, now)
        if self.rec:
            path = self.rec.image_path(window, index, seq)
        elif path is None and self.out:
            path = self.out / f"w{window:06d}_f{index:07d}_s{seq:05d}.jpg"
        ok = markers_ok(jpeg)
        dec = decode_ok(jpeg)
        good = None if dec is None else bool(ok and dec)
        if self.rec:
            self.rec.image(path, window, index, score, seq, jpeg, good)
        if not ok or dec is False:
            st.decode_failures += 1
            self.message(f"!! {path.name if path else index}: {'markers wrong' if not ok else 'does not decode'}", now)
        elif self.rec:
            self.rec.console(image_text(seq, window, index, score, len(jpeg), path.name), now)
        if self.on_image:
            self.on_image(path, window, index, score, seq, jpeg, ok and dec is not False, now)
