#!/usr/bin/env bash

# --- INITIALISATION ---
ids=()             # Tableau pour stocker les adresses uniques des fenêtres (ex: 0x55ab...)
display_names=()   # Tableau pour stocker les noms lisibles qui seront affichés dans le menu

# --- RÉCUPÉRATION DES DONNÉES ---
# 1. hyprctl clients -j : Récupère la liste des fenêtres ouvertes au format JSON.
# 2. jq -r : Filtre le JSON pour exclure les fenêtres invalides (workspace -1)
#    et extrait : adresse, numéro de workspace, classe de l'appli et titre de la fenêtre.
RAW_DATA=$(hyprctl clients -j | jq -r '.[] | select(.workspace.id != -1) | "\(.address)\t\(.workspace.id)\t\(.class)\t\(.initialTitle)\t\(.title)"')

# --- TRAITEMENT DES DONNÉES ---
# On lit chaque ligne de RAW_DATA en utilisant la tabulation (\t) comme séparateur
while IFS=$'\t' read -r id ws class initial title; do
    
    FINAL_NAME=$(~/dotfiles/scripts/display-names.sh "$class" "$initial" "$title")
    
    # Formatage de la ligne finale (ex: "[1] Firefox")
    display_str="[$ws] $FINAL_NAME"

    # Ajout des données dans nos tableaux respectifs
    ids+=("$id")
    display_names+=("$display_str")

done <<< "$RAW_DATA"

# S'il n'y a aucune fenêtre ouverte, on quitte proprement
if [ ${#ids[@]} -eq 0 ]; then exit 0; fi

# --- INTERFACE UTILISATEUR (MENU) ---
# Envoie la liste des noms au menu 'fuzzel'.
# --index permet de récupérer la position (0, 1, 2...) de l'élément choisi plutôt que son texte.
SELECTED_INDEX=$(printf "%s\n" "${display_names[@]}" | fuzzel -d --prompt="Switch > " --width=30 --index)

# --- ACTION FINALE ---
# Si l'utilisateur a sélectionné une fenêtre (n'a pas fait Echap)
if [ -n "$SELECTED_INDEX" ]; then
    # Récupère l'adresse correspondante via l'index sélectionné
    TARGET_ID="${ids[$SELECTED_INDEX]}"
    # Commande Hyprland pour donner le focus à la fenêtre choisie
    hyprctl dispatch focuswindow address:"$TARGET_ID"
fi