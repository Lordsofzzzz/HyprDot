#!/bin/bash
set -x

killall waybar #killing waybar


# Check if swww-daemon is running, and start it if it is not
if ! pgrep -x "swww-daemon" > /dev/null
then
    swww-daemon &
fi

# Set a random wallpaper
wallpaper=$(find /home/lord/Downloads -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

# Set wallpaper with swww, but only if a wallpaper was found
if [ -n "$wallpaper" ]; then
    swww img "$wallpaper"

    # Generate colors with pywal
    wal -i "$wallpaper"
fi

# Start Waybar
waybar &

