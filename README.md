# kmitl-vpn

A bash script that sets up and runs the KMITL VPN on Linux.

> [!NOTE]
> A VPN (virtual private network) sends your internet traffic through an encrypted tunnel to another network. This script uses NetworkManager, the Linux service that manages network connections.

## What it does

- Installs the VPN software it needs.
- Asks for your KMITL VPN username and password.
- Creates a VPN profile in NetworkManager.
- Connects and disconnects the VPN.
- Chooses which networks use the VPN.

## Quick start

```bash
./kmitl-vpn setup
./kmitl-vpn connect
./kmitl-vpn disconnect
```

> [!IMPORTANT]
> Run the script as your normal user. It calls `sudo` by itself when it needs root.

## Commands

| Command | What it does |
| --- | --- |
| `setup` | Installs missing packages, asks for username and password, creates the VPN profile |
| `connect` | Connects the VPN |
| `disconnect` | Disconnects the VPN |
| `status` | Shows connected, disconnected, or not set up |
| `routes` | Shows or changes which networks use the VPN |
| `uninstall` | Removes the profile and the libreswan files that setup installed |
| `help` | Shows usage |

## More

| Page | Read it when |
| --- | --- |
| [Install](docs/install.md) | You need the requirements or the list of what gets installed |
| [Usage](docs/usage.md) | You want an example for each command |
| [How it works](docs/how-it-works.md) | You want to know the VPN settings and why they are set |
| [Troubleshooting](docs/troubleshooting.md) | Something fails |
| [Development](docs/development.md) | You want to change the script |
