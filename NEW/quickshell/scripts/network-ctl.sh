#!/usr/bin/env bash

ACTION="$1"
ARG1="$2"
ARG2="$3"

case "$ACTION" in
    status)
        python3 -c '
import subprocess, json

has_wifi = False
wifi_enabled = False
active_type = "none"
net_name = ""
net_ip = ""

try:
    devs = subprocess.check_output(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev"], stderr=subprocess.DEVNULL).decode()
    for line in devs.splitlines():
        parts = line.strip().split(":")
        if len(parts) >= 3:
            dev, dtype, state = parts[0], parts[1], parts[2]
            conn = parts[3] if len(parts) > 3 else ""
            if dtype == "wifi":
                has_wifi = True
            if "connected" in state and "externally" not in state:
                if dtype == "ethernet" and active_type != "ethernet":
                    active_type = "ethernet"
                    net_name = dev
                elif dtype == "wifi" and active_type == "none":
                    active_type = "wifi"
                    net_name = conn
except Exception:
    pass

try:
    rad = subprocess.check_output(["nmcli", "radio", "wifi"], stderr=subprocess.DEVNULL).decode().strip()
    wifi_enabled = (rad == "enabled")
except Exception:
    pass

try:
    ip_out = subprocess.check_output(["ip", "-4", "addr", "show", "scope", "global"], stderr=subprocess.DEVNULL).decode()
    for line in ip_out.splitlines():
        line = line.strip()
        if line.startswith("inet "):
            net_ip = line.split()[1].split("/")[0]
            break
except Exception:
    pass

print(json.dumps({
    "active_type": active_type,
    "net_name": net_name,
    "net_ip": net_ip,
    "has_wifi": has_wifi,
    "wifi_enabled": wifi_enabled
}))
'
        ;;
    wifi-list)
        python3 -c '
import subprocess, json

saved_ssids = set()
try:
    saved_out = subprocess.check_output(["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"], stderr=subprocess.DEVNULL).decode()
    for line in saved_out.splitlines():
        parts = line.strip().split(":")
        if len(parts) >= 2 and parts[1] == "802-11-wireless":
            saved_ssids.add(parts[0])
except Exception:
    pass

networks = []
seen_ssids = set()

try:
    out = subprocess.check_output(["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"], stderr=subprocess.DEVNULL).decode()
    for line in out.splitlines():
        parts = line.strip().split(":")
        if len(parts) >= 4:
            in_use = (parts[0] == "*")
            ssid = parts[1].strip()
            if not ssid or ssid in seen_ssids:
                continue
            seen_ssids.add(ssid)
            signal = int(parts[2]) if parts[2].isdigit() else 50
            sec = parts[3].strip()
            is_secured = len(sec) > 0 and sec != "--"
            is_saved = ssid in saved_ssids
            networks.append({
                "ssid": ssid,
                "signal": signal,
                "security": sec,
                "secured": is_secured,
                "saved": is_saved,
                "connected": in_use
            })
except Exception:
    pass

# Sort: active first, then saved first, then signal descending
networks.sort(key=lambda x: (not x["connected"], not x["saved"], -x["signal"]))

print(json.dumps(networks))
'
        ;;
    wifi-connect)
        SSID="$ARG1"
        PASS="$ARG2"
        IFNAME=$(nmcli -t -f DEVICE,TYPE dev 2>/dev/null | grep ':wifi$' | cut -d: -f1 | head -n1)
        IFNAME="${IFNAME:-wlp0s20f0u2u2}"

        if [ -n "$PASS" ]; then
            # Delete any previous incomplete/corrupted profile for this SSID
            nmcli connection delete id "$SSID" >/dev/null 2>&1 || true
            # Create fresh profile with explicit key-mgmt and psk
            nmcli connection add type wifi con-name "$SSID" ifname "$IFNAME" ssid "$SSID" \
                wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$PASS" >/dev/null 2>&1
            nmcli connection up id "$SSID"
        else
            # Try existing saved connection first
            if nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq "$SSID"; then
                nmcli connection up id "$SSID"
            else
                # Open network
                nmcli dev wifi connect "$SSID" ifname "$IFNAME"
            fi
        fi
        ;;
    wifi-forget)
        SSID="$ARG1"
        nmcli connection delete id "$SSID" >/dev/null 2>&1
        ;;
    wifi-disconnect)
        SSID="$ARG1"
        nmcli con down id "$SSID" >/dev/null 2>&1
        ;;
    wifi-toggle)
        STATE="$ARG1"
        nmcli radio wifi "$STATE" >/dev/null 2>&1
        ;;
esac
