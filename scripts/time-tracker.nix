{ pkgs }:

pkgs.writeShellScriptBin "time-tracker" ''
    STATE=$(uairctl fetch {state})
    PERCENT=$(uairctl fetch {percent})

    if [[ $STATE == "work-paused" ]]; then
        if [[ $PERCENT == "100" ]]; then
            PRINT="Start\nContinue\nNext"
        else
            PRINT="Resume Work\nNext"
        fi
    elif [[ $STATE == "work-resumed" ]]; then
        PRINT="Pause Work\nNext"
    elif [[ $STATE == "break-paused" ]]; then
        PRINT="Resume Break\nNext"
    else
        PRINT="Pause Break\nNext"
    fi

    CHOSEN=$(echo -e "$PRINT" | fuzzel -d -p "> ")

    if [[ $CHOSEN == "Start" ]]; then
        ARGS=$(fuzzel -d --prompt-only "")
        timew start $ARGS
        uairctl resume
    elif [[ $CHOSEN == "Resume Work" || $CHOSEN == "Continue" ]]; then
        timew continue
        uairctl resume
    elif [[ $CHOSEN == "Pause Work" ]]; then
        timew stop
        uairctl pause
    elif [[ $CHOSEN == "Resume Break" ]]; then
        uairctl resume
    elif [[ $CHOSEN == "Pause Work" ]]; then
        uairctl pause
    elif [[ $CHOSEN == "Next" ]]; then
        timew stop
        uairctl next
    fi
''