[Back to README](../README.md)

# Development

## Files

| Path | What it is |
| --- | --- |
| `kmitl-vpn` | Entry point. Finds the lib folder and runs `main` |
| `lib/log.sh` | Logger: colors, levels, categories |
| `lib/common.sh` | Shared constants and helpers |
| `lib/packages.sh` | Package manager detection and installs |
| `lib/libreswan.sh` | Builds and removes libreswan |
| `lib/profile.sh` | NetworkManager profile and reconnect |
| `lib/routes.sh` | Network checks and route changes |
| `lib/commands.sh` | One function per command, and `main` |
| `docs/` | Documentation pages |
| `README.md` | Front page |

The entry script loads the lib files in this order: `log`, `common`, `packages`, `libreswan`, `profile`, `routes`, `commands`.

## Checks after an edit

```bash
bash -n kmitl-vpn lib/*.sh
./kmitl-vpn help
./kmitl-vpn status
```

To check that every function loads, source the lib files from the project folder and run `type`:

```bash
cd /path/to/kmitl-vpn
for f in lib/log.sh lib/common.sh lib/packages.sh lib/libreswan.sh lib/profile.sh lib/routes.sh lib/commands.sh; do
  source "$f"
done
type cmd_setup
```

> [!WARNING]
> `setup`, `connect`, and `uninstall` change the system. Run them only on a test machine.

## Conventions

- Use small named functions.
- Every log line has a level, a timestamp, and a category (for example `setup`, `vpn`, or `cli`).
- Colors are used only when the output is a terminal. Setting `NO_COLOR` turns them off.
- Each category gets the same color every run. The color comes from a hash of the category name.
- Level colors are separate. INFO is green, WARN is yellow, and ERROR is red.
