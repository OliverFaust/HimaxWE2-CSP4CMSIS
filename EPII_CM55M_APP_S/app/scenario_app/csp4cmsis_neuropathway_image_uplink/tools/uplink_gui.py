#!/usr/bin/env python3
"""Uplink monitor: the received images, the live statistics and the console
output in one window.

Live: pick the port and press Connect; Disconnect parks the port (as
uplink_rx.py does on exit), so reconnecting does not reset the board. The
first open after another program (the flasher, a terminal) still resets the
board once. With Record on, the run is written to the output folder as by
uplink_rx.py (JPEGs, windows.csv, images.csv, console.log), so analyse_run.py
can read it.

Replay: --replay <folder> plays a recorded run: console.log if the folder
has one, otherwise windows.csv and images.csv (folders recorded before
console.log existed). The speed can be changed while it plays. The GUI logs
each Connect and Disconnect in console.log, and replay resynchronises at a
Connect as the live reader did, so the counts come out the same.

The person threshold is a display and statistics setting only. The model's
output is int8 with scale 1/256 and zero point -128, so a score s is the
probability p = (s + 128) / 256 and 50 % is s = 0.

The image is shown at 1:1 or the largest integer scale that fits, never
stretched. Fonts, plots and widget sizes follow the desktop's scaling: Tk
assumes 96 dpi, so the GUI reads Xft.dpi (192 at 200 %) and scales by
Xft.dpi / 96, or by --scale. "Display correction" applies a gray-world white balance and gamma
2.2 to what is shown; the saved JPEGs stay as received.

A reader thread does the serial I/O (or the replay) and the parsing and puts
events on a queue; the Tk main loop drains it every 50 ms and never touches
the port.

    python3 uplink_gui.py
    python3 uplink_gui.py --port /dev/ttyACM0 --connect --out run1 --record
    python3 uplink_gui.py --replay run_person1 --speed 10
"""
import argparse
import bisect
import collections
import csv
import io
import math
import pathlib
import queue
import re
import subprocess
import sys
import threading
import time
import tkinter as tk
from tkinter import filedialog, font as tkfont, ttk

import numpy as np
from PIL import Image, ImageTk

import matplotlib
matplotlib.use("TkAgg")
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.figure import Figure

from uplink_proto import (COMMAND_LINE, IMAGE_LOG, RX_PREFIX, SETTING_NAMES, UPLINK_WINDOW, Recorder, Session,
                          Stats, Window, list_ports, open_port, park, parse_applied, parse_settings, probability,
                          score_at, window_text)

DRAIN_MS = 50
DRAIN_BUDGET_S = 0.04
CONSOLE_LINES = 5000
STRIP = 10
KEEP_IMAGES = 200
PLOT_S = 60
FRAME_HISTORY = 4000
DEFAULT_FPS = 8.26
PLOT_EVERY_S = 0.5
STATS_EVERY_S = 1.0
SPEEDS = ("1", "2", "5", "10", "20", "50")
GREEN = "#2e9e44"
GREY = "#9a9a9a"
CONNECTED = "-- connected to"
IMAGE_W, IMAGE_H = 640, 480
LINE_LENGTH_PCK = 3448
PIXEL_RATE = 182.4e6
DEFAULTS = {"again": 0xB4, "dgain": 0xDDF, "exposure": 0x11CC, "framelen": 0x1908, "window": 8,
            "threshold": 0, "k": 1}
SLIDERS = (("again", 0, 232), ("dgain", 0x100, 0xFFF), ("exposure", 1, 0x1908 - 4),
           ("framelen", 2464 + 32, 8000), ("window", 2, 20), ("k", 1, 20))
PREVIEW_WINDOW = 4
CFG_DEFINES = (("exposure", "IMX219_EXPOSURE_SETTING"), ("again", "IMX219_AGAIN_SETTING"),
               ("dgain", "IMX219_DGAIN_SETTING"), ("framelen", "IMX219_FRAMELEN_SETTING"))
RIGHT_MIN_W = 560
UI = 1.0


def px(n):
    return int(round(n * UI))


def detect_scale():
    try:
        out = subprocess.run(["xrdb", "-query"], capture_output=True, text=True, timeout=2).stdout
        m = re.search(r"^Xft\.dpi:\s*([\d.]+)", out, re.M)
        if m:
            return max(1.0, float(m.group(1)) / 96.0)
    except (OSError, subprocess.SubprocessError):
        pass
    return 1.0


def apply_scale(root):
    root.tk.call("tk", "scaling", UI * 96.0 / 72.0)
    for name in tkfont.names(root):
        f = tkfont.nametofont(name, root)
        size = int(f.cget("size"))
        if size < 0:
            f.configure(size=int(round(size * UI)))
    style = ttk.Style(root)
    style.configure(".", arrowsize=px(14), indicatorsize=px(12), indicatordiameter=px(12))
GAMMA = 2.2
ERROR_MARKS = ("!!", "FAIL", "FATAL", "not sent")


def display_correction(im):
    a = np.asarray(im, dtype=np.float32)
    means = a.reshape(-1, 3).mean(axis=0)
    a = a * (means.mean() / np.maximum(means, 1.0))
    a = np.power(np.clip(a, 0, 255) / 255.0, 1.0 / GAMMA) * 255.0
    return Image.fromarray((a + 0.5).astype(np.uint8), "RGB")


def setting_note(name, v):
    if v is None:
        return "applied -"
    if name == "again":
        return f"applied {v} (x{256 / (256 - v):.2f})"
    if name == "dgain":
        return f"applied 0x{v:X} (x{v / 256:.2f})"
    if name == "exposure":
        return f"applied {v} lines ({v * LINE_LENGTH_PCK / PIXEL_RATE * 1e3:.1f} ms)"
    if name == "framelen":
        return f"applied {v} lines ({PIXEL_RATE / (LINE_LENGTH_PCK * v):.2f} frames/s)"
    if name == "k":
        return f"applied {v} frame(s) >= T per window"
    return f"applied {v} frames"


def cfg_lines(values):
    return "\n".join(f"#define {define}\t\t\t(0x{values[name]:X})" for name, define in CFG_DEFINES) + "\n"


def stack_text(stacks):
    items = [f"{name} {used}/{alloc}" for name, (used, alloc) in stacks.items()]
    if not items:
        return "-"
    half = (len(items) + 1) // 2
    return "  ".join(items[:half]) + ("\n            " + "  ".join(items[half:]) if items[half:] else "")


def snapshot(st):
    return {
        "elapsed": st.elapsed(), "fps": st.fps(), "images": st.images, "crc": st.crc_errors,
        "seq_gaps": st.seq_gaps, "eoi": st.eoi_errors, "window_gaps": st.window_gaps,
        "decode": st.decode_failures, "merged": st.windows_merged, "failed": st.inference_failures,
        "not_best": st.not_best, "resets": st.resets, "bad_frames": st.bad_frames,
        "resync_losses": st.resync_losses, "windows": st.windows, "lines": st.text_lines,
        "stacks": dict(st.stacks), "first_frame": st.first_frame, "last_frame": st.last_frame,
        "sent": st.windows_sent, "suppressed": st.suppressed, "above": st.frames_above, "scored": st.scored,
        "score_gaps": st.score_gaps, "max_batch": st.max_batch, "scores_lost": st.scores_lost,
    }


class Source(threading.Thread):
    def __init__(self, q, session):
        super().__init__(daemon=True)
        self.q = q
        self.session = session
        self.stop = threading.Event()
        session.on_text = lambda text, now: self.put("text", text)
        session.on_message = lambda text, now: self.put("text", text)
        session.on_window = lambda w, now: self.put("window", w, now - session.st.t0)
        session.on_image = lambda path, window, index, score, seq, jpeg, ok, now: self.put(
            "image", {"path": path, "window": window, "frame": index, "score": score, "seq": seq,
                      "jpeg": jpeg, "ok": ok, "t": now - session.st.t0})
        session.on_scores = lambda first, pairs, now: self.put("scores", first, pairs, now - session.st.t0)
        self.last_stats = 0.0

    def put(self, kind, *payload):
        self.q.put((kind, time.monotonic()) + payload)
        if kind == "window":
            self.stats()

    def stats(self):
        self.last_stats = time.monotonic()
        self.q.put(("stats", self.last_stats, snapshot(self.session.st)))

    def tick(self):
        if time.monotonic() - self.last_stats >= STATS_EVERY_S:
            self.stats()


class LiveSource(Source):
    def __init__(self, q, session, port, baud, recorder):
        super().__init__(q, session)
        self.port = port
        self.baud = baud
        self.recorder = recorder
        self.tx = queue.Queue()

    def run(self):
        try:
            s = open_port(self.port, self.baud)
            s.timeout = 0.05
        except Exception as e:
            self.q.put(("ended", time.monotonic(), f"cannot open {self.port}: {e}"))
            return
        now = time.monotonic()
        self.session.rec = self.recorder()
        self.session.resync(now)
        self.session.message(f"{CONNECTED} {self.port}", now)
        self.q.put(("status", now, f"connected to {self.port}"))
        buf = bytearray()
        try:
            while not self.stop.is_set():
                self.session.rec = self.recorder()
                while not self.tx.empty():
                    cmd = self.tx.get_nowait()
                    s.write((cmd + "\n").encode("ascii"))
                    self.session.message(f"-> {cmd}", time.monotonic())
                buf += s.read(8192)
                self.session.feed(buf, time.monotonic())
                self.tick()
        except Exception as e:
            self.q.put(("status", time.monotonic(), f"!! reader stopped: {e}"))
        finally:
            park(s)
            self.session.message(f"-- disconnected, {self.port} parked", time.monotonic())
            if self.session.rec:
                self.session.rec.flush()
            self.stats()
            self.q.put(("ended", time.monotonic(), f"disconnected, {self.port} parked"))


def replay_timeline(folder):
    folder = pathlib.Path(folder)
    items = []
    log = folder / "console.log"
    if log.exists():
        for raw in log.read_text(errors="replace").splitlines():
            t, _, text = raw.strip(" ").partition(" ")
            try:
                t = float(t)
            except ValueError:
                continue
            if text.startswith(RX_PREFIX):
                items.append((t, "rx", text[len(RX_PREFIX):]))
                continue
            m = IMAGE_LOG.match(text)
            if m:
                seq, window, index, score, _, name = m.groups()
                items.append((t, "image", (int(seq), int(window), int(index), int(score), folder / name)))
            else:
                items.append((t, "line", text))
        return items, "console.log"
    with open(folder / "images.csv", newline="") as f:
        images = {int(r["window"]): r for r in csv.DictReader(f)}
    with open(folder / "windows.csv", newline="") as f:
        for r in csv.DictReader(f):
            p = [int(r[f"p{k}"]) for k in range(UPLINK_WINDOW) if r[f"p{k}"]] if r.get("p0") else None
            n = [int(r[f"n{k}"]) for k in range(UPLINK_WINDOW) if r[f"n{k}"]] if r.get("n0") else None
            y = float(r["y_mean"]) if r.get("y_mean") else None
            c = float(r["clip_pct"]) if r.get("clip_pct") else None
            w = Window(int(r["window"]), int(r["first"]), int(r["last"]),
                       int(r["best"]) if r["best"] else None, int(r["best_score"]) if r["best_score"] else None,
                       int(r["merged"]), int(r["failed"]), p, n, y, c)
            t = float(r["t_pc"])
            items.append((t, "line", window_text(w)))
            img = images.get(w.window)
            if img is not None:
                items.append((t + 0.001, "image", (int(img["seq"]), int(img["window"]), int(img["frame"]),
                                                    int(img["score"]), folder / img["file"])))
    items.sort(key=lambda it: it[0])
    return items, "windows.csv + images.csv"


class ReplaySource(Source):
    def __init__(self, q, session, folder, speed):
        super().__init__(q, session)
        self.items, self.kind = replay_timeline(folder)
        self.speed = speed
        self.vt = 0.0
        session.st.clock = lambda: self.vt
        session.st.t0 = 0.0
        session.st.resync_until = 0.0

    def run(self):
        self.q.put(("status", time.monotonic(), f"replaying {len(self.items)} events from {self.kind}"))
        st = self.session.st
        last = time.monotonic()
        i = 0
        while i < len(self.items) and not self.stop.is_set():
            time.sleep(0.01)
            now = time.monotonic()
            self.vt += (now - last) * self.speed()
            last = now
            while i < len(self.items) and self.items[i][0] <= self.vt:
                t, kind, payload = self.items[i]
                i += 1
                if kind == "line":
                    self.session.line(payload.encode("ascii", "replace"), t)
                elif kind == "image":
                    seq, window, index, score, path = payload
                    jpeg = path.read_bytes() if path.exists() else b""
                    self.session.image(seq, window, index, score, jpeg, t, path=path)
                elif payload.startswith(CONNECTED):
                    self.session.resync(t)
                    self.session.message(payload, t)
                elif payload.startswith("!! CRC error"):
                    st.crc_errors += 1
                    self.session.message(payload, t)
                elif payload.startswith("!! seq gap"):
                    st.seq_gaps += 1
                    self.session.message(payload, t)
            self.tick()
        self.stats()
        self.q.put(("ended", time.monotonic(), "replay finished" if i >= len(self.items) else "replay stopped"))


class App:
    def __init__(self, root, args):
        self.root = root
        self.args = args
        self.q = queue.Queue()
        self.source = None
        self.stats = Stats(say=lambda text: None)
        self.session = Session(self.stats)
        self.recorders = {}
        self.rec = None
        self.record = tk.BooleanVar(value=args.record)
        self.out = tk.StringVar(value=args.out)
        self.threshold = tk.DoubleVar(value=args.threshold)
        self.speed = tk.StringVar(value=str(args.speed))
        self.port = tk.StringVar(value=args.port or "")
        self.only_above = tk.BooleanVar(value=False)
        self.follow = tk.BooleanVar(value=True)
        self.paused = tk.BooleanVar(value=False)
        self.hide_windows = tk.BooleanVar(value=False)
        self.correct = tk.BooleanVar(value=not args.no_correction)
        self.layout_pending = False
        self.scale = None
        self.strip_recs = []
        self.applied = {name: None for name in SETTING_NAMES}
        self.slider_vars = {}
        self.slider_widgets = {}
        self.slider_notes = {}
        self.dragging = set()
        self.yhist = []
        self.frame_pts = collections.deque(maxlen=FRAME_HISTORY)
        self.frame_t = {}
        self.sent_frames = collections.deque(maxlen=200)
        self.hide_scores = tk.BooleanVar(value=True)
        self.last_caption = 0.0
        self.lines = []
        self.windows = {}
        self.images = collections.deque(maxlen=KEEP_IMAGES)
        self.image_count = 0
        self.selected = None
        self.shown = None
        self.last_window = None
        self.console = collections.deque(maxlen=CONSOLE_LINES)
        self.console_count = 0
        self.snap = None
        self.plot_dirty = False
        self.last_plot = 0.0
        self.lag_max = 0.0
        self.lag_minute = collections.defaultdict(float)
        self.lag_last = 0.0
        self.t_start = time.monotonic()
        self.photo = None
        self.thumb_photos = {}
        self.build()
        self.root.after(200, self.relayout)
        self.threshold.trace_add("write", lambda *a: self.threshold_changed())
        self.root.protocol("WM_DELETE_WINDOW", self.quit)
        self.root.after(DRAIN_MS, self.drain)
        if args.replay:
            self.start_replay()
        elif args.connect:
            self.toggle_connect()
        for t in args.toggle_at:
            self.root.after(int(t * 1000), self.toggle_connect)
        for t, cmd in args.send_at or []:
            self.root.after(int(float(t) * 1000), lambda c=cmd: self.send_command(c))
        if args.exit_after:
            self.root.after(int(args.exit_after * 1000), self.quit)

    def build(self):
        root = self.root
        root.title("Uplink monitor" + (f" - replay {self.args.replay}" if self.args.replay else ""))
        root.geometry(self.args.geometry or self.default_geometry())
        root.minsize(px(1000), px(640))
        bar = ttk.Frame(root, padding=(px(4), px(3)))
        bar.pack(side=tk.TOP, fill=tk.X)
        self.bar = bar
        live = not self.args.replay
        ttk.Label(bar, text="Port").pack(side=tk.LEFT)
        self.port_box = ttk.Combobox(bar, textvariable=self.port, width=12, postcommand=self.refresh_ports,
                                     state="normal" if live else "disabled")
        self.port_box.pack(side=tk.LEFT, padx=(px(2), px(4)))
        self.connect_button = ttk.Button(bar, text="Connect", command=self.toggle_connect,
                                         state="normal" if live else "disabled")
        self.connect_button.pack(side=tk.LEFT, padx=(px(0), px(10)))
        ttk.Label(bar, text="Output").pack(side=tk.LEFT)
        ttk.Entry(bar, textvariable=self.out, width=18).pack(side=tk.LEFT, padx=px(2))
        ttk.Button(bar, text="...", width=3, command=self.choose_out).pack(side=tk.LEFT)
        ttk.Checkbutton(bar, text="Record", variable=self.record,
                        state="normal" if live else "disabled").pack(side=tk.LEFT, padx=(px(4), px(10)))
        ttk.Label(bar, text="Threshold").pack(side=tk.LEFT)
        thr_scale = ttk.Scale(bar, from_=0, to=100, variable=self.threshold, length=px(150),
                              command=lambda v: self.threshold.set(round(float(v) * 2) / 2))
        thr_scale.pack(side=tk.LEFT, padx=px(2))
        thr_scale.bind("<ButtonRelease-1>", lambda e: self.send_threshold())
        self.threshold_label = ttk.Label(bar, width=16)
        self.threshold_label.pack(side=tk.LEFT, padx=(px(2), px(10)))
        ttk.Label(bar, text="Speed").pack(side=tk.LEFT)
        ttk.Combobox(bar, textvariable=self.speed, values=SPEEDS, width=4,
                     state="readonly" if self.args.replay else "disabled").pack(side=tk.LEFT, padx=px(2))
        ttk.Checkbutton(bar, text="Display correction", variable=self.correct,
                        command=self.correction_changed).pack(side=tk.LEFT, padx=(px(10), px(0)))

        body = ttk.Frame(root)
        body.pack(fill=tk.BOTH, expand=True)
        left = ttk.Frame(body, padding=px(4))
        left.pack(side=tk.LEFT, fill=tk.Y)
        self.left = left
        self.image_box = tk.Frame(left, bg=GREY, padx=px(4), pady=px(4))
        self.image_box.pack(side=tk.TOP, anchor="nw")
        self.blank = None
        self.image_label = tk.Label(self.image_box, bg="black", bd=0, highlightthickness=0)
        self.image_label.pack()
        self.caption = ttk.Label(left, text="no image yet", font="TkFixedFont")
        self.caption.pack(side=tk.TOP, fill=tk.X, pady=(px(4), px(0)))
        opts = ttk.Frame(left)
        opts.pack(side=tk.TOP, fill=tk.X)
        ttk.Checkbutton(opts, text="Only at or above the threshold", variable=self.only_above,
                        command=self.images_changed).pack(side=tk.LEFT)
        ttk.Checkbutton(opts, text="Follow latest", variable=self.follow,
                        command=self.images_changed).pack(side=tk.LEFT, padx=px(12))
        self.strip = ttk.Frame(left)
        self.strip.pack(side=tk.TOP, anchor="nw", pady=(px(2), px(0)))
        self.thumbs = []
        for k in range(STRIP):
            box = tk.Frame(self.strip, bg=GREY, padx=px(2), pady=px(2))
            box.grid(row=0, column=k, padx=px(1))
            lab = tk.Label(box, bg="black", bd=0, highlightthickness=0)
            lab.pack()
            text = tk.Label(self.strip, font=("TkFixedFont", 7))
            text.grid(row=1, column=k)
            lab.bind("<Button-1>", lambda e, k=k: self.thumb_clicked(k))
            self.thumbs.append((box, lab, text, None))

        right = ttk.PanedWindow(body, orient=tk.VERTICAL)
        right.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        stats_frame = ttk.Frame(right, padding=(px(4), px(2)))
        right.add(stats_frame, weight=0)
        self.stats_label = tk.Label(stats_frame, font="TkFixedFont", justify=tk.LEFT, anchor="nw")
        self.stats_label.pack(fill=tk.X)
        self.status = ttk.Label(stats_frame, text="", foreground="#555")
        self.status.pack(fill=tk.X)
        plot_frame = ttk.Frame(right)
        right.add(plot_frame, weight=3)
        self.fig = Figure(figsize=(5, 3), dpi=80 * UI, layout="constrained")
        gs = self.fig.add_gridspec(3, 1, height_ratios=(3, 2, 2))
        self.ax_t = self.fig.add_subplot(gs[0])
        self.ax_f = self.fig.add_subplot(gs[1])
        self.ax_y = self.fig.add_subplot(gs[2])
        self.ax_c = self.ax_y.twinx()
        self.canvas = FigureCanvasTkAgg(self.fig, master=plot_frame)
        self.canvas.get_tk_widget().configure(height=px(200))
        self.canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

        notebook = ttk.Notebook(right)
        right.add(notebook, weight=2)
        bottom = ttk.Frame(notebook, padding=(px(4), px(2)))
        notebook.add(bottom, text="Console")
        tune = ttk.Frame(notebook, padding=(px(4), px(2)))
        notebook.add(tune, text="Tuning")
        self.build_tuning(tune)
        if self.args.tab == "tuning":
            notebook.select(tune)
        cbar = ttk.Frame(bottom)
        cbar.pack(fill=tk.X)
        ttk.Label(cbar, text="Console").pack(side=tk.LEFT)
        ttk.Checkbutton(cbar, text="Pause", variable=self.paused, command=self.console_rebuild).pack(side=tk.LEFT, padx=px(8))
        ttk.Button(cbar, text="Clear", command=self.console_clear).pack(side=tk.LEFT)
        ttk.Checkbutton(cbar, text="Hide Window lines", variable=self.hide_windows,
                        command=self.console_rebuild).pack(side=tk.LEFT, padx=px(8))
        ttk.Checkbutton(cbar, text="Hide Scores lines", variable=self.hide_scores,
                        command=self.console_rebuild).pack(side=tk.LEFT, padx=px(8))
        cbody = ttk.Frame(bottom)
        cbody.pack(fill=tk.BOTH, expand=True)
        self.text = tk.Text(cbody, font="TkFixedFont", wrap=tk.NONE, height=6, width=40, state=tk.DISABLED)
        ys = ttk.Scrollbar(cbody, orient=tk.VERTICAL, command=self.text.yview)
        xs = ttk.Scrollbar(cbody, orient=tk.HORIZONTAL, command=self.text.xview)
        self.text.configure(yscrollcommand=ys.set, xscrollcommand=xs.set)
        self.text.tag_configure("err", foreground="#c62828")
        ys.pack(side=tk.RIGHT, fill=tk.Y)
        xs.pack(side=tk.BOTTOM, fill=tk.X)
        self.text.pack(fill=tk.BOTH, expand=True)
        root.bind("<Configure>", self.root_configured)
        self.set_display_size(IMAGE_W, IMAGE_H, 1.0)
        self.update_threshold_label()
        self.render_stats()
        self.render_plot()

    def default_geometry(self):
        w = min(px(1500), self.root.winfo_screenwidth())
        h = min(px(980), self.root.winfo_screenheight())
        return f"{w}x{h}"

    def build_tuning(self, tune):
        live = not self.args.replay
        for row, (name, lo, hi) in enumerate(SLIDERS):
            ttk.Label(tune, text=name, width=9).grid(row=row, column=0, sticky="w")
            var = tk.IntVar(value=DEFAULTS[name])
            sc = tk.Scale(tune, from_=lo, to=hi, orient=tk.HORIZONTAL, variable=var, showvalue=False,
                          resolution=1, length=px(240), width=px(15), sliderlength=px(30),
                          state="normal" if live else "disabled")
            sc.grid(row=row, column=1, sticky="we")
            sc.bind("<ButtonPress-1>", lambda e, n=name: self.dragging.add(n))
            sc.bind("<ButtonRelease-1>", lambda e, n=name: self.slider_released(n))
            ent = ttk.Entry(tune, textvariable=var, width=7, state="normal" if live else "disabled")
            ent.grid(row=row, column=2, padx=px(4))
            ent.bind("<Return>", lambda e, n=name: self.send_setting(n))
            note = ttk.Label(tune, text=setting_note(name, None), width=34)
            note.grid(row=row, column=3, sticky="w")
            self.slider_vars[name] = var
            self.slider_widgets[name] = sc
            self.slider_notes[name] = note
        tune.columnconfigure(1, weight=1)
        buttons = ttk.Frame(tune)
        buttons.grid(row=len(SLIDERS), column=0, columnspan=4, sticky="w", pady=(px(4), px(0)))
        state = "normal" if live else "disabled"
        ttk.Button(buttons, text="Get", command=lambda: self.send_command("get"), state=state).pack(side=tk.LEFT)
        self.preview_button = ttk.Button(buttons, text=f"Preview (window {PREVIEW_WINDOW})",
                                         command=self.toggle_preview, state=state)
        self.preview_button.pack(side=tk.LEFT, padx=px(6))
        ttk.Button(buttons, text="Copy settings", command=self.copy_settings).pack(side=tk.LEFT)
        self.tune_status = ttk.Label(tune, text="", foreground="#555")
        self.tune_status.grid(row=len(SLIDERS) + 1, column=0, columnspan=4, sticky="w")

    def send_command(self, cmd):
        src = self.source
        if self.args.replay or not isinstance(src, LiveSource) or not src.is_alive():
            self.tune_status.configure(text="not connected", foreground="#c62828")
            return False
        src.tx.put(cmd)
        return True

    def slider_released(self, name):
        self.dragging.discard(name)
        self.send_setting(name)

    def send_setting(self, name):
        try:
            v = int(self.slider_vars[name].get())
        except (tk.TclError, ValueError):
            self.tune_status.configure(text=f"{name}: not a number", foreground="#c62828")
            return
        if self.send_command(f"set {name} {v}"):
            self.tune_status.configure(text=f"sent set {name} {v}", foreground="#555")

    def send_threshold(self):
        if self.send_command(f"set threshold {self.score_min()}"):
            self.tune_status.configure(text=f"sent set threshold {self.score_min()}", foreground="#555")

    def toggle_preview(self):
        w = self.applied["window"]
        self.send_command(f"set window {UPLINK_WINDOW if w == PREVIEW_WINDOW else PREVIEW_WINDOW}")

    def current_settings(self):
        return {name: (self.applied[name] if self.applied[name] is not None else DEFAULTS[name])
                for name in SETTING_NAMES}

    def copy_settings(self):
        text = cfg_lines(self.current_settings())
        self.root.clipboard_clear()
        self.root.clipboard_append(text)
        self.tune_status.configure(text="copied: " + text.replace("\n", "  ").replace("\t\t\t", " "),
                                   foreground="#555")

    def setting_applied(self, name, v):
        self.applied[name] = v
        if name in self.slider_notes:
            self.slider_notes[name].configure(text=setting_note(name, v))
            if name not in self.dragging:
                self.slider_vars[name].set(v)
        if name == "framelen":
            self.slider_widgets["exposure"].configure(to=v - 4)
        if name == "exposure":
            self.slider_widgets["framelen"].configure(from_=max(SLIDERS[3][1], v + 4))
        if name == "threshold":
            self.threshold.set(round(probability(v) * 200) / 2)
        if name == "window":
            self.preview_button.configure(
                text=f"Normal (window {UPLINK_WINDOW})" if v == PREVIEW_WINDOW else f"Preview (window {PREVIEW_WINDOW})")

    def tuning_text(self, text):
        a = parse_applied(text)
        if a:
            name, v, frame, ok = a
            self.setting_applied(name, v)
            self.tune_status.configure(text=text, foreground="#555" if ok else "#c62828")
            return
        values = parse_settings(text)
        if values:
            for name, v in values.items():
                self.setting_applied(name, v)
            self.tune_status.configure(text=text, foreground="#555")
            return
        m = COMMAND_LINE.match(text)
        if m and "bytes used" not in text:
            self.tune_status.configure(text=text, foreground="#c62828")

    def root_configured(self, event):
        if event.widget is self.root and not self.layout_pending:
            self.layout_pending = True
            self.root.after_idle(self.relayout)

    def fits(self, scale, avail_w, avail_h, base_h):
        w, h = int(IMAGE_W * scale), int(IMAGE_H * scale)
        thumb_h = (w // STRIP - px(6)) * 3 // 4
        return w + px(16) <= avail_w and base_h + h + thumb_h + px(24) <= avail_h

    def display_scale(self):
        self.root.update_idletasks()
        avail_w = self.root.winfo_width() - px(RIGHT_MIN_W)
        avail_h = self.root.winfo_height() - self.bar.winfo_height()
        base_h = px(24) + self.caption.winfo_reqheight() * 2
        k = 1
        while self.fits(k + 1, avail_w, avail_h, base_h):
            k += 1
        if self.fits(k, avail_w, avail_h, base_h):
            return float(k)
        d = 2
        while not self.fits(1.0 / d, avail_w, avail_h, base_h) and d < 8:
            d += 1
        return 1.0 / d

    def relayout(self):
        self.layout_pending = False
        scale = self.display_scale()
        if scale != self.scale:
            self.set_display_size(IMAGE_W, IMAGE_H, scale)
            self.render_image(force=True)
            self.render_strip(self.strip_recs)

    def set_display_size(self, w, h, scale):
        self.scale = scale
        self.disp = (int(w * scale), int(h * scale))
        tw = self.disp[0] // STRIP - px(6)
        self.thumb_size = (tw, tw * 3 // 4)
        self.blank = ImageTk.PhotoImage(Image.new("RGB", self.disp, "black"))
        if self.selected is None:
            self.image_label.configure(image=self.blank)
        self.blank_thumb = ImageTk.PhotoImage(Image.new("RGB", self.thumb_size, "black"))
        for box, lab, text, rec in self.thumbs:
            if rec is None:
                lab.configure(image=self.blank_thumb)
        self.thumb_photos.clear()

    def correction_changed(self):
        self.thumb_photos.clear()
        self.render_image(force=True)
        self.render_strip(self.strip_recs)

    def display_image(self, jpeg, size):
        im = Image.open(io.BytesIO(jpeg)).convert("RGB")
        if self.correct.get():
            im = display_correction(im)
        if im.size != size:
            im = im.resize(size, Image.NEAREST if size[0] > im.width else Image.BOX)
        return im

    def refresh_ports(self):
        self.port_box["values"] = list_ports()

    def choose_out(self):
        d = filedialog.askdirectory(initialdir=self.out.get() or ".")
        if d:
            self.out.set(d)

    def recorder(self):
        if not self.record.get() or not self.out.get():
            return None
        out = self.out.get()
        rec = self.recorders.get(out)
        if rec is None:
            rec = self.recorders[out] = Recorder(out, self.stats.t0)
        return rec

    def set_status(self, text):
        self.status.configure(text=text, foreground="#c62828" if text.startswith("!!") else "#555")

    def toggle_connect(self):
        if self.args.replay:
            return
        if self.source and self.source.is_alive():
            self.source.stop.set()
            self.connect_button.configure(state="disabled")
            return
        port = self.port.get()
        if not port:
            ports = list_ports()
            if not ports:
                self.set_status("!! no serial port found")
                return
            port = ports[0]
            self.port.set(port)
        self.rec = self.recorder()
        self.source = LiveSource(self.q, self.session, port, self.args.baud, lambda: self.rec)
        self.connect_button.configure(text="Disconnect")
        self.source.start()
        self.source.tx.put("get")

    def start_replay(self):
        self.source = ReplaySource(self.q, self.session, self.args.replay, self.replay_speed)
        self.source.start()

    def replay_speed(self):
        try:
            return float(self.speed_value)
        except (AttributeError, ValueError):
            return 1.0

    def drain(self):
        self.speed_value = self.speed.get()
        self.rec = self.recorder()
        t_end = time.monotonic() + DRAIN_BUDGET_S
        new_image = False
        changed = False
        while time.monotonic() < t_end:
            try:
                ev = self.q.get_nowait()
            except queue.Empty:
                break
            kind, t_read = ev[0], ev[1]
            lag = time.monotonic() - t_read
            self.lag_last = lag
            self.lag_max = max(self.lag_max, lag)
            minute = int((time.monotonic() - self.t_start) // 60)
            self.lag_minute[minute] = max(self.lag_minute[minute], lag)
            if kind == "text":
                self.console_add(ev[2])
                self.tuning_text(ev[2])
            elif kind == "window":
                self.window_added(ev[2], ev[3])
                changed = True
            elif kind == "image":
                self.image_added(ev[2])
                new_image = True
            elif kind == "scores":
                self.scores_added(ev[2], ev[3], ev[4])
            elif kind == "stats":
                self.snap = ev[2]
                changed = True
            elif kind == "status":
                self.set_status(ev[2])
            elif kind == "ended":
                self.set_status(ev[2])
                if not self.args.replay:
                    self.connect_button.configure(text="Connect", state="normal")
        if new_image:
            self.images_changed()
        if changed:
            self.render_stats()
        if self.plot_dirty and time.monotonic() - self.last_plot >= PLOT_EVERY_S:
            self.render_plot()
        if time.monotonic() - self.last_caption >= 1.0 and self.shown is not None:
            self.last_caption = time.monotonic()
            self.update_caption(self.shown)
        self.root.after(DRAIN_MS, self.drain)

    def frame_period(self):
        fps = self.snap["fps"] if self.snap and self.snap["fps"] else DEFAULT_FPS
        return 1.0 / fps

    def scores_added(self, first, pairs, t):
        period = self.frame_period()
        n = len(pairs)
        for k, (person, _) in enumerate(pairs):
            tk_ = t - (n - 1 - k) * period
            frame = first + k
            self.frame_pts.append((tk_, frame, probability(person) * 100))
            self.frame_t[frame] = (tk_, probability(person) * 100)
        while len(self.frame_t) > FRAME_HISTORY:
            del self.frame_t[next(iter(self.frame_t))]
        self.plot_dirty = True

    def score_min(self):
        return math.ceil(score_at(self.threshold.get() / 100) - 1e-9)

    def above(self, score):
        return score is not None and score >= self.score_min()

    def window_added(self, w, t):
        self.windows[w.window] = w
        if len(self.windows) > 2 * KEEP_IMAGES:
            for k in sorted(self.windows)[:KEEP_IMAGES]:
                del self.windows[k]
        self.lines.append((t, w.score))
        if w.sent:
            self.sent_frames.append(w.best)
        if w.y is not None:
            self.yhist.append((t, w.y, w.clip))
        self.last_window = w
        self.plot_dirty = True

    def image_added(self, rec):
        w = self.windows.get(rec["window"])
        rec["merged"] = w.merged if w else None
        rec["failed"] = w.failed if w else None
        self.image_count += 1
        rec["n"] = self.image_count
        self.images.append(rec)

    def visible_images(self):
        if self.only_above.get():
            return [r for r in self.images if self.above(r["score"])]
        return list(self.images)

    def images_changed(self):
        vis = self.visible_images()
        if self.follow.get() or self.selected not in self.images:
            self.selected = vis[-1] if vis else None
            if not self.follow.get() and self.selected is None:
                self.follow.set(True)
        self.render_image()
        self.render_strip(vis[-STRIP:])

    def thumb_clicked(self, k):
        rec = self.thumbs[k][3]
        if rec is not None:
            self.follow.set(False)
            self.selected = rec
            self.render_image()

    def render_image(self, force=False):
        rec = self.selected
        if rec is None:
            self.image_label.configure(image=self.blank)
            self.image_box.configure(bg=GREY)
            self.caption.configure(text="no detection yet" if not self.images else "no image at or above the threshold")
            return
        if rec is self.shown and not force:
            self.update_caption(rec)
            return
        try:
            im = self.display_image(rec["jpeg"], self.disp)
        except Exception:
            self.image_label.configure(image=self.blank)
            self.caption.configure(text="image does not decode")
            return
        self.photo = ImageTk.PhotoImage(im)
        self.image_label.configure(image=self.photo)
        self.shown = rec
        self.update_caption(rec)

    def update_caption(self, rec):
        p = probability(rec["score"]) * 100
        self.image_box.configure(bg=GREEN if self.above(rec["score"]) else GREY)
        age = max(0.0, self.session.st.elapsed() - rec.get("t", 0.0))
        age_text = f"{age:.0f} s ago" if age < 120 else f"{age / 60:.0f} min ago"
        self.caption.configure(text=f"detection: window {rec['window']}  frame {rec['frame']}  p {p:.1f} % "
                                    f"(score {rec['score']})  {age_text}"
                                    + ("" if self.follow.get() else "   (selected)"))

    def thumb_photo(self, rec):
        key = rec["n"]
        ph = self.thumb_photos.get(key)
        if ph is None:
            try:
                ph = ImageTk.PhotoImage(self.display_image(rec["jpeg"], self.thumb_size))
            except Exception:
                ph = None
            self.thumb_photos[key] = ph
            if len(self.thumb_photos) > 4 * STRIP:
                live = {r["n"] for r in self.images}
                for k in [k for k in self.thumb_photos if k not in live]:
                    del self.thumb_photos[k]
        return ph

    def render_strip(self, recs):
        self.strip_recs = recs
        recs = [None] * (STRIP - len(recs)) + recs
        for k, rec in enumerate(recs):
            box, lab, text, _ = self.thumbs[k]
            if rec is None:
                lab.configure(image=self.blank_thumb)
                box.configure(bg=GREY)
                text.configure(text="")
            else:
                ph = self.thumb_photo(rec)
                lab.configure(image=ph if ph else self.blank_thumb)
                lab.image = ph
                box.configure(bg=GREEN if self.above(rec["score"]) else GREY)
                text.configure(text=f"w{rec['window']} {probability(rec['score']) * 100:.0f}%")
            self.thumbs[k] = (box, lab, text, rec)

    def detection(self):
        smin = self.score_min()
        n = len(self.lines)
        hits = run = longest = 0
        for _, s in self.lines:
            if s is not None and s >= smin:
                hits += 1
                run += 1
                longest = max(longest, run)
            else:
                run = 0
        return n, hits, run, longest

    def update_threshold_label(self):
        thr = self.threshold.get()
        self.threshold_label.configure(text=f"{thr:.1f} % (s >= {self.score_min()})")

    def threshold_changed(self):
        self.update_threshold_label()
        self.images_changed()
        self.render_stats()
        self.plot_dirty = True

    def render_stats(self):
        s = self.snap
        out = []
        if s is None:
            out.append("Link: no data yet")
        else:
            fps = "-" if s["fps"] is None else f"{s['fps']:.2f}"
            el = s["elapsed"]
            out += [
                f"Link        elapsed {int(el) // 60}:{int(el) % 60:02d}   frames/s {fps}   detections {s['images']}",
                f"  errors    CRC {s['crc']}   seq gaps {s['seq_gaps']}   EOI {s['eoi']}   "
                f"window gaps {s['window_gaps']}   decode {s['decode']}   resets {s['resets']}",
                f"Windows     {s['windows']}   sent {s['sent']}   suppressed {s['suppressed']}   "
                f"merged {s['merged']}   frames >= T {s['above']}   failed {s['failed']}",
                f"Scores      {s['scored']} frames   gaps {s['score_gaps']}   max batch {s['max_batch']}   "
                f"lost on board {s['scores_lost']}   not best {s['not_best']}",
            ]
        out += [
            f"Threshold   {self.threshold.get():.1f} % (score >= {self.score_min()})   k "
            f"{self.applied.get('k') if self.applied.get('k') is not None else '-'}   window "
            f"{self.applied.get('window') if self.applied.get('window') is not None else '-'}",
            "Stacks      " + stack_text(s["stacks"] if s else {}),
            f"GUI lag     last {1000 * self.lag_last:.0f} ms   max {1000 * self.lag_max:.0f} ms",
        ]
        self.stats_label.configure(text="\n".join(out))

    def render_plot(self):
        self.last_plot = time.monotonic()
        self.plot_dirty = False
        thr = self.threshold.get()
        ax = self.ax_t
        ax.clear()
        t_now = self.frame_pts[-1][0] if self.frame_pts else 0.0
        if self.frame_pts:
            pts = [(t, pr) for t, _, pr in self.frame_pts if t >= t_now - PLOT_S]
            xs, ys = zip(*pts)
            ax.plot(xs, ys, color="#1f5fa8", linewidth=1)
            ax.fill_between(xs, thr, ys, where=[y >= thr for y in ys], color=GREEN, alpha=0.25, linewidth=0)
            sent = [self.frame_t[f] for f in self.sent_frames if f in self.frame_t and self.frame_t[f][0] >= t_now - PLOT_S]
            if sent:
                sx, sy = zip(*sent)
                ax.scatter(sx, sy, s=40, marker="*", color="#e08a1e", zorder=3, label="sent")
        ax.set_xlim(max(0, t_now - PLOT_S), max(t_now, 10))
        ax.axhline(thr, color="#c62828", linewidth=1, linestyle="--")
        ax.set_ylim(0, 100)
        ax.set_title("person probability per frame, last 60 s (stars: sent)", fontsize=9)
        ax.set_xlabel("time (s)", fontsize=8)
        ax.set_ylabel("%", fontsize=8)
        ax.tick_params(labelsize=7)
        ax.grid(alpha=0.3)
        ax = self.ax_f
        ax.clear()
        w = self.last_window
        if w is not None and w.first in self.frame_t:
            frames = list(range(w.first, w.last + 1))
            probs = [self.frame_t[f][1] if f in self.frame_t else 0 for f in frames]
            colours = ["#e08a1e" if f == w.best else "#7aa6d6" for f in frames]
            ax.bar(range(len(frames)), probs, color=colours)
            state = "" if w.sent is None else (" sent" if w.sent else " suppressed")
            ax.set_title(f"window {w.window}: frames {w.first}-{w.last}, best {w.best}{state}", fontsize=9)
            ax.set_xlim(-0.6, max(len(frames), 2) - 0.4)
        else:
            ax.set_title("frame probabilities of the latest window", fontsize=9)
        ax.axhline(thr, color="#c62828", linewidth=1, linestyle="--")
        ax.set_ylim(0, 100)
        ax.tick_params(labelsize=7)
        ax, axc = self.ax_y, self.ax_c
        ax.clear()
        axc.clear()
        if self.yhist:
            t_now = self.yhist[-1][0]
            i = bisect.bisect_left([t for t, _, _ in self.yhist], t_now - PLOT_S)
            xs = [t for t, _, _ in self.yhist[i:]]
            ax.plot(xs, [y for _, y, _ in self.yhist[i:]], color="#1f5fa8", linewidth=1)
            axc.plot(xs, [c for _, _, c in self.yhist[i:]], color="#c62828", linewidth=1)
            ax.set_xlim(max(0, t_now - PLOT_S), max(t_now, 10))
            ax.set_title(f"input Y mean {self.yhist[-1][1]:.1f} (blue), clipped {self.yhist[-1][2]:.2f} % (red)",
                         fontsize=9)
        else:
            ax.set_title("input Y mean and % clipped (Y >= 250)", fontsize=9)
        ax.set_ylim(0, 255)
        axc.set_ylim(0, max(5.0, max((c for _, _, c in self.yhist), default=0) * 1.2))
        ax.tick_params(labelsize=7)
        axc.tick_params(labelsize=7, colors="#c62828")
        ax.grid(alpha=0.3)
        self.canvas.draw_idle()

    def hidden(self, text):
        return ((text.startswith("Window ") and self.hide_windows.get())
                or (text.startswith("Scores ") and self.hide_scores.get()))

    def console_add(self, text):
        err = any(m in text for m in ERROR_MARKS)
        self.console.append((text, err, False))
        if not self.paused.get() and not self.hidden(text):
            self.console_insert(text, err)

    def console_insert(self, text, err):
        t = self.text
        at_end = t.yview()[1] >= 0.999
        t.configure(state=tk.NORMAL)
        t.insert(tk.END, text + "\n", ("err",) if err else ())
        self.console_count += 1
        if self.console_count > CONSOLE_LINES:
            t.delete("1.0", f"{self.console_count - CONSOLE_LINES + 1}.0")
            self.console_count = CONSOLE_LINES
        t.configure(state=tk.DISABLED)
        if at_end:
            t.see(tk.END)

    def console_rebuild(self):
        if self.paused.get():
            return
        t = self.text
        t.configure(state=tk.NORMAL)
        t.delete("1.0", tk.END)
        self.console_count = 0
        for text, err, _ in self.console:
            if not self.hidden(text):
                t.insert(tk.END, text + "\n", ("err",) if err else ())
                self.console_count += 1
        t.configure(state=tk.DISABLED)
        t.see(tk.END)

    def console_clear(self):
        self.console.clear()
        self.console_rebuild()

    def report(self):
        st = self.stats
        print(st.summary())
        print(f"threshold {self.threshold.get():.1f} % (score >= {self.score_min()}); "
              f"plotted frames {len(self.frame_pts)}, sent frames marked {len(self.sent_frames)}")
        mins = " ".join(f"{1000 * self.lag_minute[m]:.0f}" for m in sorted(self.lag_minute))
        print(f"GUI lag: max {1000 * self.lag_max:.0f} ms; max per minute (ms): {mins}")
        print("applied settings: " + ", ".join(f"{k}={v}" for k, v in self.applied.items()))
        print("copy settings:\n" + cfg_lines(self.current_settings()), end="")

    def quit(self):
        if self.source and self.source.is_alive():
            self.source.stop.set()
            self.source.join(timeout=2)
        while True:
            try:
                ev = self.q.get_nowait()
            except queue.Empty:
                break
            if ev[0] == "stats":
                self.snap = ev[2]
            elif ev[0] == "window":
                self.window_added(ev[2], ev[3])
        for rec in self.recorders.values():
            rec.close()
        if self.args.report:
            self.report()
        self.root.destroy()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port")
    ap.add_argument("--baud", type=int, default=921600)
    ap.add_argument("--connect", action="store_true", help="connect at start")
    ap.add_argument("--out", default="uplink_gui_run", help="output folder for recording")
    ap.add_argument("--record", action="store_true", help="record from the start")
    ap.add_argument("--threshold", type=float, default=50.0, help="person threshold in percent")
    ap.add_argument("--replay", metavar="FOLDER", help="play a recorded run")
    ap.add_argument("--speed", type=float, default=1.0, help="replay speed")
    ap.add_argument("--exit-after", type=float, metavar="S", help="close the window after S seconds")
    ap.add_argument("--toggle-at", type=float, nargs="*", default=[], metavar="S",
                    help="press Connect/Disconnect after S seconds (tests)")
    ap.add_argument("--send-at", nargs=2, action="append", metavar=("S", "COMMAND"),
                    help="send COMMAND through the tuning path after S seconds (tests)")
    ap.add_argument("--tab", choices=("console", "tuning"), default="console", help="tab shown at start")
    ap.add_argument("--no-correction", action="store_true", help="start with Display correction off")
    ap.add_argument("--geometry", help="window size (and position), as for Tk (default: 1500x980 times the scale)")
    ap.add_argument("--scale", default="auto",
                    help="UI scale: a factor, or auto (Xft.dpi / 96, e.g. 2 with 200 %% display scaling)")
    ap.add_argument("--report", action="store_true", help="print the statistics when the window closes")
    args = ap.parse_args()
    global UI
    UI = detect_scale() if args.scale == "auto" else max(0.5, float(args.scale))
    root = tk.Tk()
    apply_scale(root)
    App(root, args)
    root.mainloop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
