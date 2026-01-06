#!/bin/bash
# ZiVPN Manager Xtreme Installer

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}"
cat << "EOF"
 ███████╗██╗██╗   ██╗███╗   ██╗██████╗ 
╚══███╔╝██║██║   ██║████╗  ██║██╔══██╗
  ███╔╝ ██║██║   ██║██╔██╗ ██║██║  ██║
 ███╔╝  ██║██║   ██║██║╚██╗██║██║  ██║
███████╗██║╚██████╔╝██║ ╚████║██████╔╝
╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ 
EOF
echo -e "╔══════════════════════════════════════════════╗"
echo -e "║          ZiVPN Manager Xtreme               ║"
echo -e "║           Installation Script               ║"
echo -e "╚══════════════════════════════════════════════╝${NC}"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root: sudo -i ${NC}"
    exit 1
fi

# Update system
echo -e "${YELLOW}[1/6] Updating system...${NC}"
apt update -y
apt upgrade -y

# Install dependencies
echo -e "${YELLOW}[2/6] Installing dependencies...${NC}"
apt install -y \
    curl wget git jq \
    net-tools ufw \
    screen htop \
    python3 python3-pip \
    openssl

# Install UDP Custom
echo -e "${YELLOW}[3/6] Installing UDP Custom...${NC}"
wget -O /usr/local/bin/udp-custom \
    "https://raw.githubusercontent.com/Haris131/UDP-Custom/main/udp-custom-linux-amd64"
chmod +x /usr/local/bin/udp-custom

# Create directories
echo -e "${YELLOW}[4/6] Creating directories...${NC}"
mkdir -p /etc/zivpn
mkdir -p /etc/zivpn/users
mkdir -p /etc/zivpn/configs
mkdir -p /etc/zivpn/backup
mkdir -p /var/log/zivpn

# Download main script
echo -e "${YELLOW}[5/6] Installing ZiVPN Manager...${NC}"
wget -O /usr/local/bin/zivpn \
    "https://raw.githubusercontent.com/shwtrya/vpnmanager/main/zivpn-manager.sh"
chmod +x /usr/local/bin/zivpn

# Create config files
cat > /etc/zivpn/settings.json << EOF
{
    "version": "3.0",
    "server_ip": "$(curl -s ifconfig.me)",
    "default_port": "20801",
    "default_method": "chacha20-ietf-poly1305",
    "default_obfs": "zivpn",
    "auto_backup": true,
    "backup_days": 7
}
EOF

cat > /etc/udp-custom.json << EOF
{
    "servers": [
        {
            "listen": ":20801",
            "protocol": "udp",
            "obfs": "zivpn",
            "timeout": 300
        },
        {
            "listen": ":20802",
            "protocol": "ws",
            "obfs": "plain",
            "timeout": 300
        }
    ],
    "users": []
}
EOF

# Create systemd service
cat > /etc/systemd/system/udp-custom.service << EOF
[Unit]
Description=UDP Custom Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/udp-custom -config /etc/udp-custom.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable firewall
echo -e "${YELLOW}[6/6] Configuring firewall...${NC}"
ufw allow 22/tcp
ufw allow 20801:20803/udp
ufw allow 20801:20803/tcp
ufw --force enable

# Start services
systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗"
echo -e "║     INSTALLATION COMPLETE!              ║"
echo -e "╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "Usage: ${YELLOW}zivpn${NC} to start the manager"
echo -e "Server IP: $(curl -s ifconfig.me)"
echo -e "Ports: 20801 (ZiVPN), 20802 (WebSocket)"
echo ""
echo -e "${YELLOW}Rebooting in 5 seconds...${NC}"
sleep 5
reboot
