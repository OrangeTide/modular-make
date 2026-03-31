#!/bin/sh
# Test suite for modular-make build system.
# Uses only C and C++ to avoid exotic compiler dependencies.
#
# Usage: tests/run-tests.sh
#        tests/run-tests.sh USE_CLANG=1

set -e
cd "$(dirname "$0")"

PASS=0
FAIL=0
MAKE="make -j$(nproc 2>/dev/null || echo 1)"

pass() { PASS=$((PASS + 1)); printf "  PASS: %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  FAIL: %s\n" "$1"; }

run_test() {
	desc="$1"; shift
	if "$@" >/dev/null 2>&1; then
		pass "$desc"
	else
		fail "$desc"
	fi
}

# Forward extra args (e.g. USE_CLANG=1) to make
EXTRA="$*"

printf "=== clean slate ===\n"
$MAKE clean $EXTRA 2>/dev/null || true

printf "\n=== default build ===\n"
run_test "make (default)" $MAKE $EXTRA
run_test "app runs" _out/*/bin/app
run_test "cxxapp runs" _out/*/bin/cxxapp
run_test "app: foo transitive dep (foo_val=42)" sh -c '_out/*/bin/app | grep -q "foo_val=42"'
run_test "app: baz C++ lib (baz_val=99)" sh -c '_out/*/bin/app | grep -q "baz_val=99"'
run_test "cxxapp: foo transitive dep (foo_val=42)" sh -c '_out/*/bin/cxxapp | grep -q "foo_val=42"'

printf "\n=== run-tests ===\n"
run_test "make run-tests" $MAKE run-tests $EXTRA
run_test "make run-test-app" $MAKE run-test-app $EXTRA
run_test "make run-test-cxxapp" $MAKE run-test-cxxapp $EXTRA

printf "\n=== clean ===\n"
run_test "make clean" $MAKE clean $EXTRA
run_test "binaries removed" sh -c '! test -f _out/*/bin/app'
run_test "objects removed" sh -c '! test -f _build/*/src/main.o'

printf "\n=== DEBUG build ===\n"
run_test "make DEBUG=1" $MAKE DEBUG=1 $EXTRA
run_test "app runs (debug)" _out/*/bin/app
run_test "debug symbols present" sh -c 'file _out/*/bin/app | grep -q "not stripped"'
$MAKE clean $EXTRA >/dev/null 2>&1

printf "\n=== RELEASE build ===\n"
run_test "make RELEASE=1" $MAKE RELEASE=1 $EXTRA
run_test "app runs (release)" _out/*/bin/app
$MAKE clean $EXTRA >/dev/null 2>&1

printf "\n=== RELEASE with RELEASE_MARCH ===\n"
run_test "make RELEASE=1 RELEASE_MARCH=x86-64" $MAKE RELEASE=1 RELEASE_MARCH=x86-64 $EXTRA
run_test "app runs (release x86-64)" _out/*/bin/app
$MAKE clean $EXTRA >/dev/null 2>&1

printf "\n=== clean-all ===\n"
$MAKE $EXTRA >/dev/null 2>&1
run_test "make clean-all" $MAKE clean-all $EXTRA
run_test "build dirs removed" sh -c '! test -d _build'

printf "\n=== Results ===\n"
printf "  %d passed, %d failed\n" "$PASS" "$FAIL"
test "$FAIL" -eq 0
