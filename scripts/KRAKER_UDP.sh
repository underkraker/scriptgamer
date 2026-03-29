#!/bin/bash
# KRAKER VPS - UDP GAMING (BadVPN)
# Versión Auditada y Estandarizada

AZUL="\033[1;34m" && VERDE="\033[1;32m" && ROJO="\033[1;31m" && AMARILLO="\033[1;33m" && CYAN="\033[1;36m" && RESET="\033[0m"
BARRA="${ROJO}======================================================${RESET}"

msg_header() {
    clear
    echo -e "${BARRA}"
    echo -e "${AZUL}    🐲 KRAKER VPS - UDP GAMING OPTIMIZER 🐲${RESET}"
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

# 1. Optimización Kernel BBR
tune_network() {
    echo -e "${AMARILLO}[1/3] Aplicando BBR y Tunings de Gaming...${RESET}"
    if ! sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    fi
    sysctl -p > /dev/null 2>&1
}

# 2. Instalación BadVPN
install_badvpn() {
    echo -e "${AMARILLO}[2/3] Instalando BadVPN udpgw...${RESET}"
    wget -O /usr/bin/badvpn-udpgw "https://github.com/ambrop72/badvpn/releases/download/1.999.130/badvpn-linux-x86_64" > /dev/null 2>&1
    chmod +x /usr/bin/badvpn-udpgw
}

# 3. Servicio Systemd
create_service() {
    echo -e "${AMARILLO}[3/3] Iniciando Sistema de Prioridad Alta...${RESET}"
    cat << 'EOF' > /etc/systemd/system/kraker-udp.service
[Unit]
Description=KRAKER VPS - UDP Gateway
After=network.target

[Service]
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 0.0.0.0:7100 --max-clients 500 --listen-addr 0.0.0.0:7200 --max-clients 500 --listen-addr 0.0.0.0:7300 --max-clients 500
Restart=always
Nice=-20
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=99

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable kraker-udp > /dev/null 2>&1
    systemctl restart kraker-udp > /dev/null 2>&1
}

msg_header
setup_banner
tune_network
install_badvpn
create_service

echo -e "${VERDE}✔ KRAKER UDP GAMING ACTIVADO!${RESET}"
echo -e "${CYAN}Puertos: 7100, 7200, 7300${RESET}"
echo -e "${BARRA}"
