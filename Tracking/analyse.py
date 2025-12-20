"""
parse_texcount.py

Parse a TeXcount output and store per-file and overall summary statistics
into a PostgreSQL database for progress tracking.
"""

import argparse
import os
import re
import subprocess
from datetime import datetime, timezone

import psycopg2

# -----------------------------------------------------------------------------
# SCHEMA (PostgreSQL):
#
#   runs
#     id            SERIAL PRIMARY KEY
#     run_timestamp TIMESTAMPTZ
#
#   file_stats
#     id               SERIAL PRIMARY KEY
#     run_id           INTEGER REFERENCES runs(id)
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
#   python parse_texcount.py --input mycount.txt [--dsn postgresql://...]
#   # or rely on PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
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


def get_connection(dsn=None):
    if dsn:
        return psycopg2.connect(dsn)

    # Secrets are sourced from environment; fail fast if anything is missing.
    env = {
        'host': os.getenv('PGHOST'),
        'port': os.getenv('PGPORT', '5432'),
        'dbname': os.getenv('PGDATABASE'),
        'user': os.getenv('PGUSER'),
        'password': os.getenv('PGPASSWORD'),
    }
    missing = [k for k, v in env.items() if not v and k != 'port']
    if missing:
        raise RuntimeError(f"Missing PostgreSQL environment variables: {', '.join(missing)}")

    return psycopg2.connect(**env)


def run_texcount(tex_root, texcount_path, extra_args=None, workdir=None):
    """Execute texcount and return its stdout."""
    extra_args = extra_args or []
    cmd = ["perl", texcount_path, "-dir", "-inc", tex_root, *extra_args]
    try:
        completed = subprocess.run(
            cmd,
            cwd=workdir,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(
            f"texcount failed with exit code {exc.returncode}: {exc.stderr}"
        ) from exc
    return completed.stdout

def init_db(conn):
        # Ensure tables exist; keep the schema aligned with the original SQLite layout.
        with conn, conn.cursor() as c:
                c.execute(
                        """
                        CREATE TABLE IF NOT EXISTS runs (
                            id            SERIAL PRIMARY KEY,
                            run_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
                        )
                        """
                )
                c.execute(
                        """
                        CREATE TABLE IF NOT EXISTS file_stats (
                            id               SERIAL PRIMARY KEY,
                            run_id           INTEGER NOT NULL REFERENCES runs(id) ON DELETE CASCADE,
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
                        """
                )

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
    # Single transaction to keep runs/file_stats consistent.
    with conn:
        with conn.cursor() as c:
            timestamp = datetime.now(timezone.utc)
            c.execute(
                "INSERT INTO runs (run_timestamp) VALUES (%s) RETURNING id",
                (timestamp,),
            )
            run_id = c.fetchone()[0]
            for f in files_metrics:
                c.execute(
                    """
                    INSERT INTO file_stats
                      (run_id, filename, encoding, words_text, words_headers,
                       words_outside, num_headers, num_floats,
                       math_inlines, math_displayed, is_summary)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
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
                        f['is_summary'],
                    ),
                )

def main():
    p = argparse.ArgumentParser()
    source = p.add_mutually_exclusive_group(required=True)
    source.add_argument('--input', '-i', dest='input_file',
                        help="path to a precomputed texcount output text file")
    source.add_argument('--tex-root', dest='tex_root',
                        help="root LaTeX file to pass to texcount (runs texcount internally)")
    p.add_argument('--texcount-path', default='Tracking/texcount.pl',
                   help="path to the texcount.pl script")
    p.add_argument('--texcount-extra-args', nargs='*', default=[],
                   help="additional arguments forwarded to texcount")
    p.add_argument('--dsn', default=None,
                   help="optional PostgreSQL DSN; if omitted, PG* env vars are used")
    # Backward-compatible alias for callers that still pass --db
    p.add_argument('--db', dest='dsn', help=argparse.SUPPRESS)
    args = p.parse_args()

    if args.tex_root:
        text = run_texcount(
            tex_root=args.tex_root,
            texcount_path=args.texcount_path,
            extra_args=args.texcount_extra_args,
            workdir=os.getcwd(),
        )
    else:
        with open(args.input_file, 'r', encoding='utf-8') as infile:
            text = infile.read()

    files_metrics = parse_texcount(text)
    if not files_metrics:
        print("No file blocks found in input – is this a valid TeXcount output?")
        return

    conn = get_connection(args.dsn)
    init_db(conn)
    insert_run_and_stats(conn, files_metrics)
    print(f"Imported {len(files_metrics)} items (including summary) into PostgreSQL")

if __name__ == '__main__':
    main()