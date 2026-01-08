#!/system/bin/sh
MODDIR="${0%/*}"
LOGFILE="/data/local/tmp/fgms.log"

echo "$(date): GMS Lock script started" >> $LOGFILE

# Load config file from /data/local/tmp (user-editable location)
CONFIG_FILE="/data/local/tmp/stayGMS_config.sh"
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
    echo "$(date): Loaded config from $CONFIG_FILE" >> $LOGFILE
else
    # Copy default config if it doesn't exist
    if [ -f "$MODDIR/config.sh" ]; then
        cp "$MODDIR/config.sh" "$CONFIG_FILE"
        echo "$(date): Created default config at $CONFIG_FILE" >> $LOGFILE
        . "$CONFIG_FILE"
    else
        echo "$(date): Config not found, using default" >> $LOGFILE
    fi
fi

# Default target version if not set in config
TARGET="${TARGET_VERSION:-25.49.32}"

# Get both versions
VERSION_DATA=$(dumpsys package com.google.android.gms | grep "codePath=/data/app" -A 1 | grep versionName | grep -oP '\d+\.\d+\.\d+' | head -1)
VERSION_SYSTEM=$(dumpsys package com.google.android.gms | grep "codePath=/product/priv-app" -A 1 | grep versionName | grep -oP '\d+\.\d+\.\d+' | head -1)

# Determine which version is active (higher one)
if [ -z "$VERSION_DATA" ]; then
    ACTIVE_VERSION="$VERSION_SYSTEM"
elif [ -z "$VERSION_SYSTEM" ]; then
    ACTIVE_VERSION="$VERSION_DATA"
else
    ACTIVE_VERSION=$([ "$VERSION_DATA" \> "$VERSION_SYSTEM" ] && echo "$VERSION_DATA" || echo "$VERSION_SYSTEM")
fi

echo "Active: $ACTIVE_VERSION, System: $VERSION_SYSTEM, Data: $VERSION_DATA" >> $LOGFILE

# If active version is above target, uninstall user version and reboot
if [ -n "$ACTIVE_VERSION" ] && [ "$ACTIVE_VERSION" \> "$TARGET" ]; then
    echo "$(date): Version $ACTIVE_VERSION exceeds target $TARGET. Uninstalling user version..." >> $LOGFILE
    pm uninstall --user 0 com.google.android.gms
    echo "$(date): Rebooting..." >> $LOGFILE
    reboot
    exit 0
fi

# Disable update services to prevent auto-updates
echo "$(date): Ensuring update services are disabled..." >> $LOGFILE

pm disable --user 0 com.google.android.gms/.update.SystemUpdatePersistentListenerService 2>/dev/null
if [ $? -eq 0 ]; then
    echo "$(date): Disabled SystemUpdatePersistentListenerService" >> $LOGFILE
fi

pm disable --user 0 com.google.android.gms/.update.SystemUpdateService 2>/dev/null
if [ $? -eq 0 ]; then
    echo "$(date): Disabled SystemUpdateService" >> $LOGFILE
fi

echo "$(date): Script completed successfully. Current version: $ACTIVE_VERSION" >> $LOGFILE
