#!/usr/bin/env bash
set -euo pipefail

device_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ -n "${TWRP_TOP:-}" ]]; then
    top="$(cd "$TWRP_TOP" && pwd)"
elif [[ -d "$device_dir/../../../system/vold" ]]; then
    top="$(cd "$device_dir/../../.." && pwd)"
else
    echo "Set TWRP_TOP when running outside device/xiaomi/nezha" >&2
    exit 1
fi
apply_patch() {
    local project="$1"
    local patch="$2"

    if git -C "$top/$project" apply --reverse --check "$patch" 2>/dev/null; then
        echo "Already applied: $(basename "$patch")"
    else
        git -C "$top/$project" apply --check "$patch"
        git -C "$top/$project" apply "$patch"
        echo "Applied: $(basename "$patch")"
    fi
}

apply_patch system/vold \
    "$device_dir/patches/twrp-16/0001-vold-fix-synthetic-password-gcm.patch"
apply_patch bootable/recovery \
    "$device_dir/patches/twrp-16/0002-recovery-report-super-partition-size.patch"
apply_patch bootable/recovery \
    "$device_dir/patches/twrp-16/0003-recovery-fix-removable-storage-and-battery.patch"
wlan_final_patch="$device_dir/patches/twrp-16/0006-recovery-simplify-wlan-and-save-network.patch"
if git -C "$top/bootable/recovery" apply --reverse --check "$wlan_final_patch" 2>/dev/null; then
    echo "Superseded by 0006: 0004-recovery-wire-wlan-service-controls.patch"
else
    apply_patch bootable/recovery \
        "$device_dir/patches/twrp-16/0004-recovery-wire-wlan-service-controls.patch"
fi
apply_patch bootable/recovery \
    "$device_dir/patches/twrp-16/0005-recovery-remove-wlan-page-label.patch"
apply_patch bootable/recovery \
    "$wlan_final_patch"
apply_patch bootable/recovery \
    "$device_dir/patches/twrp-16/0007-recovery-link-wlan-credential-crypto.patch"
apply_patch bootable/recovery \
    "$device_dir/patches/twrp-16/0008-recovery-fix-wlan-scan-and-save-multiple-networks.patch"
apply_patch bootable/recovery \
    "$device_dir/patches/twrp-16/0009-recovery-add-saved-wlan-management.patch"
