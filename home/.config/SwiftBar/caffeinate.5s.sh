#!/bin/bash

# <bitbar.title>Caffeinate</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Mike</bitbar.author>
# <bitbar.desc>Toggle caffeinate -d to keep display awake</bitbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

PID_FILE="$HOME/.swiftbar-caffeinate.pid"
SCRIPT_PATH="$0"

is_running() {
  [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null
}

start_caffeinate() {
  nohup caffeinate -d >/dev/null 2>&1 &
  echo $! > "$PID_FILE"
  disown
}

stop_caffeinate() {
  if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
  fi
  # Catch any orphans
  pkill -x caffeinate 2>/dev/null
}

case "$1" in
  start)  start_caffeinate; exit 0 ;;
  stop)   stop_caffeinate;  exit 0 ;;
  toggle) is_running && stop_caffeinate || start_caffeinate; exit 0 ;;
esac

# ---------- Render menu ----------
if is_running; then
  echo "☕"
  echo "---"
  echo "Display sleep: PREVENTED | size=13"
  echo "Turn off | shell='$SCRIPT_PATH' param1=stop terminal=false refresh=true"
else
  echo "💤"
  echo "---"
  echo "Display sleep: normal | size=13"
  echo "Turn on | shell='$SCRIPT_PATH' param1=start terminal=false refresh=true"
fi

echo "---"
echo "Refresh | refresh=true"