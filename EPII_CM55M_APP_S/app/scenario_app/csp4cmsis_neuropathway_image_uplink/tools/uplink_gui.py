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
import sys
import threading
import time
import tkinter as tk
from tkinter import filedialog, ttk

from PIL import Image, ImageTk

import matplotlib
matplotlib.use("TkAgg")
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.figure import Figure

from uplink_proto import (IMAGE_LOG, RX_PREFIX, UPLINK_WINDOW, Recorder, Session, Stats, Window, list_ports,
                          open_port, park, probability, score_at, window_text)

DRAIN_MS = 50
DRAIN_BUDGET_S = 0.04
CONSOLE_LINES = 5000
STRIP = 10
KEEP_IMAGES = 200
PLOT_S = 300
PLOT_EVERY_S = 0.5
STATS_EVERY_S = 1.0
SPEEDS = ("1", "2", "5", "10", "20", "50")
GREEN = "#2e9e44"
GREY = "#9a9a9a"
CONNECTED = "-- connected to"
ERROR_MARKS = ("!!", "FAIL", "FATAL", "not sent")


def snapshot(st):
    return {
        "elapsed": st.elapsed(), "fps": st.fps(), "images": st.images, "crc": st.crc_errors,
        "seq_gaps": st.seq_gaps, "eoi": st.eoi_errors, "window_gaps": st.window_gaps,
        "decode": st.decode_failures, "merged": st.windows_merged, "failed": st.inference_failures,
        "not_best": st.not_best, "resets": st.resets, "bad_frames": st.bad_frames,
        "resync_losses": st.resync_losses, "windows": st.windows, "lines": st.text_lines,
        "stacks": dict(st.stacks), "first_frame": st.first_frame, "last_frame": st.last_frame,
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
                      "jpeg": jpeg, "ok": ok})
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

    def run(self):
        try:
            s = open_port(self.port, self.baud)
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
            p = [int(r[f"p{k}"]) for k in range(UPLINK_WINDOW)] if r.get("p0") else None
            n = [int(r[f"n{k}"]) for k in range(UPLINK_WINDOW)] if r.get("n0") else None
            w = Window(int(r["window"]), int(r["first"]), int(r["last"]),
                       int(r["best"]) if r["best"] else None, int(r["best_score"]) if r["best_score"] else None,
                       int(r["merged"]), int(r["failed"]), p, n)
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
        self.threshold.trace_add("write", lambda *a: self.threshold_changed())
        self.root.protocol("WM_DELETE_WINDOW", self.quit)
        self.root.after(DRAIN_MS, self.drain)
        if args.replay:
            self.start_replay()
        elif args.connect:
            self.toggle_connect()
        for t in args.toggle_at:
            self.root.after(int(t * 1000), self.toggle_connect)
        if args.exit_after:
            self.root.after(int(args.exit_after * 1000), self.quit)

    def build(self):
        root = self.root
        root.title("Uplink monitor" + (f" - replay {self.args.replay}" if self.args.replay else ""))
        root.geometry(self.args.geometry)
        bar = ttk.Frame(root, padding=4)
        bar.pack(side=tk.TOP, fill=tk.X)
        live = not self.args.replay
        ttk.Label(bar, text="Port").pack(side=tk.LEFT)
        self.port_box = ttk.Combobox(bar, textvariable=self.port, width=14, postcommand=self.refresh_ports,
                                     state="normal" if live else "disabled")
        self.port_box.pack(side=tk.LEFT, padx=(2, 4))
        self.connect_button = ttk.Button(bar, text="Connect", command=self.toggle_connect,
                                         state="normal" if live else "disabled")
        self.connect_button.pack(side=tk.LEFT, padx=(0, 12))
        ttk.Label(bar, text="Output").pack(side=tk.LEFT)
        ttk.Entry(bar, textvariable=self.out, width=24).pack(side=tk.LEFT, padx=2)
        ttk.Button(bar, text="...", width=3, command=self.choose_out).pack(side=tk.LEFT)
        ttk.Checkbutton(bar, text="Record", variable=self.record,
                        state="normal" if live else "disabled").pack(side=tk.LEFT, padx=(4, 12))
        ttk.Label(bar, text="Threshold").pack(side=tk.LEFT)
        ttk.Scale(bar, from_=0, to=100, variable=self.threshold, length=200,
                  command=lambda v: self.threshold.set(round(float(v) * 2) / 2)).pack(side=tk.LEFT, padx=2)
        self.threshold_label = ttk.Label(bar, width=22)
        self.threshold_label.pack(side=tk.LEFT, padx=(2, 12))
        ttk.Label(bar, text="Replay speed").pack(side=tk.LEFT)
        ttk.Combobox(bar, textvariable=self.speed, values=SPEEDS, width=4,
                     state="readonly" if self.args.replay else "disabled").pack(side=tk.LEFT, padx=2)
        self.status = ttk.Label(bar, text="", foreground="#555")
        self.status.pack(side=tk.LEFT, padx=12)

        main = ttk.PanedWindow(root, orient=tk.VERTICAL)
        main.pack(fill=tk.BOTH, expand=True)
        upper = ttk.PanedWindow(main, orient=tk.HORIZONTAL)
        main.add(upper, weight=4)

        left = ttk.Frame(upper, padding=4)
        upper.add(left, weight=3)
        strip = ttk.Frame(left)
        strip.pack(side=tk.BOTTOM, fill=tk.X, pady=(4, 0))
        opts = ttk.Frame(left)
        opts.pack(side=tk.BOTTOM, fill=tk.X)
        self.caption = ttk.Label(left, text="no image yet", font="TkFixedFont")
        self.caption.pack(side=tk.BOTTOM, fill=tk.X, pady=(4, 2))
        self.image_box = tk.Frame(left, bg=GREY, padx=6, pady=6)
        self.image_box.pack(fill=tk.BOTH, expand=True)
        self.image_label = tk.Label(self.image_box, bg="black")
        self.image_label.pack(fill=tk.BOTH, expand=True)
        self.image_label.bind("<Configure>", lambda e: self.render_image(force=True))
        ttk.Checkbutton(opts, text="Only at or above the threshold", variable=self.only_above,
                        command=self.images_changed).pack(side=tk.LEFT)
        ttk.Checkbutton(opts, text="Follow latest", variable=self.follow,
                        command=self.images_changed).pack(side=tk.LEFT, padx=12)
        self.thumbs = []
        for k in range(STRIP):
            box = tk.Frame(strip, bg=GREY, padx=3, pady=3)
            box.grid(row=0, column=k, padx=2)
            lab = tk.Label(box, bg="black", width=11, height=4)
            lab.pack()
            text = tk.Label(strip, font=("TkFixedFont", 8))
            text.grid(row=1, column=k)
            lab.bind("<Button-1>", lambda e, k=k: self.thumb_clicked(k))
            self.thumbs.append((box, lab, text, None))

        right = ttk.PanedWindow(upper, orient=tk.VERTICAL)
        upper.add(right, weight=2)
        stats_frame = ttk.Frame(right, padding=4)
        right.add(stats_frame, weight=1)
        self.stats_label = tk.Label(stats_frame, font="TkFixedFont", justify=tk.LEFT, anchor="nw")
        self.stats_label.pack(fill=tk.BOTH, expand=True)
        plot_frame = ttk.Frame(right)
        right.add(plot_frame, weight=2)
        self.fig = Figure(figsize=(5, 4), dpi=90)
        gs = self.fig.add_gridspec(2, 1, height_ratios=(2, 1), hspace=0.55)
        self.ax_t = self.fig.add_subplot(gs[0])
        self.ax_f = self.fig.add_subplot(gs[1])
        self.fig.subplots_adjust(left=0.12, right=0.97, top=0.93, bottom=0.12)
        self.canvas = FigureCanvasTkAgg(self.fig, master=plot_frame)
        self.canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

        bottom = ttk.Frame(main, padding=4)
        main.add(bottom, weight=2)
        cbar = ttk.Frame(bottom)
        cbar.pack(fill=tk.X)
        ttk.Label(cbar, text="Console").pack(side=tk.LEFT)
        ttk.Checkbutton(cbar, text="Pause", variable=self.paused, command=self.console_rebuild).pack(side=tk.LEFT, padx=8)
        ttk.Button(cbar, text="Clear", command=self.console_clear).pack(side=tk.LEFT)
        ttk.Checkbutton(cbar, text="Hide Window lines", variable=self.hide_windows,
                        command=self.console_rebuild).pack(side=tk.LEFT, padx=8)
        body = ttk.Frame(bottom)
        body.pack(fill=tk.BOTH, expand=True)
        self.text = tk.Text(body, font="TkFixedFont", wrap=tk.NONE, height=12, state=tk.DISABLED)
        ys = ttk.Scrollbar(body, orient=tk.VERTICAL, command=self.text.yview)
        xs = ttk.Scrollbar(body, orient=tk.HORIZONTAL, command=self.text.xview)
        self.text.configure(yscrollcommand=ys.set, xscrollcommand=xs.set)
        self.text.tag_configure("err", foreground="#c62828")
        ys.pack(side=tk.RIGHT, fill=tk.Y)
        xs.pack(side=tk.BOTTOM, fill=tk.X)
        self.text.pack(fill=tk.BOTH, expand=True)
        self.update_threshold_label()
        self.render_stats()
        self.render_plot()

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
            elif kind == "window":
                self.window_added(ev[2], ev[3])
                changed = True
            elif kind == "image":
                self.image_added(ev[2])
                new_image = True
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
        self.root.after(DRAIN_MS, self.drain)

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
            self.image_label.configure(image="", text="")
            self.image_box.configure(bg=GREY)
            self.caption.configure(text="no image yet" if not self.images else "no image at or above the threshold")
            return
        aw = max(64, self.image_label.winfo_width())
        ah = max(48, self.image_label.winfo_height())
        if rec is self.shown and not force and getattr(self, "shown_size", None) == (aw, ah):
            self.update_caption(rec)
            return
        try:
            im = Image.open(io.BytesIO(rec["jpeg"]))
            im.load()
        except Exception:
            self.image_label.configure(image="", text="image does not decode", fg="white")
            self.update_caption(rec)
            return
        scale = min(aw / im.width, ah / im.height)
        im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.BILINEAR)
        self.photo = ImageTk.PhotoImage(im)
        self.image_label.configure(image=self.photo, text="")
        self.shown = rec
        self.shown_size = (aw, ah)
        self.update_caption(rec)

    def update_caption(self, rec):
        p = probability(rec["score"]) * 100
        self.image_box.configure(bg=GREEN if self.above(rec["score"]) else GREY)
        extra = "" if rec["merged"] is None else f"  merged {rec['merged']}  failed {rec['failed']}"
        self.caption.configure(text=f"window {rec['window']}  frame {rec['frame']}  score {rec['score']}  "
                                    f"p {p:.1f} %{extra}" + ("" if self.follow.get() else "   (selected)"))

    def thumb_photo(self, rec):
        key = rec["n"]
        ph = self.thumb_photos.get(key)
        if ph is None:
            try:
                im = Image.open(io.BytesIO(rec["jpeg"]))
                im.thumbnail((84, 63))
                ph = ImageTk.PhotoImage(im)
            except Exception:
                ph = None
            self.thumb_photos[key] = ph
            if len(self.thumb_photos) > 4 * STRIP:
                live = {r["n"] for r in self.images}
                for k in [k for k in self.thumb_photos if k not in live]:
                    del self.thumb_photos[k]
        return ph

    def render_strip(self, recs):
        recs = [None] * (STRIP - len(recs)) + recs
        for k, rec in enumerate(recs):
            box, lab, text, _ = self.thumbs[k]
            if rec is None:
                lab.configure(image="", width=11, height=4)
                box.configure(bg=GREY)
                text.configure(text="")
            else:
                ph = self.thumb_photo(rec)
                lab.configure(image=ph if ph else "", width=84 if ph else 11, height=63 if ph else 4)
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
        self.threshold_label.configure(text=f"{thr:.1f} % (score >= {self.score_min()})")

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
                f"Link        elapsed {int(el) // 60}:{int(el) % 60:02d}   frames/s {fps}   images {s['images']}",
                f"  errors    CRC {s['crc']}   seq gaps {s['seq_gaps']}   EOI {s['eoi']}   "
                f"window gaps {s['window_gaps']}   decode {s['decode']}",
                f"  windows   {s['windows']}   merged {s['merged']}   failed inferences {s['failed']}",
                f"  checks    images not the window's best {s['not_best']}   board resets {s['resets']}",
            ]
        n, hits, run, longest = self.detection()
        pct = f"{100 * hits / n:.1f} %" if n else "-"
        out += [
            "",
            f"Detection   threshold {self.threshold.get():.1f} % (score >= {self.score_min()})",
            f"  windows at or above   {hits} of {n} lines ({pct})",
            f"  current run {run}   longest run {longest}",
            "",
            "Stacks (used/allocated bytes)",
        ]
        if s and s["stacks"]:
            for name, (used, alloc) in s["stacks"].items():
                out.append(f"  {name:10s} {used:5d}/{alloc}")
        else:
            out.append("  -")
        out += ["", f"GUI lag     last {1000 * self.lag_last:.0f} ms   max {1000 * self.lag_max:.0f} ms"]
        self.stats_label.configure(text="\n".join(out))

    def render_plot(self):
        self.last_plot = time.monotonic()
        self.plot_dirty = False
        thr = self.threshold.get()
        ax = self.ax_t
        ax.clear()
        if self.lines:
            t_now = self.lines[-1][0]
            i = bisect.bisect_left([t for t, _ in self.lines], t_now - PLOT_S)
            pts = [(t, probability(s) * 100) for t, s in self.lines[i:] if s is not None]
            if pts:
                xs, ys = zip(*pts)
                ax.plot(xs, ys, color="#1f5fa8", linewidth=1)
                ax.scatter(xs, ys, s=6, c=[GREEN if y >= thr else GREY for y in ys], zorder=3)
            ax.set_xlim(max(0, t_now - PLOT_S), max(t_now, 10))
        ax.axhline(thr, color="#c62828", linewidth=1, linestyle="--")
        ax.set_ylim(0, 100)
        ax.set_title("window-best person probability, last 5 min", fontsize=9)
        ax.set_xlabel("time (s)", fontsize=8)
        ax.set_ylabel("%", fontsize=8)
        ax.tick_params(labelsize=7)
        ax.grid(alpha=0.3)
        ax = self.ax_f
        ax.clear()
        w = self.last_window
        if w is not None and w.p is not None:
            probs = [probability(v) * 100 for v in w.p]
            k = None if w.best is None else w.best - w.first
            colours = ["#e08a1e" if j == k else "#7aa6d6" for j in range(len(probs))]
            ax.bar(range(len(probs)), probs, color=colours)
            ax.set_title(f"window {w.window}: frame probabilities (selected: frame {w.best})", fontsize=9)
        else:
            ax.set_title("frame probabilities (score-log build only)", fontsize=9)
        ax.axhline(thr, color="#c62828", linewidth=1, linestyle="--")
        ax.set_ylim(0, 100)
        ax.set_xlim(-0.6, UPLINK_WINDOW - 0.4)
        ax.set_xticks(range(0, UPLINK_WINDOW, 2))
        ax.tick_params(labelsize=7)
        self.canvas.draw_idle()

    def console_add(self, text):
        err = any(m in text for m in ERROR_MARKS)
        win = text.startswith("Window ")
        self.console.append((text, err, win))
        if not self.paused.get() and not (win and self.hide_windows.get()):
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
        hide = self.hide_windows.get()
        for text, err, win in self.console:
            if not (win and hide):
                t.insert(tk.END, text + "\n", ("err",) if err else ())
                self.console_count += 1
        t.configure(state=tk.DISABLED)
        t.see(tk.END)

    def console_clear(self):
        self.console.clear()
        self.console_rebuild()

    def report(self):
        st = self.stats
        n, hits, run, longest = self.detection()
        print(st.summary())
        print(f"detection: threshold {self.threshold.get():.1f} % (score >= {self.score_min()}): "
              f"{hits} of {n} window lines at or above, longest run {longest}")
        mins = " ".join(f"{1000 * self.lag_minute[m]:.0f}" for m in sorted(self.lag_minute))
        print(f"GUI lag: max {1000 * self.lag_max:.0f} ms; max per minute (ms): {mins}")

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
    ap.add_argument("--geometry", default="1500x980", help="window size (and position), as for Tk")
    ap.add_argument("--report", action="store_true", help="print the statistics when the window closes")
    args = ap.parse_args()
    root = tk.Tk()
    App(root, args)
    root.mainloop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
