#!/usr/bin/env bash
set -euo pipefail

device_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ -n "${TWRP_TOP:-}" ]]; then
    top="$(cd "$TWRP_TOP" && pwd)"
elif [[ -d "$device_dir/../../../build/make" ]]; then
    top="$(cd "$device_dir/../../.." && pwd)"
else
    echo "Set TWRP_TOP to the root of the TWRP 16 source checkout" >&2
    exit 1
fi

export OUT_DIR="${OUT_DIR:-out-clean-audit}"
export SKIP_ABI_CHECKS=true

build_device_dir="$top/device/xiaomi/nezha"
if [[ "$device_dir" != "$build_device_dir" ]]; then
    mkdir -p "$build_device_dir"
    rsync -a --delete --exclude=.git/ "$device_dir/" "$build_device_dir/"
fi

cd "$top"
set +u
source build/envsetup.sh >/dev/null
lunch twrp_nezha-bp2a-eng >/dev/null
TWRP_TOP="$top" bash "$build_device_dir/apply-source-patches.sh"
# rsync preserves source timestamps, so explicitly invalidate Kati's cached flags.
touch "$build_device_dir/BoardConfig.mk" "$top/bootable/recovery/Android.mk"
mka recoveryimage

echo "Recovery image: $top/$OUT_DIR/target/product/nezha/recovery.img"
