#!/bin/bash
# KRAKER VPS - Xray VLESS-REALITY Setup
# Optimized for Gaming and Ultra-Stealth (Vision + REALITY)

# Colores y UI Header
RED='\033[0;31m' && GREEN='\033[0;32m' && YELLOW='\033[1;33m' && CYAN='\033[0;36m' && NC='\033[0m'

msg_header() {
    clear
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${GREEN}      KRAKER VPS - XRAY REALITY SETUP         ${NC}"
    echo -e "${CYAN}==============================================${NC}"
}

setup_banner() {
    # Configurar Banner para que se vea en el Log de las Apps
    cat << 'EOF' > /etc/motd
  ██╗  ██╗██████╗  █████╗ ██╗  ██╗███████╗██████╗     ██╗   ██╗██████╗ ███████╗
  ██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝██╔════╝██╔══██╗    ██║   ██║██╔══██╗██╔════╝
  █████╔╝ ██████╔╝███████║█████╔╝ █████╗  ██████╔╝    ██║   ██║██████╔╝███████╗
  ██╔═██╗ ██╔══██╗██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██╔═══╝ ╚════██║
  ██║  ██╗██║  ██║██║  ██║██║  ██╗███████╗██║  ██║     ╚████╔╝ ██║     ███████║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚═╝     ╚══════╝
                               BIENVENIDO A KRAKER VPS
EOF
    sed -i 's/#PrintMotd yes/PrintMotd yes/g' /etc/ssh/sshd_config
    systemctl restart sshd > /dev/null 2>&1
}

# 1. Install Dependencies
msg_header
echo -e "${YELLOW}[1/6] Instalando dependencias...${NC}"
apt update -y && apt install -y curl jq openssl coreutils ufw lsof > /dev/null 2>&1

# 2. Xray Installation
echo -e "${YELLOW}[2/6] Verificando Xray-core...${NC}"
if [[ ! -f /usr/local/bin/xray ]]; then
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
fi

# 3. Security IDs & Keys
echo -e "${YELLOW}[3/6] Generando Identificadores de Seguridad...${NC}"
UUID=$(/usr/local/bin/xray uuid)
KEYS=$(/usr/local/bin/xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | awk -F': ' '/PrivateKey/ || /Private key/ {print $2}' | tr -d ' ')
PUBLIC_KEY=$(echo "$KEYS" | awk -F': ' '/PublicKey/ || /Public key/ {print $2}' | tr -d ' ')
SHORT_ID=$(head /dev/urandom | tr -dc 'a-f0-9' | head -c 8)
IP_PUB=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')

# 4. Interactivity (SNI Bug)
echo -e "${CYAN}Ingresa el SNI Bug para REALITY (ej: cdn-global.configcat.com)${NC}"
read -p "SNI Bug: " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

# Port Selection (Priority 443)
PORT=443
if lsof -Pi :443 -sTCP:LISTEN -t >/dev/null ; then
    PORT=$(( RANDOM % 5000 + 40000 ))
    echo -e "${YELLOW}Aviso: Puerto 443 ocupado. Usando: $PORT${NC}"
fi

# 5. Configuration (JSON)
cat > /usr/local/etc/xray/config.json <<EOF
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": $PORT, "protocol": "vless",
        "settings": {"clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}], "decryption": "none"},
        "streamSettings": {
            "network": "tcp", "security": "reality",
            "realitySettings": {
                "show": false, "dest": "$BUG:443", "xver": 0,
                "serverNames": ["$BUG"], "privateKey": "$PRIVATE_KEY", "shortIds": ["$SHORT_ID"]
            }
        },
        "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF

# 6. Service & Banner
setup_banner
ufw allow $PORT/tcp > /dev/null 2>&1
systemctl restart xray > /dev/null 2>&1

LINK="vless://$UUID@$IP_PUB:$PORT?security=reality&sni=$BUG&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#KRAKER_VPS_REALITY"

msg_header
echo -e "${VERDE}✔ KRAKER REALITY INSTALADO CON ÉXITO!${NC}"
echo -e "${BARRA}"
echo -e "${YELLOW}SNI Bug:${NC} $BUG"
echo -e "${YELLOW}Puerto :${NC} $PORT"
echo -e "${BARRA}"
echo -e "${GREEN}ENLACE VLESS:${NC}\n$LINK"
echo -e "${BARRA}"
