#!/bin/bash
set -x

#set wallpaper
wallpaper=$(find {WALLPAPER LOCATION}-type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | shuf -n 1)

# Set wallpaper with swww
swww img $wallpaper

# Generate colors with pywal
wal -i $wallpaper

# Start Waybar
waybar &
