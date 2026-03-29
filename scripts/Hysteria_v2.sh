#!/bin/bash
# KRAKER VPS - HYSTERIA v2 SETUP
# Optimized for Ultra-Speed and Gaming

# Colores y UI Header
RED='\033[0;31m' && GREEN='\033[0;32m' && YELLOW='\033[1;33m' && CYAN='\033[0;36m' && NC='\033[0m'

msg_header() {
    clear
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${GREEN}      KRAKER VPS - HYSTERIA v2 SETUP          ${NC}"
    echo -e "${CYAN}==============================================${NC}"
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

# 1. Install Dependencies
msg_header
echo -e "${YELLOW}[1/4] Instalando dependencias...${NC}"
apt update -y && apt install -y curl openssl coreutils ufw lsof > /dev/null 2>&1

# 2. Hysteria Installation
echo -e "${YELLOW}[2/4] Instalando Hysteria v2...${NC}"
bash <(curl -fsSL https://get.hy2.biz) > /dev/null 2>&1

# 3. Config & Certs
msg_header
echo -e "${CYAN}Ingresa el SNI Bug para Hysteria (ej: cdn-global.configcat.com)${NC}"
read -p "SNI Bug: " BUG
[[ -z $BUG ]] && BUG="cdn-global.configcat.com"

# Generar Certificado
mkdir -p /etc/hysteria
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null

# Password Aleatoria
PASS=$(openssl rand -hex 8)
IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')

# 4. Configuration (YAML)
cat << EOF > /etc/hysteria/config.yaml
listen: :443
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
auth:
  type: password
  password: $PASS
masquerade:
  type: proxy
  proxy:
    url: https://$BUG/
EOF

# Service & Firewall
setup_banner
ufw allow 443/udp > /dev/null 2>&1
systemctl enable hysteria-server.service > /dev/null 2>&1
systemctl restart hysteria-server.service > /dev/null 2>&1

msg_header
echo -e "${VERDE}✔ KRAKER HYSTERIA v2 INSTALADO CON ÉXITO!${NC}"
echo -e "${BARRA}"
echo -e "${YELLOW}DATOS DE CONEXIÓN:${NC}"
echo -e "${CYAN}IP       :${NC} $IP"
echo -e "${CYAN}Puerto   :${NC} 443 (UDP)"
echo -e "${CYAN}Password :${NC} $PASS"
echo -e "${CYAN}SNI Bug  :${NC} $BUG"
echo -e "${BARRA}"
echo -e "${GREEN}RECUERDA: Hysteria usa UDP para máxima velocidad.${NC}"
echo -e "${BARRA}"
