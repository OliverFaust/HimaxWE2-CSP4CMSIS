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
image to images.csv (window, frame, score, seq, file, bytes, decoded);
console.log has every text line, image and receiver message with its time,
for uplink_gui.py --replay. The protocol code is in uplink_proto.py.

`--prompts phases.csv` (columns start_s, phase, prompt) prints each operator
prompt when its start time is reached, with the elapsed time, and a warning
10 s before; the file is copied into the output folder for analyse_run.py.

`--send-at T COMMAND` sends a command line to the board's Command process
T seconds after the start (repeatable); `--send-every MS COMMAND...` sends
the commands in turn, one every MS milliseconds, from 2 s on. Each command
sent is logged as "-> <command>"; the board answers with "Camera: ... applied
at frame N" lines or "Command: rejected ..." lines.

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
import pathlib
import sys
import time

from uplink_proto import (UPLINK_WINDOW, BOOT_BANNER, EOI_ERROR, Recorder, Session, Stats, image_text,
                          open_port, park)

PROMPT_WARN_S = 10.0


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


class Sender:
    def __init__(self, s, session, args, t0):
        self.s = s
        self.session = session
        self.at = sorted((t0 + float(t), cmd) for t, cmd in (args.send_at or []))
        self.every = None
        if args.send_every:
            self.every = (float(args.send_every[0]) / 1000.0, args.send_every[1:])
            self.next_every = t0 + 2.0
            self.k = 0
        self.sent = 0

    def send(self, cmd, now):
        self.s.write((cmd + "\n").encode("ascii"))
        self.sent += 1
        self.session.message(f"-> {cmd}", now)

    def poll(self, now):
        while self.at and self.at[0][0] <= now:
            self.send(self.at.pop(0)[1], now)
        if self.every and now >= self.next_every:
            period, cmds = self.every
            self.send(cmds[self.k % len(cmds)], now)
            self.k += 1
            self.next_every += period
            if self.next_every < now:
                self.next_every = now + period


def receive(s, session, buf, deadline, next_summary, args):
    st = session.st
    pause = None
    if args.pause:
        pause = (st.t0 + args.pause[0], st.t0 + args.pause[0] + args.pause[1])
    while time.monotonic() < deadline:
        now = time.monotonic()
        if args.prompter:
            args.prompter.poll(now)
        args.sender.poll(now)
        if pause and pause[0] <= now < pause[1]:
            f0 = st.last_frame[0] if st.last_frame else None
            print(f"-- pausing reads for {pause[1] - now:.0f} s (port stays open)", flush=True)
            time.sleep(pause[1] - now)
            s.reset_input_buffer()
            buf.clear()
            now = time.monotonic()
            session.resync(now)
            st.pauses.append([pause[0], None, f0, None])
            print("-- reading again", flush=True)
            pause = None
        buf += s.read(8192)
        now = time.monotonic()
        session.feed(buf, now)
        args.sender.poll(now)
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
    ap.add_argument("--send-at", nargs=2, action="append", metavar=("T", "COMMAND"),
                    help="send COMMAND (quoted) to the board T seconds after the start")
    ap.add_argument("--send-every", nargs="+", metavar="MS_THEN_COMMANDS",
                    help="MS followed by commands (quoted), sent in turn every MS milliseconds")
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
    rec = Recorder(out, st.t0)

    def on_text(text, now):
        if not args.quiet or BOOT_BANNER.decode() in text or text.startswith(EOI_ERROR.decode()):
            print(text)

    def on_window(w, now):
        for pz in st.pauses:
            if pz[1] is None:
                pz[1] = now
                pz[3] = w.last

    def on_image(path, window, index, score, seq, jpeg, ok, now):
        if ok and not args.quiet:
            print(image_text(seq, window, index, score, len(jpeg), path.name))

    session = Session(st, rec, on_text=on_text, on_message=lambda text, now: print(text),
                      on_window=on_window, on_image=on_image)
    buf = bytearray()
    s = open_port(args.port, args.baud)
    s.timeout = 0.02
    args.sender = Sender(s, session, args, st.t0)
    deadline = time.monotonic() + args.duration
    next_summary = time.monotonic() + 30

    try:
        receive(s, session, buf, deadline, next_summary, args)
    except KeyboardInterrupt:
        pass
    finally:
        park(s)
        rec.close()

    print()
    print(st.summary())
    if args.sender.sent:
        print(f"commands sent {args.sender.sent}")
    ok = st.passed()
    if st.first_frame is not None and st.first_frame[0] < UPLINK_WINDOW:
        print("!! the first window seen was window 0: the board started (or restarted) while the receiver was open")
    print("UPLINK:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
