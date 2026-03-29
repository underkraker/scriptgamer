#!/bin/bash
# KRAKER VPS - TROJAN WS + TLS
# Versión Auditada y Estandarizada

AZUL="\033[1;34m" && VERDE="\033[1;32m" && ROJO="\033[1;31m" && AMARILLO="\033[1;33m" && RESET="\033[0m"
BARRA="${ROJO}======================================================${RESET}"

msg_header() {
    clear
    echo -e "${BARRA}"
    echo -e "${AZUL}    🐲 KRAKER VPS - TROJAN WS + TLS (ELITE) 🐲${RESET}"
    echo -e "${BARRA}"
}

setup_banner() {
    cat << 'EOF' > /etc/motd
  ██╗  ██╗██████╗  █████╗ ██╗  ██╗███████╗██████╗     ██╗   ██╗██████╗ ███████╗
  ██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝██╔════╝██╔══██╗    ██║   ██║██╔══██╗██╔════╝
  █████╔╝ ██████╔╝███████║█████╔╝ █████╗  ██████╔╝    ██║   ██║██████╔╝███████╗
  ██╔═██╗ ██╔══██╗██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██╔═══╝ ╚════██║
  ██║  ██╗██║  ██║██║  ██║██║  ██╗███████╗██║  ██║     ╚████╔╝ ██║     ████████║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚═╝     ╚══════╝
                               BIENVENIDO A KRAKER VPS
EOF
}

# 1. Configuración Interactiva
msg_header
read -p "Introduce tu SNI Bug (ej: cdn-global.configcat.com): " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

read -p "Puerto para Trojan [2053]: " PORT
[[ -z $PORT ]] && PORT=2053

PASS=$(openssl rand -hex 8)
IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')

# 2. Certificados y Directorios
mkdir -p /etc/kraker_trojan
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_trojan/server.key -out /etc/kraker_trojan/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

# 3. Integración con Xray (JQ)
cat << EOM > /usr/local/etc/xray/temp_trojan.json
{
    "port": $PORT, "protocol": "trojan",
    "settings": {"clients": [{"password": "$PASS"}], "decryption": "none"},
    "streamSettings": {
        "network": "ws", "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_trojan/server.crt", "keyFile": "/etc/kraker_trojan/server.key"}]},
        "wsSettings": {"path": "/krakervps"}
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
}
EOM

if [ -f /usr/local/etc/xray/config.json ]; then
    jq --argjson new_inbound "$(cat /usr/local/etc/xray/temp_trojan.json)" '.inbounds += [$new_inbound]' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp && mv /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/config.json
else
    echo "{\"inbounds\": [$(cat /usr/local/etc/xray/temp_trojan.json)], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

# 4. Finalización
setup_banner
ufw allow $PORT/tcp > /dev/null 2>&1
systemctl restart xray
rm /usr/local/etc/xray/temp_trojan.json

LINK="trojan://$PASS@$IP:$PORT?security=tls&sni=$BUG&fp=chrome&type=ws&path=/krakervps#KRAKER_VPS_TROJAN"
msg_header
echo -e "${VERDE}✔ KRAKER TROJAN INSTALADO CON ÉXITO!${RESET}"
echo -e "${YELLOW}Enlace:${RESET} $LINK"
echo -e "${BARRA}"
