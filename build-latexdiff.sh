#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$repo_dir"

usage() {
    cat <<USAGE
Usage: ${0##*/} [options] [base-ref]

Builds:
  1. a full latexdiff of the thesis; and
  2. an editable, rendered LaTeX summary containing only changed semantic blocks.

Options:
  --keep-aux              Keep latexmk auxiliary files.
  --keep-intermediate     Keep the raw patch and temporary old/new summary files.
  --summary-only          Build only the rendered change summary.
  --full-only             Build only the full latexdiff thesis.
  --context-blocks N      Include N neighbouring LaTeX blocks around each change.
                          Default: 0. Pure additions always include one block
                          on either side.
  --include PATHSPEC      Git pathspec to include. Repeatable. Supplying this option
                          replaces the default '*.tex' include pathspec.
  --exclude PATHSPEC      Git pathspec to exclude. Repeatable. Default: diff/**.
  --font-size LATEX       Body font-size command used in the summary.
                          Default: \\small.
  --root FILE             Root thesis file. Default: thesis.tex.
  -h, --help              Show this help.

Examples:
  ${0##*/} main
  ${0##*/} --summary-only --context-blocks 1 main
  ${0##*/} --include 'chapters/Fatigue/**' --exclude 'chapters/Fatigue/old/**' main
  ${0##*/} --font-size '\\normalsize' main
USAGE
}

base_ref=main
base_ref_set=false
keep_aux=false
keep_intermediate=false
build_full=true
build_summary=true
context_blocks=0
root_tex=thesis.tex
summary_font_size='\small'
include_paths=('*.tex')
exclude_paths=('diff/**')
custom_include=false

while (($#)); do
    case $1 in
        --keep-aux)
            keep_aux=true
            shift
            ;;
        --keep-intermediate)
            keep_intermediate=true
            shift
            ;;
        --summary-only)
            build_full=false
            shift
            ;;
        --full-only)
            build_summary=false
            shift
            ;;
        --context-blocks)
            [[ $# -ge 2 ]] || { printf 'Missing value for --context-blocks\n' >&2; exit 2; }
            context_blocks=$2
            shift 2
            ;;
        --include)
            [[ $# -ge 2 ]] || { printf 'Missing value for --include\n' >&2; exit 2; }
            if [[ $custom_include == false ]]; then
                include_paths=()
                custom_include=true
            fi
            include_paths+=("$2")
            shift 2
            ;;
        --exclude)
            [[ $# -ge 2 ]] || { printf 'Missing value for --exclude\n' >&2; exit 2; }
            exclude_paths+=("$2")
            shift 2
            ;;
        --font-size)
            [[ $# -ge 2 ]] || { printf 'Missing value for --font-size\n' >&2; exit 2; }
            summary_font_size=$2
            shift 2
            ;;
        --root)
            [[ $# -ge 2 ]] || { printf 'Missing value for --root\n' >&2; exit 2; }
            root_tex=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            while (($#)); do
                if [[ $base_ref_set == true ]]; then
                    printf 'Only one base ref may be specified\n' >&2
                    exit 2
                fi
                base_ref=$1
                base_ref_set=true
                shift
            done
            ;;
        -*)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ $base_ref_set == true ]]; then
                printf 'Only one base ref may be specified\n' >&2
                usage >&2
                exit 2
            fi
            base_ref=$1
            base_ref_set=true
            shift
            ;;
    esac
done

if [[ $build_full == false && $build_summary == false ]]; then
    printf 'Cannot combine --summary-only and --full-only\n' >&2
    exit 2
fi

if ! [[ $context_blocks =~ ^[0-9]+$ ]]; then
    printf '--context-blocks must be a non-negative integer\n' >&2
    exit 2
fi

if [[ ! -f $root_tex ]]; then
    printf 'Root LaTeX file not found: %s\n' "$root_tex" >&2
    exit 1
fi

output_dir=diff
root_base=${root_tex##*/}
root_stem=${root_base%.tex}
generated_tex="${root_tex%.tex}-diff${base_ref}.tex"
full_diff_tex="$output_dir/${root_stem}-diff${base_ref//\//-}.tex"
summary_name="${root_stem}-change-summary"
summary_patch="$output_dir/.${summary_name}.patch"
summary_old="$output_dir/.${summary_name}-old.tex"
summary_new="$output_dir/.${summary_name}-new.tex"
summary_tex="$output_dir/$summary_name.tex"
summary_pdf="$output_dir/$summary_name.pdf"

required=(git flock perl latexmk)
if [[ $build_full == true ]]; then
    required+=(latexdiff-vc)
fi
if [[ $build_summary == true ]]; then
    required+=(latexdiff python3)
fi

for dependency in "${required[@]}"; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$dependency" >&2
        exit 1
    fi
done

if ! git rev-parse --verify "${base_ref}^{commit}" >/dev/null 2>&1; then
    printf 'Git base ref does not resolve to a commit: %s\n' "$base_ref" >&2
    exit 1
fi

# Concurrent builds share auxiliary filenames and can corrupt one another.
exec 9<"$repo_dir/${BASH_SOURCE[0]##*/}"
if ! flock -n 9; then
    printf 'Another LaTeX diff build is already using %s\n' "$output_dir" >&2
    exit 1
fi

mkdir -p "$output_dir"

# latexdiff decodes UTF-8 correctly, but its large-input comparison path writes
# Unicode strings to raw temporary handles and emits a warning for each one.
# Suppress only that Perl warning category; the generated bytes are unchanged.
latexdiff_perl5opt=${PERL5OPT-}
latexdiff_perl5opt="${latexdiff_perl5opt:+$latexdiff_perl5opt }-M-warnings=utf8"

# latexdiff can put change markup inside booktabs' \cmidrule syntax, which
# causes a runaway-argument error. Restore those arguments before compiling.
repair_cmidrules() {
    perl -0pi -e 's/\\cmidrule\\DIFadd\{(\([^{}]*\))\}\{\\DIFadd\{([^{}]*)\}\}/\\cmidrule$1\{$2\}/g' "$1"
}

clean_aux() {
    local source_tex=$1
    local source_base=${source_tex%.tex}

    latexmk -c -outdir="$output_dir" "$source_tex" >/dev/null || true
    rm -f -- "$source_base.bbl" "$source_base.bbl-SAVE-ERROR" \
        "$source_base.bcf-SAVE-ERROR"
}

build_pdf() {
    local source_tex=$1

    clean_aux "$source_tex"
    latexmk -pdf -interaction=nonstopmode -halt-on-error \
        -outdir="$output_dir" "$source_tex"
}

if [[ $build_full == true ]]; then
    PERL5OPT="$latexdiff_perl5opt" \
        latexdiff-vc --git --flatten --force -r "$base_ref" "$root_tex"

    # latexdiff-vc chooses the generated filename. Move it into diff/ and use a
    # slash-safe filename for refs such as origin/main.
    if [[ ! -f $generated_tex ]]; then
        printf 'Expected latexdiff-vc output not found: %s\n' "$generated_tex" >&2
        exit 1
    fi
    mv -f -- "$generated_tex" "$full_diff_tex"
    repair_cmidrules "$full_diff_tex"
    build_pdf "$full_diff_tex"
fi

if [[ $build_summary == true ]]; then
    git_pathspecs=("${include_paths[@]}")
    for excluded in "${exclude_paths[@]}"; do
        git_pathspecs+=(":(exclude)$excluded")
    done

    # The patch is used only as a map of changed locations. It is never typeset.
    git diff --no-ext-diff --no-color --unified=0 --find-renames \
        "$base_ref" -- "${git_pathspecs[@]}" > "$summary_patch"

    if [[ ! -s $summary_patch ]]; then
        printf 'No included LaTeX source changes found relative to %s\n' "$base_ref" >&2
        exit 1
    fi

    # Build two small, structurally identical LaTeX documents containing the
    # old and new versions of each changed semantic block. A semantic block is
    # normally a paragraph; if it intersects a LaTeX environment or display
    # maths block, the extraction expands until that construct is balanced.
    # latexdiff is then run on these two summary documents, so the final report
    # contains real, rendered LaTeX rather than verbatim source code.
    python3 - "$repo_dir" "$base_ref" "$root_tex" "$summary_patch" \
        "$summary_old" "$summary_new" "$context_blocks" "$summary_font_size" <<'PY'
from __future__ import annotations

import re
import shlex
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

repo = Path(sys.argv[1])
base_ref = sys.argv[2]
root_tex = sys.argv[3]
patch_path = Path(sys.argv[4])
old_out = Path(sys.argv[5])
new_out = Path(sys.argv[6])
context_blocks = int(sys.argv[7])
font_size = sys.argv[8]


@dataclass
class Hunk:
    old_path: str | None
    new_path: str | None
    old_start: int
    old_count: int
    new_start: int
    new_count: int


@dataclass
class Record:
    old_path: str | None
    new_path: str | None
    old_span: tuple[int, int] | None
    new_span: tuple[int, int] | None


def path_from_marker(value: str) -> str | None:
    value = value.strip()
    if value == "/dev/null":
        return None
    try:
        parts = shlex.split(value)
        value = parts[0] if parts else value
    except ValueError:
        pass
    if value.startswith("a/") or value.startswith("b/"):
        value = value[2:]
    return value


def parse_patch(text: str) -> list[Hunk]:
    hunks: list[Hunk] = []
    old_path: str | None = None
    new_path: str | None = None
    hunk_re = re.compile(
        r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@"
    )

    for line in text.splitlines():
        if line.startswith("diff --git "):
            try:
                fields = shlex.split(line)
                old_path = path_from_marker(fields[2])
                new_path = path_from_marker(fields[3])
            except (ValueError, IndexError):
                old_path = new_path = None
        elif line.startswith("--- "):
            old_path = path_from_marker(line[4:])
        elif line.startswith("+++ "):
            new_path = path_from_marker(line[4:])
        else:
            match = hunk_re.match(line)
            if match:
                old_start = int(match.group(1))
                old_count = int(match.group(2) or "1")
                new_start = int(match.group(3))
                new_count = int(match.group(4) or "1")
                hunks.append(
                    Hunk(
                        old_path,
                        new_path,
                        old_start,
                        old_count,
                        new_start,
                        new_count,
                    )
                )
    return hunks


old_cache: dict[str, list[str]] = {}
new_cache: dict[str, list[str]] = {}


def git_show(path: str | None) -> list[str]:
    if path is None:
        return []
    if path in old_cache:
        return old_cache[path]
    result = subprocess.run(
        ["git", "show", f"{base_ref}:{path}"],
        cwd=repo,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        lines: list[str] = []
    else:
        lines = result.stdout.splitlines(keepends=True)
    old_cache[path] = lines
    return lines


def working_copy(path: str | None) -> list[str]:
    if path is None:
        return []
    if path in new_cache:
        return new_cache[path]
    source = repo / path
    if source.is_file():
        lines = source.read_text(encoding="utf-8", errors="replace").splitlines(
            keepends=True
        )
    else:
        lines = []
    new_cache[path] = lines
    return lines


def strip_comment(line: str) -> str:
    """Remove an unescaped LaTeX comment for lightweight structural parsing."""
    index = 0
    while True:
        index = line.find("%", index)
        if index < 0:
            return line
        backslashes = 0
        j = index - 1
        while j >= 0 and line[j] == "\\":
            backslashes += 1
            j -= 1
        if backslashes % 2 == 0:
            return line[:index]
        index += 1


def body_bounds(lines: list[str]) -> tuple[int, int]:
    r"""Exclude a standalone document's preamble and \end{document}."""
    begin = None
    end = None
    for i, raw in enumerate(lines):
        line = strip_comment(raw)
        if begin is None and re.search(r"\\begin\s*\{document\}", line):
            begin = i + 1
            continue
        if begin is not None and re.search(r"\\end\s*\{document\}", line):
            end = i
            break
    if begin is None:
        return 0, len(lines)
    return begin, end if end is not None else len(lines)


def paragraph_blocks(lines: list[str], lo: int, hi: int) -> list[tuple[int, int]]:
    blocks: list[tuple[int, int]] = []
    i = lo
    while i < hi:
        # Comment-only lines are visual separators in many of the thesis
        # sources.  Treat them like blank lines so an edit to a nearby command
        # does not pull an entire run of \include statements into the summary.
        while i < hi and not strip_comment(lines[i]).strip():
            i += 1
        if i >= hi:
            break
        start = i
        while i < hi and strip_comment(lines[i]).strip():
            i += 1
        blocks.append((start, i))
    return blocks


def environment_pairs(lines: list[str], lo: int, hi: int) -> list[tuple[int, int]]:
    r"""Find balanced \begin/\end environments and \[ ... \] display maths."""
    token_re = re.compile(r"\\(begin|end)\s*\{([^{}]+)\}")
    stack: list[tuple[str, int]] = []
    pairs: list[tuple[int, int]] = []
    display_stack: list[int] = []

    for i in range(lo, hi):
        text = strip_comment(lines[i])

        # Display maths delimiters. Inline \(...\) does not need expansion.
        positions: list[tuple[int, str]] = []
        positions.extend((m.start(), "open") for m in re.finditer(r"(?<!\\)\\\[", text))
        positions.extend((m.start(), "close") for m in re.finditer(r"(?<!\\)\\\]", text))
        for _, kind in sorted(positions):
            if kind == "open":
                display_stack.append(i)
            elif display_stack:
                start = display_stack.pop()
                pairs.append((start, i + 1))

        for match in token_re.finditer(text):
            kind, env = match.group(1), match.group(2)
            if env == "document":
                continue
            if kind == "begin":
                stack.append((env, i))
            else:
                # Match the nearest open environment of the same name. This is
                # deliberately forgiving of unusual source formatting.
                for j in range(len(stack) - 1, -1, -1):
                    if stack[j][0] == env:
                        _, start = stack.pop(j)
                        pairs.append((start, i + 1))
                        break
    return pairs


def semantic_span(
    lines: list[str], start_1based: int, count: int, context: int
) -> tuple[int, int] | None:
    if not lines:
        return None

    body_lo, body_hi = body_bounds(lines)
    start = max(start_1based - 1, body_lo)
    end = min(start_1based - 1 + count, body_hi)
    if start > body_hi or end < body_lo:
        return None

    blocks = paragraph_blocks(lines, body_lo, body_hi)
    if not blocks:
        return None

    # A pure insertion has no old-side changed lines. With context enabled,
    # select the blocks immediately before and after the insertion point so
    # latexdiff can show unchanged prose around the added material. The new
    # side selects the inserted block plus the same number of neighbours.
    if count <= 0:
        if context <= 0:
            return None
        before = [i for i, (_, block_end) in enumerate(blocks) if block_end <= start]
        after = [i for i, (block_start, _) in enumerate(blocks) if block_start >= start]
        selected = before[-context:] + after[:context]
        if not selected:
            return None
        span_start = blocks[min(selected)][0]
        span_end = blocks[max(selected)][1]
    else:
        if start >= body_hi or end <= body_lo or start >= end:
            return None

        hits = [
            i
            for i, (block_start, block_end) in enumerate(blocks)
            if block_end > start and block_start < end
        ]

        if hits:
            first = max(min(hits) - context, 0)
            last = min(max(hits) + context, len(blocks) - 1)
        else:
            # A hunk containing only blank-line changes sits between semantic
            # blocks. Include the blocks on each side so the paragraph
            # merge/split is visible and remains valid LaTeX.
            before = [i for i, (_, block_end) in enumerate(blocks) if block_end <= start]
            after = [i for i, (block_start, _) in enumerate(blocks) if block_start >= end]
            candidates = []
            if before:
                candidates.append(before[-1])
            if after:
                candidates.append(after[0])
            if not candidates:
                return None
            first = max(min(candidates) - context, 0)
            last = min(max(candidates) + context, len(blocks) - 1)

        span_start = blocks[first][0]
        span_end = blocks[last][1]

    # Expanding to balanced environments is what makes the extracted source
    # independently typesettable. A changed item therefore brings its list
    # environment with it; a changed equation brings the full equation, etc.
    pairs = environment_pairs(lines, body_lo, body_hi)
    changed = True
    while changed:
        changed = False
        for pair_start, pair_end in pairs:
            if pair_end > span_start and pair_start < span_end:
                new_start = min(span_start, pair_start)
                new_end = max(span_end, pair_end)
                if new_start != span_start or new_end != span_end:
                    span_start, span_end = new_start, new_end
                    changed = True

    return span_start, span_end


def spans_touch(a: tuple[int, int] | None, b: tuple[int, int] | None) -> bool:
    if a is None or b is None:
        return False
    return a[0] <= b[1] and b[0] <= a[1]


def union_span(
    a: tuple[int, int] | None, b: tuple[int, int] | None
) -> tuple[int, int] | None:
    if a is None:
        return b
    if b is None:
        return a
    return min(a[0], b[0]), max(a[1], b[1])


def same_file(a: Record, b: Record) -> bool:
    return a.old_path == b.old_path and a.new_path == b.new_path


def merge_records(records: list[Record]) -> list[Record]:
    merged: list[Record] = []
    for record in records:
        if not merged or not same_file(merged[-1], record):
            merged.append(record)
            continue
        previous = merged[-1]
        if spans_touch(previous.old_span, record.old_span) or spans_touch(
            previous.new_span, record.new_span
        ):
            previous.old_span = union_span(previous.old_span, record.old_span)
            previous.new_span = union_span(previous.new_span, record.new_span)
        else:
            merged.append(record)
    return merged


structure_re = re.compile(
    r"^\s*\\(chapter|section|subsection|subsubsection)\*?"
    r"(?:\[[^\]]*\])?\{(.+?)\}"
    r"(?:\s*\\label\s*\{[^{}]*\})?\s*$"
)

# Chapter files sometimes define notation locally (for example, \def\gammaMax)
# instead of placing it in the root preamble.  A changed paragraph copied into
# the summary still needs every definition that was in scope before it.
definition_start_re = re.compile(
    r"^\s*\\(?:def|gdef|edef|xdef)\s*\\"
    r"|^\s*\\(?:newcommand|renewcommand|providecommand|DeclareRobustCommand|"
    r"DeclareMathOperator|newenvironment|renewenvironment)\*?\b"
)


def brace_delta(text: str) -> tuple[int, bool]:
    """Return the unescaped brace balance and whether an opening brace occurs."""
    balance = 0
    saw_open = False
    for i, char in enumerate(text):
        if char not in "{}":
            continue
        backslashes = 0
        j = i - 1
        while j >= 0 and text[j] == "\\":
            backslashes += 1
            j -= 1
        if backslashes % 2:
            continue
        if char == "{":
            balance += 1
            saw_open = True
        else:
            balance -= 1
    return balance, saw_open


def definitions_before(lines: list[str], index: int) -> str:
    """Extract macro/environment declarations visible before a changed block."""
    definitions: list[str] = []
    i = 0
    limit = min(max(index, 0), len(lines))
    while i < limit:
        clean = strip_comment(lines[i])
        if not definition_start_re.match(clean):
            i += 1
            continue

        declaration = [lines[i]]
        balance, saw_open = brace_delta(clean)
        i += 1
        while i < limit and (not saw_open or balance > 0):
            declaration.append(lines[i])
            delta, opened = brace_delta(strip_comment(lines[i]))
            balance += delta
            saw_open = saw_open or opened
            i += 1
        definitions.extend(declaration)

    return "".join(definitions)


def structure_at(lines: list[str], index: int) -> dict[str, str]:
    structure: dict[str, str] = {}
    hierarchy = ["chapter", "section", "subsection", "subsubsection"]
    for raw in lines[: max(index + 1, 0)]:
        match = structure_re.match(strip_comment(raw).strip())
        if not match:
            continue
        level, title = match.group(1), match.group(2)
        structure[level] = title
        level_index = hierarchy.index(level)
        for deeper in hierarchy[level_index + 1 :]:
            structure.pop(deeper, None)
    return structure


def deepest_location(structure: dict[str, str]) -> str:
    for level in ("subsubsection", "subsection", "section", "chapter"):
        if level in structure:
            return structure[level]
    return "Document-level change"


def chapter_title(structure: dict[str, str], fallback: str) -> str:
    return structure.get("chapter", fallback)


def file_fallback(path: str) -> str:
    stem = Path(path).stem.replace("_", " ").replace("-", " ")
    return stem[:1].upper() + stem[1:] if stem else path


def get_content(lines: list[str], span: tuple[int, int] | None) -> str:
    if span is None:
        return ""
    text = "".join(lines[span[0] : span[1]])
    text = text.strip("\n")

    # Do not execute a whole source file merely because an extracted block
    # contains a standalone \input or \include.  The referenced file has its
    # own summary record when it changed; here, render the command as metadata.
    source_command_re = re.compile(
        r"^\s*\\(input|include)\s*\{([^{}]+)\}\s*(?:%.*)?$", re.MULTILINE
    )

    def render_source_command(match: re.Match[str]) -> str:
        command, path = match.group(1), detokenize_arg(match.group(2))
        return rf"\DiffReportSourceCommand{{{command}}}{{{path}}}"

    text = source_command_re.sub(render_source_command, text)

    # A summary block is already the placement context for its figure. Normal
    # float specifiers can move it several pages away or even above the report
    # title, so make every extracted figure non-floating in this document.
    figure_begin_re = re.compile(
        r"\\begin\s*\{figure\}(?:\s*\[[^\]]*\])?"
    )
    return figure_begin_re.sub(r"\\begin{figure}[H]", text)


def detokenize_arg(text: str) -> str:
    # Paths/base refs are placed inside \detokenize. Braces are exceptionally
    # uncommon in Git paths; make them harmless rather than trying to preserve
    # them literally in a macro argument.
    return text.replace("{", "(").replace("}", ")")


patch = patch_path.read_text(encoding="utf-8", errors="replace")
hunks = parse_patch(patch)
if not hunks:
    raise SystemExit("Patch contains no textual hunks to render")

records: list[Record] = []
for hunk in hunks:
    old_lines = git_show(hunk.old_path)
    new_lines = working_copy(hunk.new_path)
    # Insertions are hard to interpret in isolation. Give them one unchanged
    # semantic block on either side even when general context is disabled.
    hunk_context = context_blocks
    if hunk.old_count == 0 and hunk.new_count > 0:
        hunk_context = max(hunk_context, 1)
    old_span = semantic_span(old_lines, hunk.old_start, hunk.old_count, hunk_context)
    new_span = semantic_span(new_lines, hunk.new_start, hunk.new_count, hunk_context)

    # Changes confined to the preamble of a standalone .tex file are skipped.
    # Preamble commands cannot be inserted into the body of a rendered report.
    if old_span is None and new_span is None:
        continue

    records.append(Record(hunk.old_path, hunk.new_path, old_span, new_span))

records = merge_records(records)


def renderable_signature(content: str) -> str:
    """Normalise content that TeX renders identically for summary purposes."""
    uncommented = "\n".join(strip_comment(line) for line in content.splitlines())
    return " ".join(uncommented.split())


def record_has_visible_change(record: Record) -> bool:
    old_content = get_content(git_show(record.old_path), record.old_span)
    new_content = get_content(working_copy(record.new_path), record.new_span)
    return renderable_signature(old_content) != renderable_signature(new_content)


record_count_before_filter = len(records)
records = [record for record in records if record_has_visible_change(record)]
removed_record_count = record_count_before_filter - len(records)
if removed_record_count:
    print(
        f"Removed {removed_record_count} whitespace/comment-only change block(s)"
    )

if not records:
    raise SystemExit(
        "The included changes are preamble-only or otherwise have no renderable body blocks"
    )

root_source = (repo / root_tex).read_text(encoding="utf-8", errors="replace")
root_lines = root_source.splitlines(keepends=True)
preamble_end = None
for i, raw in enumerate(root_lines):
    if re.search(r"\\begin\s*\{document\}", strip_comment(raw)):
        preamble_end = i
        break
if preamble_end is None:
    raise SystemExit(f"Could not find \\begin{{document}} in {root_tex}")

preamble = "".join(root_lines[:preamble_end]).rstrip() + "\n"

report_preamble = rf"""

% ---------------------------------------------------------------------------
% Rendered change-summary controls. Edit these in the generated .tex file if
% you want to change the report appearance without changing the extractor.
% ---------------------------------------------------------------------------
\usepackage{{geometry}}
\usepackage{{float}}
% duthesis sets both offsets to -1in for its own hand-built page layout.
% geometry calculates margins independently of those offsets, so reset them
% before applying the report layout or the page is shifted off its left edge.
\setlength{{\hoffset}}{{0pt}}
\setlength{{\voffset}}{{0pt}}
\geometry{{a4paper,left=20mm,right=20mm,top=20mm,bottom=22mm}}
\setlength{{\emergencystretch}}{{3em}}
\raggedbottom

\newcommand{{\DiffReportBodyFont}}{{{font_size}}}
\newcommand{{\DiffReportTitleFont}}{{\huge\bfseries}}
\newcommand{{\DiffReportFileFont}}{{\Large\bfseries}}
\newcommand{{\DiffReportLocationFont}}{{\large\bfseries}}
\newcommand{{\DiffReportMetaFont}}{{\small\ttfamily}}

\newcommand{{\DiffReportMakeTitle}}{{%
  \begin{{center}}
    {{\DiffReportTitleFont Thesis change summary\par}}
    \vspace{{0.5em}}
    {{\DiffReportMetaFont Relative to \detokenize{{{detokenize_arg(base_ref)}}}\par}}
  \end{{center}}
  \vspace{{1em}}
}}

\newcommand{{\DiffReportFile}}[2]{{%
  \par\bigskip
  {{\DiffReportFileFont #1\par}}
  {{\DiffReportMetaFont \detokenize{{#2}}\par}}
  \smallskip\hrule\medskip
}}

\newcommand{{\DiffReportLocation}}[1]{{%
  \par\medskip
  {{\DiffReportLocationFont #1\par}}
}}

\newcommand{{\DiffReportChange}}[1]{{%
  \par\smallskip
  {{\DiffReportMetaFont Change #1\par}}
  \smallskip
}}

\newcommand{{\DiffReportSourceCommand}}[2]{{%
  \par{{\DiffReportMetaFont \textbackslash#1\{{\detokenize{{#2}}\}}\par}}
}}

\newenvironment{{DiffReportContent}}
  {{\begingroup\DiffReportBodyFont}}
  {{\par\endgroup\medskip}}
% ---------------------------------------------------------------------------
"""


def record_metadata(record: Record) -> tuple[str, str, str]:
    path = record.new_path or record.old_path or "unknown.tex"
    if record.new_span is not None and record.new_path is not None:
        lines = working_copy(record.new_path)
        index = record.new_span[0]
    elif record.old_span is not None and record.old_path is not None:
        lines = git_show(record.old_path)
        index = record.old_span[0]
    else:
        lines = []
        index = 0
    structure = structure_at(lines, index)
    return path, chapter_title(structure, file_fallback(path)), deepest_location(structure)


def record_definitions(record: Record) -> str:
    # Use the working-copy definitions for both sides of the comparison so
    # latexdiff treats this supporting context as unchanged.  For a deleted
    # file, fall back to the base revision.
    if record.new_span is not None and record.new_path is not None:
        return definitions_before(working_copy(record.new_path), record.new_span[0])
    if record.old_span is not None and record.old_path is not None:
        return definitions_before(git_show(record.old_path), record.old_span[0])
    return ""


def build_document(which: str) -> str:
    pieces = [preamble, report_preamble, "\n\\begin{document}\n", "\\DiffReportMakeTitle\n"]
    last_path: str | None = None

    for number, record in enumerate(records, start=1):
        path, file_title, location = record_metadata(record)
        if path != last_path:
            pieces.append(
                f"\n\\DiffReportFile{{{file_title}}}"
                f"{{{detokenize_arg(path)}}}\n"
            )
            definitions = record_definitions(record)
            if definitions:
                pieces.append("% Local source definitions needed by extracted blocks.\n")
                pieces.append(definitions)
                if not definitions.endswith("\n"):
                    pieces.append("\n")
            last_path = path

        pieces.append(f"\\DiffReportLocation{{{location}}}\n")
        pieces.append(f"\\DiffReportChange{{{number}}}\n")
        pieces.append("\\begin{DiffReportContent}\n")

        if which == "old":
            content = get_content(git_show(record.old_path), record.old_span)
        else:
            content = get_content(working_copy(record.new_path), record.new_span)

        if content:
            pieces.append(content)
            if not content.endswith("\n"):
                pieces.append("\n")
        pieces.append("\\end{DiffReportContent}\n")

    pieces.append("\n\\end{document}\n")
    return "".join(pieces)


old_out.write_text(build_document("old"), encoding="utf-8")
new_out.write_text(build_document("new"), encoding="utf-8")
print(f"Prepared {len(records)} rendered change block(s)")
PY

    # WHOLE keeps changed display/inline maths as complete mathematical units,
    # which is both more readable and substantially more robust than inserting
    # word-level DIF markup into complicated equations.
    PERL5OPT="$latexdiff_perl5opt" \
        latexdiff --math-markup=whole \
            "$summary_old" "$summary_new" > "$summary_tex"

    # latexdiff can align a deletion with similar text in the preceding block,
    # leaving behind an empty report heading. Remove those non-rendering blocks
    # and any duplicate location heading that becomes adjacent as a result.
    python3 - "$summary_tex" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8", errors="replace")

# Neutralise anchors only after latexdiff has aligned the old and new documents.
# An inert token is retained because removing a label-sized alignment token can
# expose malformed math markup from latexdiff; \relax creates no destination.
text, neutralised_labels = re.subn(
    r"\\label\s*\{[^{}]*\}", lambda _: r"\relax", text
)

empty_block_re = re.compile(
    r"\\DiffReportChange\{\d+\}\s*"
    r"\\begin\{DiffReportContent\}"
    r"(?:\s|%[^\n]*(?:\n|$))*"
    r"\\end\{DiffReportContent\}"
)
text, removed_empty = empty_block_re.subn("", text)

# Section titles in this thesis contain at most one nested brace level (for
# example, \texorpdfstring), which this pattern deliberately preserves.
location_re = re.compile(
    r"\\DiffReportLocation\{((?:[^{}]|\{[^{}]*\})*)\}"
)
dif_control_re = re.compile(
    r"\\DIF(?:add|del)(?:begin|end)(?:FL)?\s*"
)

pieces: list[str] = []
cursor = 0
previous_title: str | None = None
previous_end = 0
removed_locations = 0
for match in location_re.finditer(text):
    between = text[previous_end : match.start()]
    controls_only = not dif_control_re.sub("", between).strip()
    if previous_title == match.group(1) and controls_only:
        pieces.append(text[cursor : match.start()])
        cursor = match.end()
        removed_locations += 1
    else:
        previous_title = match.group(1)
    previous_end = match.end()

pieces.append(text[cursor:])
text = "".join(pieces)

# Renumber only executable headings (not copies inside latexdiff comments) so
# removing a blank block does not leave gaps in the visible report.
change_re = re.compile(r"\\DiffReportChange\{\d+\}")
change_number = 0
renumbered_lines: list[str] = []
for line in text.splitlines(keepends=True):
    comment_at = None
    for i, char in enumerate(line):
        if char != "%":
            continue
        backslashes = 0
        j = i - 1
        while j >= 0 and line[j] == "\\":
            backslashes += 1
            j -= 1
        if backslashes % 2 == 0:
            comment_at = i
            break

    code = line if comment_at is None else line[:comment_at]
    comment = "" if comment_at is None else line[comment_at:]

    def renumber_change(match: re.Match[str]) -> str:
        nonlocal_change_number[0] += 1
        return rf"\DiffReportChange{{{nonlocal_change_number[0]}}}"

    nonlocal_change_number = [change_number]
    code = change_re.sub(renumber_change, code)
    change_number = nonlocal_change_number[0]
    renumbered_lines.append(code + comment)

path.write_text("".join(renumbered_lines), encoding="utf-8")

if removed_empty:
    print(f"Removed {removed_empty} empty latexdiff change block(s)")
if removed_locations:
    print(f"Removed {removed_locations} duplicate empty location heading(s)")
if neutralised_labels:
    print(f"Neutralised {neutralised_labels} source label anchor(s)")
print(f"Numbered {change_number} visible change block(s)")
PY

    repair_cmidrules "$summary_tex"
    build_pdf "$summary_tex"
fi

if [[ $keep_aux == false ]]; then
    if [[ $build_full == true ]]; then
        clean_aux "$full_diff_tex"
    fi
    if [[ $build_summary == true ]]; then
        clean_aux "$summary_tex"
    fi
fi

if [[ $build_summary == true && $keep_intermediate == false ]]; then
    rm -f -- "$summary_patch" "$summary_old" "$summary_new"
fi

if [[ $build_full == true ]]; then
    printf 'Built %s\n' "${full_diff_tex%.tex}.pdf"
    printf 'Kept editable source %s\n' "$full_diff_tex"
fi
if [[ $build_summary == true ]]; then
    printf 'Built %s\n' "$summary_pdf"
    printf 'Kept editable source %s\n' "$summary_tex"
fi
if [[ $keep_aux == true ]]; then
    printf 'Kept auxiliary files in %s\n' "$output_dir"
fi
if [[ $keep_intermediate == true && $build_summary == true ]]; then
    printf 'Kept summary intermediates in %s\n' "$output_dir"
fi
