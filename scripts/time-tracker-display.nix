{ pkgs }:

pkgs.writeShellScriptBin "time-tracker-display" ''

    trap "exit" INT TERM QUIT EXIT

    while true; do
        STATUS=$(timew)
        if [[ -f /tmp/timer_mode ]]; then
            if [[ "$STATUS" == *"Tracking"* ]]; then
                if [[ "$STATUS" =~ Total[[:space:]]+([0-9]+:[0-9]+):[0-9]+ ]]; then
                    echo "Work: ''${BASH_REMATCH[1]}"
                fi
            else
                rm -f /tmp/timer_mode
                echo "$(uairctl fetch '{name} {time}\n')"
            fi
        else
            if [[ "$STATUS" == *"Tracking"* ]]; then
                touch /tmp/timer_mode
            fi

            echo "$(uairctl fetch '{name} {time}\n')"
        fi

        sleep 1
    done
''