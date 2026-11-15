[Back to README](../README.md)

# Usage

Run every command from the project folder:

```bash
./kmitl-vpn <command>
```

## setup

Installs what is missing and creates the VPN profile. See [Install](install.md).

```bash
./kmitl-vpn setup
```

- Setup asks for the username, then the password. The password is hidden while you type.
- Running setup again replaces the old `kmitl-vpn` profile.

## connect

```bash
./kmitl-vpn connect
```

## disconnect

```bash
./kmitl-vpn disconnect
```

## status

```bash
./kmitl-vpn status
```

| Output | Meaning |
| --- | --- |
| `connected` | The VPN is up |
| `disconnected` | The profile exists, but the VPN is down |
| `not set up` | Setup has not run yet |

## routes

Sets which traffic goes through the VPN. See [How it works](how-it-works.md#split-tunnel-and-full-tunnel) for the difference.

| Command | Result |
| --- | --- |
| `./kmitl-vpn routes` | Shows the mode and the networks |
| `./kmitl-vpn routes 161.246.166.0/24 161.246.127.0/24` | Split tunnel with these networks |
| `./kmitl-vpn routes 161.246.166.0/24,161.246.127.0/24` | Same as above, comma form |
| `./kmitl-vpn routes all` | Full tunnel: all traffic uses the VPN |

Rules:

- Spaces or commas both work.
- Networks use the form `a.b.c.d/n`, such as `161.246.166.0/24`. This is called CIDR. The number after the slash sets the size of the range.
- The list you give replaces the old list.
- Invalid networks are rejected with `Invalid network: ...`. Example: `300.1.1.1/24`.
- If the VPN is connected, it reconnects to apply the change.

## uninstall

```bash
./kmitl-vpn uninstall
```

| Removes | Keeps |
| --- | --- |
| The VPN is disconnected if it is up | NetworkManager |
| The `kmitl-vpn` profile, with the saved username and password | Other distro packages, such as xl2tpd |
| The libreswan files listed in the install record | |

> [!NOTE]
> The install record is `/var/lib/kmitl-vpn/libreswan.files`. It lists every libreswan file that setup installed.

## help

```bash
./kmitl-vpn help
```
