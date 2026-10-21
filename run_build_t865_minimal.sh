#!/bin/bash
set -e
cd $HOME/kernel/android_device_samsung_gts6l

export ARCH=arm64
export KBUILD_BUILD_USER=felix
export KBUILD_BUILD_HOST=gts6l
export LOCALVERSION=""

BASE=$HOME
CROSS_COMPILE_PREFIX="$BASE/toolchains/gcc-4.9/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9-lineage-19.1/bin/aarch64-linux-android-"
CLANG_BIN="$BASE/toolchains/proton-clang/proton-clang-20210522/bin/clang"
CLANG_TRIPLE="aarch64-linux-gnu-"

mkdir -p out

MAKE_ARGS=(
  -C "$(pwd)"
  O="$(pwd)/out"
  DTC_EXT="$(pwd)/tools/dtc"
  CONFIG_BUILD_ARM64_DT_OVERLAY=y
  ARCH=arm64
  CROSS_COMPILE="$CROSS_COMPILE_PREFIX"
  REAL_CC="$CLANG_BIN"
  CC="$CLANG_BIN"
  CLANG_TRIPLE="$CLANG_TRIPLE"
)

echo "=== [1/3] Generando config desde gts6l_eur_open_defconfig (arch/arm64/configs/) ==="
# Todos los ajustes (seguridad Samsung off, IOSCHED_ZEN, EROFS, Simple LMK,
# devfreq_boost, Boeffla WL blocker, etc.) ya viven directamente en el
# defconfig - este script ya no parchea .config a mano.
make "${MAKE_ARGS[@]}" gts6l_eur_open_defconfig

echo "=== [2/3] Normalizando config ==="
# chmod necesarios para que el build no falle por permisos perdidos al
# extraer el tar (lecciones tecnicas previas, no son ajustes de CONFIG).
chmod +x scripts/crypto/fips_crypto_integrity.py 2>/dev/null || true
chmod +x tools/dtc 2>/dev/null || true

make "${MAKE_ARGS[@]}" olddefconfig

echo "=== [2.5/3] Generando vdso-offsets.h de forma confiable ==="
# El hook prepare/vdso_prepare de kbuild no genera este header de forma fiable
# con este toolchain (queda vacio), asi que lo hacemos a mano siempre.
make "${MAKE_ARGS[@]}" arch/arm64/kernel/vdso/ 2>&1 | tail -10
(
  cd out
  "${CROSS_COMPILE_PREFIX}nm" arch/arm64/kernel/vdso/vdso.so.dbg | bash ../arch/arm64/kernel/vdso/gen_vdso_offsets.sh | LC_ALL=C sort > include/generated/vdso-offsets.h
)
echo "vdso-offsets.h: $(cat out/include/generated/vdso-offsets.h)"

echo "=== [3/3] Compilando ==="
make "${MAKE_ARGS[@]}" -j1 2>&1

echo ""
echo "=== Build terminado. Verificando salida ==="
ls -la out/arch/arm64/boot/Image out/arch/arm64/boot/Image-dtb 2>&1
