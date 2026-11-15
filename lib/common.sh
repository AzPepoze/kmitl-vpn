# Shared constants and helpers used by every command.

readonly CONN_NAME="kmitl-vpn"
readonly VPN_GATEWAY="myvpn.kmitl.ac.th"
readonly VPN_PSK="kmitl2vpn"
readonly VPN_DNS="161.246.52.21"
readonly DEFAULT_SPLIT_ROUTES="161.246.166.0/24,161.246.127.0/24,10.252.0.0/16,10.128.0.0/16"
readonly L2TP_PLUGIN_PATHS=(
  /usr/lib/NetworkManager/VPN/nm-l2tp-service.name
  /usr/lib64/NetworkManager/VPN/nm-l2tp-service.name
)
readonly STATE_DIR="/var/lib/kmitl-vpn"
readonly LIBRESWAN_MANIFEST="$STATE_DIR/libreswan.files"

run_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    sudo "$@"
  fi
}

escape_nm_value() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//,/\\,}
  printf '%s' "$value"
}

profile_exists() {
  local names
  names=$(nmcli -t -f NAME connection show 2>/dev/null || true)
  grep -qxF -- "$CONN_NAME" <<<"$names"
}

connection_active() {
  local active
  active=$(nmcli -t -f NAME connection show --active 2>/dev/null || true)
  grep -qxF -- "$CONN_NAME" <<<"$active"
}

require_profile() {
  if ! profile_exists; then
    log_error vpn "No $CONN_NAME profile. Run: kmitl-vpn setup"
    return 1
  fi
}
