#!/usr/bin/env python3
"""Run the person-detection model on the PC on SD-card frames and compare
with the board's scores.

The board runs person_detect_model_data_vela.cc, the Vela-compiled model
(one ethos-u custom operator), which only runs on the NPU. Its source is the
int8 TFLM person-detection model, in this repository as
library/inference/tflmtag2209_u55tag2205/tensorflow/lite/micro/models/
person_detect_model_data.cc (the same bytes as
app/scenario_app/allon_sensor_tflm_cmsis_nn/person_detect_model_data.cc):
the same input [1, 96, 96, 1] int8, scale 1/127.5, zero point -1, and output
[1, 2] int8, scale 1/256, zero point -128, as the Vela model. This script
reads the byte array from that .cc file (or uses --model, a .tflite file).
TF Lite refuses 14 of its bias tensors, which have per-channel scales but
quantized_dimension 3 on a 1-D tensor (TFLM ignores it); they are set to 0
in memory, nothing else changes.

Each frame's .y file (manifest.csv in the frames folder) is rescaled to 96x96
exactly as img_rescale() in cvapp.cpp does (8-bit fixed-point bilinear,
truncating, minus 128), and run with the reference kernels (no XNNPACK; or
--xnnpack). The person score is output[1], the no-person score output[0], as
in cv_invoke().

With --scores (the board's scores.csv from uplink_rx.py or the GUI), board
frame f is manifest row (f - first) mod N, first being --first or the lowest
frame in scores.csv: this holds when FileSource skipped no frame. It prints
how many board scores match exactly and the largest difference, and writes
ref_scores.csv into --out (default: the frames folder).

Needs TensorFlow (tf.lite) and numpy, e.g. the conda env "tf":
    ~/anaconda3/envs/tf/bin/python ref_infer.py sd_frames --scores run/scores.csv --out run
"""
import argparse
import csv
import importlib.util
import pathlib
import re
import sys

import numpy as np

REPO_APP = pathlib.Path(__file__).resolve().parents[1]
DEFAULT_CC = (REPO_APP.parents[2] / "library" / "inference" / "tflmtag2209_u55tag2205" / "tensorflow" / "lite" /
              "micro" / "models" / "person_detect_model_data.cc")
SIZE = 96
FRAQ = 8


def model_from_cc(path):
    text = pathlib.Path(path).read_text()
    start = text.index("{", text.index("[]")) + 1
    return bytes(int(x, 16) for x in re.findall(r"0x([0-9a-fA-F]{2})", text[start:text.index("}", start)]))


def fix_quantized_dimension(data, tf):
    path = pathlib.Path(tf.__file__).parent / "lite" / "python" / "schema_py_generated.py"
    spec = importlib.util.spec_from_file_location("tflite_schema", path)
    schema = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(schema)
    import flatbuffers
    model = schema.ModelT.InitFromObj(schema.Model.GetRootAsModel(data, 0))
    fixed = 0
    for g in model.subgraphs:
        for t in g.tensors:
            q = t.quantization
            if q is not None and q.scale is not None and len(t.shape) <= q.quantizedDimension:
                q.quantizedDimension = 0
                fixed += 1
    b = flatbuffers.Builder(1024)
    b.Finish(model.Pack(b), file_identifier=b"TFL3")
    return bytes(b.Output()), fixed


def rescale(y, w, h):
    nx = (w << FRAQ) // SIZE
    ny = (h << FRAQ) // SIZE
    img = np.frombuffer(y, dtype=np.uint8).reshape(h, w).astype(np.int64)
    xs = np.arange(SIZE, dtype=np.int64)
    ys = np.arange(SIZE, dtype=np.int64)
    fx = (xs * nx) >> FRAQ
    fy = (ys * ny) >> FRAQ
    cx = np.where(fx + 1 >= w, fx, fx + 1)
    cy = np.where(fy + 1 >= h, fy, fy + 1)
    ax = xs * nx - (fx << FRAQ)
    ay = ys * ny - (fy << FRAQ)
    bx = (1 << FRAQ) - ax
    by = (1 << FRAQ) - ay
    p0 = img[fy][:, fx]
    p1 = img[fy][:, cx]
    p2 = img[cy][:, fx]
    p3 = img[cy][:, cx]
    out = by[:, None] * (bx[None, :] * p0 + ax[None, :] * p1) + ay[:, None] * (bx[None, :] * p2 + ax[None, :] * p3)
    out = out >> (FRAQ * 2)
    return (out - 128).astype(np.int8)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("frames", help="folder with manifest.csv and the .y files")
    ap.add_argument("--model", help=".tflite file (default: the int8 model from the .cc file)")
    ap.add_argument("--model-cc", default=str(DEFAULT_CC), help="TFLM model .cc file")
    ap.add_argument("--scores", help="board scores.csv to compare with")
    ap.add_argument("--first", type=int, help="board frame index of manifest row 0")
    ap.add_argument("--out", help="folder for ref_scores.csv (default: the frames folder)")
    ap.add_argument("--xnnpack", action="store_true", help="use TF Lite's default kernels (XNNPACK)")
    args = ap.parse_args()

    import tensorflow as tf
    if args.model:
        data, fixed, source = pathlib.Path(args.model).read_bytes(), 0, args.model
    else:
        data, fixed = fix_quantized_dimension(model_from_cc(args.model_cc), tf)
        source = args.model_cc
    resolver = (tf.lite.experimental.OpResolverType.AUTO if args.xnnpack
                else tf.lite.experimental.OpResolverType.BUILTIN_REF)
    it = tf.lite.Interpreter(model_content=data, experimental_op_resolver_type=resolver)
    it.allocate_tensors()
    inp = it.get_input_details()[0]
    outp = it.get_output_details()[0]
    print(f"model {source} ({len(data)} bytes, {fixed} quantized_dimension fields set to 0), "
          f"{'XNNPACK' if args.xnnpack else 'reference kernels'}")

    frames = pathlib.Path(args.frames)
    with open(frames / "manifest.csv", newline="") as f:
        rows = list(csv.DictReader(f))
    ref = []
    for r in rows:
        w, h = int(r["width"]), int(r["height"])
        x = rescale((frames / r["y_file"]).read_bytes(), w, h)
        it.set_tensor(inp["index"], x.reshape(1, SIZE, SIZE, 1))
        it.invoke()
        o = it.get_tensor(outp["index"])[0]
        ref.append((int(o[1]), int(o[0])))
    out = pathlib.Path(args.out) if args.out else frames
    with open(out / "ref_scores.csv", "w", newline="") as f:
        wr = csv.writer(f, lineterminator="\n")
        wr.writerow(["row", "y_file", "label", "person", "no_person"])
        for r, (p, n) in zip(rows, ref):
            wr.writerow([r["index"], r["y_file"], r["label"], p, n])
    print(f"{len(ref)} frames -> {out / 'ref_scores.csv'}")

    if args.scores:
        with open(args.scores, newline="") as f:
            board = [(int(r["frame"]), int(r["person"]), int(r["no_person"])) for r in csv.DictReader(f)]
        first = args.first if args.first is not None else min(b[0] for b in board)
        exact = 0
        diffs = []
        worst = None
        for frame, p, n in board:
            rp, rn = ref[(frame - first) % len(ref)]
            d = max(abs(p - rp), abs(n - rn))
            diffs.append(d)
            exact += d == 0
            if worst is None or d > worst[0]:
                worst = (d, frame, p, n, rp, rn)
        hist = {d: diffs.count(d) for d in sorted(set(diffs))}
        print(f"board scores {len(board)} (frames {min(b[0] for b in board)}..{max(b[0] for b in board)}, "
              f"row 0 = frame {first}): exact {exact}, largest difference {worst[0]} "
              f"(frame {worst[1]}: board {worst[2]}/{worst[3]}, PC {worst[4]}/{worst[5]}); differences {hist}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
