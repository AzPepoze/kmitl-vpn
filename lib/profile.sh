# Creates and updates the NetworkManager VPN profile.

enable_network_manager() {
  if systemctl is-active --quiet NetworkManager; then
    return 0
  fi
  log_info setup "Starting NetworkManager"
  run_root systemctl enable --now NetworkManager
}

ask_credentials() {
  read -rp "Username: " VPN_USER
  if [[ -z "$VPN_USER" ]]; then
    log_error setup "Username is required."
    return 1
  fi

  read -rsp "Password: " VPN_PASSWORD
  printf '\n' >&2
  if [[ -z "$VPN_PASSWORD" ]]; then
    log_error setup "Password is required."
    return 1
  fi
}

create_profile() {
  local vpn_data vpn_secrets

  if profile_exists; then
    log_info setup "Removing old $CONN_NAME profile"
    nmcli connection delete id "$CONN_NAME" >/dev/null
  fi

  vpn_data="gateway=$VPN_GATEWAY, ipsec-enabled=yes, ipsec-psk=$VPN_PSK, user=$(escape_nm_value "$VPN_USER"), password-flags=0"
  vpn_secrets="password=$(escape_nm_value "$VPN_PASSWORD")"

  nmcli connection add type vpn con-name "$CONN_NAME" vpn-type l2tp \
    -- vpn.data "$vpn_data" \
    vpn.secrets "$vpn_secrets" \
    ipv4.never-default yes \
    ipv4.routes "$DEFAULT_SPLIT_ROUTES" \
    ipv4.dns "" \
    ipv4.ignore-auto-dns yes >/dev/null
  log_info setup "Saved $CONN_NAME profile"
}

reconnect_if_active() {
  if ! connection_active; then return 0; fi
  log_info vpn "Reconnecting to apply routes"
  nmcli connection down id "$CONN_NAME" >/dev/null
  nmcli connection up id "$CONN_NAME" >/dev/null
}
