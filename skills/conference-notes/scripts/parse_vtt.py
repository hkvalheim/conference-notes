#!/usr/bin/env python3
"""Parse YouTube auto-generated VTT captions into deduplicated plain text with timestamps.

Auto-captions arrive as rolling cue blocks that grow more complete over time
(each block re-shows a chunk of text with one more word appended). Taking the
last line of every cue block - not a globally deduplicated set of lines -
avoids the gaps that a naive dedupe strategy produces.
"""
import argparse
import glob
import json
import os
import re
import sys


def ts_to_secs(ts):
    parts = ts.split(':')
    if len(parts) == 3:
        h, m, s = parts
    else:
        h, m, s = 0, *parts
    return int(h) * 3600 + int(m) * 60 + float(s.replace(',', '.'))


def secs_to_ts(secs):
    hh, rem = divmod(int(secs), 3600)
    mm, ss = divmod(rem, 60)
    return f"{hh:02d}:{mm:02d}:{ss:02d}"


def parse_vtt(vtt_path, start_ts=None, end_ts=None):
    start_sec = ts_to_secs(start_ts) if start_ts else 0
    end_sec = ts_to_secs(end_ts) if end_ts else float('inf')

    with open(vtt_path, encoding='utf-8') as f:
        content = f.read()

    results = []
    for block in re.split(r'\n\n+', content):
        lines = block.strip().split('\n')
        ts_line = next((l for l in lines if '-->' in l), None)
        if not ts_line:
            continue
        m = re.match(r'((?:\d+:)?\d+:\d+[.,]\d+)\s*-->', ts_line)
        if not m:
            continue
        cue_start = ts_to_secs(m.group(1))
        if not (start_sec <= cue_start <= end_sec):
            continue
        text_lines = [
            re.sub(r'<[^>]+>', '', l).strip()
            for l in lines
            if '-->' not in l and not l.startswith('NOTE') and not l.strip().isdigit()
        ]
        text_lines = [t for t in text_lines if t]
        if text_lines:
            results.append((cue_start, text_lines[-1]))

    deduped = []
    prev = None
    for sec, text in results:
        if text != prev:
            deduped.append(f"[{secs_to_ts(sec)}] {text}")
            prev = text
    return deduped


def process_file(vtt_path, start_ts=None, end_ts=None, out_path=None):
    lines = parse_vtt(vtt_path, start_ts, end_ts)
    if out_path is None:
        base = re.sub(r'\.en\.vtt$', '', vtt_path)
        base = re.sub(r'\.vtt$', '', base)
        out_path = base + '.txt'
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f"Wrote: {out_path} ({len(lines)} lines)", file=sys.stderr)
    return out_path, len(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', help='A .vtt file, or a directory to glob for *.en.vtt files')
    parser.add_argument('--start', help='Start timestamp HH:MM:SS - extract only this range (single-file mode)')
    parser.add_argument('--end', help='End timestamp HH:MM:SS - extract only this range (single-file mode)')
    parser.add_argument('--out', help='Output path override (single-file mode)')
    args = parser.parse_args()

    written = []
    if os.path.isdir(args.input):
        if args.start or args.end or args.out:
            print("--start/--end/--out require a single .vtt file, not a directory", file=sys.stderr)
            sys.exit(1)
        vtt_files = sorted(glob.glob(os.path.join(args.input, '*.en.vtt')))
        if not vtt_files:
            print(f"No *.en.vtt files found in {args.input}", file=sys.stderr)
            sys.exit(1)
        for vtt_file in vtt_files:
            out_path, n = process_file(vtt_file)
            written.append({"input": vtt_file, "output": out_path, "lines": n})
    else:
        out_path, n = process_file(args.input, args.start, args.end, args.out)
        written.append({"input": args.input, "output": out_path, "lines": n})

    print(json.dumps(written))


if __name__ == '__main__':
    main()
