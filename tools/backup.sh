#!/bin/bash
# Backup Tool for ZiVPN Manager

BACKUP_DIR="/etc/zivpn/backup"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/zivpn-backup-$DATE.tar.gz"

echo "Creating backup..."

# Create backup
tar -czf $BACKUP_FILE \
    /etc/zivpn \
    /etc/udp-custom.json \
    /usr/local/bin/zivpn \
    /usr/local/bin/udp-custom \
    /etc/systemd/system/udp-custom.service 2>/dev/null

if [ $? -eq 0 ]; then
    echo "Backup created: $BACKUP_FILE"
    echo "Size: $(du -h $BACKUP_FILE | cut -f1)"
    
    # Keep only last 7 backups
    ls -t $BACKUP_DIR/zivpn-backup-*.tar.gz | tail -n +8 | xargs rm -f
else
    echo "Backup failed!"
    exit 1
fi
