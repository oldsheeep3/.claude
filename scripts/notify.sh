#!/bin/bash

# Usage: ./scripts/notify.sh "<Message>"

MESSAGE=$1
if [ -z "$MESSAGE" ]; then
    MESSAGE="Agent requires your attention."
fi

echo "NOTIFICATION: $MESSAGE"

# Play a beep sound using PowerShell
powershell.exe -Command "[System.Media.SystemSounds]::Beep.Play()" 2>/dev/null

# Show a Windows MessageBox in the foreground
powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null; [System.Windows.Forms.MessageBox]::Show('$MESSAGE', 'Antigravity Agent Notification', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)" 2>/dev/null
