#!/usr/bin/env python3
"""Analyse a score-log run recorded by uplink_rx.py --prompts.

Reads windows.csv, images.csv and phases.csv from the run folder and prints,
and writes to analysis.txt:
  - per phase (and per prompt step): person-score min, median, 90th
    percentile and max over all logged frames, the same for the window-best
    scores, and the fraction of frames with person > no-person;
  - the best-frame check: in every window the logged best is the first
    maximum of p0..p19, and the image saved for it has that frame and score;
  - a histogram of the best frame's position in its window;
  - the drift between the empty phases and the margin between the empty
    phases' highest window-best score and the stand phase's lowest;
  - a threshold table: for thresholds T on the window-best score, the
    fraction of windows with best > T, per phase;
  - a contact sheet per phase, sheet_<phase>.png (needs Pillow).
The person probability of a score s is (s + 128) / 256 (int8 output, scale
1/256, zero point -128), so 50 % is s = 0.

A window belongs to the phase in force at its midpoint (the line's PC time
minus half a window). Windows that start less than --settle seconds after the
phase changed are left out of the statistics (the operator is still moving)
but kept on the contact sheets, marked with *.

    python3 analyse_run.py run_person1

With --manifest (an SD-card run, FRAME_SOURCE=sdcard): joins the board's
per-frame scores (scores.csv) with the labels in the manifest that was on the
card, by frame index. FileSource numbers the frames it passes on
consecutively, so frame f is manifest row (f - first) mod N, first being the
first frame of the stream (from the chosen "FileSource: started" line in
console.log, --stream, default the last; or --first). The stream ends at the
next "started" line. A stream in which FileSource skipped a frame (read or
CRC error) is refused, since the join would be off from there. It prints per
set (the manifest's source column) and overall the hit rate (labelled
positives with score >= T) and the false-detection rate (labelled negatives
with score >= T) at T = 50 %, a threshold table, and whether rows seen in
several passes got the same score; it writes evaluation.txt and
evaluation_frames.csv into the run folder.

    python3 analyse_run.py eval_run --manifest eval/manifest.csv
"""
import argparse
import bisect
import csv
import math
import pathlib
import re
import statistics
import sys

WINDOW = 20
WINDOW_S = WINDOW / 19.4


def pct(values, q):
    v = sorted(values)
    return v[min(len(v) - 1, max(0, int(round(q * len(v) + 0.5)) - 1))]


def dist(values):
    if not values:
        return "-"
    return (f"min {min(values):4d}  med {statistics.median(values):6.1f}  "
            f"p90 {pct(values, 0.9):4d}  max {max(values):4d}")


def load(run, phases_path):
    with open(run / "windows.csv", newline="") as f:
        windows = [r for r in csv.DictReader(f)]
    with open(run / "images.csv", newline="") as f:
        images = {int(r["window"]): r for r in csv.DictReader(f)}
    with open(phases_path, newline="") as f:
        steps = sorted(((float(r["start_s"]), r["phase"], r["prompt"]) for r in csv.DictReader(f)),
                       key=lambda s: s[0])
    for w in windows:
        for k in ("window", "first", "last", "merged", "failed"):
            w[k] = int(w[k])
        w["best"] = int(w["best"]) if w["best"] else None
        w["best_score"] = int(w["best_score"]) if w["best_score"] else None
        w["t_pc"] = float(w["t_pc"])
        w["p"] = [int(w[f"p{k}"]) for k in range(WINDOW) if w[f"p{k}"]] if w["p0"] else None
        w["n"] = [int(w[f"n{k}"]) for k in range(WINDOW) if w[f"n{k}"]] if w["n0"] else None
    return windows, images, steps


def assign(windows, steps, settle):
    starts = [s[0] for s in steps]
    changes = [s[0] for i, s in enumerate(steps) if i == 0 or s[1] != steps[i - 1][1]]
    for w in windows:
        mid = w["t_pc"] - WINDOW_S / 2
        i = bisect.bisect_right(starts, mid) - 1
        w["phase"] = steps[i][1] if i >= 0 else None
        w["step"] = i
        j = bisect.bisect_right(changes, mid) - 1
        w["settling"] = j < 0 or (w["t_pc"] - WINDOW_S) - changes[j] < settle


def best_check(windows, images):
    checked, bad = 0, []
    for w in windows:
        if w["p"] is None or w["merged"] or w["failed"] or w["best"] is None:
            continue
        checked += 1
        k = w["p"].index(max(w["p"]))
        problems = []
        if w["first"] + k != w["best"]:
            problems.append(f"first maximum is frame {w['first'] + k}, logged best {w['best']}")
        if w["p"][k] != w["best_score"]:
            problems.append(f"maximum {w['p'][k]}, logged score {w['best_score']}")
        img = images.get(w["window"])
        if img is None:
            problems.append("no image")
        elif int(img["frame"]) != w["best"] or int(img["score"]) != w["best_score"]:
            problems.append(f"image frame {img['frame']} score {img['score']}")
        if problems:
            bad.append((w["window"], problems))
    return checked, bad


def contact_sheet(path, phase, rows, run):
    from PIL import Image, ImageDraw, ImageFont
    tw, th, lh, cols = 160, 120, 14, 10
    n = len(rows)
    sheet = Image.new("RGB", (cols * tw, 20 + ((n + cols - 1) // cols) * (th + lh)), "white")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    draw.text((4, 4), f"{phase}: {n} windows (* = settling, not in the statistics)", fill="black", font=font)
    for i, (w, img) in enumerate(rows):
        x, y = (i % cols) * tw, 20 + (i // cols) * (th + lh)
        if img is not None:
            with Image.open(run / img["file"]) as im:
                im.thumbnail((tw, th))
                sheet.paste(im, (x, y))
        label = f"w{w['window']} s{w['best_score']} {phase}{' *' if w['settling'] else ''}"
        draw.text((x + 2, y + th), label, fill="black", font=font)
    sheet.save(path)


EVAL_PERCENT = (10, 20, 30, 40, 50, 60, 70, 80, 90)
STARTED = re.compile(r"^\s*([0-9.]+) FileSource: started (\d+) frames")
FILE_ERROR = re.compile(r"^\s*([0-9.]+) FileSource: frame \d+ .*(FAILED|CRC mismatch|wrong size)")


def score_at(percent):
    return math.ceil(256 * percent / 100 - 128)


def rate(k, n):
    return f"{k / n:6.1%} ({k}/{n})" if n else "     - (0/0)"


def evaluate(args):
    run = pathlib.Path(args.run)
    with open(args.manifest, newline="") as f:
        rows = list(csv.DictReader(f))
    n_rows = len(rows)
    starts, errors = [], []
    log = run / "console.log"
    if log.exists():
        for line in log.read_text(errors="replace").splitlines():
            m = STARTED.match(line)
            if m:
                starts.append((float(m.group(1)), int(m.group(2))))
            m = FILE_ERROR.match(line)
            if m:
                errors.append((float(m.group(1)), line.strip()))
    scores = []
    with open(run / "scores.csv", newline="") as f:
        for r in csv.DictReader(f):
            scores.append((int(r["frame"]), int(r["person"]), float(r["t_pc"])))
    t_start, t_end = 0.0, math.inf
    if args.first is None:
        if not starts:
            sys.exit("no 'FileSource: started' line in console.log; give --first")
        k = args.stream if args.stream is not None else len(starts) - 1
        t_start = starts[k][0]
        if k + 1 < len(starts):
            t_end = starts[k + 1][0]
        if starts[k][1] != n_rows:
            sys.exit(f"the stream has {starts[k][1]} frames, the manifest {n_rows}: not the same set")
    stream = [(f, p) for f, p, t in scores if t_start < t < t_end]
    if not stream:
        sys.exit("no scores in the chosen stream")
    first = args.first if args.first is not None else min(f for f, _ in stream)
    stream = sorted((f, p) for f, p in stream if f >= first)
    bad = [line for t, line in errors if t_start < t < t_end]
    if bad:
        sys.exit("FileSource skipped frames in this stream, so frame indices no longer match manifest rows:\n  "
                 + "\n  ".join(bad[:5]))

    out = []

    def say(text=""):
        out.append(text)
        print(text)

    seen = {}
    frames = []
    for f, p in stream:
        row = (f - first) % n_rows
        r = rows[row]
        frames.append((f, row, r["source"], r["label"].strip(), p))
        seen.setdefault(row, set()).add(p)
    sets = sorted({s for _, _, s, _, _ in frames})
    unlabelled = sum(1 for x in frames if x[3] not in ("0", "1"))
    passes = len(frames) / n_rows
    say(f"run {run}, manifest {args.manifest} ({n_rows} rows): frames {stream[0][0]}..{stream[-1][0]} "
        f"({len(frames)} scores, {passes:.2f} passes), row 0 = frame {first}; {unlabelled} unlabelled")
    repeated = [row for row, ps in seen.items() if len(ps) > 1]
    multi = sum(1 for row in seen if sum(1 for x in frames if x[1] == row) > 1)
    if multi:
        say(f"rows seen in more than one pass: {multi}, with differing scores: {len(repeated)}")
    say()

    def counts(selection, threshold):
        pos = [x for x in selection if x[3] == "1"]
        neg = [x for x in selection if x[3] == "0"]
        return (sum(x[4] >= threshold for x in pos), len(pos), sum(x[4] >= threshold for x in neg), len(neg))

    t50 = score_at(50)
    say(f"at T = 50 % (score >= {t50}), per frame")
    say(f"  {'set':12s} {'hit rate':>18s} {'false detections':>20s}")
    for name in sets + ["all"]:
        sel = frames if name == "all" else [x for x in frames if x[2] == name]
        h, p, fd, n = counts(sel, t50)
        say(f"  {name:12s} {rate(h, p):>18s} {rate(fd, n):>20s}")
    say()

    say("threshold table, per frame: hit rate / false-detection rate")
    say(f"  {'T':>4s} {'score':>6s}  " + "  ".join(f"{name:>15s}" for name in sets + ["all"]))
    for pc in EVAL_PERCENT:
        t = score_at(pc)
        cells = []
        for name in sets + ["all"]:
            sel = frames if name == "all" else [x for x in frames if x[2] == name]
            h, p, fd, n = counts(sel, t)
            cells.append((f"{h / p:6.1%}" if p else "     -") + " / " + (f"{fd / n:6.1%}" if n else "     -"))
        say(f"  {pc:3d}% {t:6d}  " + "  ".join(f"{c:>15s}" for c in cells))

    (run / "evaluation.txt").write_text("\n".join(out) + "\n")
    with open(run / "evaluation_frames.csv", "w", newline="") as f:
        wr = csv.writer(f, lineterminator="\n")
        wr.writerow(["frame", "row", "set", "label", "person"])
        wr.writerows(frames)
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run")
    ap.add_argument("--phases", help="phase table (default: phases.csv in the run folder)")
    ap.add_argument("--settle", type=float, default=5.0)
    ap.add_argument("--no-sheets", action="store_true")
    ap.add_argument("--manifest", help="manifest.csv of an SD-card run: evaluate against its labels")
    ap.add_argument("--stream", type=int, help="which 'FileSource: started' line (0 = first; default the last)")
    ap.add_argument("--first", type=int, help="board frame index of manifest row 0")
    args = ap.parse_args()
    if args.manifest:
        return evaluate(args)

    run = pathlib.Path(args.run)
    windows, images, steps = load(run, pathlib.Path(args.phases) if args.phases else run / "phases.csv")
    assign(windows, steps, args.settle)
    out = []

    def say(s=""):
        out.append(s)
        print(s)

    phases = []
    for _, name, _ in steps:
        if name not in phases and any(w["phase"] == name for w in windows):
            phases.append(name)
    used = [w for w in windows if w["phase"] and not w["settling"] and w["p"] is not None]
    say(f"run {run}: {len(windows)} window lines, {len(used)} in the statistics "
        f"(settle {args.settle:.0f} s), {len(images)} images")
    at50 = sum(w["best_score"] is not None and w["best_score"] >= 0 for w in windows)
    say(f"window lines with best score >= 0 (person probability >= 50 %): {at50} of {len(windows)}")
    say()

    say("person score per frame / window-best score, per phase")
    for name in phases:
        ws = [w for w in used if w["phase"] == name]
        frames = [p for w in ws for p in w["p"]]
        wins = sum((p > n) for w in ws for p, n in zip(w["p"], w["n"]))
        say(f"  {name:9s} {len(ws):4d} windows  frames: {dist(frames)}  "
            f"person>no-person {wins / max(1, len(frames)):6.1%}")
        say(f"  {'':9s} {'':12s}  best:   {dist([w['best_score'] for w in ws])}")
    say()

    say("per prompt step")
    for i, (start, name, prompt) in enumerate(steps):
        ws = [w for w in used if w["step"] == i]
        if not ws:
            continue
        say(f"  {start:5.0f} s {name:9s} {len(ws):3d} windows  best: {dist([w['best_score'] for w in ws])}  {prompt}")
    say()

    checked, bad = best_check(windows, images)
    say(f"best-frame check: {checked - len(bad)} of {checked} windows correct"
        + ("" if checked else " (no score log in this run)"))
    for window, problems in bad[:20]:
        say(f"  !! window {window}: {'; '.join(problems)}")
    say()

    say("position of the best frame in its window (all windows, not merged)")
    pos = [0] * WINDOW
    for w in windows:
        if w["best"] is not None and not w["merged"]:
            pos[w["best"] - w["first"]] += 1
    top = max(pos) or 1
    for k, c in enumerate(pos):
        say(f"  {k:2d} {c:4d} {'#' * round(40 * c / top)}")
    say()

    empty = [n for n in phases if n.startswith("empty")]
    person = [n for n in phases if not n.startswith("empty")]
    best_of = {n: [w["best_score"] for w in used if w["phase"] == n] for n in phases}
    if len(empty) >= 2:
        a, b = empty[0], empty[1]
        fa = [p for w in used if w["phase"] == a for p in w["p"]]
        fb = [p for w in used if w["phase"] == b for p in w["p"]]
        if fa and fb:
            say(f"drift {a} -> {b}: frame median {statistics.median(fa):.1f} -> {statistics.median(fb):.1f}, "
                f"p90 {pct(fa, 0.9)} -> {pct(fb, 0.9)}, window-best max {max(best_of[a])} -> {max(best_of[b])}")
    empty_best = [s for n in empty for s in best_of[n]]
    if empty_best and best_of.get("stand"):
        say(f"margin: empty phases' highest window-best {max(empty_best)}, stand's lowest "
            f"{min(best_of['stand'])}, margin {min(best_of['stand']) - max(empty_best)}")
    say()

    all_best = [s for n in phases for s in best_of[n]]
    if all_best:
        say("threshold table: fraction of windows with best score > T")
        cols = ["empty"] + ["person"] + person
        say("     T " + "".join(f"{c:>10s}" for c in cols))
        person_best = [s for n in person for s in best_of[n]]
        step = max(1, (max(all_best) - min(all_best)) // 16)
        lo, hi = min(all_best) // step * step, max(all_best)
        ts = sorted(set(range(lo, hi + 1, step)) | ({max(empty_best)} if empty_best else set()))
        for t in ts:
            vals = [empty_best, person_best] + [best_of[n] for n in person]
            say(f"  {t:4d} " + "".join(f"{(sum(s > t for s in v) / len(v)) if v else 0:10.1%}" for v in vals))
        say()

    if not args.no_sheets:
        try:
            for name in phases:
                rows = [(w, images.get(w["window"])) for w in windows if w["phase"] == name]
                path = run / f"sheet_{name}.png"
                contact_sheet(path, name, rows, run)
                say(f"contact sheet {path} ({len(rows)} windows)")
        except ImportError:
            say("contact sheets skipped: Pillow not installed")

    (run / "analysis.txt").write_text("\n".join(out) + "\n")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
