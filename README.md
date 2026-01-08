# GMS Version Locker

A Magisk module that automatically locks Google Play Services to version 25.49.32 and prevents auto-updates.

## What it does

1. **Checks on every boot** which version of GMS is installed
2. **If the version exceeds 25.49.32**, it automatically:
   - Uninstalls the user-installed version (from `/data/app/`)
   - Falls back to the system version (23.37.17 from `/product/priv-app/`)
   - Triggers a reboot
3. **Disables update services** that would otherwise auto-update GMS:
   - `com.google.android.gms.update.SystemUpdatePersistentListenerService`
   - `com.google.android.gms.update.SystemUpdateService`

## Installation

1. Download/zip the module files
2. Flash via Magisk Manager
3. Reboot

## Logs

Check the script execution logs at:
```
/data/local/tmp/fgms.log
```

## How it works

- The script runs after boot completes (`service.sh`)
- It compares the active GMS version against the target (25.49.32)
- If both versions exist, it uses whichever is higher
- If the active version is above the target, it uninstalls the user version and reboots
- Update services are disabled to prevent future auto-updates

## Customization

To change the target version, edit `service.sh` and change:
```bash
TARGET="25.49.32"
```

to your desired version.
