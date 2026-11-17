# Detects the package manager and installs or removes the VPN packages.

# Packages that ship /usr/bin/ipsec and conflict with libreswan.
readonly IPSEC_CONFLICT_PACKAGES=(strongswan openswan)

detect_pkg_manager() {
  local ids id
  ids=$(. /etc/os-release && printf '%s %s' "${ID:-}" "${ID_LIKE:-}")
  for id in $ids; do
    case "$id" in
      arch|cachyos|manjaro|endeavouros) echo pacman; return 0 ;;
      debian|ubuntu|linuxmint|pop) echo apt; return 0 ;;
      fedora|rhel|centos|rocky|alma) echo dnf; return 0 ;;
      opensuse*|sles) echo zypper; return 0 ;;
    esac
  done
  return 1
}

l2tp_plugin_present() {
  local path
  for path in "${L2TP_PLUGIN_PATHS[@]}"; do
    if [[ -e "$path" ]]; then return 0; fi
  done
  return 1
}

libreswan_present() {
  ipsec --version 2>/dev/null | grep -qi libreswan
}

deps_present() {
  command -v nmcli >/dev/null && l2tp_plugin_present \
    && command -v xl2tpd >/dev/null && libreswan_present
}

# Exit status 0 when the package is installed. Prints nothing.
package_installed() {
  local pm=$1 name=$2
  case "$pm" in
    pacman) pacman -Q "$name" >/dev/null 2>&1 ;;
    apt) dpkg-query -W -f='${Status}' "$name" 2>/dev/null | grep -q 'install ok installed' ;;
    dnf|zypper) rpm -q "$name" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

remove_package() {
  local pm=$1 name=$2
  case "$pm" in
    pacman) run_root pacman -Rns --noconfirm "$name" ;;
    apt) run_root apt-get remove -y "$name" ;;
    dnf) run_root dnf remove -y "$name" ;;
    zypper) run_root zypper --non-interactive remove "$name" ;;
  esac
}

# Removes conflicting IPsec packages, since they would be overwritten by libreswan.
remove_ipsec_conflicts() {
  local pm=$1 name

  for name in "${IPSEC_CONFLICT_PACKAGES[@]}"; do
    if package_installed "$pm" "$name"; then
      log_warn setup "Found $name, which conflicts with libreswan. Removing it."
      remove_package "$pm" "$name"
    fi
  done
}

install_build_deps() {
  local pm=$1

  log_info setup "Installing build dependencies with $pm"
  case "$pm" in
    pacman)
      run_root pacman -S --needed --noconfirm \
        base-devel bison flex pkgconf nss nspr libcap-ng libevent pam \
        curl audit libxcrypt systemd-libs xmlto docbook-xml docbook-xsl gnupg ;;
    apt)
      run_root apt-get update
      run_root apt-get install -y \
        build-essential bison flex pkg-config libaudit-dev libcap-ng-dev \
        libcurl4-gnutls-dev libevent-dev libnspr4-dev libnss3-dev libnss3-tools \
        libpam0g-dev libselinux1-dev libldap2-dev xmlto docbook-xml docbook-xsl gnupg curl ;;
    dnf)
      run_root dnf install -y \
        gcc make bison flex pkgconfig audit-libs-devel curl-devel \
        libcap-ng-devel libevent-devel nspr-devel nss-devel nss-tools \
        openldap-devel pam-devel libselinux-devel hostname xmlto \
        docbook-style-xsl docbook-dtds systemd-rpm-macros gnupg2 curl ;;
    zypper)
      run_root zypper --non-interactive install \
        gcc make bison flex pkgconf gpg2 curl ;;
  esac
}

install_packages() {
  local pm=$1

  install_build_deps "$pm"

  log_info setup "Installing missing packages with $pm"
  case "$pm" in
    pacman)
      run_root pacman -S --needed --noconfirm \
        networkmanager networkmanager-l2tp xl2tpd ppp ;;
    apt)
      run_root apt-get install -y \
        network-manager network-manager-l2tp xl2tpd ;;
    dnf)
      run_root dnf install -y \
        NetworkManager NetworkManager-l2tp xl2tpd ;;
    zypper)
      run_root zypper --non-interactive install \
        NetworkManager NetworkManager-l2tp xl2tpd ;;
  esac
}

ensure_deps() {
  local pm=$1
  if deps_present; then
    log_info setup "Packages already installed"
    return 0
  fi

  if (( EUID != 0 )) && ! command -v sudo >/dev/null; then
    log_error setup "sudo is missing. Run as root or install sudo."
    return 1
  fi

  if ! libreswan_present; then
    remove_ipsec_conflicts "$pm"
  fi
  install_packages "$pm"
  if ! libreswan_present; then
    build_libreswan
  fi

  if ! deps_present; then
    log_error setup "Some packages are still missing after install."
    return 1
  fi
}
