#!/usr/bin/env python3
"""Uplink receiver: prints the board's text lines and saves the JPEGs it sends.

The console carries plain text lines and binary frames:
    A5 5A 'I' 'M' | type u8 | reserved u8 | seq u16 | length u32 |
    body (length bytes) | CRC32 of body (u32), all little-endian.
Type 1 (image): body = frame index u32, score i8, window id u32, JPEG.

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
"""
import argparse
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
MAX_BODY = 1 << 20
FRAME_LINE = re.compile(rb"^Frame (\d+): ")
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
            f"board resets seen {self.resets}",
        ]
        if fps is not None:
            lines.append(f"frame rate {fps:.2f} frames/s over frames {self.first_frame[0]}..{self.last_frame[0]}")
        return "\n".join(lines)


def receive(s, st, buf, deadline, next_summary, text, out, args):
    while time.monotonic() < deadline:
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
                st.bad_frames += 1
                del buf[:1]
                continue
            total = HEADER.size + length + 4
            if len(buf) < total:
                break
            body = bytes(buf[HEADER.size:HEADER.size + length])
            (crc,) = struct.unpack_from("<I", buf, HEADER.size + length)
            del buf[:total]
            if zlib.crc32(body) != crc:
                st.crc_errors += 1
                print(f"!! CRC error in frame seq {seq}")
                continue
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
            path = out / f"w{window:06d}_f{index:07d}_s{seq:05d}.jpg"
            path.write_bytes(jpeg)
            ok = jpeg[:2] == b"\xff\xd8" and jpeg[-2:] == b"\xff\xd9"
            dec = decode_ok(jpeg)
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
            m = FRAME_LINE.match(line)
            if m:
                st.frame_line(int(m.group(1)), now)
            if not args.quiet or BOOT_BANNER in line or line.startswith(EOI_ERROR):
                print(line.decode("ascii", "replace"))

    try:
        receive(s, st, buf, deadline, next_summary, text, out, args)
    except KeyboardInterrupt:
        pass
    finally:
        park(s)

    print()
    print(st.summary())
    ok = (st.images > 0 and st.crc_errors == 0 and st.bad_frames == 0 and st.seq_gaps == 0
          and st.decode_failures == 0 and st.eoi_errors == 0 and st.resets == 0
          and st.first_frame is not None and st.first_frame[0] > 0)
    if st.first_frame is not None and st.first_frame[0] == 0:
        print("!! the first frame seen was frame 0: the board started (or restarted) while the receiver was open")
    print("STAGE 1:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
