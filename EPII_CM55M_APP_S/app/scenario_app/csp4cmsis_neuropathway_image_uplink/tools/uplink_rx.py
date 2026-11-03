#!/usr/bin/env python3
"""Uplink receiver: prints the board's text lines and saves the JPEGs it sends.

The console carries plain text lines and binary frames:
    A5 5A 'I' 'M' | type u8 | reserved u8 | seq u16 | length u32 |
    body (length bytes) | CRC32 of body (u32), all little-endian.
Type 1 (image): body = frame index u32, score i8, window id u32, JPEG.

Inference sends one text line per window it reports,
    Window W: frames A-B best F score S merged M failed K
followed by the image of frame F (best and score are "-" if every frame
failed). M windows that could not be sent (the uplink was still busy) are
merged into this one, so A-B spans M+1 windows. The frame rate is taken from
these lines (frame B against the PC's clock). A line must start one frame
after the previous one ended, and the image that follows must be frame F with
score S and window id W; otherwise the run fails, and so does K > 0.

The score-log build (-DUPLINK_SCORE_LOG) appends the window's 20 person and
20 no-person scores to the line, "... p P0 .. P19 n N0 .. N19". Every Window
line goes to windows.csv in the output folder (window, first, last, best,
best_score, merged, failed, t_pc, p0..p19, n0..n19; t_pc is seconds since the
receiver started, the score columns are empty without the log), and every
image to images.csv (window, frame, score, seq, file, bytes, decoded).

`--prompts phases.csv` (columns start_s, phase, prompt) prints each operator
prompt when its start time is reached, with the elapsed time, and a warning
10 s before; the file is copied into the output folder for analyse_run.py.

`--pause START SECONDS` stops reading for SECONDS after START seconds, with the
port open, to check that the board carries on when the host stalls: data sent
meanwhile is lost in the USB bridge, so after the pause the receiver flushes
its input, resynchronises on the next frame and line (errors in the first
2 s are counted as resync losses, not failures), and the frame rate across the
pause shows whether the board slowed down.

The board's USB bridge (WCH CH343, cdc_acm) resets the WE2 on a rising edge of
RTS, and Linux raises DTR and RTS in open() unless the port's stored baud rate
is B0; deasserting them after open() is too late. The receiver therefore
"parks" the port at B0 when it exits, so that its next open() leaves RTS low
and the app keeps running. The first open after another program (flasher,
terminal) still resets the board once; `--park` does that step on its own.
`--unpark` restores 921600 Bd so that the flasher's open() resets the board
into the bootloader again. A bootloader banner in the stream means the board
restarted and fails the run.

    python3 uplink_rx.py --port /dev/ttyACM0 --park
    python3 uplink_rx.py --port /dev/ttyACM0 --duration 600 --out images
    python3 uplink_rx.py --port /dev/ttyACM0 --unpark
    python3 uplink_rx.py --port /dev/ttyACM0 --duration 600 --out run_person1 --prompts phases.csv
"""
import argparse
import csv
import io
import pathlib
import re
import struct
import sys
import termios
import time
import zlib

MAGIC = b"\xa5\x5aIM"
HEADER = struct.Struct("<4sBBHI")
IMAGE_META = struct.Struct("<IbI")
MAX_BODY = 1 << 16
WINDOW_LINE = re.compile(rb"^Window (\d+): frames (\d+)-(\d+) best (\d+|-) score (-?\d+|-) merged (\d+) failed (\d+)")
SCORES = re.compile(rb" p((?: -?\d+){20}) n((?: -?\d+){20})\s*$")
STACK_LINE = re.compile(rb"^(\w+): (\d+)/(\d+) bytes used")
RESYNC_S = 2.0
PROMPT_WARN_S = 10.0
UPLINK_WINDOW = 20
BOOT_BANNER = b"1st BL Modem"
EOI_ERROR = b"Uplink: frame"


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


def read_prompts(path):
    with open(path, newline="") as f:
        rows = [(float(r["start_s"]), r["phase"], r["prompt"]) for r in csv.DictReader(f)]
    return sorted(rows)


def mmss(t):
    return f"{int(t) // 60}:{int(t) % 60:02d}"


class Prompter:
    def __init__(self, rows, t0):
        self.rows = rows
        self.t0 = t0
        self.next = 0
        self.warned = -1

    def poll(self, now):
        t = now - self.t0
        while self.next < len(self.rows) and t >= self.rows[self.next][0]:
            start, phase, prompt = self.rows[self.next]
            print(f"\n==== {mmss(t)} elapsed | phase {phase} | {prompt}\n", flush=True)
            self.next += 1
        if (self.next < len(self.rows) and self.warned < self.next
                and t >= self.rows[self.next][0] - PROMPT_WARN_S):
            start, phase, prompt = self.rows[self.next]
            print(f"\n==== {mmss(t)} elapsed | in {start - t:.0f} s: {prompt}\n", flush=True)
            self.warned = self.next


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


class Stats:
    def __init__(self):
        self.t0 = time.monotonic()
        self.images = 0
        self.crc_errors = 0
        self.bad_frames = 0
        self.seq_gaps = 0
        self.decode_failures = 0
        self.eoi_errors = 0
        self.resets = 0
        self.last_seq = None
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

    def resyncing(self, now):
        return now < self.resync_until

    def resync(self, now):
        self.last_seq = None
        self.last_window_end = None
        self.expect = None
        self.resync_until = now + RESYNC_S

    def window_line(self, window, first, last, best, score, merged, failed, now):
        self.windows += merged + 1
        self.windows_merged += merged
        self.lines_merged += merged > 0
        self.inference_failures += failed
        if self.last_window_end is not None and first != self.last_window_end + 1:
            self.window_gaps += 1
            print(f"!! window gap: previous window ended at frame {self.last_window_end}, next starts at {first}")
        if self.expect is not None:
            self.not_best += 1
            print(f"!! no image for the window line ending at frame {self.expect[3]}")
        self.last_window_end = last
        self.expect = None if best is None else (window, best, score, last)
        self.frame_line(last, now)

    def image(self, window, index, score, now):
        if self.expect is None:
            if not self.resyncing(now):
                self.not_best += 1
                print(f"!! image of frame {index} without a window line naming it")
            return
        if self.expect[:3] != (window, index, score):
            self.not_best += 1
            print(f"!! image (window {window}, frame {index}, score {score}) is not the best of its "
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

    def summary(self):
        fps = self.fps()
        elapsed = time.monotonic() - self.t0
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
        for start, end, f0, f1 in self.pauses:
            if f0 is not None and f1 is not None and end > start:
                lines.append(f"paused {end - start:.0f} s: frames {f0}..{f1} across the pause, "
                             f"{(f1 - f0) / (end - start):.2f} frames/s (approximate)")
        if self.stacks:
            lines.append("last stack lines: " + ", ".join(f"{k} {u}/{a}" for k, (u, a) in self.stacks.items()))
        if fps is not None:
            lines.append(f"frame rate {fps:.2f} frames/s over frames {self.first_frame[0]}..{self.last_frame[0]}")
        return "\n".join(lines)


def receive(s, st, buf, deadline, next_summary, text, out, args):
    pause = None
    if args.pause:
        pause = (st.t0 + args.pause[0], st.t0 + args.pause[0] + args.pause[1])
    while time.monotonic() < deadline:
        now = time.monotonic()
        if args.prompter:
            args.prompter.poll(now)
        if pause and pause[0] <= now < pause[1]:
            f0 = st.last_frame[0] if st.last_frame else None
            print(f"-- pausing reads for {pause[1] - now:.0f} s (port stays open)", flush=True)
            time.sleep(pause[1] - now)
            s.reset_input_buffer()
            buf.clear()
            now = time.monotonic()
            st.resync(now)
            st.pauses.append([pause[0], None, f0, None])
            print("-- reading again", flush=True)
            pause = None
        buf += s.read(8192)
        now = time.monotonic()
        while True:
            i = buf.find(MAGIC)
            if i < 0:
                cut = buf.rfind(b"\n") + 1
                if cut:
                    text(bytes(buf[:cut]), now)
                    del buf[:cut]
                break
            if i:
                text(bytes(buf[:i]), now)
                del buf[:i]
            if len(buf) < HEADER.size:
                break
            _, ftype, _, seq, length = HEADER.unpack_from(buf)
            if length > MAX_BODY or length < IMAGE_META.size:
                if st.resyncing(now):
                    st.resync_losses += 1
                else:
                    st.bad_frames += 1
                del buf[:1]
                continue
            total = HEADER.size + length + 4
            if len(buf) < total:
                break
            body = bytes(buf[HEADER.size:HEADER.size + length])
            (crc,) = struct.unpack_from("<I", buf, HEADER.size + length)
            if zlib.crc32(body) != crc:
                del buf[:1]
                if st.resyncing(now):
                    st.resync_losses += 1
                    continue
                st.crc_errors += 1
                print(f"!! CRC error in frame seq {seq}")
                continue
            del buf[:total]
            if st.last_seq is not None and seq != (st.last_seq + 1) & 0xFFFF:
                st.seq_gaps += 1
                print(f"!! seq gap: {st.last_seq} -> {seq}")
            st.last_seq = seq
            if ftype != 1:
                st.bad_frames += 1
                continue
            index, score, window = IMAGE_META.unpack_from(body)
            jpeg = body[IMAGE_META.size:]
            st.images += 1
            st.image(window, index, score, now)
            path = out / f"w{window:06d}_f{index:07d}_s{seq:05d}.jpg"
            path.write_bytes(jpeg)
            ok = jpeg[:2] == b"\xff\xd8" and jpeg[-2:] == b"\xff\xd9"
            dec = decode_ok(jpeg)
            args.images_csv.writerow([window, index, score, seq, path.name, len(jpeg),
                                      "" if dec is None else int(bool(ok and dec))])
            if not ok or dec is False:
                st.decode_failures += 1
                print(f"!! {path.name}: {'markers wrong' if not ok else 'does not decode'}")
            elif not args.quiet:
                print(f"[image seq {seq} window {window} frame {index} score {score} {len(jpeg)} bytes -> {path.name}]")
        if now >= next_summary:
            print("--", st.summary().replace("\n", "\n-- "), flush=True)
            next_summary = now + 30


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", required=True)
    ap.add_argument("--baud", type=int, default=921600)
    ap.add_argument("--duration", type=float, default=60.0)
    ap.add_argument("--out", default="uplink_images")
    ap.add_argument("--quiet", action="store_true", help="do not echo text lines")
    ap.add_argument("--prompts", metavar="PHASES_CSV", help="print the operator prompts of this phase table")
    ap.add_argument("--pause", nargs=2, type=float, metavar=("START", "SECONDS"),
                    help="stop reading for SECONDS after START seconds, port open")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--park", action="store_true", help="only park the port at B0 (resets the board if it was not parked)")
    mode.add_argument("--unpark", action="store_true", help="only restore 921600 Bd, for the flasher")
    args = ap.parse_args()

    if args.park:
        park(open_port(args.port, args.baud))
        print("port parked at B0")
        return 0
    if args.unpark:
        open_port(args.port, args.baud).close()
        print(f"port unparked at {args.baud} Bd")
        return 0

    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    st = Stats()
    args.prompter = None
    if args.prompts:
        args.prompter = Prompter(read_prompts(args.prompts), st.t0)
        (out / "phases.csv").write_bytes(pathlib.Path(args.prompts).read_bytes())
    windows_file = open(out / "windows.csv", "w", newline="")
    windows_csv = csv.writer(windows_file)
    windows_csv.writerow(["window", "first", "last", "best", "best_score", "merged", "failed", "t_pc"]
                         + [f"p{k}" for k in range(UPLINK_WINDOW)] + [f"n{k}" for k in range(UPLINK_WINDOW)])
    images_file = open(out / "images.csv", "w", newline="")
    args.images_csv = csv.writer(images_file)
    args.images_csv.writerow(["window", "frame", "score", "seq", "file", "bytes", "decoded"])
    buf = bytearray()
    s = open_port(args.port, args.baud)
    deadline = time.monotonic() + args.duration
    next_summary = time.monotonic() + 30

    def text(chunk, now):
        for raw in chunk.split(b"\n"):
            line = raw.rstrip(b"\r")
            if not line:
                continue
            st.text_lines += 1
            if BOOT_BANNER in line:
                st.resets += 1
            if line.startswith(EOI_ERROR):
                st.eoi_errors += 1
            m = WINDOW_LINE.match(line)
            if m:
                best = None if m.group(4) == b"-" else int(m.group(4))
                score = None if m.group(5) == b"-" else int(m.group(5))
                st.window_line(int(m.group(1)), int(m.group(2)), int(m.group(3)), best, score,
                               int(m.group(6)), int(m.group(7)), now)
                sc = SCORES.search(line)
                scores = sc.group(1).split() + sc.group(2).split() if sc else [b""] * (2 * UPLINK_WINDOW)
                windows_csv.writerow([int(m.group(1)), int(m.group(2)), int(m.group(3)),
                                      "" if best is None else best, "" if score is None else score,
                                      int(m.group(6)), int(m.group(7)), f"{now - st.t0:.2f}"]
                                     + [v.decode() for v in scores])
                for pz in st.pauses:
                    if pz[1] is None:
                        pz[1] = now
                        pz[3] = int(m.group(3))
            m = STACK_LINE.match(line)
            if m:
                st.stacks[m.group(1).decode()] = (int(m.group(2)), int(m.group(3)))
            if not args.quiet or BOOT_BANNER in line or line.startswith(EOI_ERROR):
                print(line.decode("ascii", "replace"))

    try:
        receive(s, st, buf, deadline, next_summary, text, out, args)
    except KeyboardInterrupt:
        pass
    finally:
        park(s)
        windows_file.close()
        images_file.close()

    print()
    print(st.summary())
    ok = (st.images > 0 and st.crc_errors == 0 and st.bad_frames == 0 and st.seq_gaps == 0
          and st.decode_failures == 0 and st.eoi_errors == 0 and st.resets == 0
          and st.window_gaps == 0 and st.inference_failures == 0 and st.not_best == 0
          and st.first_frame is not None and st.first_frame[0] >= UPLINK_WINDOW)
    if st.first_frame is not None and st.first_frame[0] < UPLINK_WINDOW:
        print("!! the first window seen was window 0: the board started (or restarted) while the receiver was open")
    print("UPLINK:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
