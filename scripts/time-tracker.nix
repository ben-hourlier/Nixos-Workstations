{ pkgs }:

pkgs.writeShellScriptBin "time-tracker" ''
    if [ ! findmnt /home/ben/GoogleDrive -t fuse.rclone > /dev/null ]; then
        notify-send --category="system_alert" "Error" "Gdrive not mounted"
    fi

    if [[ -f /tmp/timer_mode ]]; then
        PRINT="Stop timer"
    else
        STATE=$(uairctl fetch '{state}')
        PERCENT=$(uairctl fetch '{percent}')

        if [[ $STATE == "work-paused" ]]; then
            if [[ $PERCENT == "100" ]]; then
                PRINT="Start work session\nContinue previous session\nStart timer\nContinue previous timer\nNext"
            else
                PRINT="Resume work session\nNext"
            fi
        elif [[ $STATE == "work-resumed" ]]; then
            PRINT="Pause work session\nCancel\nNext"
        elif [[ $STATE == "break-paused" ]]; then
            PRINT="Resume break\nNext"
        else
            PRINT="Pause break\nNext"
        fi
    fi

    CHOSEN=$(echo -e "$PRINT" | fuzzel -d -p "> ")

    # 2. ACTIONS
    if [[ $CHOSEN == "Start work session" ]]; then
        ARGS=$(fuzzel -d --prompt-only "Tags: ")
        timew start $ARGS
        uairctl resume

    elif [[ $CHOSEN == "Start timer" ]]; then
        ARGS=$(fuzzel -d --prompt-only "Tags: ")
        timew start $ARGS
        touch /tmp/timer_mode

    elif [[ $CHOSEN == "Continue previous timer" ]]; then
        timew continue
        touch /tmp/timer_mode

    elif [[ $CHOSEN == "Stop timer" ]]; then
        rm -f /tmp/timer_mode
        timew stop

    elif [[ $CHOSEN == "Resume work session" || $CHOSEN == "Continue previous session" ]]; then
        timew continue
        uairctl resume
    elif [[ $CHOSEN == "Pause work session" ]]; then
        timew stop
        uairctl pause
    elif [[ $CHOSEN == "Resume break" ]]; then
        uairctl resume
    elif [[ $CHOSEN == "Pause break" ]]; then
        uairctl pause
    elif [[ $CHOSEN == "Next" ]]; then
        timew stop
        uairctl next
    elif [[ $CHOSEN == "Cancel" ]]; then
        timew cancel
        uairctl next
    fi
''