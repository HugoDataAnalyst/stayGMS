# stayGMS

A Magisk module that automatically locks Google Play Services to a target version and prevents auto-updates.

## What it does

1. **Checks on every boot** which version of GMS is installed
2. **If the version exceeds the target** (default: 25.49.32), it automatically:
   - Uninstalls the user-installed version (from `/data/app/`)
   - Falls back to the system version
   - Triggers a reboot
3. **Disables update services** that would otherwise auto-update GMS

## Installation

1. Download the latest release zip from [Releases](https://github.com/HugoDataAnalyst/stayGMS/releases)
2. Flash via Magisk Manager
3. Reboot

## Configuration

To change the target GMS version, edit the config file:
```
/data/local/tmp/stayGMS_config.sh
```

Set your desired version:
```sh
TARGET_VERSION="25.49.32"
```

The config file is created automatically on first boot. After editing, reboot for changes to take effect.

## Logs

Check the script execution logs at:
```
/data/local/tmp/fgms.log
```

## How it works

- The script runs after boot completes (`service.sh`)
- It compares the active GMS version against the target
- If both system and user versions exist, it uses whichever is higher
- If the active version exceeds the target, it uninstalls the user version and reboots
- Update services are disabled to prevent future auto-updates
