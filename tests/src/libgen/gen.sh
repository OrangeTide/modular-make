#!/bin/sh
# Test code generator: reads an integer from $1 and writes gen.c + gen.h into
# the directory $2.  Stands in for tools like bin2c or microser-gen.sh that
# emit a paired source and header.  Made by a machine. PUBLIC DOMAIN (CC0-1.0)
set -e
in=$1
outdir=$2
val=$(cat "$in")
mkdir -p "$outdir"
cat > "$outdir/gen.h" <<EOF
#ifndef GEN_H
#define GEN_H
#define GEN_TAG $val
int gen_value(void);
#endif
EOF
cat > "$outdir/gen.c" <<EOF
#include "gen.h"
int gen_value(void) { return GEN_TAG; }
EOF
