#!/bin/sh

# Wrapper script for "lock screen now"; provides opportunity to display a notification
# to user before screen is locked

# TODO: Change to only run script if a sentinel file exists; would give more granularity than
# launchd currently provides

#TODO: Insert notification code here, with any relevant delay
# path/to/notification_binary "Locking now…"
# sleep 10

"${HOME}/Library/LaunchAgents/Scripts/bin/locknow"
