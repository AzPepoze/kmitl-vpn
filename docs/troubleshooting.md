[Back to README](../README.md)

# Troubleshooting

## Error messages

| Message or symptom | Cause | Fix |
| --- | --- | --- |
| `global ikev1-policy=drop does not allow IKEv1 connections` | libreswan 5 blocks IKEv1 by default | Run `./kmitl-vpn setup` again. It sets `ikev1-policy=accept`. |
| `The VPN service failed to start` | Any IPsec failure | Read the logs (see below). Look for `pluto` lines. |
| `No kmitl-vpn profile. Run: kmitl-vpn setup` | Setup has not run yet | Run `./kmitl-vpn setup`. |
| `Invalid network: ...` | Bad network format in `routes` | Use a form like `161.246.166.0/24`. |
| `Could not find the latest libreswan release` | GitHub cannot be reached | Check your internet connection and try again. |
| `libreswan signature check failed` | The download is corrupted or changed | Run setup again. Do not skip the check. |

## Read the logs

Show the latest system log entries:

```bash
journalctl -xe
```

Show NetworkManager entries from the last 10 minutes:

```bash
journalctl -u NetworkManager --since "10 min ago"
```

> [!TIP]
> Look for `pluto` lines. They show the IPsec step that failed.

## Known limits

- Only Arch-family distros are checked so far. Other distros use the same steps, but package names may need changes.
- openSUSE: the build dependency list is not complete, so the build may fail.

> [!IMPORTANT]
> Run the script as your normal user. It calls `sudo` by itself.
