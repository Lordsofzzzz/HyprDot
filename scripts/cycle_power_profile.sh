#!/bin/bash

current_profile=$(powerprofilesctl get)

case $current_profile in
    "performance")
        powerprofilesctl set balanced
        ;;
    "balanced")
        powerprofilesctl set power-saver
        ;;
    "power-saver")
        powerprofilesctl set performance
        ;;
    *)
        # Default to balanced if current profile is unknown or not set
        powerprofilesctl set balanced
        ;;
esac
