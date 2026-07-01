#!/bin/bash

# Usage: ./scripts/notify.sh "<Message>"

MESSAGE=$1
if [ -z "$MESSAGE" ]; then
    MESSAGE="Agent requires your attention."
fi

echo "========================================"
echo "  NOTIFICATION: $MESSAGE"
echo "========================================"

# 1. Beep Sound
if command -v powershell.exe &> /dev/null; then
    # Windows / WSL
    powershell.exe -Command "[System.Media.SystemSounds]::Beep.Play()" 2>/dev/null
elif command -v tput &> /dev/null; then
    # Linux terminal beep
    tput bel 2>/dev/null || printf "\a"
else
    printf "\a"
fi

# 2. GUI Dialog / MessageBox / Wall Notification
if command -v powershell.exe &> /dev/null; then
    # Windows / WSL
    powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; [System.Windows.Forms.MessageBox]::Show('$MESSAGE', 'Antigravity Agent Notification', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)" 2>/dev/null
elif command -v notify-send &> /dev/null; then
    # Linux Desktop Notification (if desktop environment/dbus is active)
    notify-send "Antigravity Agent" "$MESSAGE" 2>/dev/null
elif command -v zenity &> /dev/null; then
    # Linux GUI Dialog
    zenity --info --title="Antigravity Agent Notification" --text="$MESSAGE" --timeout=10 2>/dev/null
elif command -v xmessage &> /dev/null; then
    # Linux X11 Dialog fallback
    xmessage -timeout 10 "$MESSAGE" 2>/dev/null
else
    # Non-GUI fallback: write message to all terminal sessions of current user
    if command -v wall &> /dev/null; then
        echo "Antigravity Agent: $MESSAGE" | wall 2>/dev/null
    fi
fi

