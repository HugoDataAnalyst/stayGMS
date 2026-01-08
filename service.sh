#!/system/bin/sh
MODDIR="${0%/*}"
LOGFILE="/data/local/tmp/stayGMS.log"

echo "$(date): stayGMS script started" >> $LOGFILE

# Wait for system to be ready (GMS needs time to initialize)
sleep 30

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

# Get GMS package info
GMS_DUMP=$(dumpsys package com.google.android.gms)

# Check if user-installed version exists (in /data/app)
HAS_USER_VERSION=$(echo "$GMS_DUMP" | grep -c "codePath=/data/app")

# Get both versions (first = user/data, second = system/product)
VERSION_USER=$(echo "$GMS_DUMP" | grep "versionName=" | head -1 | sed 's/.*versionName=//' | cut -d' ' -f1)
VERSION_SYSTEM=$(echo "$GMS_DUMP" | grep "versionName=" | tail -1 | sed 's/.*versionName=//' | cut -d' ' -f1)

echo "$(date): User version: '$VERSION_USER', System version: '$VERSION_SYSTEM'" >> $LOGFILE
echo "$(date): Has user-installed update: $HAS_USER_VERSION" >> $LOGFILE

# Safety check: only proceed if system version is at or below target
# This prevents boot loops if even the system version exceeds target
if [ -n "$VERSION_SYSTEM" ] && [ "$VERSION_SYSTEM" \> "$TARGET" ]; then
    echo "$(date): WARNING - System version $VERSION_SYSTEM exceeds target $TARGET. Cannot downgrade system. Skipping." >> $LOGFILE
else
    # Only uninstall if there's a user-installed version AND it exceeds target
    if [ "$HAS_USER_VERSION" -gt 0 ] && [ -n "$VERSION_USER" ] && [ "$VERSION_USER" \> "$TARGET" ]; then
        echo "$(date): User version $VERSION_USER exceeds target $TARGET. Uninstalling user update..." >> $LOGFILE
        pm uninstall --user 0 com.google.android.gms
        echo "$(date): Rebooting to apply system version..." >> $LOGFILE
        reboot
        exit 0
    else
        echo "$(date): Version OK. User: '$VERSION_USER', Target: '$TARGET'" >> $LOGFILE
    fi
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

echo "$(date): Script completed successfully. Active version: $VERSION_USER" >> $LOGFILE
