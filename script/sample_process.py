#!/usr/bin/env python3
"""Passive CPU/RSS sample; does not launch, activate or control the application."""
import argparse, json, subprocess, time
from pathlib import Path
p = argparse.ArgumentParser()
p.add_argument('--seconds', type=int, default=60)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
ids = subprocess.check_output(['pgrep', '-x', 'Rightnest'], text=True).split()
if len(ids) != 1:
    raise SystemExit('Exactly one running Rightnest process is required')
pid = ids[0]
def sample():
    raw = subprocess.check_output(['ps', '-p', pid, '-o', 'time=', '-o', 'rss='], text=True).split()
    if len(raw) != 2:
        raise SystemExit('Process exited during sampling')
    parts = raw[0].split(':')
    cpu = sum(float(n) * 60**i for i, n in enumerate(reversed(parts)))
    return time.monotonic(), cpu, int(raw[1])
start = sample()
rows = [start]
while time.monotonic() - start[0] < a.seconds:
    time.sleep(min(2, max(0, a.seconds - (time.monotonic() - start[0]))))
    rows.append(sample())
end = rows[-1]
report = {'durationSeconds': round(end[0]-start[0], 2), 'averageCPUPercent': round(100*(end[1]-start[1])/(end[0]-start[0]), 3),
          'initialRSSKiB': start[2], 'finalRSSKiB': end[2], 'peakRSSKiB': max(r[2] for r in rows),
          'samples': len(rows), 'scope': 'Passive short sample; not a one-hour soak or active-overlay benchmark',
          'os': subprocess.check_output(['sw_vers', '-productVersion'], text=True).strip()}
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps(report))
