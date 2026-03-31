#!/bin/sh
# Extract embedded documentation from GNUmakefile header comments
# and convert to Markdown suitable for GitHub Pages.
#
# Usage: scripts/extract-docs.sh [GNUmakefile] > index.md

set -e

INPUT="${1:-GNUmakefile}"

awk '
BEGIN {
    in_code = 0
    state = "normal"  # normal, saw_sep, saw_title
}

# Stop at first non-comment line (ignoring blank lines)
/^[^#]/ && !/^$/ { exit }

# Skip blank non-comment lines
/^$/ { next }

# Handle separator lines: # ====...
/^# =+$/ {
    if (state == "normal") {
        # Opening separator
        if (in_code) { print "```"; in_code = 0 }
        state = "saw_sep"
    } else if (state == "saw_title") {
        # Closing separator -- emit the heading
        print ""
        print "## " section_title
        print ""
        state = "normal"
    }
    next
}

# If we just saw the opening separator, this line is the title
state == "saw_sep" {
    sub(/^# ?/, "")
    section_title = $0
    state = "saw_title"
    next
}

# First line: extract title
NR == 1 {
    sub(/^# ?/, "")
    # "modular-make -- Title [v1.1.0]" -> "# Title"
    sub(/^[^ ]+ -- /, "")
    sub(/ \[v[0-9.]+\]$/, "")
    print "# " $0
    next
}

# Skip preamble lines (updated, requires)
NR == 2 && /^# updated:/ { next }
NR == 3 && /^# Requires / { next }
NR == 3 && /^#$/ { next }

# Regular comment lines
{
    # Strip "# " or lone "#"
    if ($0 == "#") {
        line = ""
    } else {
        sub(/^# ?/, "")
        line = $0
    }

    # Lines with 2+ leading spaces are "code"
    is_indented = (line ~ /^  /)

    if (is_indented && !in_code) {
        print "```makefile"
        in_code = 1
    } else if (!is_indented && in_code) {
        print "```"
        in_code = 0
    }

    print line
}

END {
    if (in_code) print "```"
}
' "$INPUT"
