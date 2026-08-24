#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$repo_dir"

base_ref=${1:-main}
root_tex=thesis.tex
diff_tex="${root_tex%.tex}-diff${base_ref}.tex"

for dependency in latexdiff-vc perl latexmk; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$dependency" >&2
        exit 1
    fi
done

latexdiff-vc --git --flatten --force -r "$base_ref" "$root_tex"

# latexdiff can put change markup inside booktabs' \cmidrule syntax, which
# causes a runaway-argument error. Restore those arguments before compiling.
perl -0pi -e 's/\\cmidrule\\DIFadd\{(\([^{}]*\))\}\{\\DIFadd\{([^{}]*)\}\}/\\cmidrule$1\{$2\}/g' "$diff_tex"

# Remove stale auxiliary files left by an interrupted or failed build.
latexmk -c "$diff_tex"
latexmk -pdf -interaction=nonstopmode -halt-on-error "$diff_tex"

printf 'Built %s\n' "${diff_tex%.tex}.pdf"
