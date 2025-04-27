"""
parse_texcount.py

Parse a TeXcount output and store per-file and overall summary statistics
into an SQLite database for progress tracking.
"""

import re
import sqlite3
import argparse
from datetime import datetime, timezone

# -----------------------------------------------------------------------------
# SCHEMA:
#
#   runs
#     id            INTEGER PRIMARY KEY
#     run_timestamp TEXT
#
#   file_stats
#     id               INTEGER PRIMARY KEY
#     run_id           INTEGER    REFERENCES runs(id)
#     filename         TEXT
#     encoding         TEXT
#     words_text       INTEGER
#     words_headers    INTEGER
#     words_outside    INTEGER
#     num_headers      INTEGER
#     num_floats       INTEGER
#     math_inlines     INTEGER
#     math_displayed   INTEGER
#     is_summary       INTEGER    -- 1 if this row is the overall summary
#
# Usage:
#   python parse_texcount.py --input mycount.txt --db texcount.db
# -----------------------------------------------------------------------------

FILE_BLOCK_RE = re.compile(
    r'^(File:|Included file:)\s*(?P<filename>.+?)\n'
    r'Encoding:\s*(?P<encoding>\S+)\n'
    r'Words in text:\s*(?P<words_text>\d+)\n'
    r'Words in headers:\s*(?P<words_headers>\d+)\n'
    r'Words outside text \(captions, etc.\):\s*(?P<words_outside>\d+)\n'
    r'Number of headers:\s*(?P<num_headers>\d+)\n'
    r'Number of floats/tables/figures:\s*(?P<num_floats>\d+)\n'
    r'Number of math inlines:\s*(?P<math_inlines>\d+)\n'
    r'Number of math displayed:\s*(?P<math_displayed>\d+)',
    re.MULTILINE
)

SUMMARY_RE = re.compile(
    r'Words in text:\s*(?P<words_text>\d+)\n'
    r'Words in headers:\s*(?P<words_headers>\d+)\n'
    r'Words outside text \(captions, etc.\):\s*(?P<words_outside>\d+)\n'
    r'Number of headers:\s*(?P<num_headers>\d+)\n'
    r'Number of floats/tables/figures:\s*(?P<num_floats>\d+)\n'
    r'Number of math inlines:\s*(?P<math_inlines>\d+)\n'
    r'Number of math displayed:\s*(?P<math_displayed>\d+)\n'
    r'Files:\s*(?P<files>\d+)',
    re.MULTILINE
)

def init_db(conn):
    c = conn.cursor()
    c.execute("""
      CREATE TABLE IF NOT EXISTS runs (
        id            INTEGER PRIMARY KEY,
        run_timestamp TEXT NOT NULL
      )
    """)
    c.execute("""
      CREATE TABLE IF NOT EXISTS file_stats (
        id               INTEGER PRIMARY KEY,
        run_id           INTEGER NOT NULL REFERENCES runs(id),
        filename         TEXT NOT NULL,
        encoding         TEXT,
        words_text       INTEGER,
        words_headers    INTEGER,
        words_outside    INTEGER,
        num_headers      INTEGER,
        num_floats       INTEGER,
        math_inlines     INTEGER,
        math_displayed   INTEGER,
        is_summary       INTEGER NOT NULL DEFAULT 0
      )
    """)
    conn.commit()

def parse_texcount(text):
    files = []
    for m in FILE_BLOCK_RE.finditer(text):
        files.append({
            'filename':        m.group('filename'),
            'encoding':        m.group('encoding'),
            'words_text':      int(m.group('words_text')),
            'words_headers':   int(m.group('words_headers')),
            'words_outside':   int(m.group('words_outside')),
            'num_headers':     int(m.group('num_headers')),
            'num_floats':      int(m.group('num_floats')),
            'math_inlines':    int(m.group('math_inlines')),
            'math_displayed':  int(m.group('math_displayed')),
            'is_summary':      0,
        })
    # overall summary (last)
    sm = SUMMARY_RE.search(text)
    if sm:
        files.append({
            'filename':        'SUMMARY',
            'encoding':        None,
            'words_text':      int(sm.group('words_text')),
            'words_headers':   int(sm.group('words_headers')),
            'words_outside':   int(sm.group('words_outside')),
            'num_headers':     int(sm.group('num_headers')),
            'num_floats':      int(sm.group('num_floats')),
            'math_inlines':    int(sm.group('math_inlines')),
            'math_displayed':  int(sm.group('math_displayed')),
            'is_summary':      1,
        })
    return files

def insert_run_and_stats(conn, files_metrics):
    c = conn.cursor()
    timestamp = datetime.now(timezone.utc).isoformat()
    c.execute("INSERT INTO runs (run_timestamp) VALUES (?)", (timestamp,))
    run_id = c.lastrowid
    for f in files_metrics:
        c.execute("""
          INSERT INTO file_stats
            (run_id, filename, encoding, words_text, words_headers,
             words_outside, num_headers, num_floats,
             math_inlines, math_displayed, is_summary)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
          run_id,
          f['filename'],
          f['encoding'],
          f['words_text'],
          f['words_headers'],
          f['words_outside'],
          f['num_headers'],
          f['num_floats'],
          f['math_inlines'],
          f['math_displayed'],
          f['is_summary']
        ))
    conn.commit()

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--input', '-i', required=True,
                   help="path to the texcount output text file")
    p.add_argument('--db', '-d', default='texcount_progress.db',
                   help="SQLite database file (will be created if missing)")
    args = p.parse_args()

    with open(args.input, 'r', encoding='utf-8') as infile:
        text = infile.read()

    files_metrics = parse_texcount(text)
    if not files_metrics:
        print("No file blocks found in input – is this a valid TeXcount output?")
        return

    conn = sqlite3.connect(args.db)
    init_db(conn)
    insert_run_and_stats(conn, files_metrics)
    print(f"Imported {len(files_metrics)} items (including summary) into {args.db}")

if __name__ == '__main__':
    main()