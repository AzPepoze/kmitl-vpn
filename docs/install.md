[Back to README](../README.md)

# Install

Run `setup` once. It installs the software and creates the VPN profile.

## Requirements

| Requirement | Why |
| --- | --- |
| Linux with a supported distro | Setup uses the distro's package manager |
| NetworkManager | Manages the VPN connection. Setup starts it. |
| sudo access | Setup installs packages and system files as root |
| Internet access to GitHub | Setup downloads libreswan from GitHub |
| A KMITL VPN account | You need a username and password |

## Supported distros

| Package manager | Distros |
| --- | --- |
| pacman | Arch, CachyOS, Manjaro, EndeavourOS |
| apt | Debian, Ubuntu, Linux Mint, Pop!_OS |
| dnf | Fedora, RHEL, CentOS, Rocky, Alma |
| zypper | openSUSE, SLES |

> [!NOTE]
> Arch-based distros such as CachyOS use the pacman path.
> Other distros stop with an error.

> [!WARNING]
> openSUSE: the build dependency list is not complete. The build may fail there.

## What setup installs

- **NetworkManager** and its **L2TP plugin**. L2TP is the tunnel protocol the VPN uses.
- **xl2tpd**. An L2TP daemon, the program that runs the tunnel.
- **ppp** (pacman only). The point-to-point protocol tools.
- **Build tools and libraries**. These are needed to compile libreswan.
- **libreswan**. The IPsec program, built from source. IPsec encrypts the tunnel.

Setup also removes **strongSwan** and **openswan** if they are installed. They conflict with libreswan.

For the full list of steps, see [How it works](how-it-works.md).

## Run setup

```bash
./kmitl-vpn setup
```

- Setup asks for your sudo password when it installs packages. This is normal.
- Building libreswan takes a few minutes.
- Setup then asks for your VPN username and password.

## Remove

Run `./kmitl-vpn uninstall`. See [Usage](usage.md#uninstall).
