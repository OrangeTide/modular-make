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

# Escape prose so Markdown renders makefile notation literally.
# "<name>_CFLAGS" would otherwise parse as a raw HTML tag and disappear,
# and a pair of underscores or asterisks in one paragraph ("_EXPORTED_*",
# "_build/x86_64-linux-gnu/") would italicise the text between them.
#
# Text already inside a `backtick span` is left alone: it is a code span,
# where a backslash would show up literally rather than escaping anything.
# Splitting on the backtick puts the spans at even positions, so only the
# odd ones get escaped.  Indented lines never reach here; they are emitted
# verbatim inside a fenced block.
function escape_prose(s,   n, parts, i, out) {
    n = split(s, parts, "`")
    out = ""
    for (i = 1; i <= n; i++) {
        if (i % 2 == 1) {
            gsub(/</, "\\&lt;", parts[i])
            gsub(/>/, "\\&gt;", parts[i])
            gsub(/_/, "\\_", parts[i])
            gsub(/\*/, "\\*", parts[i])
        }
        out = out parts[i]
        if (i < n) out = out "`"
    }
    return out
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
        print "## " escape_prose(section_title)
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
    print "# " escape_prose($0)
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

    print in_code ? line : escape_prose(line)
}

END {
    if (in_code) print "```"
}
' "$INPUT"
