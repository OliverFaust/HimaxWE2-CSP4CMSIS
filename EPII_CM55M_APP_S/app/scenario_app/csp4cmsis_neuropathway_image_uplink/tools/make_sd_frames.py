#!/usr/bin/env python3
"""Make frames for the SD-card frame source (FileSource).

Inputs are video files (decoded with ffmpeg) and image files, in the order
given. Each frame is centre-cropped to 4:3, scaled to --size (640x480 by
default, or 320x240) and written to the output directory as

  fNNNNNN.y    the 8-bit luma plane, width x height bytes, row by row: the
               Y plane at the start of the board's YUV420 raw buffer, which
               is all that img_rescale() reads (luma = 0.299 R + 0.587 G +
               0.114 B, full range, as Pillow's "L" conversion)
  fNNNNNN.jpg  the same frame as a baseline JPEG, 4:2:0, at --quality (60
               by default: its luminance table is the board's 4x table, 13,
               9, 8, 13, ..., and its chrominance table differs from the
               board's in one entry)

and listed in manifest.csv:

  index, y_file, jpg_file, width, height, crc32_y, crc32_jpg, label,
  source, source_frame, fps

crc32 is the zlib CRC-32 (the board's crc32_update()) as 8 hex digits.
label is 1 (person), 0 (no person) or empty (unknown), from --labels: a CSV
with the columns source, first, last, label (source is the input's file name,
first and last are inclusive source frame numbers; an image is frame 0).
fps is the source frame rate divided by --every (videos) or --fps (images);
FileSource's default pace is 1000 / fps ms.

The output directory must be new or empty; nothing is written outside it.
Copy its contents to the card's /frames/ directory.

    python3 make_sd_frames.py --out sd_frames clip.mp4 --every 2 --max-frames 200
    python3 make_sd_frames.py --out sd320 --size 320x240 img/*.jpg --fps 4
    python3 make_sd_frames.py --crc raw640.y raw320.y small.jpg

--crc only prints the size and CRC-32 of each file, e.g. the bench files, to
check the board's SdBench lines against the PC.
"""
import argparse
import csv
import io
import json
import pathlib
import subprocess
import sys
import zlib

import numpy as np
from PIL import Image

SIZES = {"640x480": (640, 480), "320x240": (320, 240)}
VIDEO_SUFFIXES = {".mp4", ".avi", ".mov", ".mkv", ".webm", ".m4v", ".mpg", ".mpeg"}
JPEG_BUFFER = 115872


def crc32(data):
    return zlib.crc32(data) & 0xFFFFFFFF


def crop_4_3(img):
    w, h = img.size
    if w * 3 > h * 4:
        cw, ch = (h * 4 + 1) // 3, h
    else:
        cw, ch = w, (w * 3 + 2) // 4
    x, y = (w - cw) // 2, (h - ch) // 2
    return img.crop((x, y, x + cw, y + ch))


def video_info(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                          "stream=width,height,r_frame_rate", "-of", "json", str(path)],
                         check=True, capture_output=True, text=True).stdout
    s = json.loads(out)["streams"][0]
    num, den = s["r_frame_rate"].split("/")
    return int(s["width"]), int(s["height"]), float(num) / float(den)


def video_frames(path):
    w, h, fps = video_info(path)
    proc = subprocess.Popen(["ffmpeg", "-v", "error", "-i", str(path), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                            stdout=subprocess.PIPE)
    n = w * h * 3
    k = 0
    try:
        while True:
            buf = proc.stdout.read(n)
            if len(buf) < n:
                break
            yield k, Image.frombuffer("RGB", (w, h), buf, "raw", "RGB", 0, 1), fps
            k += 1
    finally:
        if proc.poll() is None:
            proc.kill()
        proc.stdout.close()
        proc.wait()


def read_labels(path):
    table = []
    if path:
        with open(path, newline="") as f:
            for r in csv.DictReader(f):
                table.append((r["source"], int(r["first"]), int(r["last"]), r["label"].strip()))
    return table


def label_of(table, source, frame):
    for s, first, last, label in table:
        if s == source and first <= frame <= last:
            return label
    return ""


def inputs(args):
    for p in args.inputs:
        path = pathlib.Path(p)
        if path.suffix.lower() in VIDEO_SUFFIXES:
            for k, img, fps in video_frames(path):
                if k % args.every == 0:
                    yield path.name, k, img, fps / args.every
        else:
            with Image.open(path) as img:
                yield path.name, 0, img.convert("RGB"), args.fps


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("inputs", nargs="*")
    ap.add_argument("--out", help="output directory (new or empty)")
    ap.add_argument("--size", choices=sorted(SIZES), default="640x480")
    ap.add_argument("--quality", type=int, default=60, help="JPEG quality (default 60, the board's 4x tables)")
    ap.add_argument("--every", type=int, default=1, help="take every Nth video frame")
    ap.add_argument("--max-frames", type=int, default=0, help="stop after this many frames (0: all)")
    ap.add_argument("--fps", type=float, default=8.26, help="frame rate recorded for image inputs")
    ap.add_argument("--labels", help="CSV with source, first, last, label")
    ap.add_argument("--crc", nargs="+", metavar="FILE", help="only print size and CRC-32 of these files")
    args = ap.parse_args()

    if args.crc:
        for p in args.crc:
            data = pathlib.Path(p).read_bytes()
            print(f"{p}: {len(data)} bytes, crc32 {crc32(data):08x}")
        return 0
    if not args.out or not args.inputs:
        ap.error("--out and at least one input are needed (or --crc)")
    if args.every < 1:
        ap.error("--every must be at least 1")

    out = pathlib.Path(args.out).resolve()
    if out.exists() and any(out.iterdir()):
        ap.error(f"{out} is not empty")
    out.mkdir(parents=True, exist_ok=True)
    w, h = SIZES[args.size]
    labels = read_labels(args.labels)

    rows = []
    sizes = []
    for source, k, img, fps in inputs(args):
        if args.max_frames and len(rows) >= args.max_frames:
            break
        i = len(rows)
        frame = crop_4_3(img).resize((w, h), Image.Resampling.LANCZOS)
        y = np.asarray(frame.convert("L"), dtype=np.uint8).tobytes()
        buf = io.BytesIO()
        frame.save(buf, "JPEG", quality=args.quality, subsampling="4:2:0", optimize=False, progressive=False)
        jpg = buf.getvalue()
        if not (jpg[:2] == b"\xff\xd8" and jpg[-2:] == b"\xff\xd9"):
            sys.exit(f"frame {i}: JPEG without SOI/EOI")
        if len(jpg) > JPEG_BUFFER:
            sys.exit(f"frame {i}: JPEG of {len(jpg)} bytes does not fit the board's {JPEG_BUFFER}-byte buffer; "
                     f"lower --quality")
        y_name, jpg_name = f"f{i:06d}.y", f"f{i:06d}.jpg"
        (out / y_name).write_bytes(y)
        (out / jpg_name).write_bytes(jpg)
        sizes.append(len(jpg))
        rows.append([i, y_name, jpg_name, w, h, f"{crc32(y):08x}", f"{crc32(jpg):08x}",
                     label_of(labels, source, k), source, k, f"{fps:.3f}"])

    with open(out / "manifest.csv", "w", newline="") as f:
        wr = csv.writer(f, lineterminator="\n")
        wr.writerow(["index", "y_file", "jpg_file", "width", "height", "crc32_y", "crc32_jpg", "label",
                     "source", "source_frame", "fps"])
        wr.writerows(rows)
    if rows:
        print(f"{len(rows)} frames {w}x{h} in {out}; JPEG {min(sizes)}..{max(sizes)} bytes, "
              f"mean {sum(sizes) // len(sizes)}")
    else:
        print("no frames")
    return 0


if __name__ == "__main__":
    sys.exit(main())
