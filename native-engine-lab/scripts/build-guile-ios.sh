#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/out"
SRC_DIR="$OUT_DIR/source-cache"
BUILD_DIR="$OUT_DIR/build"
PREFIX_DIR="$OUT_DIR/prefix"
PRODUCT_DIR="$OUT_DIR/products"
REPORT_DIR="$OUT_DIR/report"
LOG_DIR="$OUT_DIR/logs"

SDK="iphonesimulator"
ARCH="arm64"
THREADS="pthreads"
GMP_MODE="mini"
STAGE="all"
MIN_IOS="17.0"

BDWGC_VERSION="8.2.8"
LIBFFI_VERSION="3.4.6"
LIBUNISTRING_VERSION="1.2"
GUILE_VERSION="3.0.9"

while [ $# -gt 0 ]; do
  case "$1" in
    --sdk) SDK="$2"; shift 2 ;;
    --arch) ARCH="$2"; shift 2 ;;
    --threads) THREADS="$2"; shift 2 ;;
    --gmp) GMP_MODE="$2"; shift 2 ;;
    --stage) STAGE="$2"; shift 2 ;;
    --output) OUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Normalize --output to an absolute path because later build stages cd into source directories.
case "$OUT_DIR" in
  /*) ;;
  *) OUT_DIR="$PWD/$OUT_DIR" ;;
esac

SRC_DIR="$OUT_DIR/source-cache"
BUILD_DIR="$OUT_DIR/build"
PREFIX_DIR="$OUT_DIR/prefix"
PRODUCT_DIR="$OUT_DIR/products"
REPORT_DIR="$OUT_DIR/report"
LOG_DIR="$OUT_DIR/logs"

mkdir -p "$SRC_DIR" "$BUILD_DIR" "$PREFIX_DIR" "$PRODUCT_DIR" "$REPORT_DIR" "$LOG_DIR"
REPORT="$REPORT_DIR/Gate1-Guile-iOS-build-report.txt"
: > "$REPORT"

log() {
  echo "$*"
  echo "$*" >> "$REPORT"
}

run_logged() {
  name="$1"
  shift
  log "==> $name"
  log_file="$LOG_DIR/$name.log"
  if "$@" > "$log_file" 2>&1; then
    log "PASS $name"
  else
    code=$?
    log "FAIL $name exit=$code log=$log_file"
    tail -80 "$log_file" || true
    exit $code
  fi
}

download() {
  url="$1"
  file="$2"
  if [ ! -f "$SRC_DIR/$file" ]; then
    run_logged "download-$file" curl -L --retry 3 --fail "$url" -o "$SRC_DIR/$file"
  fi
}

extract() {
  file="$1"
  dir="$2"
  if [ ! -d "$BUILD_DIR/$dir" ]; then
    run_logged "extract-$dir" tar -xzf "$SRC_DIR/$file" -C "$BUILD_DIR"
  fi
}

sdk_path() {
  xcrun --sdk "$SDK" --show-sdk-path
}

setup_toolchain() {
  SDKROOT_PATH="$(sdk_path)"
  CC_BIN="$(xcrun --sdk "$SDK" --find clang)"
  AR_BIN="$(xcrun --sdk "$SDK" --find ar)"
  RANLIB_BIN="$(xcrun --sdk "$SDK" --find ranlib)"
  STRIP_BIN="$(xcrun --sdk "$SDK" --find strip)"

  case "$SDK" in
    iphonesimulator)
      TARGET="${ARCH}-apple-ios${MIN_IOS}-simulator"
      MIN_FLAG="-mios-simulator-version-min=$MIN_IOS"
      ;;
    iphoneos)
      TARGET="${ARCH}-apple-ios${MIN_IOS}"
      MIN_FLAG="-miphoneos-version-min=$MIN_IOS"
      ;;
    *) echo "Unsupported sdk: $SDK" >&2; exit 2 ;;
  esac

  HOST_TRIPLE="aarch64-apple-darwin"
  CFLAGS_BASE="-target $TARGET -isysroot $SDKROOT_PATH $MIN_FLAG -O2 -fembed-bitcode=off"
  LDFLAGS_BASE="-target $TARGET -isysroot $SDKROOT_PATH $MIN_FLAG"

  export CC="$CC_BIN"
  export AR="$AR_BIN"
  export RANLIB="$RANLIB_BIN"
  export STRIP="$STRIP_BIN"
  export SDKROOT="$SDKROOT_PATH"
  export PKG_CONFIG_PATH="$PREFIX_DIR/lib/pkgconfig:$PREFIX_DIR/share/pkgconfig"
  export PKG_CONFIG_LIBDIR="$PKG_CONFIG_PATH"
  export MAKEINFO=true

  log "Gate 1 Guile iOS build"
  log "SDK=$SDK"
  log "ARCH=$ARCH"
  log "TARGET=$TARGET"
  log "HOST_TRIPLE=$HOST_TRIPLE"
  log "THREADS=$THREADS"
  log "GMP_MODE=$GMP_MODE"
  log "STAGE=$STAGE"
  log "SDKROOT=$SDKROOT_PATH"
  xcodebuild -version >> "$REPORT" 2>&1 || true
}

check_env() {
  run_logged env-xcode xcodebuild -version
  run_logged env-sdk xcrun --sdk "$SDK" --show-sdk-path
  run_logged env-clang xcrun --sdk "$SDK" --find clang
  if ! command -v pkg-config >/dev/null 2>&1; then
    log "pkg-config missing"
    exit 3
  fi
}

prepare_sources() {
  download "https://github.com/ivmai/bdwgc/releases/download/v${BDWGC_VERSION}/gc-${BDWGC_VERSION}.tar.gz" "gc-${BDWGC_VERSION}.tar.gz"
  download "https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION}/libffi-${LIBFFI_VERSION}.tar.gz" "libffi-${LIBFFI_VERSION}.tar.gz"
  download "https://ftp.gnu.org/gnu/libunistring/libunistring-${LIBUNISTRING_VERSION}.tar.gz" "libunistring-${LIBUNISTRING_VERSION}.tar.gz"
  download "https://ftp.gnu.org/gnu/guile/guile-${GUILE_VERSION}.tar.gz" "guile-${GUILE_VERSION}.tar.gz"
  extract "gc-${BDWGC_VERSION}.tar.gz" "gc-${BDWGC_VERSION}"
  extract "libffi-${LIBFFI_VERSION}.tar.gz" "libffi-${LIBFFI_VERSION}"
  extract "libunistring-${LIBUNISTRING_VERSION}.tar.gz" "libunistring-${LIBUNISTRING_VERSION}"
  extract "guile-${GUILE_VERSION}.tar.gz" "guile-${GUILE_VERSION}"
}

build_bdwgc() {
  cd "$BUILD_DIR/gc-${BDWGC_VERSION}"
  run_logged bdwgc-configure env CFLAGS="$CFLAGS_BASE" LDFLAGS="$LDFLAGS_BASE" ./configure --host="$HOST_TRIPLE" --prefix="$PREFIX_DIR" --disable-shared --enable-static --enable-threads=posix --with-libatomic-ops=none
  run_logged bdwgc-make make -j"$(sysctl -n hw.ncpu)"
  run_logged bdwgc-install make install
}

build_libffi() {
  cd "$BUILD_DIR/libffi-${LIBFFI_VERSION}"
  run_logged libffi-configure env CFLAGS="$CFLAGS_BASE" LDFLAGS="$LDFLAGS_BASE" ./configure --host="$HOST_TRIPLE" --prefix="$PREFIX_DIR" --disable-shared --enable-static --disable-builddir
  run_logged libffi-make make -j"$(sysctl -n hw.ncpu)"
  run_logged libffi-install make install
}

build_libunistring() {
  cd "$BUILD_DIR/libunistring-${LIBUNISTRING_VERSION}"
  run_logged libunistring-configure env CFLAGS="$CFLAGS_BASE" LDFLAGS="$LDFLAGS_BASE" ./configure --host="$HOST_TRIPLE" --prefix="$PREFIX_DIR" --disable-shared --enable-static --disable-nls
  run_logged libunistring-make make -j"$(sysctl -n hw.ncpu)"
  run_logged libunistring-install make install
}

build_guile() {
  cd "$BUILD_DIR/guile-${GUILE_VERSION}"
  gmp_flag="--enable-mini-gmp"
  if [ "$GMP_MODE" = "full" ]; then
    gmp_flag=""
  fi
  run_logged guile-configure env CFLAGS="$CFLAGS_BASE -I$PREFIX_DIR/include" CPPFLAGS="-I$PREFIX_DIR/include" LDFLAGS="$LDFLAGS_BASE -L$PREFIX_DIR/lib" ./configure --host="$HOST_TRIPLE" --prefix="$PREFIX_DIR" --disable-shared --enable-static --disable-jit --disable-networking --disable-tmpnam --with-modules=no --without-64-calls --with-threads="$THREADS" $gmp_flag
  run_logged guile-make make -j"$(sysctl -n hw.ncpu)"
  run_logged guile-install make install
}

build_smoke() {
  cd "$ROOT_DIR"
  smoke_bin="$PRODUCT_DIR/guile-smoke-ios-sim"
  libs="-lguile-3.0 -lgc -lffi -lunistring -lm"
  run_logged smoke-compile "$CC" $CFLAGS_BASE -I"$PREFIX_DIR/include" smoke/guile_smoke.c -L"$PREFIX_DIR/lib" $libs -o "$smoke_bin"
  run_logged smoke-file file "$smoke_bin"
}

run_smoke() {
  device="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ && /Shutdown/ { print $2; exit }')"
  if [ -z "$device" ]; then
    device="$(xcrun simctl list devices booted | awk -F '[()]' '/Booted/ { print $2; exit }')"
  fi
  if [ -z "$device" ]; then
    log "No simulator device found"
    exit 4
  fi
  xcrun simctl boot "$device" >/dev/null 2>&1 || true
  run_logged sim-bootstatus xcrun simctl bootstatus "$device" -b
  run_logged smoke-run xcrun simctl spawn "$device" "$PRODUCT_DIR/guile-smoke-ios-sim"
}

summarize_products() {
  log "==> products"
  find "$PREFIX_DIR" "$PRODUCT_DIR" -maxdepth 3 -type f 2>/dev/null | sort | while read f; do
    size="$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")"
    echo "$size $f" | tee -a "$REPORT"
  done
}

setup_toolchain
check_env
prepare_sources

case "$STAGE" in
  env) ;;
  bdwgc) build_bdwgc ;;
  libffi) build_bdwgc; build_libffi ;;
  libunistring) build_bdwgc; build_libffi; build_libunistring ;;
  guile) build_bdwgc; build_libffi; build_libunistring; build_guile ;;
  smoke|all) build_bdwgc; build_libffi; build_libunistring; build_guile; build_smoke; run_smoke ;;
  *) echo "Unknown stage: $STAGE" >&2; exit 2 ;;
esac

summarize_products
log "Gate 1 script completed"
