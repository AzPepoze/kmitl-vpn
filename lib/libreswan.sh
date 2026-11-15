# Builds, installs and removes libreswan (the IPsec daemon) from source.

readonly LIBRESWAN_ARGS=(
  LIBEXECDIR=/usr/lib/ipsec
  MANDIR=/usr/share/man
  SBINDIR=/usr/bin
  PREFIX=/usr
  USE_DNSSEC=false
  USE_LABELED_IPSEC=false
  USE_LIBCAP_NG=true
  USE_DH2=false
  USE_LEAK_DETECTIVE=false
  USE_XAUTH=true
)
# Lets libreswan build on newer GCC and flex.
readonly LIBRESWAN_CFLAGS="-Wp,-w -DYY_BUF_SIZE=16384 -Wno-error -Wno-stringop-overflow"

# Prints the tag of the latest libreswan GitHub release, e.g. v5.4.1.
latest_libreswan_tag() {
  local effective_url
  effective_url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
    https://github.com/libreswan/libreswan/releases/latest) || return 1
  printf '%s\n' "${effective_url##*/}"
}

# Downloads the signed release tarball for tag into build_dir, verifies it and extracts it.
fetch_libreswan_source() {
  local build_dir=$1 version=$2 tag=$3
  local release_url="https://github.com/libreswan/libreswan/releases/download/$tag"
  local key_url="https://raw.githubusercontent.com/libreswan/libreswan/$tag/LIBRESWAN-OPENPGP-KEY.txt"
  local tarball="libreswan-${version}.tar.gz"
  local signature="${tarball}.asc"
  local key="LIBRESWAN-OPENPGP-KEY.txt"

  curl -fsSL -o "$build_dir/$tarball" "$release_url/$tarball"
  curl -fsSL -o "$build_dir/$signature" "$release_url/$signature"
  curl -fsSL -o "$build_dir/$key" "$key_url"

  # Use a throwaway keyring so the upstream key never reaches the user's keyring.
  local gnupg_home="$build_dir/gnupg"
  mkdir -m 700 "$gnupg_home"
  GNUPGHOME="$gnupg_home" gpg --import "$build_dir/$key"
  if ! GNUPGHOME="$gnupg_home" gpg --verify "$build_dir/$signature" "$build_dir/$tarball"; then
    log_error setup "libreswan signature check failed"
    return 1
  fi

  tar -xzf "$build_dir/$tarball" -C "$build_dir"
}

# Records the staged files so uninstall can remove them later.
write_libreswan_manifest() {
  local stage_dir=$1

  run_root install -dm755 "$STATE_DIR"
  (cd "$stage_dir" && find . \( -type f -o -type l \) | sed 's|^\.||') \
    | run_root tee "$LIBRESWAN_MANIFEST" >/dev/null
}

# Builds the latest libreswan release from its signed tarball and installs it.
build_libreswan() {
  local tag version build_dir source_dir stage_dir

  if ! tag=$(latest_libreswan_tag); then
    log_error setup "Could not find the latest libreswan release"
    return 1
  fi
  version=${tag#v}
  log_info setup "Latest libreswan release is $tag"

  log_info setup "Building libreswan $version from source (this takes a few minutes)"
  build_dir=$(mktemp -d)
  fetch_libreswan_source "$build_dir" "$version" "$tag"
  source_dir="$build_dir/libreswan-$version"
  stage_dir="$build_dir/stage"

  make -C "$source_dir" programs "${LIBRESWAN_ARGS[@]}" CFLAGS="$LIBRESWAN_CFLAGS"
  make -C "$source_dir" install DESTDIR="$stage_dir" "${LIBRESWAN_ARGS[@]}" CFLAGS="$LIBRESWAN_CFLAGS"
  write_libreswan_manifest "$stage_dir"
  run_root cp -a --no-preserve=ownership "$stage_dir"/. /
  run_root install -dm700 /var/lib/ipsec/nss
  rm -rf "$build_dir"
  log_info setup "libreswan installed"
}

# Libreswan 5 drops IKEv1 by default; the KMITL server needs it.
enable_ikev1_policy() {
  run_root sed -i 's/^[[:space:]]*#*[[:space:]]*ikev1-policy=.*/\tikev1-policy=accept/' /etc/ipsec.conf
  if ! grep -qE '^[[:space:]]*ikev1-policy=accept' /etc/ipsec.conf; then
    log_error setup "Could not set ikev1-policy=accept in /etc/ipsec.conf"
    return 1
  fi
}

# Older setup installed libreswan files as the user; the daemon must not run files a user can change.
repair_libreswan_owner() {
  local path
  local paths=()

  if [[ ! -f "$LIBRESWAN_MANIFEST" ]]; then
    return 0
  fi

  while IFS= read -r path; do
    if [[ -z "$path" ]]; then continue; fi
    if [[ -e "$path" || -L "$path" ]] && [[ -O "$path" ]]; then
      paths+=("$path")
    fi
  done <"$LIBRESWAN_MANIFEST"

  if (( ${#paths[@]} == 0 )); then
    return 0
  fi

  log_info setup "Fixing owner of ${#paths[@]} libreswan files to root"
  run_root chown -h root:root -- "${paths[@]}"
}

# Removes the libreswan files listed in the manifest. Distro packages are kept.
remove_libreswan_files() {
  local path

  if [[ ! -f "$LIBRESWAN_MANIFEST" ]]; then
    log_info vpn "No libreswan install record found, skipping"
    return 0
  fi

  while IFS= read -r path; do
    if [[ -z "$path" ]]; then continue; fi
    if [[ -f "$path" || -L "$path" ]]; then
      run_root rm -f -- "$path"
    fi
  done <"$LIBRESWAN_MANIFEST"

  run_root rm -f "$LIBRESWAN_MANIFEST"
  run_root rmdir --ignore-fail-on-non-empty "$STATE_DIR" 2>/dev/null || true
}
