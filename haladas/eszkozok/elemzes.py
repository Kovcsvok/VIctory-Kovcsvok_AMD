# KLBF-futás elemzése az ab75ac3-kérdéshez (Claude, 2026-11-26).
# Használat: py -3 -I elemzes.py <futás mappája> [--akadas-ms 250]
# Bemenet: victory.log, frametime.csv (VICTORY_FRAMETIME_DUMP), memoria.csv (memoria-mintavevo.ps1).
# Kimenet: osszegzes.md ugyanabban a mappában, és rövid összegzés a konzolon.
#
# Fontos: egyik bemenet sem képkockánkénti adatsor. A naplósor és a frametime.csv kb.
# másodpercenként összesít (átlag és a legrosszabb egyedi képkocka), ezért p95 nem számolható.
import argparse, csv, re, statistics, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument('dir')
ap.add_argument('--akadas-ms', type=float, default=250.0)
a = ap.parse_args()
sys.stdout.reconfigure(errors='replace')
run = Path(a.dir)

ANSI = re.compile(r'\x1b\[[0-9;]*m')
TS = re.compile(r'^(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?)Z')
STATS = re.compile(r'([0-9.]+) fps, ([0-9.]+) ms/frame \(([0-9.]+) preparing: copies ([0-9.]+) ms\s+([0-9.]+) MB, '
                   r'textures ([0-9.]+) ms ([0-9.]+) MB;\s+([0-9.]+) on the\s+GPU;\s+([0-9.]+) copying back '
                   r'([0-9.]+) MB\), (\d+) draws/frame')
WAIT = re.compile(r'textures picked by index: (\d+) uploaded so far \((\d+) MB\),\s+(\d+) waiting, (\d+) passed over unmapped')
RAM = re.compile(r'ram line: process working set (\d+) MB, private (\d+) MB; PC free (\d+) MB, free commit (\d+) MB')
CARD = re.compile(r'card \(VRAM\) (\d+) MB in use of (\d+) MB budget, shared (\d+) MB in use')
# C1 tesztág (klbf-c1): a leképezési útvonal sorai
LEAN = re.compile(r'views over physical pages over \d+ s \(VICTORY_MAP_LEAN=(\d)\): (\d+) mapped over their own placeholder without a split, (\d+) after a split; (\d+) found')
LEAN_MODE = re.compile(r'views over physical pages \(VICTORY_MAP_LEAN=(\d)\):')
EVENTS = {
    'no upload buffer (feltöltési puffer elutasítva)': re.compile(r'no upload buffer'),
    'no host texture (GPU-textúra elutasítva)': re.compile(r'no host texture'),
    'no read-back buffer': re.compile(r'no read-back buffer'),
    '0x8007000E / E_OUTOFMEMORY': re.compile(r'8007000e|E_OUTOFMEMORY', re.I),
    'Rust-foglalás megszakadt': re.compile(r'memory allocation of \d+ bytes failed'),
    'VRAM-kapu: a textúrasor elutasítva': re.compile(r'the texture queue is refused|the card has no room'),
    'eszközvesztés': re.compile(r'the host device went|device removed|DEVICE_REMOVED|DEVICE_HUNG', re.I),
    'panic': re.compile(r'panicked at'),
}
OOM_KEYS = [k for k in EVENTS if k.startswith(('no upload', 'no host', 'no read', '0x8007', 'Rust'))]
ROOM_KEY = 'VRAM-kapu: a textúrasor elutasítva'


def utc(s):
    return datetime.fromisoformat(s).replace(tzinfo=timezone.utc)


def local(d):
    return d.astimezone().strftime('%H:%M:%S')


def near(series, t, within):
    """A `series` [(idő, érték)] t-hez legközelebbi eleme `within` másodpercen belül."""
    best = None
    for ts, v in series:
        dt = abs((ts - t).total_seconds())
        if dt <= within and (best is None or dt < best[0]):
            best = (dt, v)
    return None if best is None else best[1]


def count_near(times, t, within):
    return sum(1 for x in times if abs((x - t).total_seconds()) <= within)


def fmt(v, spec='.1f', none='–'):
    return none if v is None else format(v, spec)


# --- victory.log --------------------------------------------------------------------------------
stats, waits, rams, cards = [], [], [], []
events = {k: [] for k in EVENTS}
oom_lines = []  # soronként egyszer: egy sor több mintára is illeszkedhet
lean_lines, lean_modes = [], []
log_path = run / 'victory.log'
lines = 0
if log_path.exists():
    for raw in open(log_path, encoding='utf-8', errors='replace'):
        lines += 1
        line = ANSI.sub('', raw)
        m = TS.match(line)
        if not m:
            continue
        t = utc(m.group(1))
        s = STATS.search(line)
        if s:
            stats.append((t, {'fps': float(s.group(1)), 'ms': float(s.group(2)), 'textures_ms': float(s.group(6)),
                              'textures_mb': float(s.group(7)), 'draws': int(s.group(11))}))
        w = WAIT.search(line)
        if w:
            waits.append((t, int(w.group(3))))
        r = RAM.search(line)
        if r:
            rams.append((t, {'private_mb': int(r.group(2)), 'free_commit_mb': int(r.group(4))}))
        c = CARD.search(line)
        if c:
            cards.append((t, {'vram_used_mb': int(c.group(1)), 'vram_budget_mb': int(c.group(2)), 'shared_mb': int(c.group(3))}))
        for k, rx in EVENTS.items():
            if rx.search(line):
                events[k].append(t)
        if any(EVENTS[k].search(line) for k in OOM_KEYS):
            oom_lines.append(t)
        m = LEAN.search(line)
        if m:
            lean_lines.append((m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4))))
        m = LEAN_MODE.search(line)
        if m:
            lean_modes.append(m.group(1))

# --- frametime.csv ------------------------------------------------------------------------------
frames = []
ft_path = run / 'frametime.csv'
if ft_path.exists():
    rows = [l for l in open(ft_path, encoding='utf-8', errors='replace') if l.strip() and not l.startswith('#')]
    for row in csv.DictReader(rows):
        try:
            t = datetime.fromtimestamp(int(row['t_ms']) / 1000, tz=timezone.utc)
            frames.append((t, {k: float(row[k]) for k in ('fps', 'ms_per_frame', 'frame_ms_max', 'frame_ms_avg',
                                                           'draws', 'textures_ms', 'textures_mb')}))
        except (KeyError, ValueError):
            continue

# --- memoria.csv --------------------------------------------------------------------------------
mem = []
mem_path = run / 'memoria.csv'
if mem_path.exists():
    rows = [l for l in open(mem_path, encoding='utf-8', errors='replace') if l.strip() and not l.startswith('#')]
    for row in csv.DictReader(rows):
        try:
            t = utc(row['utc'].rstrip('Z'))
        except ValueError:
            continue
        num = lambda k: float(row[k]) if row.get(k) not in (None, '') else None
        mem.append((t, {k: num(k) for k in ('commit_free_gb', 'commit_used_gb', 'commit_limit_gb', 'avail_ram_gb',
                                            'victory_private_gb', 'victory_gpu_dedicated_gb', 'victory_gpu_shared_gb',
                                            'adapter_dedicated_gb', 'adapter_shared_gb', 'pages_input_per_s')}))

# --- Világ-szakasz: >= 1000 rajzolás/képkocka (mint a tools\fps-session.py) -------------------------
world_stats = [(t, s) for t, s in stats if s['draws'] >= 1000]
world_frames = [(t, f) for t, f in frames if f['draws'] >= 1000]
w_from = min((t for t, _ in world_stats), default=None)
w_to = max((t for t, _ in world_stats), default=None)
in_world = (lambda t: w_from is not None and w_from - timedelta(seconds=5) <= t <= w_to + timedelta(seconds=5))

ram_world = [(t, r) for t, r in rams if in_world(t)]
mem_world = [(t, m) for t, m in mem if in_world(t)]
min_commit_log = min((r['free_commit_mb'] / 1024 for _, r in ram_world), default=None)
min_commit_mem = min((m['commit_free_gb'] for _, m in mem_world if m['commit_free_gb'] is not None), default=None)
peak = lambda key: max((m[key] for _, m in mem_world if m[key] is not None), default=None)
oom_times = sorted(oom_lines)
room_times = events[ROOM_KEY]

# --- Akadások: az intervallum legrosszabb képkockája >= küszöb ------------------------------------------
source = 'frametime.csv (intervallumonkénti legrosszabb képkocka)'
cands = [(t, f['frame_ms_max'], f) for t, f in world_frames]
if not cands:
    source = 'naplósor (csak intervallum-átlag: a rövid akadás elmosódik)'
    cands = [(t, s['ms'], None) for t, s in world_stats]
stalls = sorted([c for c in cands if c[1] >= a.akadas_ms], key=lambda c: -c[1])

wait_vals = [v for t, v in waits if in_world(t)]
wait_median = statistics.median(wait_vals) if wait_vals else None
detail = []
for t, worst, f in stalls[:25]:
    r = near(ram_world, t, 6)
    m = near(mem_world, t, 2)
    s = f or near(world_stats, t, 1.5)
    detail.append({
        't': t, 'worst': worst, 'avg': f['frame_ms_avg'] if f else None,
        'tex_ms': s['textures_ms'] if s else None,
        'tex_mb': s['textures_mb'] if s else None,
        'waiting': near(waits, t, 3),
        'commit_log': r['free_commit_mb'] / 1024 if r else None,
        'commit_mem': m['commit_free_gb'] if m else None,
        'gpu_ded': m['victory_gpu_dedicated_gb'] if m else None,
        'gpu_sh': m['victory_gpu_shared_gb'] if m else None,
        'oom': count_near(oom_times, t, 5),
        'room': count_near(room_times, t, 5),
    })

low_commit = lambda d: any(v is not None and v < 4.0 for v in (d['commit_log'], d['commit_mem']))
n_st = len(stalls)
n_oom_st = sum(1 for d in detail if d['oom'] > 0)
n_low_st = sum(1 for d in detail if low_commit(d))
n_room_st = sum(1 for d in detail if d['room'] > 0)
n_wait_st = sum(1 for d in detail if wait_median is not None and d['waiting'] is not None and d['waiting'] > wait_median)
min_commit = min((v for v in (min_commit_log, min_commit_mem) if v is not None), default=None)

if not world_stats:
    verdict = 'NINCS ADAT: a napló nem tartalmaz világ-szakaszt (>= 1000 rajzolás/képkocka).'
elif oom_times and (n_oom_st or n_low_st):
    verdict = ('IGEN, valószínű: memóriafoglalási hiba (E_OUTOFMEMORY / elutasított puffer) és akadás esik egybe. '
               'Az ab75ac3 visszatartása és a slot újrapróbálása ezt a hibát célozza.')
elif not oom_times and min_commit is not None and min_commit >= 4.0:
    verdict = ('NEM látszik: nem volt foglalási hiba, és a szabad commit végig 4 GiB felett maradt, '
               'tehát az ab75ac3 kapuja sem lépett volna működésbe. Az akadások oka máshol keresendő.')
else:
    verdict = 'BIZONYTALAN: a jelek vegyesek, lásd az alábbi táblákat.'

# --- osszegzes.md -------------------------------------------------------------------------------------
L = []
L.append(f'# Futás összegzése: {run.name}\n')
info = run / 'futas.txt'
if info.exists():
    L.append('```text\n' + info.read_text(encoding='utf-8-sig', errors='replace').strip() + '\n```\n')
L.append(f'**Ítélet az ab75ac3-kérdésre:** {verdict}\n')
L.append('**Adattípus:** nincs képkockánkénti adatsor. A KLBF-naplósor és a `frametime.csv` kb. másodpercenként '
         'összesít (átlag és a legrosszabb egyedi képkocka), a memóriasor 5 másodpercenként jön, a `memoria.csv` '
         'másodpercenként. Ezért képkockaidő-p95 nem számolható; az alábbi értékek intervallum-statisztikák.\n')
L.append('## Alapadatok\n')
L.append('| Mérőszám | Érték |\n|---|---|')
L.append(f'| Naplósorok / összesítő sorok / világ-sorok (>= 1000 rajzolás) | {lines} / {len(stats)} / {len(world_stats)} |')
if w_from:
    L.append(f'| Világ-szakasz (helyi idő) | {local(w_from)}–{local(w_to)} ({(w_to - w_from).total_seconds() / 60:.1f} perc) |')
if world_stats:
    L.append(f'| Intervallumok FPS-mediánja (világ) | {statistics.median(s["fps"] for _, s in world_stats):.1f} |')
    L.append(f'| Intervallumok ms/kép mediánja (világ) | {statistics.median(s["ms"] for _, s in world_stats):.1f} |')
if world_frames:
    worst_all = max(world_frames, key=lambda x: x[1]['frame_ms_max'])
    L.append(f'| Legrosszabb egyedi képkocka (világ) | {worst_all[1]["frame_ms_max"]:.0f} ms ({local(worst_all[0])}) |')
    for th in (100, 250, 500, 1000):
        L.append(f'| Intervallumok, ahol volt >= {th} ms-os képkocka | {sum(1 for _, f in world_frames if f["frame_ms_max"] >= th)} / {len(world_frames)} |')
L.append(f'| Várakozó textúrák (slot) mediánja / csúcsa (világ) | {fmt(wait_median, ".0f")} / {fmt(max(wait_vals) if wait_vals else None, ".0f")} |')
L.append(f'| Legkisebb szabad commit (napló / mintavevő) | {fmt(min_commit_log, ".2f")} / {fmt(min_commit_mem, ".2f")} GiB |')
L.append(f'| victory.exe privát csúcs (mintavevő) | {fmt(peak("victory_private_gb"), ".2f")} GiB |')
L.append(f'| victory.exe GPU dedikált / megosztott csúcs | {fmt(peak("victory_gpu_dedicated_gb"), ".2f")} / {fmt(peak("victory_gpu_shared_gb"), ".2f")} GiB |')
L.append(f'| Egész GPU dedikált csúcs | {fmt(peak("adapter_dedicated_gb"), ".2f")} GiB |')
if cards:
    worst_card = max(cards, key=lambda c: c[1]['vram_used_mb'])
    L.append(f'| KLBF VRAM-sor csúcsa | {worst_card[1]["vram_used_mb"]} MB a {worst_card[1]["vram_budget_mb"]} MB-os keretből ({local(worst_card[0])}) |')
L.append('')
L.append('## Memória- és hibasorok a naplóban\n')
L.append('| Esemény | Darab | Első (helyi idő) | Utolsó |\n|---|---:|---|---|')
for k, ts in events.items():
    L.append(f'| {k} | {len(ts)} | {local(min(ts)) if ts else "–"} | {local(max(ts)) if ts else "–"} |')
L.append('')
L.append(f'## Akadások (forrás: {source}; küszöb {a.akadas_ms:.0f} ms)\n')
L.append(f'{n_st} akadásos intervallum. A 25 legrosszabból: {n_oom_st} esetben volt foglalási hiba ±5 s-on belül, '
         f'{n_low_st} esetben 4 GiB alatti szabad commit, {n_room_st} esetben VRAM-kapu, '
         f'{n_wait_st} esetben a medián feletti textúrasor.\n')
L.append('| Idő | Legrosszabb kép (ms) | Átlag (ms) | Textúra ms / MB | Várakozó slot | Szabad commit napló / minta (GiB) | GPU ded. / megosztott (GiB) | Foglalási hiba ±5 s | VRAM-kapu ±5 s |')
L.append('|---|---:|---:|---|---:|---|---|---:|---:|')
for d in detail:
    L.append(f'| {local(d["t"])} | {d["worst"]:.0f} | {fmt(d["avg"])} | {fmt(d["tex_ms"])} / {fmt(d["tex_mb"])} | '
             f'{fmt(d["waiting"], ".0f")} | {fmt(d["commit_log"], ".2f")} / {fmt(d["commit_mem"], ".2f")} | '
             f'{fmt(d["gpu_ded"], ".2f")} / {fmt(d["gpu_sh"], ".2f")} | {d["oom"]} | {d["room"]} |')
L.append('')
L.append('Értelmezés: az ab75ac3 akkor releváns, ha az akadások mellett `no upload buffer`, `no host texture` vagy '
         '0x8007000E jelenik meg, illetve a szabad commit 4 GiB alá esik. Ha az akadásokat a VRAM-kapu kíséri, '
         'a KLBF `resource::room()` kerete és a `-LowMemory` profil az elsődleges vizsgálati irány.\n')
if lean_modes or lean_lines:
    modes = sorted(set(lean_modes) | {x[0] for x in lean_lines})
    L.append('## C1: leképezési útvonal (VICTORY_MAP_LEAN)\n')
    L.append(f'A naplóban szereplő érték(ek): {", ".join(modes)}. '
             f'Hasítás nélkül leképezett nézetek: {sum(x[1] for x in lean_lines)}, hasítás után: {sum(x[2] for x in lean_lines)}, '
             f'ebből saját helyfoglalót kereső, de végül hasított: {sum(x[3] for x in lean_lines)} ({len(lean_lines)} naplósor).\n')
marks = run / 'jelolesek.csv'
if marks.exists():
    rows = [r for r in csv.DictReader(open(marks, encoding='utf-8', errors='replace')) if r.get('local')]
    L.append('## F8-jelölések\n')
    L.append(', '.join(f'{r["n"]}. {r["local"]}' for r in rows) + '\n' if rows else 'Nem volt jelölés.\n')
out = run / 'osszegzes.md'
out.write_text('\n'.join(L), encoding='utf-8')
print(verdict)
print(f'Világ-sorok: {len(world_stats)}, akadásos intervallumok (>= {a.akadas_ms:.0f} ms): {n_st}, '
      f'foglalási hibasorok: {len(oom_times)}, legkisebb szabad commit: {fmt(min_commit, ".2f")} GiB')
print(f'Összegzés: {out}')
