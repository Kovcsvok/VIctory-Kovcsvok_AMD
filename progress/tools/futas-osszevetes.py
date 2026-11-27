"""Compare whole runs that differ in a setting fixed at start (no live A/B possible).

Usage: python -I futas-osszevetes.py A=<run dir> B=<run dir> [A=... B=...] [--from 180]

Per run: the frame-rate lines (about every 5 s) from second <from> on (default 180, after
loading): mean, median and p90 ms/frame, and mean draws/frame. Then per label all its
runs pooled, and a draw-matched difference: runs at the same save differ a lot in scene
load (Claude-39: 7,076 against 4,439 draws a frame), so lines are put in bins of 500
draws a frame and B is compared with A bin by bin, weighted by the smaller count.
(Claude-40, 2026-11-28.)
"""
import os
import re
import statistics
import sys

TS = re.compile(r'^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d(?:\.\d+)?)Z')
R_FPS = re.compile(r'([0-9.]+) fps, ([0-9.]+) ms/frame \(([0-9.]+) preparing.*?(\d+) draws/frame')
BIN = 500


def seconds(m):
    y, mo, d, h, mi, s = m.groups()
    return ((int(d) * 24 + int(h)) * 60 + int(mi)) * 60 + float(s)


def read(run, start):
    rows = []
    t0 = None
    with open(os.path.join(run, 'victory.log'), encoding='utf-8', errors='replace') as f:
        for line in f:
            m = TS.match(line)
            if not m:
                continue
            t = seconds(m)
            t0 = t if t0 is None else t0
            p = R_FPS.search(line)
            if p and t - t0 >= start:
                rows.append((float(p[2]), int(p[4])))
    return rows


def pct(xs, q):
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(q * len(xs)))] if xs else float('nan')


def line(name, rows):
    ms = [r[0] for r in rows]
    dr = [r[1] for r in rows]
    if not rows:
        return f'{name:44s} no frame-rate lines'
    return (f'{name:44s} n={len(rows):4d}  mean {statistics.mean(ms):6.1f}  median {statistics.median(ms):6.1f}'
            f'  p90 {pct(ms, 0.9):6.1f} ms/frame   draws {statistics.mean(dr):6.0f}')


def main():
    start = 180
    runs = []
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == '--from':
            start = int(args[i + 1])
            i += 2
            continue
        label, _, run = args[i].partition('=')
        if not run:
            sys.exit(__doc__)
        runs.append((label, run.rstrip('\\/')))
        i += 1
    pooled = {}
    print(f'Frame-rate lines from second {start} on:')
    for label, run in runs:
        rows = read(run, start)
        print('  ' + line(f'{label}  {os.path.basename(run)}', rows))
        pooled.setdefault(label, []).extend(rows)
    print('Pooled:')
    for label, rows in pooled.items():
        print('  ' + line(label, rows))
    labels = list(pooled)
    if len(labels) < 2:
        return
    a, b = labels[0], labels[1]
    bins = {}
    for k, rows in ((a, pooled[a]), (b, pooled[b])):
        for ms, dr in rows:
            bins.setdefault(dr // BIN, {}).setdefault(k, []).append(ms)
    print(f'Draw-matched, {b} minus {a} (bins of {BIN} draws a frame, both with 5 lines or more):')
    total = weight = 0.0
    for k in sorted(bins):
        x, y = bins[k].get(a, []), bins[k].get(b, [])
        if len(x) < 5 or len(y) < 5:
            continue
        d = statistics.mean(y) - statistics.mean(x)
        w = min(len(x), len(y))
        total += d * w
        weight += w
        print(f'  {k * BIN:5d}-{k * BIN + BIN - 1:5d} draws: {a} {statistics.mean(x):6.1f} (n={len(x):3d})'
              f'  {b} {statistics.mean(y):6.1f} (n={len(y):3d})  difference {d:+6.1f} ms')
    if weight:
        print(f'  weighted difference: {total / weight:+.1f} ms/frame ({b} minus {a}; negative: {b} faster)')
    else:
        print('  no bin with enough lines in both')


if __name__ == '__main__':
    main()
