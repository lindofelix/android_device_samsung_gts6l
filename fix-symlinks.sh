#!/bin/bash
# Reconstruye los symlinks del kernel que Git puede haber convertido en
# archivos de texto plano (pasa esto cuando se sube sin soporte de symlinks
# en git, ej: core.symlinks=false, o subida via interfaz web/zip).
#
# Correr desde la RAIZ del kernel source, ANTES de compilar:
#   bash fix-symlinks.sh
#
# Es seguro correrlo siempre, incluso si los symlinks ya estan bien -
# simplemente los vuelve a crear igual.

set -e
cd "$(dirname "$0")" 2>/dev/null || true

declare -A LINKS=(
  ["techpack/audio/soc/pinctrl-utils.h"]="../../../drivers/pinctrl/pinctrl-utils.h"
  ["techpack/audio/soc/core.h"]="../../../drivers/pinctrl/core.h"
  ["techpack/audio/include/soc/internal.h"]="../../../../drivers/base/regmap/internal.h"
  ["arch/arm64/boot/dts/arm/vexpress-v2m-rs1.dtsi"]="../../../../arm/boot/dts/vexpress-v2m-rs1.dtsi"
  ["arch/arm/boot/dts/qcom"]="../../../arm64/boot/dts/qcom"
  ["scripts/dtc/include-prefixes/dt-bindings"]="../../../include/dt-bindings"
  ["scripts/dtc/include-prefixes/openrisc"]="../../../arch/openrisc/boot/dts"
  ["scripts/dtc/include-prefixes/h8300"]="../../../arch/h8300/boot/dts"
  ["scripts/dtc/include-prefixes/sh"]="../../../arch/sh/boot/dts"
  ["scripts/dtc/include-prefixes/mips"]="../../../arch/mips/boot/dts"
  ["scripts/dtc/include-prefixes/arm64"]="../../../arch/arm64/boot/dts"
  ["scripts/dtc/include-prefixes/metag"]="../../../arch/metag/boot/dts"
  ["scripts/dtc/include-prefixes/c6x"]="../../../arch/c6x/boot/dts"
  ["scripts/dtc/include-prefixes/nios2"]="../../../arch/nios2/boot/dts"
  ["scripts/dtc/include-prefixes/powerpc"]="../../../arch/powerpc/boot/dts"
  ["scripts/dtc/include-prefixes/arm"]="../../../arch/arm/boot/dts"
  ["scripts/dtc/include-prefixes/microblaze"]="../../../arch/microblaze/boot/dts"
  ["scripts/dtc/include-prefixes/arc"]="../../../arch/arc/boot/dts"
  ["scripts/dtc/include-prefixes/xtensa"]="../../../arch/xtensa/boot/dts"
  ["scripts/dtc/include-prefixes/cris"]="../../../arch/cris/boot/dts"
  ["tools/testing/selftests/powerpc/copyloops/copyuser_power7.S"]="../../../../../arch/powerpc/lib/copyuser_power7.S"
  ["tools/testing/selftests/powerpc/copyloops/copyuser_64.S"]="../../../../../arch/powerpc/lib/copyuser_64.S"
  ["tools/testing/selftests/powerpc/copyloops/memcpy_power7.S"]="../../../../../arch/powerpc/lib/memcpy_power7.S"
  ["tools/testing/selftests/powerpc/copyloops/memcpy_64.S"]="../../../../../arch/powerpc/lib/memcpy_64.S"
  ["tools/testing/selftests/powerpc/vphn/vphn.c"]="../../../../../arch/powerpc/mm/vphn.c"
  ["tools/testing/selftests/powerpc/vphn/vphn.h"]="../../../../../arch/powerpc/mm/vphn.h"
  ["tools/testing/selftests/powerpc/primitives/word-at-a-time.h"]="../../../../../arch/powerpc/include/asm/word-at-a-time.h"
  ["tools/testing/selftests/powerpc/primitives/asm/asm-compat.h"]="../.././../../../../arch/powerpc/include/asm/asm-compat.h"
  ["tools/testing/selftests/powerpc/primitives/asm/ppc_asm.h"]="../../../../../../arch/powerpc/include/asm/ppc_asm.h"
  ["tools/testing/selftests/powerpc/stringloops/memcmp_64.S"]="../../../../../arch/powerpc/lib/memcmp_64.S"
  ["include/dt-bindings/input/linux-event-codes.h"]="../../uapi/linux/input-event-codes.h"
  ["include/uapi/linux/ion.h"]="../../../drivers/staging/android/uapi/ion.h"
  ["include/uapi/linux/msm_ion.h"]="../../../drivers/staging/android/uapi/msm_ion.h"
  # drivers/kernelsu se arma aparte (depende de donde clones KernelSU-Next),
  # no se toca aca para no pisar el setup.sh de KernelSU-Next.
)

fixed=0
skipped=0

for path in "${!LINKS[@]}"; do
  target="${LINKS[$path]}"
  if [ -L "$path" ]; then
    current_target=$(readlink "$path")
    if [ "$current_target" == "$target" ]; then
      skipped=$((skipped+1))
      continue
    fi
  fi
  mkdir -p "$(dirname "$path")"
  rm -f "$path"
  ln -s "$target" "$path"
  echo "fixed: $path -> $target"
  fixed=$((fixed+1))
done

echo ""
echo "=== listo: $fixed symlinks (re)creados, $skipped ya estaban bien ==="
