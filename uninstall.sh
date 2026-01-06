#!/bin/bash
# ZiVPN Manager Uninstaller

echo -e "\033[1;31m"
echo "╔════════════════════════════════════════╗"
echo "║       ZiVPN Manager Uninstaller       ║"
echo "╚════════════════════════════════════════╝"
echo -e "\033[0m"

read -p "Are you sure? This will remove all ZiVPN files! (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 1
fi

# Stop services
systemctl stop udp-custom
systemctl disable udp-custom

# Remove files
rm -f /usr/local/bin/udp-custom
rm -f /usr/local/bin/zivpn
rm -f /usr/bin/zivpn
rm -rf /etc/zivpn
rm -f /etc/udp-custom.json
rm -f /etc/systemd/system/udp-custom.service

# Remove crontab entries
crontab -l | grep -v '/etc/zivpn' | crontab -

echo ""
echo -e "\033[1;32mZiVPN Manager has been completely removed.\033[0m"
echo "You may want to manually remove firewall rules."
