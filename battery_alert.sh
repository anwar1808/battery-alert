#!/bin/bash

LOCK_79="$HOME/.battery_alert_79_triggered"
LOCK_80="$HOME/.battery_alert_80_triggered"
LOCK_20="$HOME/.battery_alert_20_triggered"

NOTIFIER="/opt/homebrew/bin/terminal-notifier"

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

# --- 79% charge alert ---
if [ "$STATUS" = "charging" ] && [ "$PERCENT" -ge 79 ]; then
    if [ ! -f "$LOCK_79" ]; then
        touch "$LOCK_79"
        "$NOTIFIER" -title "Unplug Charger" -message "Battery at 79% — unplug to protect battery health" -sound Glass &
    fi
else
    # Reset if charging but below 79% (new charge cycle) OR battery drained below 74%
    if { [ "$STATUS" = "charging" ] && [ "$PERCENT" -lt 79 ]; } || [ "$PERCENT" -lt 74 ]; then
        rm -f "$LOCK_79"
    fi
fi

# --- 20% discharge alert ---
if [ "$STATUS" = "discharging" ] && [ "$PERCENT" -le 20 ]; then
    if [ ! -f "$LOCK_20" ]; then
        touch "$LOCK_20"
        "$NOTIFIER" -title "🪫🫠 Low Battery" -message "Battery at 20% — plug in now" -sound Funk &
    fi
else
    # Reset once battery climbs back above 25%
    [ "$PERCENT" -gt 25 ] && rm -f "$LOCK_20"
fi
