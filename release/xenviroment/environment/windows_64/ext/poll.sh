#!/bin/sh

if [ "${1}" == "CLOSE1" ]; then
    # Insert POLL1 logic here.
    echo "Polling Session 1"
elif [ "${1}" == "CLOSE2" ]; then
    # Insert POLL2 logic here.
    echo "Polling Session 2"
elif [ "${1}" == "REPOLL" ]; then
    # Insert REPOLL logic here.
    echo "Repoll Session"
elif [ "${1}" == "TRICKLE" ]; then
    # Insert TRICKLE logic here.
    echo "Trickle Session"
fi

    