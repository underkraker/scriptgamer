#!/bin/bash
# KRAKER VPS - SSL GATEWAY MANAGER
# Gestión Avanzada de Protocolos SSL (Dual Mode: WS + Direct)

# Colores y UI Header
AZUL="\033[1;34m" && VERDE="\033[1;32m" && ROJO="\033[1;31m" && AMARILLO="\033[1;33m" && RESET="\033[0m"
BARRA="${ROJO}======================================================${RESET}"

msg_header() {
    clear
    echo -e "${BARRA}"
    echo -e "${AZUL}    🐲 KRAKER VPS - SSL GATEWAY (DUAL) 🐲${RESET}"
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

setup_protocol() {
    msg_header
    echo -e "${AMARILLO}[!] Configurando SSL Gateway (KRAKER VPS)...${RESET}"
    read -p "Ingresa el SNI Bug de tu compañía: " BUG
    [[ -z $BUG ]] && BUG="cdn-global.configcat.com"

    # Generar Certificado de Camuflaje
    mkdir -p /etc/ws_ssl
    openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ws_ssl/server.key -out /etc/ws_ssl/server.crt -subj "/CN=$BUG" -days 365 2>/dev/null
    
    # Liberar puerto 443 e iniciar
    setup_banner
    fuser -k 443/tcp > /dev/null 2>&1
    screen -dmS "kraker_ssl" python3 KRAKER_SSL_Gateway.py "443" "/etc/ws_ssl/server.crt" "/etc/ws_ssl/server.key"
    
    echo -e "${VERDE}[*] KRAKER VPS - Gateway Dual Iniciado en Puerto 443${RESET}"
    echo -e "${AMARILLO}[*] Redirección interna: Puerto 80 (SSH/Dropbear)${RESET}"
    sleep 3
}

stop_protocol() {
    msg_header
    screen -X -S "kraker_ssl" quit > /dev/null 2>&1
    fuser -k 443/tcp > /dev/null 2>&1
    echo -e "${VERDE}[*] Servicio KRAKER SSL detenido.${RESET}"
    sleep 2
}

menu() {
    msg_header
    echo -e "${VERDE}[1] > ${AMARILLO}INICIAR GATEWAY DUAL (WS+Direct)${RESET}"
    echo -e "${VERDE}[2] > ${AMARILLO}DETENER GATEWAY${RESET}"
    echo -e "${VERDE}[3] > ${AMARILLO}MONITOR DE LOGS${RESET}"
    echo -e "${BARRA}"
    echo -e "${VERDE}[0] > ${ROJO}SALIR${RESET}"
    read -p "Alternativa: " OPC
    case $OPC in
        1) setup_protocol ; menu ;;
        2) stop_protocol ; menu ;;
        3) screen -r kraker_ssl ; menu ;;
        0) exit ;;
        *) menu ;;
    esac
}

apt update -y && apt install -y screen openssl net-tools > /dev/null 2>&1
menu
