#!/usr/bin/env bash

# Fichier qui stocke la luminosité actuelle (La "Vérité")
CACHE_FILE="/tmp/brightness_level"
# Dossier backlight pour détecter si portable
BACKLIGHT_DIR="/sys/class/backlight"

# --- 1. INITIALISATION (Si le fichier n'existe pas) ---
if [ ! -f "$CACHE_FILE" ]; then
    # On essaie de lire la vraie valeur actuelle
    if ls $BACKLIGHT_DIR/* >/dev/null 2>&1; then
        # Portable
        CURRENT=$(brightnessctl -m | awk -F, '{print $4}' | tr -d '%')
    else
        # Fixe (On lit l'écran 1, sinon on met 50 par défaut)
        CURRENT=$(ddcutil getvcp 10 --display 1 --terse 2>/dev/null | awk '{print $4}')
        if [ -z "$CURRENT" ]; then CURRENT=50; fi
    fi
    echo "$CURRENT" > "$CACHE_FILE"
fi

# Lecture de la valeur stockée
VAL=$(cat "$CACHE_FILE")

# --- 2. CALCUL DE LA NOUVELLE VALEUR ---
case "$1" in
    up)
        NEW_VAL=$((VAL + 10))
        if [ "$NEW_VAL" -gt 100 ]; then NEW_VAL=100; fi
        ;;
    down)
        NEW_VAL=$((VAL - 10))
        if [ "$NEW_VAL" -lt 0 ]; then NEW_VAL=0; fi
        ;;
    get)
        # Pour Waybar, on renvoie juste la valeur stockée (Ultra rapide)
        echo "{\"percentage\": $VAL}"
        exit 0
        ;;
esac

# Sauvegarde de la nouvelle valeur
echo "$NEW_VAL" > "$CACHE_FILE"

# --- 3. APPLICATION AUX ÉCRANS ---
if ls $BACKLIGHT_DIR/* >/dev/null 2>&1; then
    # --- MODE PORTABLE ---
    brightnessctl set "${NEW_VAL}%"
else
    # --- MODE FIXE (Synchronisation Absolue) ---
    # On envoie la valeur exacte (ex: 60) à tous les écrans.
    # Même si un écran était décalé, il va se "recaler" sur cette valeur.
    
    # On récupère les BUS I2C (ex: 2 3)
    BUS_LIST=$(ddcutil detect --terse | grep "I2C bus:" | awk -F- '{print $2}')
    
    for BUS in $BUS_LIST; do
        ddcutil setvcp 10 $NEW_VAL --bus=$BUS &
        # Le "&" lance en parallèle. Comme on force une valeur absolue,
        # les conflits sont moins graves (au pire le prochain scroll corrigera).
        # Si ça bugue trop, enlève le "&" et ajoute "sleep 0.1".
    done
    wait
fi

# Signal à Waybar
pkill -SIGRTMIN+8 waybar