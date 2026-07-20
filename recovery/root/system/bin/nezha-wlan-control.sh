#!/system/bin/sh

CTRL_DIR=/tmp/recovery/sockets
RUNTIME_CONFIG=/tmp/recovery/wpa_supplicant.conf
SAVED_DIR=/data/recovery/wlan
SAVED_CONFIG=${SAVED_DIR}/wpa_supplicant.conf
VENDOR_CONFIG=/vendor/etc/wifi/wpa_supplicant.conf
WPA_CLI=/system/bin/wpa_cli

log_message() {
    echo "I:nezha-wlan-control: $1" >> /tmp/recovery.log
}

wait_for_supplicant() {
    count=0
    while [ "$count" -lt 20 ]; do
        if "$WPA_CLI" -iwlan0 -p"$CTRL_DIR" ping 2>/dev/null | grep -q PONG; then
            return 0
        fi
        if [ "$count" -gt 0 ] && [ "$(getprop init.svc.nezha-wpa-supplicant)" = "stopped" ]; then
            return 1
        fi
        sleep 1
        count=$((count + 1))
    done
    return 1
}

prepare_config() {
    mkdir -p /tmp/recovery
    chown 0:1010 /tmp/recovery
    chmod 0770 /tmp/recovery
    mkdir -p "$CTRL_DIR"
    chown 0:1010 "$CTRL_DIR"
    chmod 0770 "$CTRL_DIR"

    if [ -s "$SAVED_CONFIG" ]; then
        cp "$SAVED_CONFIG" "$RUNTIME_CONFIG"
        log_message "Loaded saved WLAN configuration"
    elif [ -s "$VENDOR_CONFIG" ]; then
        cp "$VENDOR_CONFIG" "$RUNTIME_CONFIG"
    else
        : > "$RUNTIME_CONFIG"
        echo "ctrl_interface=$CTRL_DIR" >> "$RUNTIME_CONFIG"
        echo "ap_scan=1" >> "$RUNTIME_CONFIG"
    fi

    if grep -q '^update_config=' "$RUNTIME_CONFIG"; then
        sed -i 's/^update_config=.*/update_config=1/' "$RUNTIME_CONFIG"
    else
        echo 'update_config=1' >> "$RUNTIME_CONFIG"
    fi
    # The vendor supplicant drops from root to Wi-Fi UID 1010 before reading
    # and later rewriting this disposable configuration.
    chown 0:1010 "$RUNTIME_CONFIG"
    chmod 0660 "$RUNTIME_CONFIG"
}

start_wlan() {
    if [ ! -e /sys/class/net/wlan0 ]; then
        log_message "Cannot start supplicant: wlan0 is unavailable"
        return 1
    fi

    prepare_config || return 1
    ifconfig wlan0 up
    setprop ctl.stop nezha-wlan-monitor
    setprop ctl.stop nezha-wpa-supplicant
    count=0
    while [ "$count" -lt 10 ]; do
        service_state=$(getprop init.svc.nezha-wpa-supplicant)
        if [ "$service_state" != "running" ] && [ "$service_state" != "stopping" ]; then
            break
        fi
        sleep 1
        count=$((count + 1))
    done
    setprop ctl.start nezha-wpa-supplicant

    if ! wait_for_supplicant; then
        log_message "Supplicant did not become responsive"
        setprop nezha.wlan.status supplicant-failed
        return 1
    fi

    setprop ctl.start nezha-wlan-monitor
    "$WPA_CLI" -iwlan0 -p"$CTRL_DIR" reconnect >/dev/null 2>&1 || true
    setprop nezha.wlan.status running
    log_message "Supplicant is responsive"
}

save_config() {
    if [ ! -d /data ] || [ ! -w /data ]; then
        log_message "Cannot save WLAN configuration: /data is unavailable"
        return 1
    fi
    # TWRP may recreate /tmp/recovery after WLAN startup. Restore the Wi-Fi
    # service's directory access immediately before supplicant writes its
    # temporary configuration file.
    chown 0:1010 /tmp/recovery || return 1
    chmod 0770 /tmp/recovery || return 1
    if ! "$WPA_CLI" -iwlan0 -p"$CTRL_DIR" save_config 2>/dev/null | grep -q OK; then
        log_message "wpa_supplicant rejected save_config"
        return 1
    fi

    mkdir -p "$SAVED_DIR" || return 1
    chmod 0700 "$SAVED_DIR" || return 1
    cp "$RUNTIME_CONFIG" "$SAVED_CONFIG" || return 1
    chown 0:0 "$SAVED_CONFIG"
    chmod 0600 "$SAVED_CONFIG"
    log_message "Saved WLAN configuration for automatic reconnection"
}

monitor_wlan() {
    wait_for_supplicant || exit 1
    exec "$WPA_CLI" -iwlan0 -p"$CTRL_DIR" -a/system/bin/nezha-wlan-control.sh
}

handle_event() {
    case "$2" in
        CONNECTED|CTRL-EVENT-CONNECTED*)
            log_message "Link connected; requesting DHCP lease"
            /system/bin/dhcpcd "$1" >> /tmp/recovery.log 2>&1
            ;;
        DISCONNECTED|CTRL-EVENT-DISCONNECTED*)
            /system/bin/ifconfig "$1" 0.0.0.0 >/dev/null 2>&1 || true
            ;;
    esac
}

case "$1" in
    start|restart)
        start_wlan
        ;;
    save)
        save_config
        ;;
    monitor)
        monitor_wlan
        ;;
    wlan0)
        handle_event "$@"
        ;;
    *)
        echo "usage: $0 {start|restart|save|monitor}" >&2
        exit 2
        ;;
esac
