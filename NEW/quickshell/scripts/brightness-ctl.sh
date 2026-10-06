#!/usr/bin/env bash

ACTION="$1"
ID="$2"
VAL="$3"

case "$ACTION" in
    get)
        python3 -c '
import subprocess, json, os

def get_brightness():
    if os.path.exists("/sys/class/backlight") and len(os.listdir("/sys/class/backlight")) > 0:
        try:
            val = subprocess.check_output("brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %", shell=True).decode().strip()
            return [{"id": 0, "name": "Écran interne", "val": int(val) if val else 50}]
        except Exception:
            return [{"id": 0, "name": "Écran interne", "val": 50}]
            
    try:
        detect = subprocess.check_output(["ddcutil", "detect", "--terse"], stderr=subprocess.DEVNULL).decode()
    except Exception:
        return []
        
    displays = []
    current_disp = None
    current_conn = ""
    current_model = ""
    
    for line in detect.splitlines():
        line = line.strip()
        if line.startswith("Display "):
            if current_disp is not None and current_model:
                displays.append((current_disp, current_model, current_conn))
            parts = line.split()
            current_disp = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else None
            current_conn = ""
            current_model = ""
        elif line.startswith("DRM connector:"):
            c = line.split(":", 1)[1].strip()
            if "card" in c and "-" in c:
                c = c.split("-", 1)[1]
            current_conn = c
        elif line.startswith("Monitor:"):
            m = line.split(":", 1)[1].strip()
            parts = [p.strip() for p in m.split(":") if p.strip()]
            current_model = parts[-1] if parts else "Moniteur"
            
    if current_disp is not None and current_model:
        displays.append((current_disp, current_model, current_conn))
        
    result = []
    for d_id, model, conn in displays:
        try:
            val_out = subprocess.check_output(["ddcutil", "getvcp", "10", "--display", str(d_id), "--terse"], stderr=subprocess.DEVNULL).decode()
            parts = val_out.strip().split()
            val = int(parts[3]) if len(parts) >= 4 else 50
            name = f"{model} ({conn})" if conn else model
            result.append({"id": d_id, "name": name, "val": val})
        except Exception:
            pass
            
    return result

print(json.dumps(get_brightness()))
'
        ;;
    set)
        if [ "$ID" -eq 0 ] || ( [ -d /sys/class/backlight ] && [ $(ls /sys/class/backlight 2>/dev/null | wc -l) -gt 0 ] ); then
            brightnessctl set "${VAL}%" >/dev/null 2>&1 &
        else
            # Terminate any previous ddcutil setvcp for this specific display to prevent I2C bus collision
            pkill -f "ddcutil setvcp 10 .* --display $ID" 2>/dev/null || true
            ddcutil setvcp 10 "$VAL" --display "$ID" >/dev/null 2>&1 &
        fi
        ;;
esac
