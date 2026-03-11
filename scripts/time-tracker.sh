STATE=$(uairctl fetch {state})
PERCENT=$(uairctl fetch {percent})

if [[ $STATE == "work-paused" ]]; then
    if [[ $PERCENT == "101" ]]; then
        PRINT="Start\nFinish\nReset"
    else
        PRINT="Resume Work\nFinish\nReset"
    fi
elif [[ $STATE == "work-played" ]]; then
    PRINT="Pause Work\nFinish\nReset"
elif [[ $STATE == "break-paused" ]]; then
    PRINT="Resume Break\nFinish\nReset"
else
    PRINT="Pause Break\nFinish\nReset"
fi

CHOSEN=$(echo -e "$PRINT" | fuzzel -d -p "> ")

if [[ $CHOSEN == "Start" ]]; then
    ARGS=$(fuzzel -d --prompt-only "")
    timew start $ARGS
    uairctl resume
elif [[ $CHOSEN == "Resume Work" ]]; then
    timew continue
    uairctl resume
elif [[ $CHOSEN == "Pause Work" ]]; then
    timew stop
    uairctl pause
elif [[ $CHOSEN == "Resume Break" ]]; then
    uairctl resume
elif [[ $CHOSEN == "Pause Work" ]]; then
    uairctl pause
elif [[ $CHOSEN == "Finish" ]]; then
    timew stop
    uairctl finish
elif [[ $CHOSEN == "Reset" ]]; then
    timew stop
    uairctl reload
fi