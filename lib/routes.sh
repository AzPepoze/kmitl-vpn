# Validates networks and applies split or full-tunnel routes.

# Exit status 0 when the value is an IPv4 network in a.b.c.d/n form.
cidr_is_valid() {
  local cidr=$1 i
  if [[ ! $cidr =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/([0-9]{1,2})$ ]]; then
    return 1
  fi
  for (( i = 1; i <= 4; i++ )); do
    if (( 10#${BASH_REMATCH[i]} > 255 )); then return 1; fi
  done
  (( 10#${BASH_REMATCH[5]} <= 32 ))
}

validate_cidr() {
  local cidr=$1
  if cidr_is_valid "$cidr"; then return 0; fi
  log_error cli "Invalid network: $cidr"
  return 1
}

apply_split_routes() {
  local routes=$1

  require_profile || return 1
  nmcli connection modify id "$CONN_NAME" \
    ipv4.never-default yes \
    ipv4.routes "$routes" \
    ipv4.ignore-auto-dns yes \
    ipv4.dns ""
  reconnect_if_active
  log_info vpn "Split tunnel: $routes"
}

apply_full_tunnel() {
  require_profile || return 1
  nmcli connection modify id "$CONN_NAME" \
    ipv4.never-default no \
    ipv4.routes "" \
    ipv4.ignore-auto-dns yes \
    ipv4.dns "$VPN_DNS"
  reconnect_if_active
  log_info vpn "Full tunnel: all traffic goes through the VPN"
}

show_routes() {
  local output never_default routes
  local -a lines

  require_profile || return 1
  output=$(nmcli -g ipv4.never-default,ipv4.routes connection show id "$CONN_NAME")
  mapfile -t lines <<<"$output"
  never_default=${lines[0]:-}
  routes=${lines[1]:-}

  if [[ $never_default == yes ]]; then
    log_info vpn "Split tunnel. Routes: ${routes:-none}"
  else
    log_info vpn "Full tunnel: all traffic goes through the VPN"
  fi
}

# Accepts networks as separate args, comma-separated args, or both.
apply_custom_routes() {
  local arg item list
  local -a items networks=()

  for arg in "$@"; do
    IFS=',' read -r -a items <<<"$arg"
    for item in "${items[@]}"; do
      validate_cidr "$item" || return 1
      networks+=("$item")
    done
  done

  if (( ${#networks[@]} == 0 )); then
    log_error cli "No networks given"
    return 1
  fi
  list=$(IFS=,; printf '%s' "${networks[*]}")
  apply_split_routes "$list"
}
