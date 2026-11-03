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
"""
import argparse
import bisect
import csv
import pathlib
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
        w["p"] = [int(w[f"p{k}"]) for k in range(WINDOW)] if w["p0"] else None
        w["n"] = [int(w[f"n{k}"]) for k in range(WINDOW)] if w["n0"] else None
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run")
    ap.add_argument("--phases", help="phase table (default: phases.csv in the run folder)")
    ap.add_argument("--settle", type=float, default=5.0)
    ap.add_argument("--no-sheets", action="store_true")
    args = ap.parse_args()

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
