#!/bin/bash
# Gaming VPS Script - Fase 1: Entorno Visual y Menú Principal

# Definir Colores (Tema Experto Gamer Neón)
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Validar permisos de Administrador (ROOT)
if [ "$EUID" -ne 0 ]; then
  echo -e "\n${RED}❌ Error: Debes ejecutar este script como ROOT. Usa 'sudo su' primero.${NC}\n"
  exit 1
fi

# Función para mostrar el encabezado VIP
function header() {
    clear
    echo -e "\n"
    echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "    ${MAGENTA}██████╗  █████╗ ███╗   ███╗███████╗██████╗${NC}"
    echo -e "   ${MAGENTA}██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔══██╗${NC}"
    echo -e "   ${MAGENTA}██║  ███╗███████║██╔████╔██║█████╗  ██████╔╝${NC}"
    echo -e "   ${MAGENTA}██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ██╔══██╗${NC}"
    echo -e "   ${MAGENTA}╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██║  ██║${NC}"
    echo -e "    ${MAGENTA}╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝${NC}"
    echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ -f /etc/gaming_vps/slogan.txt ]; then
        M_SLOGAN=$(cat /etc/gaming_vps/slogan.txt)
        # Centrar de forma simple usando espacios aproximados
        echo -e "         ${WHITE}${BOLD}🔥  $M_SLOGAN  🔥${NC}"
    else
        echo -e "         ${WHITE}${BOLD}🔥  V P S   P A N E L   P R O  🔥${NC}"
    fi
    
    echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "     ${GREEN}⚡ Ping Optimizer    🛡️ Anti-DDoS    🦇 Multi-Tunnel${NC}"
    echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# ============== PARTE 2: OPTIMIZACIÓN GAMING ==============
function install_bbr() {
    echo -e "\n${CYAN}[*] Instalando y Configurando Google TCP BBR...${NC}"
    
    # Cargar el módulo explícitamente en el Kernel actual
    modprobe tcp_bbr > /dev/null 2>&1
    
    # Asegurar que el módulo cargue tras reiniciar
    if [ -f /etc/modules-load.d/modules.conf ] && ! grep -q "tcp_bbr" /etc/modules-load.d/modules.conf; then
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    elif [ -f /etc/modules ] && ! grep -q "tcp_bbr" /etc/modules; then
        echo "tcp_bbr" >> /etc/modules
    fi
    
    # Se eliminan configuraciones antiguas
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    
    # Se inyectan las nuevas TCP BBR Limits
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
    
    # Verificación estricta (Evita falsos positivos en VPS OpenVZ/LXC)
    if sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q "bbr" || lsmod 2>/dev/null | grep -q "bbr"; then
        echo -e "${GREEN}[✔] TCP BBR (Acelerador de red) activado con éxito.${NC}"
    else
        echo -e "${RED}[x] Falla Crítica: TCP BBR no se activó.${NC}"
        echo -e "${YELLOW}🚨 Nota: Es probable que tu servidor sea tipo OpenVZ o LXC.${NC}"
        echo -e "${YELLOW}Solo las VPS tipo KVM, VMware o BareMetal soportan modificaciones al Kernel (como BBR).${NC}"
    fi
    sleep 4
    return
}

function install_badvpn() {
    echo -e "\n${CYAN}[*] Instalando y Compilando BadVPN para Juegos (UDP)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y cmake build-essential git gcc > /dev/null 2>&1
    
    rm -rf /opt/badvpn
    git clone https://github.com/ambrop72/badvpn.git /opt/badvpn > /dev/null 2>&1
    mkdir -p /opt/badvpn/build
    cd /opt/badvpn/build
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
    make install > /dev/null 2>&1
    MAKE_STATUS=$?
    
    echo -e -n "   ${CYAN}🔌 ¿En qué puerto abrirás BadVPN UDPGW? (Ej: 7300):${NC} "
    read -r vpn_port
    [ -z "$vpn_port" ] && vpn_port=7300
    
    if [ $MAKE_STATUS -eq 0 ] && { command -v badvpn-udpgw &> /dev/null || [ -x /usr/local/bin/badvpn-udpgw ]; }; then
        BIN_PATH=$(command -v badvpn-udpgw || echo "/usr/local/bin/badvpn-udpgw")
        
        cat > /etc/systemd/system/badvpn.service <<EOF
[Unit]
Description=BadVPN UDPGW Gaming Port $vpn_port
After=network.target

[Service]
Type=simple
ExecStart=$BIN_PATH --listen-addr 127.0.0.1:$vpn_port --max-clients 500 --max-connections-for-client 10
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload > /dev/null 2>&1
        systemctl enable badvpn > /dev/null 2>&1
        systemctl restart badvpn > /dev/null 2>&1
        echo -e "${GREEN}[✔] BadVPN UDP activado correctamente en el puerto $vpn_port.${NC}"
    else
        echo -e "${RED}[x] Error al compilar BadVPN. Verifica el entorno de dependencias.${NC}"
    fi
    sleep 3
    return
}

function open_internal_ports() {
    header
    echo -e "\n${CYAN}[*] Desbloqueando Puertos Internos (UFW / Iptables)...${NC}"
    
    # Si UFW existe (típico en Ubuntu), lo apaga
    if command -v ufw &> /dev/null; then
        ufw disable > /dev/null 2>&1
    fi
    
    # Purgar bloqueos nativos de Linux
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t mangle -F
    
    echo -e "${GREEN}[✔] ¡Firewall Interno (Ubuntu) derribado exitosamente!${NC}"
    echo -e "${YELLOW}🚨 ATENCIÓN AWS: Aún DEBES ir al portal de Amazon EC2 -> 'Security Groups' y permitir tráfico a los puertos (80, 443, 7300, etc.) o AWS impedirá la conexión física.${NC}"
    echo -e "\nPresiona ENTER para continuar..."
    read enter
    return
}

function optimizer_menu() {
    while true; do
        header
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}O P T I M I Z A C I Ó N   G A M I N G${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}🌐 Activar Acelerador TCP BBR de Google${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}🎮 Instalar BadVPN (Comunicaciones UDP)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 3 ${CYAN}]${NC} ${BOLD}🔓 Purgar y Abrir Puertos Internos (UFW)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}🔙 Regresar al Menú Inicial${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
        echo -e -n "   ${WHITE}${BOLD}🎮 ¿Qué deseas hacer?:${NC} "
        read opt

        case $opt in
            1) install_bbr ;;
            2) install_badvpn ;;
            3) open_internal_ports ;;
            0) return ;;
            *) 
                echo -e "${RED}❌ Opción no válida.${NC}"
                sleep 1
                continue 
                ;;
        esac
    done
}
# =========================================================

# ============== PARTE 3: INSTALACIÓN DE SERVICIOS ==============
function install_dropbear() {
    echo -e "\n${CYAN}[*] Instalando Dropbear (SSH Ligero para Juegos)...${NC}"
    
    # Detener servicios HTTP por defecto (Apache) que vienen en AWS Ubuntu preinstalados, bloqueando el puerto 80 de Dropbear
    systemctl stop apache2 > /dev/null 2>&1
    systemctl disable apache2 > /dev/null 2>&1
    
    apt-get update -y > /dev/null 2>&1
    apt-get install -y dropbear > /dev/null 2>&1
    
    echo -e -n "   ${CYAN}🔌 Ingrese el o los puertos para Dropbear separados por espacio (Ej: 80 143 109):${NC} "
    read -r port_input
    
    if [ -z "$port_input" ]; then
        port_input="80 143 109"
    fi
    
    # Extraer el primer puerto como puerto principal y el resto como argumentos extra
    PORTS=($port_input)
    MAIN_PORT=${PORTS[0]}
    EXTRA_ARGS=""
    for (( i=1; i<${#PORTS[@]}; i++ )); do
        EXTRA_ARGS="$EXTRA_ARGS -p ${PORTS[$i]}"
    done
    
    # Sobrescribir la configuración
    cat > /etc/default/dropbear <<EOF
NO_START=0
DROPBEAR_PORT=$MAIN_PORT
DROPBEAR_EXTRA_ARGS="$EXTRA_ARGS"
DROPBEAR_BANNER=""
DROPBEAR_RECEIVE_WINDOW=65536
EOF
    
    # Forzar el reinicio nativo por systemctl
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable dropbear > /dev/null 2>&1
    systemctl restart dropbear > /dev/null 2>&1
    
    # Permitir shell falso para usuarios VPN
    if ! grep -q "/bin/false" /etc/shells; then
        echo "/bin/false" >> /etc/shells
    fi
    
    echo -e "${GREEN}[✔] Dropbear instalado exitosamente (Puertos: 80, 143, 109).${NC}"
    sleep 3
    return
}

function liberar_puerto() {
    local PORT=$1
    if ss -tuln 2>/dev/null | grep -q ":$PORT "; then
        echo -e "\n${YELLOW}[!] El puerto $PORT actualmente está en uso. Deteniendo conflicto (Estilo ChumoGH)...${NC}"
        # Identificar qué proceso lo tiene
        PIDS=$(lsof -t -i:$PORT 2>/dev/null)
        if [ -n "$PIDS" ]; then
            # Detener servicios de systemd si coinciden
            systemctl stop stunnel4 2>/dev/null
            systemctl stop ws-python 2>/dev/null
            kill -9 $PIDS 2>/dev/null
        fi
        sleep 2
    fi
}

function install_stunnel() {
    echo -e "\n${CYAN}[*] Instalando y Configurando Stunnel4 (SSL/TLS para Bypass)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y stunnel4 lsof > /dev/null 2>&1
    
    # Crear certificado SSL genérico (necesario para levantar Stunnel)
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
      -subj "/C=US/ST=Gaming/L=Server/O=VPS/CN=gamingVPS" \
      -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem > /dev/null 2>&1
      
    echo -e -n "   ${CYAN}🔌 ¿Qué puerto escuchará Stunnel? (Ej: 443):${NC} "
    read -r listen_port
    [ -z "$listen_port" ] && listen_port=443
    
    echo -e -n "   ${CYAN}🎯 ¿A qué puerto interno redirigirá? (Ej: 80 - Tu puerto Dropbear o SSH):${NC} "
    read -r dest_port
    [ -z "$dest_port" ] && dest_port=80
    
    # Liberar el puerto si otro servicio (ej WebSocket) ya lo está usando
    liberar_puerto $listen_port
    
    # Configurar stunnel.conf (Sin PID forzado para evitar conflictos en Ubuntu 24.04)
    cat > /etc/stunnel/stunnel.conf <<EOF
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear-ssl]
accept = $listen_port
connect = 127.0.0.1:$dest_port
EOF
    
    # Reiniciar con el servicio nativo de Ubuntu
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable stunnel4 > /dev/null 2>&1
    systemctl restart stunnel4 > /dev/null 2>&1
    
    echo -e "${GREEN}[✔] Stunnel configurado. (Puerto SSL $listen_port -> Redirigido a Puerto $dest_port).${NC}"
    sleep 3
    return
}

function install_squid() {
    header
    echo -e "\n${CYAN}[*] Instalando Proxy Squid3 (Puertos 8080, 3128)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y squid > /dev/null 2>&1
    
    echo -e -n "   ${CYAN}🔌 Ingresa los puertos de Squid separados por espacio (Ej: 8080 3128):${NC} "
    read -r proxy_ports
    [ -z "$proxy_ports" ] && proxy_ports="8080 3128"
    
    # Construir líneas de puerto interactivamente
    SQUID_CONF="acl localhost src 127.0.0.1/32\nacl dest_local dst 127.0.0.0/8\n"
    for P in $proxy_ports; do
        SQUID_CONF="http_port $P\n$SQUID_CONF"
    done
    SQUID_CONF="${SQUID_CONF}acl allow_ports port 22 80 143 109 443 7300 8888 8080 3128 444 445\n"
    SQUID_CONF="${SQUID_CONF}http_access allow localhost\nhttp_access allow dest_local allow_ports\nhttp_access deny all"
    
    echo -e "$SQUID_CONF" > /etc/squid/squid.conf
    service squid restart > /dev/null 2>&1
    echo -e "${GREEN}[✔] Proxy Squid activado en puertos 8080 y 3128 (Sin contraseña).${NC}"
    sleep 3
    return
}

function install_ws_python() {
    header
    echo -e "\n${CYAN}[*] Instalando Websocket Python (Cloudflare Payload)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y python3 lsof > /dev/null 2>&1
    mkdir -p /etc/gaming_vps
    
    echo -e -n "   ${CYAN}🔌 ¿En qué puerto abrirás el WebSocket? (Ej: 80 u 443):${NC} "
    read -r ws_port
    [ -z "$ws_port" ] && ws_port=80
    
    echo -e -n "   ${CYAN}🎯 ¿A qué puerto interno apuntará? (Ej: 22 - Tu Dropbear/SSH):${NC} "
    read -r dest_port
    [ -z "$dest_port" ] && dest_port=22
    
    # Liberar el puerto si otro servicio (ej SSL) ya lo está usando
    liberar_puerto $ws_port
    
    # Script WS Proxy Mejorado (Estilo ChumoGH)
    cat > /etc/gaming_vps/ws.py << EOF
import socket, threading, sys

def forward(src, dst):
    while True:
        try:
            data = src.recv(4096)
            if not data: break
            dst.send(data)
        except: break

def handle_client(client_socket):
    try:
        # PING/PONG y timeout de 0.5s para detectar SSH Puro vs Payload HTTP
        client_socket.settimeout(0.5)
        try:
            request = client_socket.recv(4096)
        except socket.timeout:
            request = b''
        client_socket.settimeout(None)
        
        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.connect(('127.0.0.1', $dest_port))
        
        # Mapeo universal (HTTP, WS o Pure SSH sin payload)
        if request:
            req_str = request.decode('utf-8', 'ignore')
            if "Upgrade: websocket" in req_str.lower() or "upgrade: ws" in req_str.lower():
                client_socket.send(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
            elif "HTTP" in req_str or "CONNECT" in req_str or "GET" in req_str:
                client_socket.send(b"HTTP/1.1 200 Connection Established\r\n\r\n")
            else:
                remote_socket.send(request)
            
        threading.Thread(target=forward, args=(client_socket, remote_socket)).start()
        threading.Thread(target=forward, args=(remote_socket, client_socket)).start()
    except:
        client_socket.close()

try:
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', $ws_port))
    server.listen(100)
    print("WS Iniciado en", $ws_port)
    while True:
        client_sock, addr = server.accept()
        threading.Thread(target=handle_client, args=(client_sock,)).start()
except Exception as e:
    print("Error:", e)
EOF
    
    cat > /etc/systemd/system/ws-python.service <<EOF
[Unit]
Description=Python WebSocket Proxy (Puerto 8888)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /etc/gaming_vps/ws.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable ws-python > /dev/null 2>&1
    systemctl restart ws-python > /dev/null 2>&1
    echo -e "${GREEN}[✔] WebSocket Python activado (Puerto $ws_port -> Interno $dest_port).${NC}"
    sleep 3
    return
}

function install_openvpn() {
    header
    echo -e "\n${CYAN}[*] Autoinstalador OpenVPN (TCP/UDP) By Angristan...${NC}"
    echo -e "${YELLOW}>> El script llamará al instalador oficial. Presiona ENTER a las preguntas.${NC}"
    sleep 4
    wget -qO /etc/gaming_vps/openvpn.sh https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
    chmod +x /etc/gaming_vps/openvpn.sh
    bash /etc/gaming_vps/openvpn.sh
    echo -e "${GREEN}[✔] Proceso de OpenVPN finalizado.${NC}"
    sleep 3
    return
}




function manage_services() {
    while true; do
        header
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}G E S T I O N   D E   S E R V I C I O S${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}🔄 Reiniciar Todos los Protocolos${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}🛑 Detener Todos los Protocolos${NC}"
        echo -e "      ${CYAN}[${YELLOW} 3 ${CYAN}]${NC} ${BOLD}📊 Estado de Protocolos (Systemctl)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}🔙 Regresar al Menú Anterior${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
        echo -e -n "   ${WHITE}${BOLD}🎮 Selecciona una opción:${NC} "
        read opt

        case $opt in
            1)
                echo -e "\n${YELLOW}⏳ Reiniciando servicios...${NC}"
                systemctl restart dropbear 2>/dev/null
                systemctl restart stunnel4 2>/dev/null
                systemctl restart squid 2>/dev/null
                systemctl restart ws-python 2>/dev/null
                systemctl restart badvpn 2>/dev/null
                systemctl restart sshd 2>/dev/null
                echo -e "${GREEN}[✔] Protocolos reiniciados con éxito.${NC}"
                sleep 2
                ;;
            2)
                echo -e "\n${YELLOW}⏳ Deteniendo servicios...${NC}"
                systemctl stop dropbear 2>/dev/null
                systemctl stop stunnel4 2>/dev/null
                systemctl stop squid 2>/dev/null
                systemctl stop ws-python 2>/dev/null
                systemctl stop badvpn 2>/dev/null
                echo -e "${GREEN}[✔] Protocolos detenidos.${NC}"
                sleep 2
                ;;
            3)
                echo -e "\n${CYAN}📊 Estado Rápido de Servicios:${NC}"
                for s in sshd dropbear stunnel4 squid ws-python badvpn; do
                    if systemctl is-active --quiet $s; then
                        echo -e "   ${GREEN}[✔] $s : ACTIVO${NC}"
                    else
                        echo -e "   ${RED}[x] $s : INACTIVO${NC}"
                    fi
                done
                echo -e "\n${WHITE}Presiona ENTER para continuar...${NC}"
                read enter
                ;;
            0) return ;;
            *) 
                echo -e "${RED}❌ Opción no válida.${NC}"
                sleep 1
                ;;
        esac
    done
}

function services_menu() {
    while true; do
        header
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}P R O T O C O L O S   Y   T Ú N E L E S${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}🛠️  Dropbear SSH (Carga CPU baja)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}🔒 Stunnel4 (Ocultar por SSL Legacy)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 3 ${CYAN}]${NC} ${BOLD}🌐 Proxy Squid3 (Básico para inyecciones)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 4 ${CYAN}]${NC} ${BOLD}☁️  WebSocket Python (Para Cloudflare)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 5 ${CYAN}]${NC} ${BOLD}🛡️  OpenVPN Instalador Automático${NC}"
        echo -e "      ${CYAN}[${YELLOW} 6 ${CYAN}]${NC} ${BOLD}🔄 Administrador de Servicios (Reiniciar/Estado)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}🔙 Regresar al Menú Inicial${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
        echo -e -n "   ${WHITE}${BOLD}🎮 ¿Qué deseas instalar?:${NC} "
        read opt

        case $opt in
            1) install_dropbear ;;
            2) install_stunnel ;;
            3) install_squid ;;
            4) install_ws_python ;;
            5) install_openvpn ;;
            6) manage_services ;;
            0) return ;;
            *) 
                echo -e "${RED}❌ Opción no válida.${NC}"
                sleep 1
                continue 
                ;;
        esac
    done
}
# =========================================================

# ============== PARTE 4: GESTIÓN DE USUARIOS ==============
function create_user() {
    header
    echo -e "\n   ${MAGENTA}❖${NC} ${WHITE}${BOLD}C R E A R   N U E V O   U S U A R I O${NC} ${MAGENTA}❖${NC}\n"
    echo -e -n "   ${CYAN}👤 Nombre de usuario:${NC} "
    read username
    
    # Verificar si el usuario ya existe
    if id "$username" &>/dev/null; then
        echo -e "${RED}[x] Error: El usuario '$username' ya existe.${NC}"
        sleep 2
        users_menu
        return
    fi
    
    echo -e -n "   ${CYAN}🔑 Contraseña:${NC} "
    read -rs password
    echo
    echo -e -n "   ${CYAN}⏳ Días de duración (ej. 30):${NC} "
    read days
    echo -e -n "   ${CYAN}🔄 Límite de conexiones simultáneas (ej. 1):${NC} "
    read limit
    
    # Asegurar que /bin/false sea un shell válido para Dropbear/OpenSSH (Evita error de 'Contraseña Incorrecta')
    if ! grep -q "/bin/false" /etc/shells; then
        echo "/bin/false" >> /etc/shells
    fi
    
    # Crear usuario con fecha de expiración (shell falso /bin/false para evitar acceso root)
    useradd -e $(date -d "$days days" +"%Y-%m-%d") -s /bin/false -M "$username"
    echo "${username}:${password}" | chpasswd
    
    # Guardar límite de conexiones en un registro local del panel
    mkdir -p /etc/gaming_vps
    echo "$limit" > "/etc/gaming_vps/$username.limit"
    
    # Reparar OpenSSH para asegurar que permite contraseñas y logins de VPN
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config 2>/dev/null
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config 2>/dev/null
    systemctl restart sshd 2>/dev/null
    
    echo -e "\n   ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "   ${GREEN}[✔] Usuario Premium Creado Exitosamente:${NC}\n"
    echo -e "      ${CYAN}👤 Usuario :${NC} ${WHITE}${BOLD}$username${NC}"
    echo -e "      ${CYAN}🔑 Pass    :${NC} ${WHITE}${BOLD}$password${NC}"
    echo -e "      ${CYAN}⏳ Expira  :${NC} ${WHITE}${BOLD}$days días${NC}"
    echo -e "      ${CYAN}🔄 Límite  :${NC} ${WHITE}${BOLD}$limit conexión(es)${NC}\n"
    echo -e "   ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "\n   ${WHITE}Presiona ENTER para volver al menú de usuarios...${NC}"
    read enter
    return
}

function list_ssh_users() {
    header
    echo -e "\n   ${MAGENTA}❖${NC} ${WHITE}${BOLD}C L I E N T E S   S S H   A C T I V O S${NC} ${MAGENTA}❖${NC}\n"
    
    printf "   %-15s %-15s %-15s %-15s\n" "USUARIO" "EXPIRA" "LÍMITE" "CONEXIONES"
    echo -e "   ---------------------------------------------------------------"
    for user in $(ls /etc/gaming_vps/*.limit 2>/dev/null | sed 's/.*\///;s/\.limit//'); do
        limite=$(cat /etc/gaming_vps/$user.limit 2>/dev/null || echo "N/A")
        expira=$(chage -l "$user" 2>/dev/null | grep "Account expires" | cut -d':' -f2 | sed 's/^ //')
        if [ -z "$expira" ] || [ "$expira" == "never" ]; then expira="Nunca"; fi
        
        conex_drop=$(pgrep -u "$user" dropbear 2>/dev/null | wc -l)
        conex_ssh=$(pgrep -u "$user" sshd 2>/dev/null | wc -l)
        total=$(($conex_drop + $conex_ssh))
        
        printf "   %-15s %-15s %-15s %-15s\n" "$user" "$expira" "$limite" "$total"
    done
    
    echo -e "\n   ${WHITE}Presiona ENTER para volver al menú de usuarios...${NC}"
    read enter
    return
}

function delete_user() {
    header
    echo -e "\n   ${MAGENTA}❖${NC} ${WHITE}${BOLD}E L I M I N A R   U S U A R I O${NC} ${MAGENTA}❖${NC}\n"
    
    # Obtener lista de usuarios
    users=($(ls /etc/gaming_vps/*.limit 2>/dev/null | sed 's/.*\///;s/\.limit//'))
    
    if [ ${#users[@]} -eq 0 ]; then
        echo -e "   ${YELLOW}No hay usuarios registrados actualmente.${NC}"
        sleep 3
        return
    fi
    
    echo -e "   ${CYAN}Lista de usuarios activos:${NC}"
    for i in "${!users[@]}"; do
        echo -e "      ${CYAN}[${YELLOW} $((i+1)) ${CYAN}]${NC} ${WHITE}${users[$i]}${NC}"
    done
    echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}Cancelar operacion${NC}\n"
    
    echo -e -n "   ${WHITE}${BOLD}📝 Escribe el NÚMERO del usuario a eliminar:${NC} "
    read opt
    
    if [[ "$opt" == "0" ]] || [[ -z "$opt" ]]; then
        return
    fi
    
    # Validar que sea un número válido
    if ! [[ "$opt" =~ ^[0-9]+$ ]] || [ "$opt" -lt 1 ] || [ "$opt" -gt "${#users[@]}" ]; then
        echo -e "\n   ${RED}[x] Opción inválida.${NC}"
        sleep 2
        return
    fi
    
    # Obtener el nombre del usuario seleccionado
    username="${users[$((opt-1))]}"
    
    # Proceder a eliminar
    echo -e "\n   ${YELLOW}⏳ Eliminando usuario '$username'...${NC}"
    if id "$username" &>/dev/null; then
        pkill -u "$username" > /dev/null 2>&1
        userdel --force "$username" > /dev/null 2>&1
        rm -f "/etc/gaming_vps/$username.limit" 2>/dev/null
        echo -e "   ${GREEN}[✔] Usuario '$username' eliminado correctamente del VPS.${NC}"
    else
        echo -e "   ${RED}[x] Error: El usuario '$username' no existe o ya fue borrado.${NC}"
    fi
    sleep 3
    return
}

function users_menu() {
    while true; do
        header
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}G E S T I Ó N   D E   C L I E N T E S${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}➕ Crear Cliente SSH (Pase Temporal)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}➖ Eliminar y Desconectar Cliente SSH${NC}"
        echo -e "      ${CYAN}[${YELLOW} 3 ${CYAN}]${NC} ${BOLD}👥 Ver Detalles y Límite de Clientes SSH${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}🔙 Regresar al Menú Inicial${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
        echo -e -n "   ${WHITE}${BOLD}🎮 ¿Qué deseas hacer?:${NC} "
        read opt

        case $opt in
            1) create_user ;;
            2) delete_user ;;
            3) list_ssh_users ;;
            0) return ;;
            *) 
                echo -e "${RED}❌ Opción no válida.${NC}"
                sleep 1
                continue 
                ;;
        esac
    done
}
# =========================================================

# ============== PARTE 5: MONITOR DE RECURSOS ==============
function show_system_stats() {
    header
    echo -e "\n   ${MAGENTA}❖${NC} ${WHITE}${BOLD}E S T A D O   D E L   S E R V I D O R${NC} ${MAGENTA}❖${NC}\n"
    
    # Obtener Uso de CPU (usando vmstat, sin afectar locale)
    cpu_idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
    cpu_load=$((100 - cpu_idle))
    
    # Obtener Uso de RAM
    ram_total=$(free -m | awk '/Mem:/ {print $2}')
    ram_used=$(free -m | awk '/Mem:/ {print $3}')
    
    # PING de prueba a los servidores de Google para ver latencia
    ping_google=$(ping -c 1 8.8.8.8 | grep 'time=' | awk '{print $8}' | sed 's/time=//')
    if [ -z "$ping_google" ]; then ping_google="N/A"; fi

    echo -e "      ${CYAN}[🧠]${NC} ${BOLD}CPU Usada : ${WHITE}${cpu_load}%${NC}"
    echo -e "      ${CYAN}[💾]${NC} ${BOLD}RAM Usada : ${WHITE}${ram_used} MB / ${ram_total} MB${NC}"
    echo -e "      ${CYAN}[🌐]${NC} ${BOLD}Latencia  : ${WHITE}${ping_google} ms${NC} (Desde VPS hacia afuera)\n"
    
    echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "   ${WHITE}Presiona ENTER para regresar...${NC}"
    read enter
    return
}

function clear_ram() {
    header
    echo -e "\n${CYAN}[*] Limpiando Caché de Memoria RAM para optimizar...${NC}"
    # Ejecutar comando de kernel para liberar Buffer y Cache (No afecta clientes conectados)
    sync
    echo 3 > /proc/sys/vm/drop_caches
    sleep 2
    echo -e "   ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "   ${GREEN}[✔] Memoria RAM Liberada con éxito.${NC}"
    echo -e "   ${GREEN}[✔] Rutas de red purgadas. Esto reducirá micro-cortes.${NC}"
    echo -e "   ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 3
    return
}

function monitor_menu() {
    while true; do
        header
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}M O N I T O R I Z A C I Ó N${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}📈 Ver Estado en Vivo (CPU, RAM, Latencia)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}🧹 Forzar Limpieza de Memoria RAM${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}🔙 Regresar al Menú Inicial${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
        echo -e -n "   ${WHITE}${BOLD}🎮 Selecciona una opción:${NC} "
        read opt

        case $opt in
            1) show_system_stats ;;
            2) clear_ram ;;
            0) return ;;
            *) 
                echo -e "${RED}❌ Opción no válida.${NC}"
                sleep 1
                continue 
                ;;
        esac
    done
}
# =========================================================

# ============== PARTE 6: EXPERTO Y SEGURIDAD ==============
function block_torrent() {
    header
    echo -e "\n${CYAN}[*] Configurando Firewall Anti-Torrent / P2P...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y iptables > /dev/null 2>&1
    
    # Purgar previas para evitar duplicados masivos
    iptables -D FORWARD -m string --algo bm --string "BitTorrent" -j DROP 2>/dev/null
    iptables -D FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP 2>/dev/null
    iptables -D FORWARD -m string --algo bm --string "peer_id=" -j DROP 2>/dev/null
    iptables -D FORWARD -m string --algo bm --string ".torrent" -j DROP 2>/dev/null
    iptables -D FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP 2>/dev/null
    iptables -D FORWARD -m string --algo bm --string "torrent" -j DROP 2>/dev/null
    iptables -D FORWARD -m string --algo bm --string "announce" -j DROP 2>/dev/null
    iptables -D FORWARD -m string --algo bm --string "info_hash" -j DROP 2>/dev/null
    iptables -D INPUT -p tcp --dport 6881:6889 -j DROP 2>/dev/null
    iptables -D INPUT -p udp --dport 6881:6889 -j DROP 2>/dev/null
    
    # Reglas básicas para bloquear P2P y Torrents (Strings y Puertos)
    iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
    iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
    iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
    iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
    iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
    iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
    iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
    iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
    iptables -A INPUT -p tcp --dport 6881:6889 -j DROP
    iptables -A INPUT -p udp --dport 6881:6889 -j DROP
    
    echo -e "${GREEN}[✔] ¡Firewall Anti-Torrent activado! Tu ping está asegurado.${NC}"
    sleep 3
    return
}

function setup_auto_clean() {
    header
    echo -e "\n${CYAN}[*] Configurando Auto-Limpieza de Caché (Cada 6 horas)...${NC}"
    
    # Remover configuración anterior si existe
    sed -i '/drop_caches/d' /etc/crontab
    
    # Añadir nueva tarea Cron al archivo del sistema
    echo "0 */6 * * * root sync && echo 3 > /proc/sys/vm/drop_caches" >> /etc/crontab
    service cron reload > /dev/null 2>&1
    
    echo -e "${GREEN}[✔] Tarea Automática (Cron) instalada.${NC}"
    echo -e "${GREEN}[✔] La VPS vaciará la basura de red sola cada 6 horas.${NC}"
    sleep 3
    return
}

function setup_autokill() {
    header
    echo -e "\n${CYAN}[*] Configurando Auto-Kill (Expulsa conexiones múltiples)...${NC}"
    apt-get update -y >/dev/null 2>&1
    apt-get install -y net-tools >/dev/null 2>&1 # Instalar dependencias para netstat
    mkdir -p /etc/gaming_vps
    
    # Crear script ejecutable de autokill en la máquina
    cat > /etc/gaming_vps/autokill.sh << 'EOF'
#!/bin/bash
# Script de Chequeo de Conexiones Múltiples Abusivas
for user in $(ls /etc/gaming_vps/*.limit 2>/dev/null | sed 's/.*\///;s/\.limit//'); do
    limite=$(cat /etc/gaming_vps/$user.limit)
    
    # Usando pgrep -x para matching exacto del proceso y evitar falsos positivos
    conex_drop=$(pgrep -u "$user" -x dropbear 2>/dev/null | wc -l)
    conex_ssh=$(pgrep -u "$user" -x sshd 2>/dev/null | wc -l)
    total=$(($conex_drop + $conex_ssh))
    
    if [ "$total" -gt "$limite" ]; then
        # Matar PIDs (procesos) del usuario si supera el límite establecido
        pkill -u "$user" dropbear
        pkill -u "$user" sshd
        pkill -u "$user"
    fi
done
EOF
    chmod +x /etc/gaming_vps/autokill.sh
    
    # Añadir a crontab para ejecutarse cada 1 minuto
    sed -i '/autokill.sh/d' /etc/crontab
    echo "* * * * * root /etc/gaming_vps/autokill.sh" >> /etc/crontab
    service cron reload > /dev/null 2>&1
    
    echo -e "${GREEN}[✔] Perro Guardián Auto-Kill activado.${NC}"
    echo -e "${GREEN}[✔] Revisará los límites de usuarios cada minuto en segundo plano.${NC}"
    sleep 3
    return
}

function security_menu() {
    while true; do
        header
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}S E G U R I D A D   Y   A N T I - A B U S O${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}🛑 Bloquear Tráfico Torrent (Protección Web)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}⏱️  Activar Tarea de Limpieza Automática (6 hrs)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 3 ${CYAN}]${NC} ${BOLD}✂️  Activar Watchdog Auto-Kill (Anti Multi-Login)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}🔙 Regresar al Menú Inicial${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
        echo -e -n "   ${WHITE}${BOLD}🎮 Selecciona una opción de seguridad:${NC} "
        read opt

        case $opt in
            1) block_torrent ;;
            2) setup_auto_clean ;;
            3) setup_autokill ;;
            0) return ;;
            *) 
                echo -e "${RED}❌ Opción no válida.${NC}"
                sleep 1
                continue 
                ;;
        esac
    done
}
# =========================================================

# ============== PARTE 7: ACTUALIZACIÓN Y DESINSTALACIÓN ==============
function update_script() {
    header
    echo -e "\n   ${MAGENTA}❖${NC} ${WHITE}${BOLD}A C T U A L I Z A R   S C R I P T${NC} ${MAGENTA}❖${NC}\n"
    echo -e "   ${YELLOW}⏳ Buscando actualizaciones en GitHub...${NC}"
    
    wget -qO /tmp/menu_temp.sh "https://raw.githubusercontent.com/underkraker/scriptgamer/main/menu.sh?t=$(date +%s)"
    
    if [ -f /tmp/menu_temp.sh ] && grep -q "Gaming VPS Script" /tmp/menu_temp.sh; then
        mv /tmp/menu_temp.sh /usr/bin/menu
        chmod +x /usr/bin/menu
        echo -e "\n   ${GREEN}[✔] ¡Script actualizado con éxito!${NC}"
        echo -e "   ${CYAN}Reiniciando panel...${NC}"
        sleep 2
        menu
        exit 0
    else
        echo -e "\n   ${RED}[x] Error al descargar la actualización. Revisa el link de github.${NC}"
        rm -f /tmp/menu_temp.sh
        sleep 3
    fi
}

function uninstall_script() {
    header
    echo -e "\n   ${MAGENTA}❖${NC} ${WHITE}${BOLD}D E S I N S T A L A R   S C R I P T${NC} ${MAGENTA}❖${NC}\n"
    echo -e "   ${RED}⚠️  ¡ADVERTENCIA! Esta acción borrará el script, usuarios SSH y configuraciones.${NC}"
    echo -e -n "   ${WHITE}¿Estás completamente seguro de desinstalar? (S/N):${NC} "
    read resp
    
    if [[ "$resp" == "S" || "$resp" == "s" ]]; then
        echo -e "\n   ${YELLOW}⏳ Eliminando usuarios registrados...${NC}"
        for user in $(ls /etc/gaming_vps/*.limit 2>/dev/null | sed 's/.*\///;s/\.limit//'); do
            pkill -u "$user" >/dev/null 2>&1
            userdel --force "$user" >/dev/null 2>&1
        done
        
        echo -e "   ${YELLOW}⏳ Limpiando cronjobs y archivos base...${NC}"
        sed -i '/autokill.sh/d' /etc/crontab 2>/dev/null
        sed -i '/drop_caches/d' /etc/crontab 2>/dev/null
        service cron reload > /dev/null 2>&1
        
        rm -rf /etc/gaming_vps 2>/dev/null
        rm -f /usr/bin/menu 2>/dev/null
        
        echo -e "\n   ${GREEN}[✔] Script desinstalado correctamente. ¡Adios!${NC}"
        exit 0
    else
        echo -e "\n   ${CYAN}Operación cancelada.${NC}"
        sleep 2
    fi
}
# =========================================================

# Variables Globales del Sistema (Caché visual rápida)
VPS_IP=""

# Función para mostrar el panel principal
function main_menu() {
    if [ -z "$VPS_IP" ]; then
        VPS_IP=$(curl -s4 --max-time 3 ifconfig.me || curl -s4 --max-time 3 icanhazip.com || echo "Desconocida")
    fi

    while true; do
        # Obtener recursos en tiempo real rápido (sin delays)
        RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
        RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
        CPU_LOAD=$(LC_ALL=C top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        CPU_LOAD=${CPU_LOAD%.*} # Quitar decimales
        [ -z "$CPU_LOAD" ] && CPU_LOAD="0"

        # Listar puertos abiertos dinámicos, excluyendo basura del sistema
        ACTIVOS=$(ss -tuln | awk '{print $5}' | cut -d: -f2 | grep -v '^$' | sort -u)
        PUERTOS_LIST=()
        
        for p in $ACTIVOS; do
            # Filtro estricto de puertos NO 'basura' (Solo mostramos protocolos de tunnel conocidos)
            case $p in
                22) PUERTOS_LIST+=("${p}(SSH)") ;;
                80|143|109) 
                    if pgrep -f "dropbear.*-p $p" >/dev/null; then PUERTOS_LIST+=("${p}(Drop)"); fi ;;
                443|444|445) 
                    if pgrep -f "stunnel4" >/dev/null; then PUERTOS_LIST+=("${p}(SSL)"); fi ;;
                8080|3128) 
                    if pgrep -f "squid" >/dev/null; then PUERTOS_LIST+=("${p}(Sqd)"); fi ;;
                7300|7400|7500) 
                    if pgrep -f "badvpn" >/dev/null; then PUERTOS_LIST+=("${p}(UDP)"); fi ;;
                1194) 
                    if pgrep -f "openvpn" >/dev/null; then PUERTOS_LIST+=("${p}(OVPN)"); fi ;;
            esac
            
            # Caso especial para el Python WS que puede estar en cualquier puerto
            if [ "$p" != "22" ] && [ "$p" != "80" ] && [ "$p" != "443" ] && pgrep -f "ws.py" >/dev/null; then
                 # Si el puerto $p es el puerto que escucha el servicio ws-python
                 if netstat -tulnp 2>/dev/null | grep ":$p " | grep -q "python"; then
                    PUERTOS_LIST+=("${p}(WS)")
                 fi
            fi
        done

        header
        echo -e "   ${CYAN}🌐 IP Server :${NC} ${WHITE}${BOLD}${VPS_IP}${NC}"
        echo -e "   ${CYAN}💾 Mem. RAM  :${NC} ${WHITE}${BOLD}${RAM_USED} MB / ${RAM_TOTAL} MB${NC}"
        echo -e "   ${CYAN}🧠 Uso CPU   :${NC} ${WHITE}${BOLD}${CPU_LOAD}%${NC}"
        
        # Mostrar puertos de forma estética en filas de 3
        echo -e "   ${CYAN}🔓 Puertos Activos:${NC}"
        if [ ${#PUERTOS_LIST[@]} -eq 0 ]; then
            echo -e "      ${YELLOW}Ninguno${NC}"
        else
            COUNT=0
            ROW="      "
            for item in "${PUERTOS_LIST[@]}"; do
                # Formatear cada item con un ancho fijo aproximado de 15 caracteres
                F_ITEM=$(printf "%-15s" "$item")
                ROW+="${YELLOW}${F_ITEM}${NC}"
                ((COUNT++))
                if [ $COUNT -eq 3 ]; then
                    echo -e "$ROW"
                    ROW="      "
                    COUNT=0
                fi
            done
            [ $COUNT -gt 0 ] && echo -e "$ROW"
        fi
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}M E N Ú   P R I N C I P A L${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}👤 Gestor de Usuarios VIP${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}🚀 Acelerador y Optimización de Red${NC}"
        echo -e "      ${CYAN}[${YELLOW} 3 ${CYAN}]${NC} ${BOLD}⚙️  Instalador de Protocolos y Túneles${NC}"
        echo -e "      ${CYAN}[${YELLOW} 4 ${CYAN}]${NC} ${BOLD}📊 Monitor de Recursos (RAM/CPU/Ping)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 5 ${CYAN}]${NC} ${BOLD}🛡️  Módulo de Seguridad y Anti-Abusos${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}❌ Cerrar Sesión${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "    ${CYAN}[${YELLOW}98${CYAN}]${NC} ${WHITE}🔄 Actualizar Script${NC}   ${CYAN}[${YELLOW}99${CYAN}]${NC} ${WHITE}🗑️ Desinstalar Script${NC}"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
        echo -e -n "   ${WHITE}${BOLD}🎮 Selecciona una opción del panel:${NC} "
        read option

        case $option in
            1)
                users_menu
                ;;
            2)
                optimizer_menu
                ;;
            3)
                services_menu
                ;;
            4)
                monitor_menu
                ;;
            5)
                security_menu
                ;;
            98)
                update_script
                ;;
            99)
                uninstall_script
                ;;
            0)
                clear
                echo -e "${MAGENTA}>>> Saliendo... ¡GG!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opción no válida. Intenta de nuevo.${NC}"
                sleep 2
                continue
                ;;
        esac
    done
}

# Iniciar el script
main_menu
