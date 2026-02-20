get_window_name() {
    DATA=$(hyprctl activewindow -j)

    # Si aucune fenêtre n'est active (bureau vide)
    if [[ "$DATA" == "{}" ]]; then
        echo '{"text": ""}'
        return
    fi

    eval $(echo "$DATA" | jq -r '@sh "CLASS=\(.class) INITIAL=\(.initialTitle) TITLE=\(.title)"')

    FINAL_NAME=$(~/dotfiles/scripts/display-names.sh "$CLASS" "$INITIAL" "$TITLE")

    echo "{\"text\": \"$FINAL_NAME\"}"
}

get_window_name

socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
    if [[ "$line" == activewindow* ]]; then
        get_window_name
    fi
done