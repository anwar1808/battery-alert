#!/bin/bash

LOCK_80="$HOME/.battery_alert_80_triggered"
LOCK_20="$HOME/.battery_alert_20_triggered"

BATTERY_INFO=$(pmset -g batt)
PERCENT=$(echo "$BATTERY_INFO" | grep -o '[0-9]*%' | head -1 | tr -d '%')

# Exit if battery info unreadable
[ -z "$PERCENT" ] && exit 0

# "; charging" won't match "discharging", so this is safe
if echo "$BATTERY_INFO" | grep -q "; charging"; then
    STATUS="charging"
elif echo "$BATTERY_INFO" | grep -q "discharging"; then
    STATUS="discharging"
else
    STATUS="other"  # fully charged, AC attached, etc.
fi

# --- 80% charge alert ---
if [ "$STATUS" = "charging" ] && [ "$PERCENT" -ge 80 ]; then
    if [ ! -f "$LOCK_80" ]; then
        touch "$LOCK_80"
        afplay /System/Library/Sounds/Glass.aiff &
        osascript -e 'display notification "Battery at 80% — unplug to protect battery health" with title "Unplug Charger"'
    fi
else
    # Reset once battery drops back below 75% (so next charge cycle re-alerts)
    [ "$PERCENT" -lt 75 ] && rm -f "$LOCK_80"
fi

# --- 20% discharge alert ---
if [ "$STATUS" = "discharging" ] && [ "$PERCENT" -le 20 ]; then
    if [ ! -f "$LOCK_20" ]; then
        touch "$LOCK_20"
        afplay /System/Library/Sounds/Funk.aiff &
        osascript -e 'display notification "Battery at 20% — plug in now" with title "Low Battery"'
    fi
else
    # Reset once battery climbs back above 25%
    [ "$PERCENT" -gt 25 ] && rm -f "$LOCK_20"
fi
