#!/bin/bash

check_status() {
    STATUS=$(nmcli radio wifi)
    if [[ "$STATUS" == "enabled" ]]; then
        echo ""    # Vide si WiFi activé
    else
        echo "󰀝"   # Avion si WiFi coupé
    fi
}

check_status

nmcli monitor | while read -r _; do
    check_status
done