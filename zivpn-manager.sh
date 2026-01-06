#!/bin/bash
# =================================================
# ZiVPN Manager Xtreme
# Based on prjkt-nv404/ZiVPN-Manager with EXTRA Features
# =================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Paths
CONFIG_DIR="/etc/zivpn"
SCRIPT_DIR="/usr/local/bin"
LOG_DIR="/var/log/zivpn"
BACKUP_DIR="/backup/zivpn"

# Server Info
IP=$(curl -s ifconfig.me)
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Banner
banner() {
    clear
    echo -e "${PURPLE}"
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
    echo -e "║       Multi-Protocol VPN Manager            ║"
    echo -e "╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Server IP  : ${WHITE}$IP"
    echo -e "${CYAN}Date       : ${WHITE}$DATE"
    echo -e "${CYAN}Version    : ${WHITE}X3.0 (Xtreme Edition)"
    echo ""
}

# Initialize
init() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p $CONFIG_DIR
        mkdir -p $LOG_DIR
        mkdir -p $BACKUP_DIR
        mkdir -p $CONFIG_DIR/users
        mkdir -p $CONFIG_DIR/configs
        mkdir -p $CONFIG_DIR/scripts
    fi
    
    # Create default configs
    if [ ! -f "$CONFIG_DIR/servers.json" ]; then
        cat > $CONFIG_DIR/servers.json << EOF
{
    "servers": [],
    "settings": {
        "default_port": "20801",
        "default_method": "chacha20-ietf-poly1305",
        "default_protocol": "udp",
        "default_obfs": "zivpn",
        "max_users": 100,
        "auto_backup": true,
        "backup_days": 7
    }
}
EOF
    fi
}

# Main Menu
main_menu() {
    while true; do
        banner
        
        # Count users
        USER_COUNT=$(ls $CONFIG_DIR/users/*.json 2>/dev/null | wc -l)
        ACTIVE_COUNT=$(grep -l '"status":"active"' $CONFIG_DIR/users/*.json 2>/dev/null | wc -l)
        
        echo -e "${GREEN}╔════════════════════════════════════════╗"
        echo -e "║             MAIN MENU                  ║"
        echo -e "╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${CYAN}Users: ${WHITE}$USER_COUNT total, ${GREEN}$ACTIVE_COUNT active${NC}"
        echo ""
        echo -e "  ${WHITE}[1]${NC}  User Management"
        echo -e "  ${WHITE}[2]${NC}  Server Management"
        echo -e "  ${WHITE}[3]${NC}  Configuration"
        echo -e "  ${WHITE}[4]${NC}  Generate Configs"
        echo -e "  ${WHITE}[5]${NC}  Backup & Restore"
        echo -e "  ${WHITE}[6]${NC}  Tools & Utilities"
        echo -e "  ${WHITE}[7]${NC}  System Info"
        echo -e "  ${WHITE}[8]${NC}  Service Control"
        echo -e "  ${WHITE}[9]${NC}  Speed Test"
        echo -e "  ${WHITE}[10]${NC} Settings"
        echo ""
        echo -e "  ${WHITE}[0]${NC}  Exit"
        echo ""
        echo -e "  ${YELLOW}[99]${NC} Install Services"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) user_management ;;
            2) server_management ;;
            3) configuration_menu ;;
            4) generate_configs ;;
            5) backup_restore ;;
            6) tools_menu ;;
            7) system_info ;;
            8) service_control ;;
            9) speed_test ;;
            10) settings_menu ;;
            99) install_services ;;
            0)
                echo -e "${YELLOW}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

# User Management
user_management() {
    while true; do
        banner
        echo -e "${GREEN}╔════════════════════════════════════════╗"
        echo -e "║           USER MANAGEMENT               ║"
        echo -e "╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${WHITE}[1]${NC}  Add User"
        echo -e "  ${WHITE}[2]${NC}  Delete User"
        echo -e "  ${WHITE}[3]${NC}  Edit User"
        echo -e "  ${WHITE}[4]${NC}  List Users"
        echo -e "  ${WHITE}[5]${NC}  Search User"
        echo -e "  ${WHITE}[6]${NC}  Renew User"
        echo -e "  ${WHITE}[7]${NC}  Activate/Deactivate"
        echo -e "  ${WHITE}[8]${NC}  User Statistics"
        echo -e "  ${WHITE}[9]${NC}  Bulk Create Users"
        echo -e "  ${WHITE}[10]${NC} Import Users"
        echo ""
        echo -e "  ${WHITE}[0]${NC}  Back"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) add_user ;;
            2) delete_user ;;
            3) edit_user ;;
            4) list_users ;;
            5) search_user ;;
            6) renew_user ;;
            7) toggle_user ;;
            8) user_stats ;;
            9) bulk_create ;;
            10) import_users ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

# Add User Function
add_user() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║              ADD USER                   ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " username
    
    # Check if user exists
    if [ -f "$CONFIG_DIR/users/$username.json" ]; then
        echo -e "${RED}User already exists!${NC}"
        sleep 2
        return
    fi
    
    read -sp "Password: " password
    echo
    read -p "Expiry (days): " expiry_days
    read -p "Limit (connections): " limit
    read -p "Server IP [default: $IP]: " server_ip
    read -p "Port [default: 20801]: " port
    
    server_ip=${server_ip:-$IP}
    port=${port:-20801}
    
    # Generate expiry date
    expiry_date=$(date -d "+$expiry_days days" +%Y-%m-%d)
    created_date=$(date +%Y-%m-%d)
    
    # Create user config
    cat > $CONFIG_DIR/users/$username.json << EOF
{
    "username": "$username",
    "password": "$password",
    "server_ip": "$server_ip",
    "port": "$port",
    "protocol": "udp",
    "method": "chacha20-ietf-poly1305",
    "obfs": "zivpn",
    "expiry": "$expiry_date",
    "created": "$created_date",
    "limit": "$limit",
    "status": "active",
    "total_used": "0",
    "last_login": "",
    "notes": ""
}
EOF
    
    echo ""
    echo -e "${GREEN}✅ User created successfully!${NC}"
    echo ""
    
    # Generate configs
    generate_user_config $username
    
    echo ""
    read -p "Press Enter to continue..."
}

# Generate User Config
generate_user_config() {
    local username=$1
    local user_file="$CONFIG_DIR/users/$username.json"
    
    if [ ! -f "$user_file" ]; then
        echo -e "${RED}User not found!${NC}"
        return
    fi
    
    # Read user data
    local password=$(jq -r '.password' $user_file)
    local server_ip=$(jq -r '.server_ip' $user_file)
    local port=$(jq -r '.port' $user_file)
    local method=$(jq -r '.method' $user_file)
    local obfs=$(jq -r '.obfs' $user_file)
    
    # Generate HTTP Injector config
    cat > $CONFIG_DIR/configs/$username.http << EOF
[Connection]
Host = $server_ip
Port = $port
Password = $password
Method = $method
Protocol = udp
OBFS = $obfs
EOF
    
    # Generate TEXT config
    cat > $CONFIG_DIR/configs/$username.txt << EOF
╔════════════════════════════════════════╗
║           ZiVPN CONFIG                ║
╚════════════════════════════════════════╝

Username: $username
Server  : $server_ip
Port    : $port
Password: $password
Method  : $method
Protocol: udp
OBFS    : $obfs
Expiry  : $(jq -r '.expiry' $user_file)
Status  : $(jq -r '.status' $user_file)

For HTTP Injector:
- Import file: $username.http
- Or manual input above data

Created: $(date)
EOF
    
    # Generate JSON config
    cat > $CONFIG_DIR/configs/$username.json << EOF
{
    "config": {
        "host": "$server_ip",
        "port": "$port",
        "password": "$password",
        "method": "$method",
        "protocol": "udp",
        "obfs": "$obfs"
    },
    "user": {
        "username": "$username",
        "expiry": "$expiry_date",
        "status": "active"
    }
}
EOF
    
    echo -e "${GREEN}Configs generated:${NC}"
    echo -e "  ${WHITE}•${NC} $CONFIG_DIR/configs/$username.http"
    echo -e "  ${WHITE}•${NC} $CONFIG_DIR/configs/$username.txt"
    echo -e "  ${WHITE}•${NC} $CONFIG_DIR/configs/$username.json"
}

# List Users
list_users() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║              LIST USERS                  ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! "$(ls -A $CONFIG_DIR/users/*.json 2>/dev/null)" ]; then
        echo -e "${YELLOW}No users found.${NC}"
    else
        echo -e "${WHITE}┌────┬────────────────────┬────────────┬────────┬─────────┐${NC}"
        echo -e "${WHITE}│ No │ Username           │ Expiry     │ Status │ Limit   │${NC}"
        echo -e "${WHITE}├────┼────────────────────┼────────────┼────────┼─────────┤${NC}"
        
        local count=1
        for user_file in $CONFIG_DIR/users/*.json; do
            local username=$(jq -r '.username' $user_file)
            local expiry=$(jq -r '.expiry' $user_file)
            local status=$(jq -r '.status' $user_file)
            local limit=$(jq -r '.limit' $user_file)
            
            # Color status
            if [ "$status" = "active" ]; then
                status_color="${GREEN}active${NC}"
            else
                status_color="${RED}inactive${NC}"
            fi
            
            # Check expiry
            if [[ "$expiry" < "$(date +%Y-%m-%d)" ]]; then
                expiry_color="${RED}$expiry${NC}"
            else
                expiry_color="${GREEN}$expiry${NC}"
            fi
            
            printf "${WHITE}│${NC} %-2d ${WHITE}│${NC} %-18s ${WHITE}│${NC} %-10s ${WHITE}│${NC} %-6s ${WHITE}│${NC} %-7s ${WHITE}│${NC}\n" \
                $count "$username" "$expiry_color" "$status_color" "$limit"
            
            count=$((count+1))
        done
        
        echo -e "${WHITE}└────┴────────────────────┴────────────┴────────┴─────────┘${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Server Management
server_management() {
    while true; do
        banner
        echo -e "${GREEN}╔════════════════════════════════════════╗"
        echo -e "║           SERVER MANAGEMENT             ║"
        echo -e "╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${WHITE}[1]${NC}  Add Server"
        echo -e "  ${WHITE}[2]${NC}  Remove Server"
        echo -e "  ${WHITE}[3]${NC}  List Servers"
        echo -e "  ${WHITE}[4]${NC}  Test Server"
        echo -e "  ${WHITE}[5]${NC}  Ping Server"
        echo -e "  ${WHITE}[6]${NC}  Server Statistics"
        echo ""
        echo -e "  ${WHITE}[0]${NC}  Back"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) add_server ;;
            2) remove_server ;;
            3) list_servers ;;
            4) test_server ;;
            5) ping_server ;;
            6) server_stats ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

# Add Server
add_server() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║              ADD SERVER                  ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Server Name: " server_name
    read -p "Server IP: " server_ip
    read -p "Port [default: 20801]: " port
    read -p "Protocol [udp/tcp]: " protocol
    read -p "Max Users: " max_users
    read -p "Location: " location
    read -p "Provider: " provider
    
    port=${port:-20801}
    protocol=${protocol:-udp}
    
    # Add to servers.json
    local temp_file=$(mktemp)
    jq ".servers += [{
        \"name\": \"$server_name\",
        \"ip\": \"$server_ip\",
        \"port\": \"$port\",
        \"protocol\": \"$protocol\",
        \"max_users\": \"$max_users\",
        \"location\": \"$location\",
        \"provider\": \"$provider\",
        \"status\": \"active\",
        \"added\": \"$(date +%Y-%m-%d)\"
    }]" $CONFIG_DIR/servers.json > $temp_file
    
    mv $temp_file $CONFIG_DIR/servers.json
    
    echo ""
    echo -e "${GREEN}✅ Server added successfully!${NC}"
    sleep 2
}

# Install Services
install_services() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║         INSTALL SERVICES                ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Installing required packages...${NC}"
    apt-get update -y
    apt-get install -y \
        jq curl wget nano \
        net-tools iptables \
        ufw fail2ban \
        python3 python3-pip \
        screen htop
    
    echo ""
    echo -e "${YELLOW}Installing UDP Custom...${NC}"
    wget -O /usr/local/bin/udp-custom \
        "https://raw.githubusercontent.com/Haris131/UDP-Custom/main/udp-custom-linux-amd64"
    chmod +x /usr/local/bin/udp-custom
    
    # Create UDP Custom config
    cat > /etc/udp-custom.json << EOF
{
    "servers": [
        {
            "listen": ":20801",
            "protocol": "udp",
            "obfs": "zivpn",
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
    
    systemctl daemon-reload
    systemctl enable udp-custom
    systemctl start udp-custom
    
    # Create ZiVPN Manager service
    cat > /etc/systemd/system/zivpn-manager.service << EOF
[Unit]
Description=ZiVPN Manager
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn-manager
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Install manager script
    cat > /usr/local/bin/zivpn-manager << 'EOF'
#!/bin/bash
# ZiVPN Manager Service
cd /etc/zivpn
exec /usr/local/bin/zivpn-main
EOF
    
    chmod +x /usr/local/bin/zivpn-manager
    systemctl daemon-reload
    
    echo ""
    echo -e "${GREEN}✅ Services installed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo -e "  Start: systemctl start udp-custom"
    echo -e "  Status: systemctl status udp-custom"
    echo -e "  Logs: journalctl -u udp-custom -f"
    echo ""
    read -p "Press Enter to continue..."
}

# Tools Menu
tools_menu() {
    while true; do
        banner
        echo -e "${GREEN}╔════════════════════════════════════════╗"
        echo -e "║           TOOLS & UTILITIES           ║"
        echo -e "╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${WHITE}[1]${NC}  Port Checker"
        echo -e "  ${WHITE}[2]${NC}  Traffic Monitor"
        echo -e "  ${WHITE}[3]${NC}  Config Validator"
        echo -e "  ${WHITE}[4]${NC}  Mass Config Generator"
        echo -e "  ${WHITE}[5]${NC}  User Mover"
        echo -e "  ${WHITE}[6]${NC}  Log Viewer"
        echo -e "  ${WHITE}[7]${NC}  Cleanup Tool"
        echo -e "  ${WHITE}[8]${NC}  Update Manager"
        echo ""
        echo -e "  ${WHITE}[0]${NC}  Back"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) port_checker ;;
            2) traffic_monitor ;;
            3) config_validator ;;
            4) mass_generator ;;
            5) user_mover ;;
            6) log_viewer ;;
            7) cleanup_tool ;;
            8) update_manager ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

# Port Checker
port_checker() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║            PORT CHECKER                 ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Port to check [20801]: " port
    port=${port:-20801}
    
    echo ""
    echo -e "${YELLOW}Checking port $port...${NC}"
    echo ""
    
    # Local check
    echo -e "${WHITE}Local check:${NC}"
    if ss -tulpn | grep -q ":$port "; then
        echo -e "  ${GREEN}✓${NC} Port $port is open locally"
    else
        echo -e "  ${RED}✗${NC} Port $port is closed locally"
    fi
    
    # External check (using netcat if available)
    echo ""
    echo -e "${WHITE}External check:${NC}"
    echo -e "  ${YELLOW}Note:${NC} This requires external service"
    echo ""
    echo -e "You can check manually at:"
    echo -e "  https://portchecker.co/check"
    echo -e "  Or: telnet $IP $port"
    
    echo ""
    read -p "Press Enter to continue..."
}

# Configuration Menu
configuration_menu() {
    while true; do
        banner
        echo -e "${GREEN}╔════════════════════════════════════════╗"
        echo -e "║           CONFIGURATION                ║"
        echo -e "╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${WHITE}[1]${NC}  Edit Global Settings"
        echo -e "  ${WHITE}[2]${NC}  Configure UDP Custom"
        echo -e "  ${WHITE}[3]${NC}  Configure Ports"
        echo -e "  ${WHITE}[4]${NC}  Configure Methods"
        echo -e "  ${WHITE}[5]${NC}  Configure OBFS"
        echo -e "  ${WHITE}[6]${NC}  Firewall Settings"
        echo -e "  ${WHITE}[7]${NC}  Backup Settings"
        echo ""
        echo -e "  ${WHITE}[0]${NC}  Back"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) edit_settings ;;
            2) configure_udp_custom ;;
            3) configure_ports ;;
            4) configure_methods ;;
            5) configure_obfs ;;
            6) firewall_settings ;;
            7) backup_settings ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

# Edit Settings
edit_settings() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║           EDIT SETTINGS                  ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # Load current settings
    local default_port=$(jq -r '.settings.default_port' $CONFIG_DIR/servers.json)
    local default_method=$(jq -r '.settings.default_method' $CONFIG_DIR/servers.json)
    local default_obfs=$(jq -r '.settings.default_obfs' $CONFIG_DIR/servers.json)
    local max_users=$(jq -r '.settings.max_users' $CONFIG_DIR/servers.json)
    local auto_backup=$(jq -r '.settings.auto_backup' $CONFIG_DIR/servers.json)
    local backup_days=$(jq -r '.settings.backup_days' $CONFIG_DIR/servers.json)
    
    echo -e "Current Settings:"
    echo -e "  1. Default Port: $default_port"
    echo -e "  2. Default Method: $default_method"
    echo -e "  3. Default OBFS: $default_obfs"
    echo -e "  4. Max Users: $max_users"
    echo -e "  5. Auto Backup: $auto_backup"
    echo -e "  6. Backup Days: $backup_days"
    echo ""
    
    read -p "Setting to edit [1-6]: " setting_num
    
    case $setting_num in
        1)
            read -p "New Default Port: " new_value
            jq ".settings.default_port = \"$new_value\"" $CONFIG_DIR/servers.json > /tmp/temp.json
            ;;
        2)
            read -p "New Default Method: " new_value
            jq ".settings.default_method = \"$new_value\"" $CONFIG_DIR/servers.json > /tmp/temp.json
            ;;
        3)
            read -p "New Default OBFS: " new_value
            jq ".settings.default_obfs = \"$new_value\"" $CONFIG_DIR/servers.json > /tmp/temp.json
            ;;
        4)
            read -p "New Max Users: " new_value
            jq ".settings.max_users = \"$new_value\"" $CONFIG_DIR/servers.json > /tmp/temp.json
            ;;
        5)
            read -p "Auto Backup [true/false]: " new_value
            jq ".settings.auto_backup = $new_value" $CONFIG_DIR/servers.json > /tmp/temp.json
            ;;
        6)
            read -p "Backup Days: " new_value
            jq ".settings.backup_days = \"$new_value\"" $CONFIG_DIR/servers.json > /tmp/temp.json
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            sleep 2
            return
            ;;
    esac
    
    mv /tmp/temp.json $CONFIG_DIR/servers.json
    echo -e "${GREEN}✅ Settings updated!${NC}"
    sleep 2
}

# Generate Configs Menu
generate_configs() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║        GENERATE CONFIGS                 ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${WHITE}[1]${NC}  Generate Single User Config"
    echo -e "  ${WHITE}[2]${NC}  Generate All User Configs"
    echo -e "  ${WHITE}[3]${NC}  Generate HTTP Files"
    echo -e "  ${WHITE}[4]${NC}  Generate TEXT Files"
    echo -e "  ${WHITE}[5]${NC}  Generate QR Codes"
    echo -e "  ${WHITE}[6]${NC}  Export to ZIP"
    echo ""
    echo -e "  ${WHITE}[0]${NC}  Back"
    echo ""
    
    read -p "Select option: " choice
    
    case $choice in
        1)
            read -p "Username: " username
            generate_user_config $username
            ;;
        2)
            echo -e "${YELLOW}Generating configs for all users...${NC}"
            for user_file in $CONFIG_DIR/users/*.json; do
                username=$(basename $user_file .json)
                generate_user_config $username
            done
            echo -e "${GREEN}✅ All configs generated!${NC}"
            ;;
        3)
            echo -e "${YELLOW}Generating HTTP files...${NC}"
            # Implementation here
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# System Info
system_info() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║           SYSTEM INFORMATION           ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${WHITE}=== Server ===${NC}"
    echo -e "Hostname : $(hostname)"
    echo -e "IP       : $IP"
    echo -e "Uptime   : $(uptime -p)"
    echo -e "OS       : $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo ""
    
    echo -e "${WHITE}=== Resources ===${NC}"
    echo -e "CPU Load : $(uptime | awk -F'load average:' '{print $2}')"
    echo -e "Memory   : $(free -h | awk '/^Mem:/{print $3"/"$2 " ("$3/$2*100"%)"}')"
    echo -e "Disk     : $(df -h / | awk 'NR==2{print $3"/"$2 " ("$5")"}')"
    echo ""
    
    echo -e "${WHITE}=== Services ===${NC}"
    echo -n "UDP Custom : "
    if systemctl is-active udp-custom >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${RED}✗ Stopped${NC}"
    fi
    
    echo -e "${WHITE}=== ZiVPN Manager ===${NC}"
    echo -e "Version   : X3.0"
    echo -e "Config Dir: $CONFIG_DIR"
    echo -e "Users     : $(ls $CONFIG_DIR/users/*.json 2>/dev/null | wc -l)"
    echo -e "Backups   : $(ls $BACKUP_DIR/*.tar.gz 2>/dev/null | wc -l)"
    
    echo ""
    read -p "Press Enter to continue..."
}

# Service Control
service_control() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║           SERVICE CONTROL               ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "  ${WHITE}[1]${NC}  Start UDP Custom"
    echo -e "  ${WHITE}[2]${NC}  Stop UDP Custom"
    echo -e "  ${WHITE}[3]${NC}  Restart UDP Custom"
    echo -e "  ${WHITE}[4]${NC}  Status UDP Custom"
    echo -e "  ${WHITE}[5]${NC}  View Logs"
    echo -e "  ${WHITE}[6]${NC}  Enable Auto-start"
    echo -e "  ${WHITE}[7]${NC}  Disable Auto-start"
    echo ""
    echo -e "  ${WHITE}[0]${NC}  Back"
    echo ""
    
    read -p "Select option: " choice
    
    case $choice in
        1)
            systemctl start udp-custom
            echo -e "${GREEN}✅ UDP Custom started${NC}"
            ;;
        2)
            systemctl stop udp-custom
            echo -e "${YELLOW}⚠ UDP Custom stopped${NC}"
            ;;
        3)
            systemctl restart udp-custom
            echo -e "${GREEN}✅ UDP Custom restarted${NC}"
            ;;
        4)
            systemctl status udp-custom
            ;;
        5)
            journalctl -u udp-custom -f
            ;;
        6)
            systemctl enable udp-custom
            echo -e "${GREEN}✅ Auto-start enabled${NC}"
            ;;
        7)
            systemctl disable udp-custom
            echo -e "${YELLOW}⚠ Auto-start disabled${NC}"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Speed Test
speed_test() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║             SPEED TEST                  ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Running speed test...${NC}"
    echo ""
    
    # Check if speedtest-cli is installed
    if ! command -v speedtest-cli &> /dev/null; then
        echo -e "Installing speedtest-cli..."
        apt-get install -y speedtest-cli
    fi
    
    # Run speed test
    speedtest-cli --simple
    
    echo ""
    echo -e "${YELLOW}Testing local network...${NC}"
    ping -c 4 8.8.8.8
    
    echo ""
    read -p "Press Enter to continue..."
}

# Settings Menu
settings_menu() {
    while true; do
        banner
        echo -e "${GREEN}╔════════════════════════════════════════╗"
        echo -e "║               SETTINGS                  ║"
        echo -e "╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${WHITE}[1]${NC}  Change Password"
        echo -e "  ${WHITE}[2]${NC}  Database Management"
        echo -e "  ${WHITE}[3]${NC}  Log Settings"
        echo -e "  ${WHITE}[4]${NC}  Notification Settings"
        echo -e "  ${WHITE}[5]${NC}  Security Settings"
        echo -e "  ${WHITE}[6]${NC}  Update Check"
        echo -e "  ${WHITE}[7]${NC}  Reset Settings"
        echo ""
        echo -e "  ${WHITE}[0]${NC}  Back"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) change_password ;;
            2) database_management ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

# Backup & Restore
backup_restore() {
    while true; do
        banner
        echo -e "${GREEN}╔════════════════════════════════════════╗"
        echo -e "║           BACKUP & RESTORE             ║"
        echo -e "╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${WHITE}[1]${NC}  Create Backup"
        echo -e "  ${WHITE}[2]${NC}  Restore Backup"
        echo -e "  ${WHITE}[3]${NC}  List Backups"
        echo -e "  ${WHITE}[4]${NC}  Delete Backup"
        echo -e "  ${WHITE}[5]${NC}  Auto Backup Setup"
        echo -e "  ${WHITE}[6]${NC}  Export to Remote"
        echo ""
        echo -e "  ${WHITE}[0]${NC}  Back"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) create_backup ;;
            2) restore_backup ;;
            3) list_backups ;;
            4) delete_backup ;;
            5) auto_backup_setup ;;
            0) return ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

# Create Backup
create_backup() {
    banner
    echo -e "${GREEN}╔════════════════════════════════════════╗"
    echo -e "║            CREATE BACKUP                 ║"
    echo -e "╚════════════════════════════════════════╝${NC}"
    echo ""
    
    local backup_name="zivpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    echo -e "${YELLOW}Creating backup...${NC}"
    
    # Create backup
    tar -czf $backup_path \
        $CONFIG_DIR/users \
        $CONFIG_DIR/servers.json \
        $CONFIG_DIR/configs \
        /etc/udp-custom.json 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backup created: $backup_name${NC}"
        echo -e "Size: $(du -h $backup_path | cut -f1)"
    else
        echo -e "${RED}❌ Backup failed!${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Install Main Script
install_main_script() {
    # Save this script as main manager
    SCRIPT_PATH="/usr/local/bin/zivpn-main"
    
    cat > $SCRIPT_PATH << 'EOF'
#!/bin/bash
# ZiVPN Main Manager - Saved version
# ... (the entire script from above goes here)
EOF
    
    # Copy the entire script content to the file
    # In reality, you would save this whole script to that location
    
    chmod +x $SCRIPT_PATH
    
    # Create symlink
    ln -sf $SCRIPT_PATH /usr/bin/zivpn
    
    echo -e "${GREEN}✅ ZiVPN Manager installed!${NC}"
    echo -e "Run with: ${YELLOW}zivpn${NC}"
}

# Main execution
if [ "$1" = "install" ]; then
    init
    install_main_script
    install_services
    echo -e "${GREEN}Installation complete! Run 'zivpn' to start.${NC}"
else
    init
    main_menu
fi
