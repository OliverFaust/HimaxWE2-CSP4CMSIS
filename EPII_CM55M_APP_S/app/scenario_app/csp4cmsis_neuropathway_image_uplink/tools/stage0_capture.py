#!/usr/bin/env python3
"""Stage 0 gate: capture the WDMA2 retargeting test from the console and rebuild both JPEGs.

Reads the board's console (or a saved log), echoes it, counts the per-frame
BufferCheck lines, and writes each `JPEG BEGIN ... JPEG END` hex block to
stage0_buf<id>_frame<n>.jpg. Exits 0 only if the board reported PASS, every
check line was ok, and both JPEGs have SOI/EOI markers (and decode, if Pillow
is installed).

    python3 stage0_capture.py --port /dev/ttyACM0
    python3 stage0_capture.py --log console.txt
"""
import argparse
import io
import pathlib
import re
import sys
import time

CHECK = re.compile(r"Camera: frame (\d+) buf (\d) jpeg_addr (0x[0-9a-f]+) wdma2 (0x[0-9a-f]+) size (\d+) flags ([0-9a-f]+) (ok|FAIL)")
VERDICT = re.compile(r"Camera: STAGE0 (PASS|FAIL) \((\d+) of (\d+) frames ok\)")
BEGIN = re.compile(r"JPEG BEGIN buf=(\d) frame=(\d+) size=(\d+)")
END = re.compile(r"JPEG END buf=(\d)")


def lines_from_port(port, baud, timeout_s):
    import serial
    with serial.Serial(port, baud, timeout=1) as s:
        deadline = time.monotonic() + timeout_s
        buf = b""
        while time.monotonic() < deadline:
            buf += s.read(4096)
            *done, buf = buf.split(b"\n")
            for raw in done:
                yield raw.decode("ascii", "replace").rstrip("\r")


def lines_from_log(path):
    with open(path, "r", encoding="ascii", errors="replace") as f:
        for line in f:
            yield line.rstrip("\r\n")


def check_jpeg(data):
    problems = []
    if data[:2] != b"\xff\xd8":
        problems.append("no SOI")
    if b"\xff\xd9" not in data[-6:]:
        problems.append("no EOI in last 6 bytes")
    try:
        from PIL import Image
        with Image.open(io.BytesIO(data)) as im:
            im.load()
            return problems, f"{im.size[0]}x{im.size[1]} {im.mode}"
    except ImportError:
        return problems, "not decoded (Pillow not installed)"
    except Exception as e:
        problems.append(f"decode failed: {e}")
        return problems, None


def main():
    ap = argparse.ArgumentParser()
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--port")
    src.add_argument("--log")
    ap.add_argument("--baud", type=int, default=921600)
    ap.add_argument("--timeout", type=float, default=60.0)
    ap.add_argument("--out", default=".")
    args = ap.parse_args()

    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    lines = lines_from_port(args.port, args.baud, args.timeout) if args.port else lines_from_log(args.log)

    checks, fails, addrs = 0, [], {}
    verdict = None
    jpegs = {}
    current = None

    for line in lines:
        if current is not None:
            m = END.search(line)
            if m:
                buf_id, frame, size, hexdata = current
                data = bytes.fromhex("".join(hexdata))
                if len(data) != size:
                    print(f"!! buf {buf_id}: got {len(data)} bytes, expected {size}")
                jpegs[buf_id] = (frame, data)
                current = None
                if len(jpegs) == 2:
                    break
            else:
                current[3].append(line.strip())
            continue

        print(line)
        m = CHECK.search(line)
        if m:
            checks += 1
            frame, buf_id, info_addr, hw_addr, size, flags, ok = m.groups()
            addrs.setdefault(int(buf_id), set()).add((info_addr, hw_addr))
            if ok != "ok":
                fails.append(line)
            continue
        m = VERDICT.search(line)
        if m:
            verdict = m.groups()
            continue
        m = BEGIN.search(line)
        if m:
            current = (int(m.group(1)), int(m.group(2)), int(m.group(3)), [])

    print()
    print(f"check lines: {checks}, failed: {len(fails)}")
    for f in fails[:10]:
        print(f"  {f}")
    for buf_id, pairs in sorted(addrs.items()):
        print(f"buf {buf_id}: (jpeg_addr, wdma2) seen = {sorted(pairs)}")
    if len(addrs) == 2:
        a0 = {p[1] for p in addrs[0]}
        a1 = {p[1] for p in addrs[1]}
        if a0 & a1:
            fails.append("both buffers report the same WDMA2 address")
            print("!! both buffers report the same WDMA2 address")
    print(f"board verdict: {verdict}")

    ok = verdict is not None and verdict[0] == "PASS" and not fails and len(jpegs) == 2
    for buf_id, (frame, data) in sorted(jpegs.items()):
        path = out / f"stage0_buf{buf_id}_frame{frame}.jpg"
        path.write_bytes(data)
        problems, info = check_jpeg(data)
        print(f"{path}: {len(data)} bytes, {info}" + (f", PROBLEMS: {problems}" if problems else ""))
        ok = ok and not problems
    if len(jpegs) == 2 and jpegs[0][1] == jpegs[1][1]:
        print("!! the two JPEGs are byte-identical")
        ok = False

    print("STAGE 0:", "PASS" if ok else "FAIL")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
