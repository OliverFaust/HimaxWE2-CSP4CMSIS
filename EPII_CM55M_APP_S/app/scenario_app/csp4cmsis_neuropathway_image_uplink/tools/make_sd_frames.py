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

The output directory must be new or empty and outside this git repository;
nothing is written outside it. Copy its contents to the card's /frames/
directory (or another directory, built in with SD_FRAME_DIR).

Evaluation sets (--vww, --labelled, --images, --videos; no positional inputs):
labelled frames from several sources, each source a "set" (the manifest's
source column), balanced: a set with both labels gives as many positives as
negatives (at most --per-set frames), a set with one label up to --per-set
frames, and then frames of the larger class are dropped at random from the
one-label sets until the totals are equal (unless --no-balance), so that the
two-label sets stay balanced. The frames are shuffled (--seed), stored 100 per
subdirectory (000/f000000.y, ...), and sources.csv lists per frame the set,
the original file, its frame number, the label and, for COCO images, the
image's licence. Images are padded to 4:3 by default (--fit pad), so that
nothing that decided the label is cropped away.

  --vww ANNOTATIONS:IMAGES  Visual Wake Words: instances_val.json from
      create_visualwakewords_annotations.py (an image is a positive when its
      image_id has an annotation) and the COCO image directory (val2014).
  --labelled NAME=CSV       images with labels, columns path,label (paths
      relative to the CSV), e.g. DF26 keyframes.
  --images NAME=LABEL:GLOB  images that all have one label, e.g. board
      recordings of the empty scene (NAME=0:"run_empty/*.jpg").
  --videos NAME=LABEL:GLOB  every --every-th frame of videos with one label.

Nothing from these sets is to be committed (COCO images keep their Flickr
licences; DF26 is licence-restricted).

Visual Wake Words (github.com/Mxbonn/visualwakewords, needs pycocotools):
    bash scripts/download_mscoco.sh COCO 2014
    python scripts/create_coco_train_minival_split.py \
        --train_annotations_file=COCO/annotations/instances_train2014.json \
        --val_annotations_file=COCO/annotations/instances_val2014.json \
        --output_dir=COCO/annotations/
    python scripts/create_visualwakewords_annotations.py \
        --train_annotations_file=COCO/annotations/instances_maxitrain.json \
        --val_annotations_file=COCO/annotations/instances_minival.json \
        --output_dir=VWW/annotations/ --threshold=0.005 --foreground_class='person'
then --vww VWW/annotations/instances_val.json:COCO/val2014 (the minival
images are from val2014). COCO: the annotations are the COCO Consortium's,
under CC BY 4.0; the consortium does not own the images, whose use must
follow the Flickr Terms of Use and each image's own licence (the licence
column of sources.csv, from the annotation file); users are responsible for
their use of the images.

Own empty-scene recordings: the board sends a window's image only when it
passes the filter, so record the empty scene with every window sent, e.g.
uplink_rx.py --send-at 1 "set threshold -128" --out empty_run, and use
--images own=0:"empty_run/*.jpg" (the luma then comes from the board's JPEG,
not from its raw buffer).

    python3 make_sd_frames.py --out sd_frames clip.mp4 --every 2 --max-frames 200
    python3 make_sd_frames.py --out sd320 --size 320x240 img/*.jpg --fps 4
    python3 make_sd_frames.py --crc raw640.y raw320.y small.jpg
    python3 make_sd_frames.py --out eval --vww vww/annotations/instances_val.json:coco/val2014 \
        --images own=0:"empty_run/*.jpg" --per-set 400

--crc only prints the size and CRC-32 of each file, e.g. the bench files, to
check the board's SdBench lines against the PC.
"""
import argparse
import csv
import glob
import io
import json
import pathlib
import random
import subprocess
import sys
import zlib

import numpy as np
from PIL import Image

SIZES = {"640x480": (640, 480), "320x240": (320, 240)}
VIDEO_SUFFIXES = {".mp4", ".avi", ".mov", ".mkv", ".webm", ".m4v", ".mpg", ".mpeg"}
JPEG_BUFFER = 115872
BOARD_LINE_MAX = 160
FRAMES_PER_DIR = 100
MANIFEST_HEADER = ["index", "y_file", "jpg_file", "width", "height", "crc32_y", "crc32_jpg", "label",
                   "source", "source_frame", "fps"]


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


def pad_4_3(img):
    w, h = img.size
    cw, ch = (max(w, (h * 4 + 2) // 3), h) if w * 3 < h * 4 else (w, max(h, (w * 3 + 3) // 4))
    canvas = Image.new("RGB", (cw, ch), (128, 128, 128))
    canvas.paste(img, ((cw - w) // 2, (ch - h) // 2))
    return canvas


def write_frame(out, i, img, size, fit, quality, subdir):
    w, h = size
    frame = (pad_4_3(img) if fit == "pad" else crop_4_3(img)).resize((w, h), Image.Resampling.LANCZOS)
    y = np.asarray(frame.convert("L"), dtype=np.uint8).tobytes()
    buf = io.BytesIO()
    frame.save(buf, "JPEG", quality=quality, subsampling="4:2:0", optimize=False, progressive=False)
    jpg = buf.getvalue()
    if not (jpg[:2] == b"\xff\xd8" and jpg[-2:] == b"\xff\xd9"):
        sys.exit(f"frame {i}: JPEG without SOI/EOI")
    if len(jpg) > JPEG_BUFFER:
        sys.exit(f"frame {i}: JPEG of {len(jpg)} bytes does not fit the board's {JPEG_BUFFER}-byte buffer; "
                 f"lower --quality")
    prefix = f"{i // FRAMES_PER_DIR:03d}/" if subdir else ""
    if subdir:
        (out / prefix).mkdir(exist_ok=True)
    y_name, jpg_name = f"{prefix}f{i:06d}.y", f"{prefix}f{i:06d}.jpg"
    (out / y_name).write_bytes(y)
    (out / jpg_name).write_bytes(jpg)
    return y_name, jpg_name, crc32(y), crc32(jpg), len(jpg)


def write_manifest(out, rows):
    for r in rows:
        line = ",".join(str(v) for v in r)
        if len(line) > BOARD_LINE_MAX or "," in str(r[8]):
            sys.exit(f"manifest line too long for the board ({len(line)} > {BOARD_LINE_MAX}) or a comma in a "
                     f"source name: {line}")
    with open(out / "manifest.csv", "w", newline="") as f:
        wr = csv.writer(f, lineterminator="\n")
        wr.writerow(MANIFEST_HEADER)
        wr.writerows(rows)


def inside_repo(path):
    try:
        top = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=pathlib.Path(__file__).resolve().parent,
                             check=True, capture_output=True, text=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return False
    return pathlib.Path(top).resolve() in [path, *path.parents]


def video_frame_count(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0", "-show_entries",
                          "stream=nb_read_frames", "-of", "csv=p=0", str(path)],
                         check=True, capture_output=True, text=True).stdout
    return int(out.strip().split(",")[0])


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


def split_spec(spec, sep, what):
    if sep not in spec:
        sys.exit(f"{what}: expected '{sep}' in {spec!r}")
    return spec.split(sep, 1)


def vww_candidates(spec):
    ann, images = split_spec(spec, ":", "--vww")
    data = json.loads(pathlib.Path(ann).read_text())
    positive = {a["image_id"] for a in data["annotations"]}
    licences = {l["id"]: f"{l.get('name', '')} {l.get('url', '')}".strip() for l in data.get("licenses", [])}
    for im in data["images"]:
        yield {"set": "vww", "origin": str(pathlib.Path(images) / im["file_name"]), "frame": 0,
               "label": "1" if im["id"] in positive else "0", "licence": licences.get(im.get("license"), ""),
               "video": False}


def labelled_candidates(spec):
    name, path = split_spec(spec, "=", "--labelled")
    base = pathlib.Path(path).parent
    with open(path, newline="") as f:
        for r in csv.DictReader(f):
            label = r["label"].strip()
            if label not in ("0", "1"):
                sys.exit(f"{path}: label must be 0 or 1, not {label!r}")
            yield {"set": name, "origin": str(base / r["path"]), "frame": 0, "label": label, "licence": "",
                   "video": False}


def glob_candidates(spec, video, every):
    name, rest = split_spec(spec, "=", "--videos" if video else "--images")
    label, pattern = split_spec(rest, ":", "--videos" if video else "--images")
    if label not in ("0", "1"):
        sys.exit(f"{spec}: label must be 0 or 1")
    files = sorted(glob.glob(pattern))
    if not files:
        sys.exit(f"{spec}: no files match {pattern}")
    for p in files:
        frames = range(0, video_frame_count(p), every) if video else [0]
        for k in frames:
            yield {"set": name, "origin": p, "frame": k, "label": label, "licence": "", "video": video}


def select(candidates, per_set, balance, rng):
    by_set = {}
    for c in candidates:
        by_set.setdefault(c["set"], {"1": [], "0": []})[c["label"]].append(c)
    chosen = []
    for name, groups in by_set.items():
        for g in groups.values():
            rng.shuffle(g)
        pos, neg = groups["1"], groups["0"]
        if pos and neg:
            k = min(len(pos), len(neg), per_set // 2)
            chosen += pos[:k] + neg[:k]
        else:
            chosen += (pos or neg)[:per_set]
    if balance:
        single = {name for name, g in by_set.items() if not (g["1"] and g["0"])}
        excess = sum(1 if c["label"] == "1" else -1 for c in chosen)
        larger = "1" if excess > 0 else "0"
        trimmable = [c for c in chosen if c["set"] in single and c["label"] == larger]
        rng.shuffle(trimmable)
        drop = {id(c) for c in trimmable[:abs(excess)]}
        chosen = [c for c in chosen if id(c) not in drop]
    rng.shuffle(chosen)
    return chosen


def load_image(c, video_cache):
    if not c["video"]:
        with Image.open(c["origin"]) as img:
            return img.convert("RGB")
    frames = video_cache.get(c["origin"])
    if frames is None:
        frames = video_cache[c["origin"]] = {}
    if c["frame"] not in frames:
        wanted = sorted(k for k in video_cache["_wanted"][c["origin"]])
        for k, img, _ in video_frames(pathlib.Path(c["origin"])):
            if k in wanted:
                frames[k] = img.copy()
            if k >= wanted[-1]:
                break
    return frames.pop(c["frame"])


def eval_main(args, out, size):
    rng = random.Random(args.seed)
    candidates = []
    for spec in args.vww:
        candidates += list(vww_candidates(spec))
    for spec in args.labelled:
        candidates += list(labelled_candidates(spec))
    for spec in args.images:
        candidates += list(glob_candidates(spec, False, args.every))
    for spec in args.videos:
        candidates += list(glob_candidates(spec, True, args.every))
    chosen = select(candidates, args.per_set, not args.no_balance, rng)
    if not chosen:
        sys.exit("no frames selected")
    video_cache = {"_wanted": {}}
    for c in chosen:
        if c["video"]:
            video_cache["_wanted"].setdefault(c["origin"], set()).add(c["frame"])

    rows, sources, sizes = [], [], []
    for i, c in enumerate(chosen):
        img = load_image(c, video_cache)
        y_name, jpg_name, crc_y, crc_jpg, n = write_frame(out, i, img, size, args.fit or "pad", args.quality, True)
        sizes.append(n)
        rows.append([i, y_name, jpg_name, size[0], size[1], f"{crc_y:08x}", f"{crc_jpg:08x}", c["label"], c["set"],
                     c["frame"], f"{args.fps:.3f}"])
        sources.append([i, c["set"], c["origin"], c["frame"], c["label"], c["licence"]])
    write_manifest(out, rows)
    with open(out / "sources.csv", "w", newline="") as f:
        wr = csv.writer(f, lineterminator="\n")
        wr.writerow(["index", "set", "origin", "source_frame", "label", "licence"])
        wr.writerows(sources)
    print(f"{len(rows)} frames {size[0]}x{size[1]} in {out}; JPEG {min(sizes)}..{max(sizes)} bytes, "
          f"mean {sum(sizes) // len(sizes)}")
    counts = {}
    for c in chosen:
        counts.setdefault(c["set"], {"1": 0, "0": 0})[c["label"]] += 1
    for name, n in counts.items():
        print(f"  {name}: {n['1']} positives, {n['0']} negatives")
    print(f"  total: {sum(n['1'] for n in counts.values())} positives, {sum(n['0'] for n in counts.values())} negatives")
    return 0


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
    ap.add_argument("--fit", choices=("crop", "pad"), help="to 4:3 by centre crop (default) or padding "
                    "(default for evaluation sets)")
    ap.add_argument("--vww", action="append", default=[], metavar="ANNOTATIONS:IMAGES")
    ap.add_argument("--labelled", action="append", default=[], metavar="NAME=CSV")
    ap.add_argument("--images", action="append", default=[], metavar="NAME=LABEL:GLOB")
    ap.add_argument("--videos", action="append", default=[], metavar="NAME=LABEL:GLOB")
    ap.add_argument("--per-set", type=int, default=400, help="frames per set at most (evaluation sets)")
    ap.add_argument("--no-balance", action="store_true", help="do not trim the larger class (evaluation sets)")
    ap.add_argument("--seed", type=int, default=1)
    args = ap.parse_args()
    evaluation = bool(args.vww or args.labelled or args.images or args.videos)

    if args.crc:
        for p in args.crc:
            data = pathlib.Path(p).read_bytes()
            print(f"{p}: {len(data)} bytes, crc32 {crc32(data):08x}")
        return 0
    if evaluation and args.inputs:
        ap.error("positional inputs and evaluation sets (--vww, --labelled, --images, --videos) do not mix")
    if not args.out or not (args.inputs or evaluation):
        ap.error("--out and at least one input are needed (or --crc)")
    if args.every < 1:
        ap.error("--every must be at least 1")

    out = pathlib.Path(args.out).resolve()
    if out.exists() and any(out.iterdir()):
        ap.error(f"{out} is not empty")
    if inside_repo(out):
        ap.error(f"{out} is inside the git repository; frames are not to be committed")
    out.mkdir(parents=True, exist_ok=True)
    if evaluation:
        return eval_main(args, out, SIZES[args.size])
    w, h = SIZES[args.size]
    labels = read_labels(args.labels)

    rows = []
    sizes = []
    for source, k, img, fps in inputs(args):
        if args.max_frames and len(rows) >= args.max_frames:
            break
        i = len(rows)
        y_name, jpg_name, crc_y, crc_jpg, n = write_frame(out, i, img, (w, h), args.fit or "crop", args.quality, False)
        sizes.append(n)
        rows.append([i, y_name, jpg_name, w, h, f"{crc_y:08x}", f"{crc_jpg:08x}",
                     label_of(labels, source, k), source, k, f"{fps:.3f}"])

    write_manifest(out, rows)
    if rows:
        print(f"{len(rows)} frames {w}x{h} in {out}; JPEG {min(sizes)}..{max(sizes)} bytes, "
              f"mean {sum(sizes) // len(sizes)}")
    else:
        print("no frames")
    return 0


if __name__ == "__main__":
    sys.exit(main())
