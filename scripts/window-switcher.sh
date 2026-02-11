#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then exit 1; fi

# Find the name of the window in its desktop file
get_desktop_name() {
    local class_name=$1
    # Convertit la classe en minuscules pour faciliter la recherche de fichiers
    local lower_class=$(echo "$class_name" | tr '[:upper:]' '[:lower:]')
    
    # Liste des répertoires standards où Linux stocke les raccourcis d'applications (.desktop)
    local dirs=(
        "/run/current-system/sw/share/applications"
        "$HOME/.nix-profile/share/applications"
        "/etc/profiles/per-user/$USER/share/applications"
        "$HOME/.local/share/applications"
    )

    # Liste des noms de fichiers potentiels basés sur la classe de la fenêtre
    local candidates=(
        "$class_name.desktop" 
        "$lower_class.desktop" 
        "${lower_class##*.}.desktop" # Gère les cas comme 'org.telegram.desktop' -> 'desktop'
    )

    # Double boucle : parcourt chaque dossier, puis chaque nom de fichier candidat
    for dir in "${dirs[@]}"; do
        for file in "${candidates[@]}"; do
            if [ -f "$dir/$file" ]; then
                # Si le fichier existe, on cherche la ligne commençant par "Name="
                local found_name=$(grep -m 1 "^Name=" "$dir/$file" | cut -d= -f2-)
                if [ -n "$found_name" ]; then
                    echo "$found_name" # On renvoie le nom trouvé (ex: "Visual Studio Code")
                    return 0
                fi
            fi
        done
    done
    return 1 # Échec : aucun fichier .desktop correspondant trouvé
}

# --- INITIALISATION ---
ids=()             # Tableau pour stocker les adresses uniques des fenêtres (ex: 0x55ab...)
display_names=()   # Tableau pour stocker les noms lisibles qui seront affichés dans le menu

# --- RÉCUPÉRATION DES DONNÉES ---
# 1. hyprctl clients -j : Récupère la liste des fenêtres ouvertes au format JSON.
# 2. jq -r : Filtre le JSON pour exclure les fenêtres invalides (workspace -1)
#    et extrait : adresse, numéro de workspace, classe de l'appli et titre de la fenêtre.
RAW_DATA=$(hyprctl clients -j | jq -r '.[] | select(.workspace.id != -1) | "\(.address)\t\(.workspace.id)\t\(.class)\t\(.title)"')

# --- TRAITEMENT DES DONNÉES ---
# On lit chaque ligne de RAW_DATA en utilisant la tabulation (\t) comme séparateur
while IFS=$'\t' read -r id ws class title; do
    
    # Appel de la fonction définie plus haut pour obtenir un nom propre
    pretty_name=$(get_desktop_name "$class")

    # Si la fonction get_desktop_name n'a rien trouvé, on applique des règles de secours
    if [ -z "$pretty_name" ]; then
        lower_class=$(echo "$class" | tr '[:upper:]' '[:lower:]')
        
        # Cas spécial : Progressive Web Apps (PWA) de Chrome ou Chromium
        if [[ "$lower_class" == chrome-* ]]; then
            pretty_name="$title"
            pretty_name="${pretty_name// - Google Chrome/}"
            pretty_name="${pretty_name// - Chromium/}"
        # Cas spécial : VS Code version Open Source
        elif [[ "$lower_class" == "code-oss" ]]; then 
            pretty_name="Code OSS"
        else 
            # Par défaut, on utilise simplement la classe de la fenêtre
            pretty_name="$class"
        fi
    fi
    
    # Formatage de la ligne finale (ex: "[1] Firefox")
    display_str="[$ws] $pretty_name"

    # Ajout des données dans nos tableaux respectifs
    ids+=("$id")
    display_names+=("$display_str")

done <<< "$RAW_DATA"

# S'il n'y a aucune fenêtre ouverte, on quitte proprement
if [ ${#ids[@]} -eq 0 ]; then exit 0; fi

# --- INTERFACE UTILISATEUR (MENU) ---
# Envoie la liste des noms au menu 'fuzzel'.
# --index permet de récupérer la position (0, 1, 2...) de l'élément choisi plutôt que son texte.
SELECTED_INDEX=$(printf "%s\n" "${display_names[@]}" | fuzzel -d --prompt="Switch: " --width=30 --index)

# --- ACTION FINALE ---
# Si l'utilisateur a sélectionné une fenêtre (n'a pas fait Echap)
if [ -n "$SELECTED_INDEX" ]; then
    # Récupère l'adresse correspondante via l'index sélectionné
    TARGET_ID="${ids[$SELECTED_INDEX]}"
    # Commande Hyprland pour donner le focus à la fenêtre choisie
    hyprctl dispatch focuswindow address:"$TARGET_ID"
fi