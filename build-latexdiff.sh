#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$repo_dir"

usage() {
    printf 'Usage: %s [--keep-aux] [base-ref]\n' "${0##*/}"
}

base_ref=main
base_ref_set=false
keep_aux=false

for argument in "$@"; do
    case $argument in
        --keep-aux)
            keep_aux=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            printf 'Unknown option: %s\n' "$argument" >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ $base_ref_set == true ]]; then
                printf 'Only one base ref may be specified\n' >&2
                usage >&2
                exit 2
            fi
            base_ref=$argument
            base_ref_set=true
            ;;
    esac
done

root_tex=thesis.tex
generated_tex="${root_tex%.tex}-diff${base_ref}.tex"
output_dir=diff
full_diff_tex="$output_dir/$generated_tex"

for dependency in latexdiff-vc perl latexmk flock git; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$dependency" >&2
        exit 1
    fi
done

# Concurrent builds share auxiliary filenames and can corrupt one another.
exec 9<"$repo_dir/${BASH_SOURCE[0]##*/}"
if ! flock -n 9; then
    printf 'Another LaTeX diff build is already using %s\n' "$output_dir" >&2
    exit 1
fi

mkdir -p "$output_dir"

# latexdiff can put change markup inside booktabs' \cmidrule syntax, which
# causes a runaway-argument error. Restore those arguments before compiling.
repair_cmidrules() {
    perl -0pi -e 's/\\cmidrule\\DIFadd\{(\([^{}]*\))\}\{\\DIFadd\{([^{}]*)\}\}/\\cmidrule$1\{$2\}/g' "$1"
}

clean_aux() {
    local source_tex=$1
    local source_base=${source_tex%.tex}

    latexmk -c -outdir="$output_dir" "$source_tex"
    rm -f -- "$source_base.bbl" "$source_base.bbl-SAVE-ERROR" \
        "$source_base.bcf-SAVE-ERROR"
}

build_pdf() {
    local source_tex=$1

    # Remove stale auxiliary files left by an interrupted or failed build.
    clean_aux "$source_tex"
    latexmk -pdf -interaction=nonstopmode -halt-on-error \
        -outdir="$output_dir" "$source_tex"
}

latexdiff-vc --git --flatten --force -r "$base_ref" "$root_tex"
mv -f -- "$generated_tex" "$full_diff_tex"
repair_cmidrules "$full_diff_tex"
build_pdf "$full_diff_tex"

if [[ $keep_aux == false ]]; then
    clean_aux "$full_diff_tex"
fi

printf 'Built %s\n' "${full_diff_tex%.tex}.pdf"
if [[ $keep_aux == true ]]; then
    printf 'Kept auxiliary files in %s\n' "$output_dir"
fi
