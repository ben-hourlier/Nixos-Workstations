#!/usr/bin/env bash

CLASS=$1
INITIAL=$2
TITLE=$3

case $CLASS in
    "kitty")
        case $TITLE in
            Yazi*)
                FINAL_NAME="Yazi"
                ;;
            ncmpcpp*)
                FINAL_NAME="Ncmpcpp"
                ;;
            */* | *~*) 
                FINAL_NAME="Kitty" 
                ;;
            *) 
                FINAL_NAME=$(echo "$TITLE" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1') 
                ;;
        esac
        ;;
        
    "obsidian")
        FINAL_NAME="Obsidian"
        ;;
        
    *)

        FINAL_NAME=$(echo "$INITIAL" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
        ;;
esac

echo $FINAL_NAME