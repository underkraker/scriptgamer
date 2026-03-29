#!/bin/bash
# KRAKER VPS - SLOWDNS (DNSTT)
# Versión Auditada y Estandarizada

AZUL="\033[1;34m" && VERDE="\033[1;32m" && ROJO="\033[1;31m" && AMARILLO="\033[1;33m" && RESET="\033[0m"
BARRA="${ROJO}======================================================${RESET}"

msg_header() {
    clear
    echo -e "${BARRA}"
    echo -e "${AZUL}    🐲 KRAKER VPS - EXTREME SLOWDNS 🐲${RESET}"
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

# 1. Instalar Dependencias y DNSTT
install_dnstt() {
    echo -e "${AMARILLO}[1/4] Instalando Dependencias y Xray...${RESET}"
    apt update -y && apt install -y curl wget iptables ufw coreutils > /dev/null 2>&1
    wget -O /usr/bin/dnstt-server "https://github.com/google/dnstt/releases/download/v20220210/dnstt-server-linux-amd64" > /dev/null 2>&1
    chmod +x /usr/bin/dnstt-server
}

# 2. Generar Llaves
generate_keys() {
    echo -e "${AMARILLO}[2/4] Generando Llaves KRAKER DNS...${RESET}"
    mkdir -p /etc/kraker_dns
    /usr/bin/dnstt-server -gen-key -pub /etc/kraker_dns/server.pub -priv /etc/kraker_dns/server.key > /dev/null 2>&1
    PUB_KEY=$(cat /etc/kraker_dns/server.pub)
}

# 3. Configurar Firewall
setup_network() {
    echo -e "${AMARILLO}[3/4] Configurando Puerto 53 UDP...${RESET}"
    systemctl stop systemd-resolved > /dev/null 2>&1
    systemctl disable systemd-resolved > /dev/null 2>&1
    iptables -I INPUT -p udp --dport 53 -j ACCEPT
    iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
}

# 4. Crear Servicio
create_service() {
    cat << EOF > /etc/systemd/system/kraker-dns.service
[Unit]
Description=KRAKER VPS - SlowDNS
After=network.target

[Service]
ExecStart=/usr/bin/dnstt-server -udp :5300 -pub /etc/kraker_dns/server.pub -key /etc/kraker_dns/server.key -tunnel 127.0.0.1:80
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable kraker-dns > /dev/null 2>&1
    systemctl restart kraker-dns > /dev/null 2>&1
}

msg_header
setup_banner
install_dnstt
generate_keys
setup_network
create_service

echo -e "${VERDE}✔ KRAKER DNS (SlowDNS) ACTIVADO!${RESET}"
echo -e "${YELLOW}Public Key:${RESET} $PUB_KEY"
echo -e "${BARRA}"
