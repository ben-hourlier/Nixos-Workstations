{ pkgs }:

pkgs.writeShellScriptBin "time-tracker-display" ''

    trap "exit" INT TERM QUIT EXIT

    while true; do
        if [[ -f /tmp/timer_mode ]]; then
            STATUS=$(timew)
            if [[ "$STATUS" == *"Tracking"* ]]; then
                if [[ "$STATUS" =~ Total[[:space:]]+([0-9]+:[0-9]+):[0-9]+ ]]; then
                    echo "Work: ''${BASH_REMATCH[1]}"
                fi
            else
                rm -f /tmp/timer_mode
                echo "$(uairctl fetch '{name} {time}\n')"
            fi
        else
            echo "$(uairctl fetch '{name} {time}\n')"
        fi

        sleep1
    done
''