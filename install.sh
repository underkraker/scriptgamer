#!/bin/bash
# Instalador Automático de Gaming VPS Script

# Definir Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${CYAN}${BOLD}======================================================${NC}"
echo -e "${GREEN}${BOLD}     Preparando Servidor e Instalando Panel...        ${NC}"
echo -e "${CYAN}${BOLD}======================================================${NC}"

# Validar ROOT
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Error: Por favor, ejecuta el instalador como ROOT (sudo su o sudo bash).${NC}"
  exit 1
fi

# Actualizar e instalar base
echo -e "\n${CYAN}[*] Instalando dependencias base en el VPS...${NC}"
apt-get update -y > /dev/null 2>&1
apt-get install -y wget curl jq net-tools iproute2 cron ca-certificates iptables > /dev/null 2>&1

echo -e "\n${MAGENTA}======================================================${NC}"
echo -e "${WHITE}${BOLD}      VERIFICACIÓN DE LICENCIA PREMIUM${NC}"
echo -e "${MAGENTA}======================================================${NC}"
echo -e -n "${CYAN}🔑 Ingrese su Key de Instalación (Ej. KRAKER-ABC123): ${NC}"
read INSTALL_KEY

if [ -z "$INSTALL_KEY" ]; then
    echo -e "${RED}[x] Debe ingresar una licencia válida. Instalación abortada.${NC}"
    exit 1
fi

echo -e "${YELLOW}⏳ Verificando licencia con el servidor central...${NC}"
# Reemplaza IP_DE_TU_BOT con la IP donde corras tu Bot de Telegram
API_URL="http://IP_DE_TU_BOT:5000/api/validar"
# RESPONSE=$(curl -s "$API_URL?key=$INSTALL_KEY")

# === BYPASS TEMPORAL DE LICENCIA PARA PRUEBAS ===
echo -e "${GREEN}[✔] ¡Bypass exitoso! Simulando licencia aceptada. Procediendo con la instalación...${NC}"
# =================================================

# Descargar el menú desde GitHub (Bypass caché)
echo -e "${CYAN}[*] Descargando Panel desde el repositorio de GitHub...${NC}"
wget -qO /usr/bin/menu "https://raw.githubusercontent.com/underkraker/scriptgamer/main/menu.sh?t=$(date +%s)"

if [ -f /usr/bin/menu ]; then
    # Otorgar permisos de dueño y ejecución universal
    chmod +x /usr/bin/menu
    
    # NUEVO: Pedir slogan del reseller
    echo -e "\n${MAGENTA}======================================================${NC}"
    echo -e "${WHITE}${BOLD}      PERSONALIZACIÓN DE MARCA BLANCA${NC}"
    echo -e "${MAGENTA}======================================================${NC}"
    echo -e "${CYAN}¿Qué nombre o slogan quieres que aparezca en el encabezado?${NC}"
    echo -e -n "${YELLOW}(Presiona ENTER para dejar 'V P S  P A N E L  P R O'): ${NC}"
    read SLOGAN
    
    mkdir -p /etc/gaming_vps
    if [ -n "$SLOGAN" ]; then
        echo "$SLOGAN" > /etc/gaming_vps/slogan.txt
    else
        rm -f /etc/gaming_vps/slogan.txt
    fi
    
    echo -e "\n${GREEN}${BOLD}[✔] INSTALACIÓN COMPLETADA CON ÉXITO.${NC}"
    echo -e "${CYAN}======================================================${NC}"
    echo -e " 🎮 A partir de ahora, solo escribe el comando: ${GREEN}${BOLD}menu${NC}"
    echo -e " en cualquier parte de la consola para abrir tu panel."
    echo -e "${CYAN}======================================================${NC}\n"
else
    echo -e "${RED}[x] Error catastrófico: No se pudo conectar a GitHub o el archivo no existe.${NC}"
    echo -e "Revisa tu conexión o asegúrate de que el repositorio sea público."
fi
