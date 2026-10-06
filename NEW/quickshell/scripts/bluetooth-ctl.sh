#!/usr/bin/env bash

ACTION="$1"
ARG1="$2"

case "$ACTION" in
    status)
        python3 -c '
import subprocess, json

powered = False
connected_device = ""
try:
    show = subprocess.check_output(["bluetoothctl", "show"], stderr=subprocess.DEVNULL).decode()
    powered = "Powered: yes" in show
except Exception:
    pass

devices = []
if powered:
    try:
        p_out = subprocess.check_output(["bluetoothctl", "devices", "Paired"], stderr=subprocess.DEVNULL).decode()
        for line in p_out.splitlines():
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0] == "Device":
                mac = parts[1]
                name = " ".join(parts[2:])
                is_conn = False
                try:
                    info = subprocess.check_output(["bluetoothctl", "info", mac], stderr=subprocess.DEVNULL).decode()
                    is_conn = "Connected: yes" in info
                except Exception:
                    pass
                if is_conn and not connected_device:
                    connected_device = name
                devices.append({"mac": mac, "name": name, "connected": is_conn, "paired": True})
    except Exception:
        pass

print(json.dumps({
    "powered": powered,
    "connected_device": connected_device,
    "devices": devices
}))
'
        ;;
    connect)
        MAC="$ARG1"
        bluetoothctl connect "$MAC" >/dev/null 2>&1 &
        ;;
    disconnect)
        MAC="$ARG1"
        bluetoothctl disconnect "$MAC" >/dev/null 2>&1 &
        ;;
    toggle)
        STATE="$ARG1"
        bluetoothctl power "$STATE" >/dev/null 2>&1
        ;;
esac
