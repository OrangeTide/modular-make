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
$MAKE clean-all $EXTRA 2>/dev/null || true

printf "\n=== default build (with defconfig auto-create) ===\n"
run_test "make (default)" $MAKE $EXTRA
run_test "config.mk auto-created" sh -c 'test -f _build/*/config.mk'
run_test "app runs" _out/*/bin/app
run_test "cxxapp runs" _out/*/bin/cxxapp
run_test "app: foo transitive dep (foo_val=42)" sh -c '_out/*/bin/app | grep -q "foo_val=42"'
run_test "app: baz C++ lib (baz_val=99)" sh -c '_out/*/bin/app | grep -q "baz_val=99"'
# Diamond _LIBS: app -> foo -> bar and app -> baz -> bar. Building and running
# proves bar is not misreported as a circular dependency and is linked once,
# ordered after both foo and baz. baz_val() calls bar_val() (41 + 58 == 99).
run_test "app: diamond dep bar shared by foo and baz" sh -c '_out/*/bin/app | grep -q "baz_val=99"'
run_test "app: extra from defconfig (label=bonus)" sh -c '_out/*/bin/app | grep -q "extra: label=bonus"'
run_test "cxxapp: foo transitive dep (foo_val=42)" sh -c '_out/*/bin/cxxapp | grep -q "foo_val=42"'

printf "\n=== run-tests ===\n"
run_test "make run-tests" $MAKE run-tests $EXTRA
run_test "make run-test-app" $MAKE run-test-app $EXTRA
run_test "make run-test-cxxapp" $MAKE run-test-cxxapp $EXTRA

printf "\n=== platform suffixes ===\n"
run_test "platapp runs" _out/*/bin/platapp
run_test "platapp: arch-specific source linked (plat_has_arch=1)" sh -c '_out/*/bin/platapp | grep -q "plat_has_arch=1"'
run_test "platapp: OS name set via _CPPFLAGS.<os>" sh -c '_out/*/bin/platapp | grep -q "plat_os_name=$(uname -s)"'

printf "\n=== packages (_PKGS) ===\n"
run_test "pkgapp runs (linked libm via _PKGS=m)" _out/*/bin/pkgapp
run_test "pkgapp: math result correct (pkg_sqrt=3)" sh -c '_out/*/bin/pkgapp | grep -q "pkg_sqrt=3"'

printf "\n=== generated headers (_GENERATED_HDRS) ===\n"
run_test "genapp runs (clean-build ordering)" _out/*/bin/genapp
run_test "genapp: generated .c + .h linked (gen_value=7 tag=7)" sh -c '_out/*/bin/genapp | grep -q "gen_value=7 tag=7"'
# Rebuild-on-change: edit the generator input; the new value must flow through
# both the generated .c (gen_value) and the generated .h (tag) into the consumer.
cp src/libgen/gen.in src/libgen/gen.in.bak
printf '55\n' > src/libgen/gen.in
$MAKE genapp $EXTRA >/dev/null 2>&1
run_test "genapp rebuilds when generated header changes (gen_value=55 tag=55)" sh -c '_out/*/bin/genapp | grep -q "gen_value=55 tag=55"'
mv src/libgen/gen.in.bak src/libgen/gen.in
$MAKE genapp $EXTRA >/dev/null 2>&1

printf "\n=== clean ===\n"
run_test "make clean" $MAKE clean $EXTRA
run_test "binaries removed" sh -c '! test -f _out/*/bin/app'
run_test "objects removed" sh -c '! test -f _build/*/src/main.o'

printf "\n=== DEBUG build ===\n"
run_test "make DEBUG=1" $MAKE DEBUG=1 $EXTRA
run_test "debug variant directory used" sh -c 'test -d _out/*/debug/bin'
run_test "app runs (debug)" _out/*/debug/bin/app
run_test "debug symbols present" sh -c 'file _out/*/debug/bin/app | grep -q "not stripped"'
run_test "default build untouched by debug" sh -c '! test -f _build/*/src/main.o'
$MAKE clean DEBUG=1 $EXTRA >/dev/null 2>&1

printf "\n=== RELEASE build ===\n"
run_test "make RELEASE=1" $MAKE RELEASE=1 $EXTRA
run_test "app runs (release)" _out/*/release/bin/app
$MAKE clean RELEASE=1 $EXTRA >/dev/null 2>&1

printf "\n=== RELEASE with RELEASE_MARCH ===\n"
run_test "make RELEASE=1 RELEASE_MARCH=x86-64" $MAKE RELEASE=1 RELEASE_MARCH=x86-64 $EXTRA
run_test "app runs (release x86-64)" _out/*/release/bin/app
$MAKE clean RELEASE=1 $EXTRA >/dev/null 2>&1

printf "\n=== build variants ===\n"
run_test "make SANITIZE=address,undefined" $MAKE SANITIZE=address,undefined $EXTRA
run_test "sanitizer variant directory used" sh -c 'test -d "_build/"*"/san-address+undefined"'
run_test "app runs (sanitized)" sh -c '_out/*/san-address+undefined/bin/app'
run_test "sanitizer runtime linked" \
	sh -c 'ldd _out/*/san-address+undefined/bin/app 2>/dev/null | grep -qi asan || \
	       nm _out/*/san-address+undefined/bin/app 2>/dev/null | grep -qi asan'
# Token order must normalize to one directory, so this rebuild is a no-op.
run_test "SANITIZE token order normalized" \
	sh -c "$MAKE SANITIZE=undefined,address $EXTRA 2>&1 | grep -q 'Nothing to be done\|up to date' || \
	       test -d '_build/'*'/san-address+undefined'"
run_test "config.mk shared across variants" \
	sh -c 'test "$(find _build -name config.mk | wc -l)" -eq 1'
$MAKE clean SANITIZE=address,undefined $EXTRA >/dev/null 2>&1

run_test "make VARIANT=custom" $MAKE VARIANT=custom $EXTRA
run_test "app runs (custom variant)" _out/*/custom/bin/app
run_test "variant composes with mode" \
	sh -c "$MAKE DEBUG=1 VARIANT=custom $EXTRA >/dev/null 2>&1 && test -d _build/*/debug-custom"
$MAKE clean VARIANT=custom $EXTRA >/dev/null 2>&1
$MAKE clean DEBUG=1 VARIANT=custom $EXTRA >/dev/null 2>&1

printf "\n=== config options ===\n"
$MAKE clean-all $EXTRA >/dev/null 2>&1
# Hide defconfig so auto-create does not fire.
mv defconfig defconfig.bak
run_test "build without config" $MAKE app $EXTRA
run_test "app runs (no config)" _out/*/bin/app
run_test "no extra output without config" sh -c '! _out/*/bin/app | grep -q "extra:"'
$MAKE clean-all $EXTRA >/dev/null 2>&1
mv defconfig.bak defconfig
run_test "make defconfig" $MAKE defconfig $EXTRA
run_test "config.mk created" sh -c 'test -f _build/*/config.mk'
run_test "config.h generated" $MAKE app $EXTRA
run_test "config.h created" sh -c 'test -f _build/*/config.h'
run_test "config.h has CONFIG_EXTRA" sh -c 'grep -q "CONFIG_EXTRA" _build/*/config.h'
run_test "app runs (with config)" _out/*/bin/app
run_test "extra output with CONFIG_EXTRA" sh -c '_out/*/bin/app | grep -q "extra: label=bonus"'
$MAKE clean $EXTRA >/dev/null 2>&1

printf "\n=== user flags from .env ===\n"
# A global CFLAGS/LDFLAGS belongs to the user and must reach every target.
# Target-specific flags build on it rather than replacing it. Set them in
# .env, not on the command line: a command-line variable overrides
# target-specific assignments on its own and would pass even if the
# target-specific rules clobbered the global value.
#
# .env is gitignored, so a developer may keep a real one here. Move it aside
# and restore it on exit, however the script leaves.
if [ -f .env ]; then mv .env .env.saved; fi
restore_env() {
	rm -f .env shlib/.env
	if [ -f .env.saved ]; then mv .env.saved .env; fi
}
trap restore_env EXIT
trap 'restore_env; exit 1' INT TERM
$MAKE clean-all $EXTRA >/dev/null 2>&1
cat > .env <<'ENV'
CFLAGS=-DUSER_ENV_PROBE
LDFLAGS=-L/tmp/modular-make-probe
ENV
run_test "global CFLAGS from .env reaches the compile line" \
	sh -c "$MAKE V=1 app $EXTRA 2>&1 | grep -q -- '-DUSER_ENV_PROBE'"
$MAKE clean-all $EXTRA >/dev/null 2>&1
run_test "global LDFLAGS from .env reaches the link line" \
	sh -c "$MAKE V=1 app $EXTRA 2>&1 | grep -q -- '-L/tmp/modular-make-probe'"
run_test "app still runs with user flags" _out/*/bin/app
run_test "per-target flags still applied" \
	sh -c '_out/*/bin/app | grep -q "foo_val=42"'
rm -f .env
$MAKE clean-all $EXTRA >/dev/null 2>&1

printf "\n=== shared library flag isolation ===\n"
# Sub-project under shlib/: dynapp links libdyn.so, and each carries a
# distinctive -L. Target-specific variables are inherited by prerequisites, so
# a naive "LDFLAGS += ..." on dynapp would append dynapp's private flag to
# libdyn.so's link line. libdyn.so would then differ depending on whether the
# build was entered through "make dyn" or "make dynapp", with no relink when
# switching between them.
SHMAKE="$MAKE -C shlib"
$SHMAKE clean-all $EXTRA >/dev/null 2>&1
run_test "per-target LDFLAGS reaches its own shared library" \
	sh -c "$SHMAKE V=1 dynapp $EXTRA 2>&1 | grep -q -- '-L/tmp/modular-make-lib-only'"
run_test "per-target LDFLAGS reaches its own executable" \
	sh -c "$SHMAKE V=1 --always-make dynapp $EXTRA 2>&1 | grep -q -- '-L/tmp/modular-make-exe-only'"
# The negative case: grep the .so link line alone and require the executable's
# flag to be absent from it.
run_test "executable LDFLAGS does not leak into the shared library" \
	sh -c "! $SHMAKE V=1 --always-make dynapp $EXTRA 2>&1 | grep -- '-shared' | grep -q -- '-L/tmp/modular-make-exe-only'"
# Entering through the library alone must produce the same link line.
$SHMAKE clean-all $EXTRA >/dev/null 2>&1
so_via_lib=$($SHMAKE V=1 dyn $EXTRA 2>&1 | grep -- '-shared' || true)
$SHMAKE clean-all $EXTRA >/dev/null 2>&1
so_via_exe=$($SHMAKE V=1 dynapp $EXTRA 2>&1 | grep -- '-shared' || true)
run_test "shared library link line is the same via either entry target" \
	test "$so_via_lib" = "$so_via_exe"

# The user's global LDFLAGS still reaches both, without carrying either
# per-target value across.
$SHMAKE clean-all $EXTRA >/dev/null 2>&1
cat > shlib/.env <<'ENV'
LDFLAGS=-L/tmp/modular-make-probe
ENV
run_test "global LDFLAGS reaches the shared library too" \
	sh -c "$SHMAKE V=1 dynapp $EXTRA 2>&1 | grep -- '-shared' | grep -q -- '-L/tmp/modular-make-probe'"
rm -f shlib/.env
$SHMAKE clean-all $EXTRA >/dev/null 2>&1

printf "\n=== TARGET_TRIPLET override ===\n"
# -dumpmachine does not always identify a toolchain uniquely: a musl
# cross-compiler reports its glibc counterpart's triplet. Without an override
# both builds share one directory and silently reuse each other's objects.
# The probe keeps the OS field intact so platform detection still works.
$MAKE clean-all $EXTRA >/dev/null 2>&1
real_triplet=$($MAKE -p $EXTRA 2>/dev/null | sed -n 's/^TARGET_TRIPLET := *//p' | head -1)
probe_triplet=$(echo "$real_triplet" | sed 's/[^-]*$/probe/')
run_test "default build uses the -dumpmachine triplet" \
	sh -c "$MAKE app $EXTRA >/dev/null 2>&1 && test -d '_build/$real_triplet'"
$MAKE clean-all $EXTRA >/dev/null 2>&1
cat > .env <<ENV
TARGET_TRIPLET=$probe_triplet
ENV
run_test "TARGET_TRIPLET from .env selects the build directory" \
	sh -c "$MAKE app $EXTRA >/dev/null 2>&1 && test -d '_build/$probe_triplet'"
run_test "app runs (overridden triplet)" sh -c "_out/$probe_triplet/bin/app"
run_test "overridden build does not touch the default triplet directory" \
	sh -c "! test -d '_build/$real_triplet'"
rm -f .env
$MAKE clean-all TARGET_TRIPLET="$probe_triplet" $EXTRA >/dev/null 2>&1
run_test "TARGET_TRIPLET on the command line selects the build directory" \
	sh -c "$MAKE app TARGET_TRIPLET='$probe_triplet' $EXTRA >/dev/null 2>&1 && test -d '_build/$probe_triplet'"
$MAKE clean-all TARGET_TRIPLET="$probe_triplet" $EXTRA >/dev/null 2>&1

printf "\n=== target OS from the triplet ===\n"
# The OS does not sit at a fixed position in a triplet: gcc reports
# x86_64-linux-gnu while clang on the same machine reports
# x86_64-pc-linux-gnu. Reading the wrong field yields a bogus _TARGET_OS, and
# every .Linux suffixed variable then merges into nothing. That failure is
# silent, so pin the mapping for both shapes and for the other platforms.
check_os() {   # $1 triplet, $2 expected _TARGET_OS
	run_test "$1 -> $2" sh -c \
	  "$MAKE -pq TARGET_TRIPLET='$1' $EXTRA 2>/dev/null |
	   grep -qx '_TARGET_OS := $2'"
}
check_os x86_64-linux-gnu         Linux
check_os x86_64-pc-linux-gnu      Linux
check_os aarch64-apple-darwin23   Darwin
check_os x86_64-w64-mingw32       Windows_NT
check_os x86_64-pc-cygwin         Windows_NT
check_os wasm32-unknown-emscripten Emscripten
# Reading the database still auto-creates the config, so drop the directories
# those probes left behind before the clean-all tests inspect the tree.
for _t in x86_64-linux-gnu x86_64-pc-linux-gnu aarch64-apple-darwin23 \
          x86_64-w64-mingw32 x86_64-pc-cygwin wasm32-unknown-emscripten; do
	$MAKE clean-all TARGET_TRIPLET="$_t" $EXTRA >/dev/null 2>&1
done

printf "\n=== clean-all ===\n"
$MAKE $EXTRA >/dev/null 2>&1
$MAKE clean $EXTRA >/dev/null 2>&1
run_test "make clean-all" $MAKE clean-all $EXTRA
run_test "build dirs removed" sh -c '! test -d _build'

# clean-all on its own, with no preceding clean. It must read the existing
# config.mk: without it, objects built from CONFIG_* gated sources (extra.c,
# gated on CONFIG_EXTRA from defconfig) are invisible to the clean and stay
# behind, so the next build can link stale objects from a configuration that
# is no longer selected.
$MAKE $EXTRA >/dev/null 2>&1
run_test "config-gated object built" sh -c 'test -f _build/*/src/extra.o'
run_test "clean-all alone removes config-gated objects" \
	sh -c "$MAKE clean-all $EXTRA >/dev/null 2>&1 && ! test -d _build"

printf "\n=== ARFLAGS ===\n"
# Make's built-in default is "rv", so only that counts as nobody having
# chosen. A value from .env, the environment, or the command line is the
# user's and must survive.
#
# -pq dumps the variable database without running a single recipe. The dump
# goes to a file rather than a pipe: closing a pipe early on a -p that is
# also building wedges make.
_db=$(mktemp)
_dump_arflags() {   # any arguments are passed to make
	$MAKE -pq "$@" $EXTRA > "$_db" 2>/dev/null || true
	sed -n 's/^ARFLAGS *:*= *//p' "$_db" | head -1
}

_af_default=$(_dump_arflags)
case "$_af_default" in
rvc*) pass "ARFLAGS defaults to rv plus c" ;;
*)    fail "ARFLAGS defaults to rv plus c (got '$_af_default')" ;;
esac

_af_cmdline=$(_dump_arflags ARFLAGS=rq)
run_test "ARFLAGS on the command line is respected" test "$_af_cmdline" = rq

ARFLAGS=rq; export ARFLAGS
_af_env=$(_dump_arflags)
unset ARFLAGS
run_test "ARFLAGS from the environment is respected" test "$_af_env" = rq

# An archiver that rejects D, which is what Apple's ar does. The flag has to
# be probed for rather than assumed, or every archive fails -- and because
# the archive rule is quiet, it fails with no message at all.
_realar=$(command -v ar)
_fakebin=$(mktemp -d)
# The real archiver by absolute path. "exec ar" would find this script again,
# because $_fakebin goes on the front of PATH, and fork until the machine
# gives up.
cat > "$_fakebin/ar" <<FAKEAR
#!/bin/sh
case "\$1" in *D*) echo "ar: illegal option -- D" >&2; exit 1;; esac
exec $_realar "\$@"
FAKEAR
chmod +x "$_fakebin/ar"

_savedpath=$PATH
PATH="$_fakebin:$PATH"
_af_noD=$(_dump_arflags)
PATH=$_savedpath
run_test "D is dropped when the archiver rejects it" test "$_af_noD" = rvc

$MAKE clean-all $EXTRA >/dev/null 2>&1
run_test "archives build with an archiver that rejects D" \
	sh -c "PATH='$_fakebin':\$PATH $MAKE app $EXTRA >/dev/null 2>&1"

rm -rf "$_fakebin" "$_db"
$MAKE clean-all $EXTRA >/dev/null 2>&1

printf "\n=== Results ===\n"
printf "  %d passed, %d failed\n" "$PASS" "$FAIL"
test "$FAIL" -eq 0
