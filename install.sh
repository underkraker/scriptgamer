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

# Despliegue Directo de Marca Blanca
echo -e "\n${CYAN}[*] Iniciando despliegue de Marca Blanca v11.0 (Sin restricciones)...${NC}"

# Descargar el menú desde GitHub (Bypass caché)
echo -e "${CYAN}[*] Descargando Panel desde el repositorio de GitHub...${NC}"
wget -qO /usr/bin/menu "https://raw.githubusercontent.com/underkraker/scriptgamer/main/menu.sh?t=$(date +%s)"

if [ -f /usr/bin/menu ]; then
    # Otorgar permisos de dueño y ejecución universal
    chmod +x /usr/bin/menu
    
    # NUEVO: Personalización de Marca Blanca (Nombre y Slogan)
    echo -e "\n${MAGENTA}======================================================${NC}"
    echo -e "${WHITE}${BOLD}      PERSONALIZACIÓN DE MARCA BLANCA${NC}"
    echo -e "${MAGENTA}======================================================${NC}"
    echo -e "${CYAN}¿Qué NOMBRE quieres para el encabezado ASCII?${NC}"
    echo -e -n "${YELLOW}(Ej: UNDERKRAKER): ${NC}"
    read P_NAME
    
    echo -e "\n${CYAN}¿Qué SLOGAN o sub-título quieres debajo?${NC}"
    echo -e -n "${YELLOW}(Ej: VPS PREMIUM PRO): ${NC}"
    read SLOGAN
    
    mkdir -p /etc/gaming_vps
    [ -n "$P_NAME" ] && echo "$P_NAME" > /etc/gaming_vps/panel_name.txt || echo "GAMER" > /etc/gaming_vps/panel_name.txt
    if [ -n "$SLOGAN" ]; then
        echo "$SLOGAN" > /etc/gaming_vps/slogan.txt
    else
        rm -f /etc/gaming_vps/slogan.txt
    fi
    
    # NUEVO: Activar Seguridad Automática por defecto
    echo -e "${CYAN}[*] Configurando Auto-Kill y Limpieza de RAM...${NC}"
    # Ejecutar funciones internas de seguridad del menu.sh silenciosamente
    bash -c "source /usr/bin/menu && setup_autokill > /dev/null 2>&1 && setup_auto_clean > /dev/null 2>&1"
    
    echo -e "\n${GREEN}${BOLD}[✔] INSTALACIÓN COMPLETADA CON ÉXITO.${NC}"
    echo -e "${CYAN}======================================================${NC}"
    echo -e " 🎮 A partir de ahora, solo escribe el comando: ${GREEN}${BOLD}menu${NC}"
    echo -e " en cualquier parte de la consola para abrir tu panel."
    echo -e "${CYAN}======================================================${NC}\n"
else
    echo -e "${RED}[x] Error catastrófico: No se pudo conectar a GitHub o el archivo no existe.${NC}"
    echo -e "Revisa tu conexión o asegúrate de que el repositorio sea público."
fi
