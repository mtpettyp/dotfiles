#!/bin/bash

# <bitbar.title>DB Tunnels</bitbar.title>
# <bitbar.version>v1.4</bitbar.version>
# <bitbar.author>Mike</bitbar.author>
# <bitbar.desc>AWS SSM port-forward tunnel manager</bitbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# ---------- Configure ----------
SCRIPTS_DIR="$HOME/Development/hyperquote/hq-infra-datasources/scripts"

TUNNEL_NAMES=("staging" "production")

# Returns "script_filename:local_port" for a given tunnel name.
tunnel_config() {
  case "$1" in
    staging)    echo "rds-staging.sh:5433" ;;
    production) echo "rds-prod.sh:5434"    ;;
  esac
}
# -------------------------------

PID_DIR="$HOME/.swiftbar-tunnels"
SCRIPT_PATH="$0"
mkdir -p "$PID_DIR"

kill_tree() {
  local pid=$1 sig=${2:-TERM}
  for child in $(pgrep -P "$pid" 2>/dev/null); do
    kill_tree "$child" "$sig"
  done
  kill -"$sig" "$pid" 2>/dev/null
}

is_running() {
  local name=$1
  IFS=':' read -r _script port <<< "$(tunnel_config "$name")"
  lsof -iTCP:"$port" -sTCP:LISTEN -nP >/dev/null 2>&1
}

start_tunnel() {
  local name=$1
  IFS=':' read -r script _port <<< "$(tunnel_config "$name")"
  nohup bash -c "exec '$SCRIPTS_DIR/$script'" \
    > "$PID_DIR/$name.log" 2>&1 &
  echo $! > "$PID_DIR/$name.pid"
  disown
}

stop_tunnel() {
  local name=$1
  IFS=':' read -r _script port <<< "$(tunnel_config "$name")"
  local pidfile="$PID_DIR/$name.pid"

  if [[ -f "$pidfile" ]]; then
    kill_tree "$(cat "$pidfile")" TERM
    sleep 0.4
    kill_tree "$(cat "$pidfile")" KILL
    rm -f "$pidfile"
  fi

  local stragglers
  stragglers=$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null)
  [[ -n "$stragglers" ]] && echo "$stragglers" | xargs kill -TERM 2>/dev/null
}

case "$1" in
  start)  start_tunnel  "$2"; exit 0 ;;
  stop)   stop_tunnel   "$2"; exit 0 ;;
  toggle) is_running "$2" && stop_tunnel "$2" || start_tunnel "$2"; exit 0 ;;
esac

# ---------- Render menu ----------
title=""
for name in "${TUNNEL_NAMES[@]}"; do
  is_running "$name" && title+="🟢" || title+="🔴"
done

echo "$title"
echo "---"
echo "Database Tunnels | size=13"
echo "---"

for name in "${TUNNEL_NAMES[@]}"; do
  IFS=':' read -r script port <<< "$(tunnel_config "$name")"
  label="$(tr '[:lower:]' '[:upper:]' <<< ${name:0:1})${name:1}"

  if is_running "$name"; then
    echo "🟢 $label  (localhost:$port)"
    echo "-- Disconnect | shell='$SCRIPT_PATH' param1=stop param2=$name terminal=false refresh=true"
    echo "-- Copy psql command | shell=bash param1=-c param2=\"echo 'psql -h localhost -p $port' | pbcopy\" terminal=false"
    echo "-- View log | shell=open param1='$PID_DIR/$name.log' terminal=false"
  else
    echo "🔴 $label  (localhost:$port)"
    echo "-- Connect | shell='$SCRIPT_PATH' param1=start param2=$name terminal=false refresh=true"
    echo "-- View log | shell=open param1='$PID_DIR/$name.log' terminal=false"
  fi
done

echo "---"
echo "Refresh | refresh=true"