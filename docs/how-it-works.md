[Back to README](../README.md)

# How it works

## Overview

```
Your computer
     |  encrypted L2TP over IPsec
     v
myvpn.kmitl.ac.th  (KMITL VPN server)
     |
     v
KMITL networks
```

## Terms

| Term | Plain meaning |
| --- | --- |
| VPN | Virtual private network. An encrypted tunnel to another network. |
| L2TP | Layer 2 Tunneling Protocol. The tunnel that carries the VPN traffic. |
| IPsec | IP Security. Encrypts the L2TP traffic. |
| PSK | Pre-shared key. A secret that both sides know. |
| IKEv1 | Version 1 of the IPsec key exchange. The KMITL server needs it. |
| libreswan | An IPsec program. The script uses it. |
| strongSwan | Another IPsec program. The script removes it. |
| NetworkManager | The Linux service that manages network connections. |
| Split tunnel | Only some networks use the VPN. |
| Full tunnel | All traffic uses the VPN. |
| DNS | Turns site names, such as `example.com`, into addresses. |

## Profile settings

The `kmitl-vpn` profile in NetworkManager has these settings.

| Setting | Value |
| --- | --- |
| Type | L2TP over IPsec, using the NetworkManager L2TP plugin |
| Server (gateway) | `myvpn.kmitl.ac.th` |
| IPsec mode | Pre-shared key (PSK). The value `kmitl2vpn` comes from KMITL's public VPN guide. |
| Username and password | Entered during setup. Stored by NetworkManager. |
| Default routing | Split tunnel. Only the default networks use the VPN. |
| Default networks | `161.246.166.0/24`, `161.246.127.0/24`, `10.252.0.0/16`, `10.128.0.0/16` |

## Split tunnel and full tunnel

```
Split tunnel (default)

  campus network   ---->  VPN  ---->  KMITL
  other websites   ---->  normal internet

Full tunnel (routes all)

  every website    ---->  VPN  ---->  internet
```

| | Split tunnel | Full tunnel |
| --- | --- | --- |
| Command | `routes <network>...` | `routes all` |
| Traffic through the VPN | Only the listed networks | All traffic |
| DNS server | Not changed. Normal sites keep normal DNS. | `161.246.52.21` |
| Campus-only names | May not resolve | Resolve |

> [!NOTE]
> In split mode, the script does not set the VPN DNS. Campus-only names may not resolve.

## Setup steps

1. Reads `/etc/os-release` to find the distro and its package manager.
2. Removes strongSwan and openswan if they are installed. It prints a warning first.
3. Installs the tools and libraries needed to build libreswan.
4. Installs NetworkManager, its L2TP plugin, xl2tpd, and ppp (pacman only).
5. Downloads the latest libreswan release from GitHub, checks its signature, builds it, and installs it.
6. Writes a list of every installed file to `/var/lib/kmitl-vpn/libreswan.files`.
7. Sets `ikev1-policy=accept` in `/etc/ipsec.conf`.
8. Changes the owner of the libreswan files that your user owns to root.
9. Starts NetworkManager if it is not running, and enables it.
10. Asks for the VPN username and password. The password is hidden while you type.
11. Creates the `kmitl-vpn` profile.

## Why libreswan and not strongSwan

- strongSwan 6 without IKEv1 fails with `IKE version 1 not supported`.
- libreswan 5 blocks IKEv1 by default. Setup sets `ikev1-policy=accept` to allow it.
- Both programs provide the `ipsec` command, so they cannot be installed together.

## Signature check

Setup checks the libreswan download before it builds.

- It downloads the release tarball, its signature, and the upstream key.
- It imports the key into a temporary keyring. Your own keyring is not changed.
- If the check fails, setup stops with `libreswan signature check failed`.

## Install record

`/var/lib/kmitl-vpn/libreswan.files` lists every file that setup installed. `uninstall` uses it to remove those files. Distro packages are not listed.

## File owner

The IPsec daemon must not run files that a normal user can change. Setup therefore sets the owner of the libreswan files to root.
