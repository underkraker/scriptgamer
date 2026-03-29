#!/bin/bash
# KRAKER VPS - DROPBEAR SSH (v2.1 Elite)
# El servidor SSH ligero por excelencia para Inyectores

AZUL="\033[1;34m" && VERDE="\033[1;32m" && ROJO="\033[1;31m" && AMARILLO="\033[1;33m" && RESET="\033[0m"
BARRA="${ROJO}======================================================${RESET}"

msg_header() {
    clear
    echo -e "${BARRA}"
    echo -e "${AZUL}    🐲 KRAKER VPS - DROPBEAR SSH (LIGHT) 🐲${RESET}"
    echo -e "${BARRA}"
}

setup_banner() {
    # Configurar el MOTD (Banner ASCII de KRAKER VPS)
    cat << 'EOF' > /etc/motd
  ██╗  ██╗██████╗  █████╗ ██╗  ██╗███████╗██████╗     ██╗   ██╗██████╗ ███████╗
  ██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝██╔════╝██╔══██╗    ██║   ██║██╔══██╗██╔════╝
  █████╔╝ ██████╔╝███████║█████╔╝ █████╗  ██████╔╝    ██║   ██║██████╔╝███████╗
  ██╔═██╗ ██╔══██╗██╔══██║██╔═██╗ ██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██╔═══╝ ╚════██║
  ██║  ██╗██║  ██║██║  ██║██║  ██╗███████╗██║  ██║     ╚████╔╝ ██║     ████████║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚═╝     ╚══════╝
                               BIENVENIDO A KRAKER VPS
EOF
    # Asegurar que se muestre en los Logs
    sed -i 's/#PrintMotd yes/PrintMotd yes/g' /etc/ssh/sshd_config
    systemctl restart sshd > /dev/null 2>&1
}

# 1. Instalar Dropbear
msg_header
echo -e "${AMARILLO}[1/3] Instalando Dropbear SSH...${RESET}"
apt update -y && apt install -y dropbear coreutils ufw lsof > /dev/null 2>&1

# 2. Configurar Puertos (80, 143, 442)
echo -e "${AMARILLO}[2/3] Configurando Puertos 80, 143, 442 y Banner...${RESET}"

# Liberar puerto 80 si algo lo usa (como Apache/Nginx que se instalan solos a veces)
fuser -k 80/tcp > /dev/null 2>&1

cat << EOF > /etc/default/dropbear
# KRAKER VPS - Dropbear Config
NO_START=0
DROPBEAR_PORT=143
DROPBEAR_EXTRA_ARGS="-p 80 -p 442"
DROPBEAR_BANNER="/etc/motd"
DROPBEAR_RECEIVE_WINDOW=65536
EOF

# 3. Finalización
setup_banner
echo -e "${AMARILLO}[3/3] Reiniciando y abriendo Firewall...${RESET}"
ufw allow 80/tcp > /dev/null 2>&1
ufw allow 143/tcp > /dev/null 2>&1
ufw allow 442/tcp > /dev/null 2>&1

systemctl enable dropbear > /dev/null 2>&1
systemctl restart dropbear > /dev/null 2>&1

msg_header
echo -e "${VERDE}✔ KRAKER DROPBEAR INSTALADO CON ÉXITO!${RESET}"
echo -e "${BARRA}"
echo -e "${YELLOW}PUERTOS ACTIVOS:${RESET}"
echo -e "${CYAN}Puerto 80   : ${RESET}ACTIVO (Ideal para WSS/Payload)"
echo -e "${CYAN}Puerto 143  : ${RESET}ACTIVO (Fijo)"
echo -e "${CYAN}Puerto 442  : ${RESET}ACTIVO (Fijo)"
echo -e "${BARRA}"
echo -e "${AMARILLO}RECUERDA: Abre los puertos en tu consola de AWS.${RESET}"
echo -e "${BARRA}"
