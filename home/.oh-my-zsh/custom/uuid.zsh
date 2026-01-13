# Decode timestamp from a UUIDv7 (first 48 bits = ms since Unix epoch)
uuidv7_time() {
  emulate -L zsh
  setopt pipefail

  local uuid="${1:-}"
  if [[ -z "$uuid" ]]; then
    echo "usage: uuidv7_time <uuidv7>" >&2
    return 2
  fi

  # trim whitespace + optional trailing slash
  uuid="${uuid#"${uuid%%[![:space:]]*}"}"   # ltrim
  uuid="${uuid%"${uuid##*[![:space:]]}"}"   # rtrim
  uuid="${uuid%/}"

  # basic shape check
  if [[ ! "$uuid" =~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-7[0-9a-fA-F]{3}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' ]]; then
    echo "error: not a UUIDv7: $uuid" >&2
    return 2
  fi

  local ts_hex="${uuid[1,8]}${uuid[10,13]}"
  local ms=$(( 16#${ts_hex:l} ))

  # seconds + milliseconds remainder
  local sec=$(( ms / 1000 ))
  local mrem=$(( ms % 1000 ))

  # Format using BSD/macOS `date` (works on macOS). If GNU date is present, use it.
  if date -u -r 0 >/dev/null 2>&1; then
    local utc="$(date -u -r "$sec" '+%Y-%m-%dT%H:%M:%S')"
    local loc="$(date    -r "$sec" '+%Y-%m-%dT%H:%M:%S%z')"
    printf "UTC  : %s.%03dZ\n" "$utc" "$mrem"
    printf "Local: %s.%03d\n"  "$loc" "$mrem"
  elif command -v gdate >/dev/null 2>&1; then
    local utc="$(gdate -u -d "@$sec" '+%Y-%m-%dT%H:%M:%S')"
    local loc="$(gdate    -d "@$sec" '+%Y-%m-%dT%H:%M:%S%z')"
    printf "UTC  : %s.%03dZ\n" "$utc" "$mrem"
    printf "Local: %s.%03d\n"  "$loc" "$mrem"
  else
    echo "error: need BSD date (macOS) or GNU date (gdate)" >&2
    return 1
  fi
}
