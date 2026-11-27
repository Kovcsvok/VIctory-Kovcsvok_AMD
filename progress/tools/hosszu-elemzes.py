"""Analysis of a long-play run (meres-csomag.ps1 -Figyelo, menu option 0; Claude-35).

Usage: python -I hosszu-elemzes.py <run folder> [victory.exe for symbols]

Prints, in English:
  1. memory over time (memoria.csv, the log's own-allocation lines) and where our
     blocks that still grow were made (VICTORY_HEAP_SITES lines, symbolised with the PDB);
  2. hitches: frame gaps per 5 minutes, the frames of 250 ms or more, what the timeline
     recordings of hitches show;
  3. low FPS: slow 5-second windows by what bounded them (the card, our submitting thread,
     the title not submitting), and the causes in the recordings of slow scenes;
  4. each F8 mark: the window around it and its recording;
  5. streaming: request latency and the title's mapping costs per minute.
"""
import csv
import glob
import os
import re
import statistics
import sys
from collections import defaultdict

run = sys.argv[1]
exe = sys.argv[2] if len(sys.argv) > 2 else os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    'VIctory-dev', 'belobug-9070', 'target', 'diag', 'victory.exe')
LOG = os.path.join(run, 'victory.log')
TS = re.compile(r'^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d(?:\.\d+)?)Z')


def seconds(line):
    m = TS.match(line)
    if not m:
        return None
    return int(m[4]) * 3600 + int(m[5]) * 60 + float(m[6])


def hms(t):
    t = int(t) % 86400
    return f'{t // 3600:02d}:{t % 3600 // 60:02d}:{t % 60:02d}'


def pct(xs, p):
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(p / 100 * len(xs)))] if xs else float('nan')


# ---------------------------------------------------------------- the log, once
R_GAP = re.compile(r'frame gaps since the last line \((\d+) frames\): (\d+) over 50 ms, (\d+) over 100 ms, (\d+) over 250 ms; the longest ([0-9.]+) ms')
R_ONE = re.compile(r'a frame came (\d+) ms after the one before')
R_FPS = re.compile(r'([0-9.]+) fps, ([0-9.]+) ms/frame \(([0-9.]+) preparing.*?(\d+) draws/frame')
R_CARD = re.compile(r"the card's clock per frame: nothing of ours queued ([0-9.]+) ms \(the card about (\d+)% busy by this count\), ([0-9.]+) ms of that while the submitting thread was working.*?stood waiting for the card ([0-9.]+) ms")
R_THIN = re.compile(r'list calls translated by threads of ours per frame \(VICTORY_THIN\): (\d+) in ([0-9.]+) ms')
R_OWN = re.compile(r'our own allocations: (\d+) MB in (\d+) blocks \(under 4 KiB (\d+) MB in (\d+), to 64 KiB (\d+) MB in (\d+), to 1 MiB (\d+) MB in (\d+), larger (\d+) MB in (\d+)\)')
R_VIEWS = re.compile(r'distinct views kept: (\d+) \((\d+) free\) (\d+) MB')
R_SITES = re.compile(r'where our blocks were made \(VICTORY_HEAP_SITES\): (\d+) sampled blocks alive .*? ([0-9.]+) MB, (\d+) places, (\d+) lost; the most:(.*)$')

gaps, ones, fps, card, thin, own, views, sites = [], [], [], [], [], [], [], []
t0 = None
for raw in open(LOG, encoding='utf-8', errors='replace'):
    t = seconds(raw)
    if t is None:
        continue
    t0 = t0 if t0 is not None else t
    line = re.sub(r'\s+', ' ', raw)
    if (m := R_GAP.search(line)):
        gaps.append((t, [float(x) for x in m.groups()]))
    elif (m := R_ONE.search(line)):
        ones.append((t, int(m[1])))
    elif (m := R_FPS.search(line)):
        fps.append((t, float(m[2]), float(m[3]), int(m[4])))
    elif (m := R_CARD.search(line)):
        card.append((t, float(m[1]), int(m[2]), float(m[3]), float(m[4])))
    elif (m := R_THIN.search(line)):
        thin.append((t, int(m[1]), float(m[2])))
    elif (m := R_SITES.search(line)):
        sites.append((t, m))
    else:
        if (m := R_OWN.search(line)):
            own.append((t, [int(x) for x in m.groups()]))
        if (m := R_VIEWS.search(line)):
            views.append((t, [int(x) for x in m.groups()]))
if t0 is None:
    sys.exit('no log lines')
end = max(x[0] for x in gaps + fps) if gaps or fps else t0
print(f'run {os.path.basename(run)}: log from {hms(t0)} to {hms(end)} UTC, {(end - t0) / 60:.1f} min')

marks = []
mark_file = os.path.join(run, 'jelolesek.csv')
if os.path.exists(mark_file):
    for row in csv.DictReader(open(mark_file, encoding='utf-8-sig')):
        t = seconds(row.get('utc', ''))
        if t is not None:
            marks.append(t)
print(f'F8 marks: {len(marks)}' + (': ' + ', '.join(f'{hms(t)} ({(t - t0) / 60:.1f} min)' for t in marks) if marks else ''))

# ---------------------------------------------------------------- 1. memory
print('\n== 1. memory')
memo = os.path.join(run, 'memoria.csv')
if os.path.exists(memo):
    rows = [r for r in csv.DictReader(open(memo, encoding='utf-8-sig')) if r.get('victory_private_gb')]
    pts = []
    for r in rows:
        t = seconds(r['utc'])
        try:
            pts.append((t, float(r['victory_private_gb']), float(r['victory_ws_gb']), float(r['avail_ram_gb'])))
        except ValueError:
            pass
    print('minute  private GB  working set GB  free RAM GB')
    last = -10
    for t, p, w, a in pts:
        mnt = (t - t0) / 60
        if mnt - last >= 5:
            print(f'{mnt:6.1f}  {p:10.2f}  {w:14.2f}  {a:11.2f}')
            last = mnt
    print('private growth per 10-minute block (least squares), GB/min:')
    for b0 in range(0, int((pts[-1][0] - t0) / 60) + 1, 10):
        blk = [(t, p) for t, p, _, _ in pts if b0 <= (t - t0) / 60 < b0 + 10]
        if len(blk) > 60:
            mt = statistics.mean(t for t, _ in blk)
            mp = statistics.mean(p for _, p in blk)
            slope = sum((t - mt) * (p - mp) for t, p in blk) / sum((t - mt) ** 2 for t, _ in blk) * 60
            print(f'  min {b0:3d}-{b0 + 10:3d}: {slope:+.3f}')
if own:
    print('our own allocations (MB; under 4 KiB MB / blocks), view table:')
    last = -10
    vi = dict((int(t), v) for t, v in views)
    for t, o in own:
        mnt = (t - t0) / 60
        if mnt - last >= 5 or (t, o) == own[-1]:
            v = vi.get(int(t))
            print(f'  {mnt:5.1f} min: {o[0]:6d} MB in {o[1]:8d} blocks; <4K {o[2]:5d} MB / {o[3]:8d}' + (f'; views {v[0]} ({v[2]} MB)' if v else ''))
            last = mnt


def symbolizer(path):
    """Offsets in victory.exe to 'function file:line', with dbghelp and the PDB beside it."""
    try:
        import ctypes
        from ctypes import wintypes as w
        dbg = ctypes.WinDLL('dbghelp.dll')
    except (OSError, ImportError):
        return None
    if not os.path.exists(path):
        return None

    class SYMBOL(ctypes.Structure):
        _fields_ = [('SizeOfStruct', w.ULONG), ('TypeIndex', w.ULONG), ('Reserved', ctypes.c_uint64 * 2),
                    ('Index', w.ULONG), ('Size', w.ULONG), ('ModBase', ctypes.c_uint64), ('Flags', w.ULONG),
                    ('Value', ctypes.c_uint64), ('Address', ctypes.c_uint64), ('Register', w.ULONG),
                    ('Scope', w.ULONG), ('Tag', w.ULONG), ('NameLen', w.ULONG), ('MaxNameLen', w.ULONG),
                    ('Name', ctypes.c_wchar * 1)]

    class LINE(ctypes.Structure):
        _fields_ = [('SizeOfStruct', w.DWORD), ('Key', ctypes.c_void_p), ('LineNumber', w.DWORD),
                    ('FileName', ctypes.c_wchar_p), ('Address', ctypes.c_uint64)]

    h = ctypes.c_void_p(0x5eed)
    dbg.SymSetOptions(0x2 | 0x10)  # undecorated names, lines
    dbg.SymInitializeW.argtypes = [ctypes.c_void_p, ctypes.c_wchar_p, w.BOOL]
    if not dbg.SymInitializeW(h, os.path.dirname(path), False):
        return None
    base = 0x140000000
    dbg.SymLoadModuleExW.restype = ctypes.c_uint64
    dbg.SymLoadModuleExW.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_wchar_p, ctypes.c_wchar_p,
                                     ctypes.c_uint64, w.DWORD, ctypes.c_void_p, w.DWORD]
    if not dbg.SymLoadModuleExW(h, None, path, None, base, 0, None, 0):
        return None
    dbg.SymFromAddrW.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.POINTER(ctypes.c_uint64), ctypes.c_void_p]
    dbg.SymGetLineFromAddrW64.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.POINTER(w.DWORD), ctypes.POINTER(LINE)]
    cache = {}

    def name(offset):
        if offset in cache:
            return cache[offset]
        buf = ctypes.create_string_buffer(ctypes.sizeof(SYMBOL) + 2048)
        sym = ctypes.cast(buf, ctypes.POINTER(SYMBOL)).contents
        sym.SizeOfStruct = ctypes.sizeof(SYMBOL)
        sym.MaxNameLen = 1000
        disp = ctypes.c_uint64(0)
        text = None
        if dbg.SymFromAddrW(h, base + offset - 1, ctypes.byref(disp), buf):
            text = ctypes.wstring_at(ctypes.addressof(sym) + SYMBOL.Name.offset, sym.NameLen)
            line = LINE()
            line.SizeOfStruct = ctypes.sizeof(LINE)
            d2 = w.DWORD(0)
            if dbg.SymGetLineFromAddrW64(h, base + offset - 1, ctypes.byref(d2), ctypes.byref(line)):
                text += f' {os.path.basename(line.FileName)}:{line.LineNumber}'
        cache[offset] = text
        return text
    return name


if sites:
    first, last = sites[0], sites[-1]

    def parse_sites(m):
        out = {}
        for part in m[5].split('|')[1:]:
            mm = re.match(r'\s*(\d+) blocks (\d+) KB at (.*)$', part.strip())
            if mm:
                out[tuple(mm[3].split())] = (int(mm[1]), int(mm[2]))
        return out
    a, b = parse_sites(first[1]), parse_sites(last[1])
    print(f'\nsampled blocks (1 in 1024): {first[1][1]} ({first[1][2]} MB) at {(first[0] - t0) / 60:.1f} min -> '
          f'{last[1][1]} ({last[1][2]} MB) at {(last[0] - t0) / 60:.1f} min; {last[1][4]} lost')
    name = symbolizer(exe)
    if name is None:
        print('  (no symbols: dbghelp or the PDB beside the exe is missing)')
    skip = re.compile(r'^(alloc::|core::|std::|hashbrown::|__rust|rust_|victory_gpu::copystat::|<alloc::|<core::|<std::|<hashbrown::)')

    def place(frames):
        """The first two of our own functions on the stack (file:line of the first)."""
        out = []
        for f in frames:
            text = name(int(f, 16)) if name else None
            if text and skip.match(text):
                continue
            out.append(text or f)
            if len(out) == 2:
                break
        return tuple(out)
    totals = defaultdict(lambda: [0, 0, 0, 0])
    for frames, (n, kb) in a.items():
        t = totals[place(frames)]
        t[0] += n; t[1] += kb
    for frames, (n, kb) in b.items():
        t = totals[place(frames)]
        t[2] += n; t[3] += kb
    grow = sorted(((t[3] - t[1], t[2] - t[0], k) for k, t in totals.items()), reverse=True)
    print('the places that grew most (the top 40 stacks at each end, grouped by our first two functions; x1024 for all blocks):')
    for kb, n, key in grow[:12]:
        print(f'  {kb:+6.0f} MB (est.), {n * 1024:+9d} blocks: ' + '  <-  '.join(key))

# ---------------------------------------------------------------- 2. hitches
print('\n== 2. hitches')
print('5-min block: frames, over 50 ms %, over 100 ms, 250 ms or more, the longest')
blocks = defaultdict(lambda: [0, 0, 0, 0, 0.0])
for t, g in gaps:
    b = int((t - t0) // 300)
    blocks[b][0] += g[0]; blocks[b][1] += g[1]; blocks[b][2] += g[2]; blocks[b][3] += g[3]
    blocks[b][4] = max(blocks[b][4], g[4])
for b in sorted(blocks):
    f, o50, o100, o250, lng = blocks[b]
    print(f'  {b * 5:3d}-{b * 5 + 5:3d} min: {f:6.0f} frames, {100 * o50 / max(f, 1):5.1f} %, {o100:4.0f}, {o250:3.0f}, {lng:6.0f} ms')
print(f'frames of 250 ms or more told one by one: {len(ones)}' + (': ' + ', '.join(f'{(t - t0) / 60:.1f}m {ms}' for t, ms in ones[:40]) if ones else ''))

R_FRAME = re.compile(r'^frame of ([0-9.]+) ms, present on .*?: the chain it came out of, by cause')
R_CAUSE = re.compile(r'^\s+([0-9.]+) ms\s+(.+)$')


def recording(path):
    frames, cur = [], None
    for line in open(path, encoding='utf-8', errors='replace'):
        if (m := R_FRAME.match(line)):
            cur = [float(m[1]), []]
            frames.append(cur)
        elif cur and (m := R_CAUSE.match(line)):
            cur[1].append((float(m[1]), re.sub(r' on \d+ ', ' on ', re.sub(r'\+0x[0-9a-f]+', '', m[2].strip()))))
        elif not line.strip():
            cur = None
    return frames


recs = defaultdict(list)
for path in sorted(glob.glob(os.path.join(run, 'idovonal.*.txt'))):
    m = re.search(r'idovonal\.(\d+)-(\w+)\.txt$', path)
    if m:
        recs[m[2]].append((int(m[1]), path))
print('timeline recordings: ' + (', '.join(f'{k} {len(v)}' for k, v in recs.items()) or 'none'))


def causes_of(kind, slowest_only):
    total = defaultdict(float)
    n = 0
    for _, path in recs.get(kind, []):
        frames = recording(path)
        if not frames:
            continue
        chosen = [max(frames, key=lambda f: f[0])] if slowest_only else frames
        for ms, causes in chosen:
            n += 1
            for c_ms, c in causes:
                total[c] += c_ms
    return n, sorted(total.items(), key=lambda x: -x[1])


n, top = causes_of('hitch', True)
if n:
    print(f'the slowest frame of each hitch recording ({n}): causes summed')
    for c, ms in top[:12]:
        print(f'  {ms / n:8.1f} ms a frame  {c}')
    for when, path in recs['hitch'][:12]:
        frames = recording(path)
        if frames:
            ms, causes = max(frames, key=lambda f: f[0])
            print(f'  {when / 60:5.1f} min: {ms:.0f} ms: ' + '; '.join(f'{c} {c_ms:.0f}' for c_ms, c in causes[:3]))

# ---------------------------------------------------------------- 3. low FPS
print('\n== 3. low FPS')
cards = sorted(card)


def card_near(t):
    near = [c for c in cards if abs(c[0] - t) <= 3]
    if not near:
        return None
    return (statistics.mean(c[2] for c in near), statistics.mean(c[3] for c in near),
            statistics.mean(c[1] - c[3] for c in near), statistics.mean(c[4] for c in near))


thins = sorted(thin)
play = [f for f in fps if (f[0] - t0) >= 180]
if play:
    ms = [f[1] for f in play]
    print(f'5-s windows from 3 min on: {len(play)}; ms/frame median {statistics.median(ms):.1f}, p90 {pct(ms, 90):.1f}; '
          f'under 30 FPS (over 33.4 ms) {100 * sum(m > 33.4 for m in ms) / len(ms):.0f} %, under 20 FPS {100 * sum(m > 50 for m in ms) / len(ms):.0f} %')
    kinds = defaultdict(list)
    detail = []
    for t, m, prep, draws in play:
        c = card_near(t)
        if c is None or m <= 40:
            continue
        busy, behind, title_idle, card_wait = c
        # The largest of the three parts of the frame: the card busy, the
        # card idle behind our submitting thread, idle with nothing submitted.
        kind = max((busy / 100 * m, 'the card (GPU) busy'), (behind, 'our submitting thread'),
                   (title_idle, 'the title not submitting'))[1]
        kinds[kind].append(m)
        th = [x for x in thins if abs(x[0] - t) <= 3]
        detail.append((m, t, kind, busy, behind, title_idle, draws, th[0][2] if th else float('nan')))
    print('windows over 40 ms a frame, by what bounded them (from the card-clock lines):')
    for k, v in sorted(kinds.items(), key=lambda x: -len(x[1])):
        print(f'  {k:28s} {len(v):4d} windows, mean {statistics.mean(v):.1f} ms')
    if detail:
        print('  mean parts of those frames: card busy {:.1f} ms, idle behind our submitting thread {:.1f} ms, idle with nothing submitted {:.1f} ms'.format(
            statistics.mean(d[3] / 100 * d[0] for d in detail), statistics.mean(d[4] for d in detail), statistics.mean(d[5] for d in detail)))
    print('the slowest windows: min, ms/frame, bound by, card busy %, card idle behind us ms, card idle with the title not submitting ms, draws, our translation ms (all threads)')
    for m, t, kind, busy, behind, title_idle, draws, tr in sorted(detail, reverse=True)[:15]:
        print(f'  {(t - t0) / 60:5.1f} {m:6.1f}  {kind:26s} {busy:4.0f} {behind:6.1f} {title_idle:6.1f} {draws:6d} {tr:7.1f}')
n, top = causes_of('low', False)
if n:
    print(f'frames of the slow-scene recordings ({n}): causes summed, per frame')
    for c, ms in top[:15]:
        print(f'  {ms / n:8.1f} ms  {c}')

# ---------------------------------------------------------------- 4. marks
print('\n== 4. F8 marks')
for i, t in enumerate(marks, 1):
    near = [f for f in fps if abs(f[0] - t) <= 6]
    g = [x for x in gaps if abs(x[0] - t) <= 6]
    c = card_near(t)
    text = f'  #{i} {(t - t0) / 60:.1f} min: '
    if near:
        text += f'{statistics.mean(f[1] for f in near):.1f} ms/frame, {near[0][3]} draws'
    if g:
        text += f', longest gap {max(x[1][4] for x in g):.0f} ms'
    if c:
        text += f', card {c[0]:.0f} % busy'
    rec = [(w, p) for w, p in recs.get('mark', []) if 0 <= w - (t - t0) <= 20]
    if rec:
        frames = recording(rec[0][1])
        if frames:
            ms, causes = max(frames, key=lambda f: f[0])
            text += f'; recording {os.path.basename(rec[0][1])}: slowest {ms:.0f} ms: ' + '; '.join(f'{cc} {c_ms:.0f}' for c_ms, cc in causes[:3])
    print(text)

# ---------------------------------------------------------------- 5. streaming
print('\n== 5. streaming (betoltes.tsv)')
tsv = os.path.join(run, 'betoltes.tsv')
if os.path.exists(tsv):
    per = defaultdict(lambda: {'n': 0, 'mb': 0.0, 'lat': [], 'wait': [], 'map': [0, 0, 0, 0]})
    mark_reqs = defaultdict(list)
    epoch0 = None
    for line in open(tsv, encoding='utf-8', errors='replace'):
        f = line.rstrip('\n').split('\t')
        if f[0] == 'R' and len(f) >= 12:
            try:
                enq, sub, start, done = (int(x) for x in f[8:12])
                dst = int(f[6])
            except ValueError:
                continue
            epoch0 = epoch0 or done
            mnt = int((done - epoch0) / 60000)
            p = per[mnt]
            p['n'] += 1
            p['mb'] += dst / 1e6
            p['lat'].append(done - enq)
            p['wait'].append(start - sub)
        elif f[0] == 'M' and len(f) >= 17:
            try:
                tm = int(f[1])
                v = [int(x) for x in f[2:17]]
            except ValueError:
                continue
            epoch0 = epoch0 or tm
            p = per[int((tm - epoch0) / 60000)]
            p['map'][0] += v[0]
            p['map'][1] += v[2]
            p['map'][2] = max(p['map'][2], v[3])
            p['map'][3] += v[4]
    print('minute of the log: requests, MB, enqueue-to-done ms p50/p95/max, submit-to-start ms p95, mapping calls, their ms, the longest ms, lock wait ms')
    for mnt in sorted(per):
        p = per[mnt]
        lat = p['lat'] or [0]
        print(f'  {mnt:3d}: {p["n"]:6d} {p["mb"]:8.1f}  {pct(lat, 50):5.0f} {pct(lat, 95):6.0f} {max(lat):6.0f}  {pct(p["wait"] or [0], 95):5.0f}  '
              f'{p["map"][0]:6d} {p["map"][1]:6d} {p["map"][2]:5d} {p["map"][3]:5d}')
else:
    print('  no betoltes.tsv')
