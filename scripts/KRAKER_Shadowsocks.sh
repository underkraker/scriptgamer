#!/bin/bash
# KRAKER VPS - SHADOWSOCKS WS + TLS
# Versión Elite Auditada - Velocidad Pura para Gaming

AZUL="\033[1;34m" && VERDE="\033[1;32m" && ROJO="\033[1;31m" && AMARILLO="\033[1;33m" && RESET="\033[0m"
BARRA="${ROJO}======================================================${RESET}"

msg_header() {
    clear
    echo -e "${BARRA}"
    echo -e "${AZUL}    🐲 KRAKER VPS - SHADOWSOCKS WS + TLS 🐲${RESET}"
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

read -p "Puerto para Shadowsocks [2087]: " PORT
[[ -z $PORT ]] && PORT=2087

PASS=$(openssl rand -hex 12)
IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')

# 2. Certificados y Directorios
mkdir -p /etc/kraker_shadowsocks
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_shadowsocks/server.key -out /etc/kraker_shadowsocks/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

# 3. Integración con Xray (JQ)
cat << EOM > /usr/local/etc/xray/temp_ss.json
{
    "port": $PORT, "protocol": "shadowsocks",
    "settings": {"method": "aes-256-gcm", "password": "$PASS"},
    "streamSettings": {
        "network": "ws", "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_shadowsocks/server.crt", "keyFile": "/etc/kraker_shadowsocks/server.key"}]},
        "wsSettings": {"path": "/krakervps"}
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
}
EOM

if [ -f /usr/local/etc/xray/config.json ]; then
    jq --argjson new_inbound "$(cat /usr/local/etc/xray/temp_ss.json)" '.inbounds += [$new_inbound]' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp && mv /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/config.json
else
    echo "{\"inbounds\": [$(cat /usr/local/etc/xray/temp_ss.json)], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

# 4. Finalización
setup_banner
ufw allow $PORT/tcp > /dev/null 2>&1
systemctl restart xray
rm /usr/local/etc/xray/temp_ss.json

# Enlace Shadowsocks (SS_IP_PORT_METHOD_PASS_BASE64)
SS_CORE="aes-256-gcm:$PASS@$IP:$PORT"
ENCODED=$(echo -n "$SS_CORE" | base64 | tr -d '\n')
LINK="ss://$ENCODED?plugin=v2ray-plugin%3Btls%3Bhost%3D$BUG%3Bpath%3D%2Fkrakervps#KRAKER_VPS_SHADOWSOCKS"

msg_header
echo -e "${VERDE}✔ KRAKER SHADOWSOCKS INSTALADO CON ÉXITO!${RESET}"
echo -e "${YELLOW}Enlace SS:${RESET} $LINK"
echo -e "${BARRA}"
echo -e "Copia el enlace y asegúrate de permitir certificados inseguros en tu App."
