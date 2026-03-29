#!/bin/bash
# KRAKER VPS - VMess WS + TLS
# Versión Auditada y Estandarizada

AZUL="\033[1;34m" && VERDE="\033[1;32m" && ROJO="\033[1;31m" && AMARILLO="\033[1;33m" && RESET="\033[0m"
BARRA="${ROJO}======================================================${RESET}"

msg_header() {
    clear
    echo -e "${BARRA}"
    echo -e "${AZUL}    🐲 KRAKER VPS - VMESS WS + TLS (ELITE) 🐲${RESET}"
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

read -p "Puerto para VMess [2083]: " PORT
[[ -z $PORT ]] && PORT=2083

UUID=$(/usr/local/bin/xray uuid)
IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')

# 2. Certificados y Directorios
mkdir -p /etc/kraker_vmess
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/kraker_vmess/server.key -out /etc/kraker_vmess/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

# 3. Integración con Xray (JQ)
cat << EOM > /usr/local/etc/xray/temp_vmess.json
{
    "port": $PORT, "protocol": "vmess",
    "settings": {"clients": [{"id": "$UUID", "alterId": 0}]},
    "streamSettings": {
        "network": "ws", "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/kraker_vmess/server.crt", "keyFile": "/etc/kraker_vmess/server.key"}]},
        "wsSettings": { "path": "/krakervps" }
    },
    "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
}
EOM

if [ -f /usr/local/etc/xray/config.json ]; then
    jq --argjson new_inbound "$(cat /usr/local/etc/xray/temp_vmess.json)" '.inbounds += [$new_inbound]' /usr/local/etc/xray/config.json > /usr/local/etc/xray/config.json.tmp && mv /usr/local/etc/xray/config.json.tmp /usr/local/etc/xray/config.json
else
    echo "{\"inbounds\": [$(cat /usr/local/etc/xray/temp_vmess.json)], \"outbounds\": [{\"protocol\": \"freedom\"}]}" > /usr/local/etc/xray/config.json
fi

# 4. Finalización
setup_banner
ufw allow $PORT/tcp > /dev/null 2>&1
systemctl restart xray
rm /usr/local/etc/xray/temp_vmess.json

VMESS_JSON=$(cat << EOM
{ "v": "2", "ps": "KRAKER_VPS_VMESS", "add": "$IP", "port": "$PORT", "id": "$UUID", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$BUG", "path": "/krakervps", "tls": "tls", "sni": "$BUG" }
EOM
)
LINK="vmess://$(echo -n "$VMESS_JSON" | base64 | tr -d '\n')"

msg_header
echo -e "${VERDE}✔ KRAKER VMESS INSTALADO CON ÉXITO!${RESET}"
echo -e "${YELLOW}Enlace:${RESET} $LINK"
echo -e "${BARRA}"
