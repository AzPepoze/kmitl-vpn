# Command handlers and the main dispatcher.

cmd_setup() {
  local pm
  if ! pm=$(detect_pkg_manager); then
    log_error setup "Unsupported distro. Use arch, debian/ubuntu, fedora/rhel or opensuse/sles."
    return 1
  fi

  ensure_deps "$pm"
  enable_ikev1_policy
  repair_libreswan_owner
  enable_network_manager
  ask_credentials
  create_profile
  log_info setup "Run: kmitl-vpn connect"
}

cmd_connect() {
  local output
  if ! profile_exists; then
    log_error vpn "No $CONN_NAME profile. Run: kmitl-vpn setup"
    return 1
  fi

  log_info vpn "Connecting"
  if ! output=$(nmcli connection up id "$CONN_NAME" 2>&1); then
    log_error vpn "$output"
    return 1
  fi
  log_info vpn "$output"
}

cmd_disconnect() {
  local output
  if ! connection_active; then
    log_info vpn "Already disconnected"
    return 0
  fi

  if ! output=$(nmcli connection down id "$CONN_NAME" 2>&1); then
    log_error vpn "$output"
    return 1
  fi
  log_info vpn "$output"
}

cmd_status() {
  if ! profile_exists; then
    log_info vpn "not set up"
    return 0
  fi

  if connection_active; then
    log_info vpn "connected"
  else
    log_info vpn "disconnected"
  fi
}

cmd_routes() {
  if (( $# == 0 )); then
    show_routes
  elif [[ $# -eq 1 && $1 == all ]]; then
    apply_full_tunnel
  else
    apply_custom_routes "$@"
  fi
}

cmd_uninstall() {
  if connection_active; then
    cmd_disconnect
  fi
  if profile_exists; then
    nmcli connection delete id "$CONN_NAME" >/dev/null
    log_info vpn "Deleted $CONN_NAME profile"
  fi
  remove_libreswan_files
  log_info vpn "Packages such as NetworkManager were kept."
  log_info vpn "Uninstalled."
}

cmd_help() {
  printf '%s\n' \
    "kmitl-vpn - KMITL L2TP/IPsec VPN via NetworkManager" \
    "" \
    "Usage:" \
    "  kmitl-vpn setup       install missing packages, save username and password" \
    "  kmitl-vpn connect     connect" \
    "  kmitl-vpn disconnect  disconnect" \
    "  kmitl-vpn status      show connection state" \
    "  kmitl-vpn routes      show or set VPN networks, e.g. routes 161.246.166.0/24  (or: routes all)" \
    "  kmitl-vpn uninstall   remove the profile and libreswan files"
}

main() {
  local command=${1:-help}
  case "$command" in
    setup) cmd_setup ;;
    connect) cmd_connect ;;
    disconnect) cmd_disconnect ;;
    status) cmd_status ;;
    routes) shift; cmd_routes "$@" ;;
    uninstall) cmd_uninstall ;;
    help|-h|--help) cmd_help ;;
    *)
      log_error cli "Unknown command: $command"
      cmd_help
      exit 2 ;;
  esac
}
