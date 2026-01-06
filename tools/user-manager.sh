#!/bin/bash
# User Management Tool

CONFIG_DIR="/etc/zivpn"

case "$1" in
    add)
        echo "Adding user..."
        # Add user logic
        ;;
    list)
        echo "Listing users..."
        ls $CONFIG_DIR/users/*.json | while read file; do
            username=$(basename $file .json)
            expiry=$(jq -r '.expiry' $file)
            echo "$username - Expiry: $expiry"
        done
        ;;
    *)
        echo "Usage: $0 {add|list|delete|renew}"
        exit 1
        ;;
esac
