#!/usr/bin/env bash

set -euo pipefail

WASI_SDK_PREFIX="${WASI_SDK_PREFIX:-/workspace/.ghc-wasm/wasi-sdk}"
WASI_PREFIX="${WASI_PREFIX:-/tmp/wasi}"

cmake \
  -Bbuild-wasi \
  -DCMAKE_TOOLCHAIN_FILE="$WASI_SDK_PREFIX/share/cmake/wasi-sdk.cmake" \
  -DCMAKE_EXE_LINKER_FLAGS="-Wl,--error-limit=0,--keep-section=target_features,--stack-first,--strip-debug,--lto-O3" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_INSTALL_PREFIX="$WASI_PREFIX" \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DZSTD_BUILD_PROGRAMS=ON \
  -DZSTD_BUILD_SHARED=OFF \
  -DZSTD_LEGACY_SUPPORT=OFF \
  -DZSTD_MULTITHREAD_SUPPORT=OFF \
  -G Ninja \
  build/cmake \
  ${1+"$@"}

cmake --build build-wasi --target install -- -v

wasm-opt --debuginfo --low-memory-unused --strip-dwarf -O4 --converge "$WASI_PREFIX/bin/zstd" -o "$WASI_PREFIX/bin/zstd.wasm"

rm "$WASI_PREFIX/bin/zstd"

wasmtime run -- "$WASI_PREFIX/bin/zstd.wasm" --help
