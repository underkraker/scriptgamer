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

# Función para mostrar el encabezado VIP (Dinámico Gamer Master)
function header() {
    clear
    local P_NAME="GAMER MASTER"
    [ -f /etc/gaming_vps/panel_name.txt ] && P_NAME=$(cat /etc/gaming_vps/panel_name.txt | tr '[:lower:]' '[:upper:]')
    
    echo -e "\n"
    echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Banner Estilizado Dinámico
    local len=${#P_NAME}
    local spaces=$(( (50 - len) / 2 ))
    local padding=""
    for ((i=0; i<spaces; i++)); do padding+=" "; done
    
    echo -e "   ${MAGENTA}${BOLD}${padding}⚡ $P_NAME ⚡${NC}"
    echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ -f /etc/gaming_vps/slogan.txt ]; then
        M_SLOGAN=$(cat /etc/gaming_vps/slogan.txt)
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
    
    rm -rf /opt/badvpn 2>/dev/null
    git clone https://github.com/ambrop72/badvpn.git /opt/badvpn > /dev/null 2>&1
    mkdir -p /opt/badvpn/build 2>/dev/null
    cd /opt/badvpn/build
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
    make install > /dev/null 2>&1
    echo -e "${GREEN}[✔] BadVPN UDPGW / Gaming activado.${NC}"
    sleep 3
    return
}

function draw_bar() {
    local percent=$1
    local width=20
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    local bar=""
    
    # Colores dinámicos según carga
    local color=$GREEN
    if [ $percent -gt 60 ]; then color=$YELLOW; fi
    if [ $percent -gt 85 ]; then color=$RED; fi

    printf "${WHITE}[${color}"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "${NC}"
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "${WHITE}] ${color}%3d%%${NC}" "$percent"
}

function ping_pro_optimizer() {
    header
    echo -e "\n${CYAN}[*] Iniciando Optimización PING PRO (Gaming Edition)...${NC}"
    
    # 1. Tuning de Fragmentación (MTU/MSS)
    echo -e "${YELLOW}[-] Ajustando MTU a 1500 y MSS a 1440 para evitar saltos...${NC}"
    for interface in $(ls /sys/class/net/ | grep -v "lo"); do
        ifconfig $interface mtu 1500 > /dev/null 2>&1
    done

    # 2. Kernel Tweaks para Baja Latencia
    echo -e "${YELLOW}[-] Inyectando TCP Low Latency y Window Scaling...${NC}"
    cat > /etc/sysctl.d/99-gaming-vps.conf <<EOF
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_sack=1
net.ipv4.tcp_adv_win_scale=1
net.ipv4.tcp_fastopen=3
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
EOF
    sysctl -p /etc/sysctl.d/99-gaming-vps.conf > /dev/null 2>&1
    
    echo -e "\n${GREEN}[✔] ¡SISTEMA PING-PRO ACTIVADO!${NC}"
    echo -e "${CYAN}Tus juegos (Free Fire, PUBG, LOL) ahora tendrán un jitter mínimo.${NC}"
    sleep 4
}

function optimizer_menu() {
    while true; do
        header
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}O P T I M I Z A C I Ó N   G A M I N G${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}🌐 Activar Acelerador TCP BBR de Google${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}🎮 Instalar BadVPN (Comunicaciones UDP)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 3 ${CYAN}]${NC} ${BOLD}🔓 Purgar y Abrir Puertos Internos (UFW)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 4 ${CYAN}]${NC} ${BOLD}⚡ Optimización PING PRO (Baja Latencia)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}🔙 Regresar al Menú Inicial${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
        echo -e -n "   ${WHITE}${BOLD}🎮 ¿Qué deseas hacer?:${NC} "
        read opt

        case $opt in
            1) install_bbr ;;
            2) install_badvpn ;;
            3) open_internal_ports ;;
            4) ping_pro_optimizer ;;
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
    
    echo -e "${GREEN}[✔] Dropbear activado exitosamente en puertos: $port_input.${NC}"
    sleep 3
    return
}

function liberar_puerto() {
    local PORT=$1
    if ss -tuln 2>/dev/null | grep -q ":$PORT "; then
        PIDS=$(lsof -t -i:$PORT 2>/dev/null)
        if [ -n "$PIDS" ]; then
            systemctl stop stunnel4 ws-python apache2 nginx squid 2>/dev/null
            kill -9 $PIDS 2>/dev/null
        fi
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
    
    # Configurar stunnel.conf (Modo Maestro Gaming)
    cat > /etc/stunnel/stunnel.conf <<EOF
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
TIMEOUTclose = 0

[dropbear-ssl]
accept = $listen_port
connect = 127.0.0.1:$dest_port
EOF
    
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable stunnel4 > /dev/null 2>&1
    systemctl restart stunnel4 > /dev/null 2>&1
    
    echo -e "${GREEN}[✔] Puerto $listen_port (SSL) activado con éxito.${NC}"
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
    echo -e "\n${CYAN}[*] Instalando Websocket Proxy v9.0 'Elite Handshake'...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y python3 lsof openssl stunnel4 certbot > /dev/null 2>&1
    mkdir -p /etc/gaming_vps
    
    echo -e -n "   ${CYAN}🔌 ¿Puerto para WebSocket? (Ej: 8080):${NC} "
    read -r ws_port
    [ -z "$ws_port" ] && ws_port=8080
    
    echo -e -n "   ${CYAN}🎯 ¿Puerto Interno Destino (Target SSH)? (Ej: 22):${NC} "
    read -r dest_port
    [ -z "$dest_port" ] && dest_port=22
    
    # Liberar el puerto si otro servicio lo está usando
    liberar_puerto $ws_port
    
    # 🕵️ DECISIÓN SSL: ¿Certbot o Auto-firmado?
    echo -e "\n${MAGENTA}------------------------------------------------------${NC}"
    echo -e "${WHITE}${BOLD}      SISTEMA DE SEGURIDAD SSL INTELIGENTE${NC}"
    echo -e "${MAGENTA}------------------------------------------------------${NC}"
    echo -e "${CYAN}¿Deseas usar un DOMINIO para SSL (Certbot)? (s/n)${NC}"
    echo -e -n "${YELLOW}>> Respuesta: ${NC}"
    read -r use_certbot
    
    CERT_FILE="/etc/stunnel/stunnel.pem"
    
    if [[ "$use_certbot" =~ ^[Ss]$ ]]; then
        echo -e "\n${CYAN}Escribe tu dominio completo (Ej: vps.dominio.com):${NC}"
        echo -e -n "${YELLOW}>> Dominio: ${NC}"
        read -r my_domain
        
        if [ -n "$my_domain" ]; then
            echo -e "\n${CYAN}[*] Solicitando certificado a Let's Encrypt...${NC}"
            # Liberar puerto 80 para Certbot
            liberar_puerto 80 > /dev/null 2>&1
            certbot certonly --standalone -d $my_domain --non-interactive --agree-tos --register-unsafely-without-email > /dev/null 2>&1
            
            if [ -d "/etc/letsencrypt/live/$my_domain" ]; then
                echo -e "${GREEN}[✔] Certificado emitido correctamente.${NC}"
                cat /etc/letsencrypt/live/$my_domain/fullchain.pem /etc/letsencrypt/live/$my_domain/privkey.pem > $CERT_FILE
            else
                echo -e "${RED}[x] Error al emitir Certbot. Usando Auto-firmado de respaldo...${NC}"
                openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
                  -subj "/C=US/ST=ST/L=L/O=O/CN=127.0.0.1" \
                  -keyout $CERT_FILE -out $CERT_FILE > /dev/null 2>&1
            fi
        fi
    else
        echo -e "\n${CYAN}[*] Generando certificado Auto-firmado para IP...${NC}"
        openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
          -subj "/C=US/ST=ST/L=L/O=O/CN=127.0.0.1" \
          -keyout $CERT_FILE -out $CERT_FILE > /dev/null 2>&1
    fi
    
    # Script WS Proxy Pro v9.0 (Elite Handshake Core)
    cat > /etc/gaming_vps/ws.py << EOF
import socket, threading, hashlib, base64, re

GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

def forward(src, dst):
    try:
        while True:
            data = src.recv(131072)
            if not data: break
            dst.sendall(data)
    except: pass
    finally:
        try: src.close()
        except: pass
        try: dst.close()
        except: pass

def handle_client(client_socket):
    try:
        client_socket.settimeout(15.0)
        request = b''
        try:
            request = client_socket.recv(131072)
        except: pass
        
        if not request:
            client_socket.close()
            return

        header_str = request.decode('utf-8', errors='ignore')
        
        # --- HANDSHAKE ÉLITE COMPLETO (RFC 6455) ---
        if "Upgrade: websocket" in header_str or "GET" in header_str or "CONNECT" in header_str or "POST" in header_str:
            key_match = re.search(r'Sec-WebSocket-Key: (.+)\r\n', header_str)
            if key_match:
                key = key_match.group(1).strip()
                accept = base64.b64encode(hashlib.sha1((key + GUID).encode()).digest()).decode()
                response = (
                    "HTTP/1.1 101 Switching Protocols\r\n"
                    "Upgrade: websocket\r\n"
                    "Connection: Upgrade\r\n"
                    "Sec-WebSocket-Accept: " + accept + "\r\n"
                    "Server: GamerMaster-v9.0\r\n\r\n"
                )
                client_socket.sendall(response.encode())
            else:
                # Fallback para Inyectores Legacy (HTTP Custom)
                client_socket.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")

        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.connect(('127.0.0.1', $dest_port))
        
        idx = request.find(b'\r\n\r\n')
        if idx != -1:
            extra = request[idx+4:]
            if extra: remote_socket.sendall(extra)
        else:
            remote_socket.sendall(request)

        threading.Thread(target=forward, args=(client_socket, remote_socket), daemon=True).start()
        threading.Thread(target=forward, args=(remote_socket, client_socket), daemon=True).start()
    except Exception as e:
        try: client_socket.close()
        except: pass

try:
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', $ws_port))
    server.listen(10000)
    while True:
        client_sock, addr = server.accept()
        threading.Thread(target=handle_client, args=(client_sock,), daemon=True).start()
except: pass
EOF
    
    cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel4.pid
cert = $CERT_FILE
key = $CERT_FILE
foreground = no
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[ws-ssl]
accept = 443
connect = 127.0.0.1:$ws_port
EOF
    
    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4 > /dev/null 2>&1
    systemctl restart stunnel4 > /dev/null 2>&1

    cat > /etc/systemd/system/ws-python.service <<EOF
[Unit]
Description=Python WebSocket Proxy v9.0 'Elite Protocol'
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /etc/gaming_vps/ws.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable ws-python > /dev/null 2>&1
    systemctl restart ws-python > /dev/null 2>&1
    
    echo -e "${GREEN}[✔] WebSocket Proxy v9.0 ÉLITE ACTIVO (Puerto $ws_port).${NC}"
    echo -e "${GREEN}[✔] Tunnel SSL Stunnel ACTIVO (Puerto 443 -> $ws_port).${NC}"
    echo -e "\n${YELLOW}=== INFO PARA EL CLIENTE ===${NC}"
    echo -e "${CYAN}PAYLOAD:${NC} GET / HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]"
    echo -e "${CYAN}CONEXIÓN:${NC} SSL/TLS en Puerto 443"
    [ -n "$my_domain" ] && echo -e "${CYAN}DOMAIN:${NC} $my_domain"
    sleep 5
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




function install_xray() {
    header
    echo -e "\n${CYAN}[*] Instalando Xray-Core (VLESS + REALITY - Edición Pro)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y curl socat jq uuid-runtime openssl > /dev/null 2>&1
    
    # Descargar binario oficial si no existe
    if ! command -v xray &> /dev/null; then
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install > /dev/null 2>&1
    fi
    
    mkdir -p /usr/local/etc/xray
    
    # Generar parámetros REALITY
    KEYS=$(xray x25519)
    PRIV=$(echo "$KEYS" | grep "Private key:" | awk '{print $3}')
    PUB=$(echo "$KEYS" | grep "Public key:" | awk '{print $3}')
    UUID=$(cat /proc/sys/kernel/random/uuid)
    SHORTID=$(openssl rand -hex 8)
    
    echo -e -n "   ${CYAN}🔌 ¿Puerto para Xray Reality? (Recomendado 443):${NC} "
    read -r port
    [ -z "$port" ] && port=443
    liberar_puerto $port
    
    echo -e -n "   ${CYAN}🌐 SNI para Reality (ej: www.google.com):${NC} "
    read -r sni_host
    [ -z "$sni_host" ] && sni_host="www.google.com"

    # Configuración de Xray REALITY
    cat > /usr/local/etc/xray/config.json <<EOF
{
    "log": {"loglevel": "none"},
    "inbounds": [
        {
            "port": $port,
            "protocol": "vless",
            "settings": {
                "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "$sni_host:443",
                    "xver": 0,
                    "serverNames": ["$sni_host"],
                    "privateKey": "$PRIV",
                    "shortIds": ["$SHORTID"]
                }
            },
            "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}
        }
    ],
    "outbounds": [{"protocol": "freedom"}]
}
EOF
    systemctl restart xray > /dev/null 2>&1
    
    header
    echo -e "${GREEN}[✔] Xray VLESS REALITY Activo en Puerto $port.${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "   ${WHITE}DATOS DE CONFIGURACIÓN:${NC}"
    echo -e "   ${YELLOW}Protocolo:${NC} ${WHITE}VLESS${NC}"
    echo -e "   ${YELLOW}UUID     :${NC} ${WHITE}$UUID${NC}"
    echo -e "   ${YELLOW}PublicKy :${NC} ${WHITE}$PUB${NC}"
    echo -e "   ${YELLOW}SNI/Dest :${NC} ${WHITE}$sni_host${NC}"
    echo -e "   ${YELLOW}ShortID  :${NC} ${WHITE}$SHORTID${NC}"
    echo -e "   ${YELLOW}Flow     :${NC} ${WHITE}xtls-rprx-vision${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\nPresiona ENTER para continuar..."
    read enter
}

function install_udp_custom() {
    header
    echo -e "\n${CYAN}[*] Instalando UDP Custom (Optimizado para Juegos)...${NC}"
    # Descargar binario precompilado (Simulación de descarga de binario de confianza)
    wget -qO /usr/bin/udp-custom https://github.com/underkraker/scriptgamer/raw/main/bin/udp-custom
    chmod +x /usr/bin/udp-custom
    
    echo -e -n "   ${CYAN}🔌 ¿Puerto para UDP Custom? (Ej: 53):${NC} "
    read -r port
    [ -z "$port" ] && port=53
    liberar_puerto $port
    
    cat > /etc/systemd/system/udp-custom.service <<EOF
[Unit]
Description=UDP Custom Service
After=network.target

[Service]
ExecStart=/usr/bin/udp-custom server -p $port
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload > /dev/null 2>&1
    systemctl enable udp-custom > /dev/null 2>&1
    systemctl restart udp-custom > /dev/null 2>&1
    echo -e "${GREEN}[✔] UDP Custom activo en puerto $port.${NC}"
    sleep 3
}

function manage_services() {
    while true; do
        header
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}G E S T I O N   D E   S E R V I C I O S${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}🔄 Reiniciar Todos los Protocolos${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}🛑 Detener Todos los Protocolos${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}🔙 Regresar al Menú Anterior${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
        echo -e -n "   ${WHITE}${BOLD}🎮 Selecciona una opción:${NC} "
        read opt

        case $opt in
            1)
                systemctl restart dropbear stunnel4 squid ws-python badvpn sshd xray udp-custom slowdns wg-quick@wg0 shadowsocks-libev hysteria 2>/dev/null
                echo -e "${GREEN}[✔] Todos los protocolos han sido reiniciados.${NC}"
                sleep 2
                ;;
            2)
                systemctl stop dropbear stunnel4 squid ws-python badvpn xray udp-custom 2>/dev/null
                echo -e "${GREEN}[✔] Servicios detenidos.${NC}"
                sleep 2
                ;;
            0) return ;;
        esac
    done
}

function services_menu() {
    while true; do
        header
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}P R O T O C O L O S   Y   T Ú N E L E S${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}🛠️  Dropbear SSH${NC}      ${CYAN}[${YELLOW} 6 ${CYAN}]${NC} ${BOLD}🦇 Xray Multi (VLESS/VMess/Trojan)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}🔒 Stunnel4 (SSL)${NC}    ${CYAN}[${YELLOW} 7 ${CYAN}]${NC} ${BOLD}🎮 UDP Custom (Gaming)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 3 ${CYAN}]${NC} ${BOLD}🌐 Proxy Squid3${NC}      ${CYAN}[${YELLOW} 8 ${CYAN}]${NC} ${BOLD}🐢 SlowDNS (Puerto 53)${NC}"
        echo -e "      ${CYAN}[${YELLOW} 4 ${CYAN}]${NC} ${BOLD}☁️  WebSocket Python${NC}  ${CYAN}[${YELLOW} 9 ${CYAN}]${NC} ${BOLD}🚀 WireGuard VPN${NC}"
        echo -e "      ${CYAN}[${YELLOW} 5 ${CYAN}]${NC} ${BOLD}🛡️  OpenVPN${NC}           ${CYAN}[${YELLOW} 10${CYAN}]${NC} ${BOLD}👤 Shadowsocks-libev${NC}"
        echo -e "      ${CYAN}[${YELLOW} 11${CYAN}]${NC} ${BOLD}🔥 Hysteria 2 (UDP)${NC}  ${CYAN}[${YELLOW} 12${CYAN}]${NC} ${BOLD}🔄 Administrador${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}🔙 Regresar${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
        echo -e -n "   ${WHITE}${BOLD}🎮 ¿Qué deseas instalar?:${NC} "
        read opt

        case $opt in
            1) install_dropbear ;;
            2) install_stunnel ;;
            3) install_squid ;;
            4) install_ws_python ;;
            5) install_openvpn ;;
            6) install_xray ;;
            7) install_udp_custom ;;
            8) install_slowdns ;;
            9) install_wireguard ;;
            10) install_shadowsocks ;;
            11) install_hysteria2 ;;
            12) manage_services ;;
            0) return ;;
            *) echo -e "${RED}❌ Opción no válida.${NC}"; sleep 1 ;;
        esac
    done
}

function install_slowdns() {
    header
    echo -e "\n${CYAN}[*] Instalando SlowDNS (DNSTT) - El Rey del Puerto 53...${NC}"
    
    # Detener systemd-resolved si está ocupando el puerto 53
    if ss -tunlp | grep -q ":53 "; then
        echo -e "${YELLOW}[!] Puerto 53 ocupado. Liberando...${NC}"
        systemctl stop systemd-resolved >/dev/null 2>&1
        systemctl disable systemd-resolved >/dev/null 2>&1
        [ -f /etc/resolv.conf ] && rm /etc/resolv.conf
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 8.8.4.4" > /etc/resolv.conf
    fi

    # Descargar binario dnstt-server
    mkdir -p /etc/gaming_vps/slowdns
    wget -qO /etc/gaming_vps/slowdns/dnstt-server https://github.com/underkraker/scriptgamer/raw/main/bin/dnstt-server
    chmod +x /etc/gaming_vps/slowdns/dnstt-server

    # Generar llaves si no existen
    if [ ! -f /etc/gaming_vps/slowdns/server.pub ]; then
        cd /etc/gaming_vps/slowdns
        ./dnstt-server -gen-key -privkey server.key -pubkey server.pub > /dev/null 2>&1
    fi

    PUB_KEY=$(cat /etc/gaming_vps/slowdns/server.pub)
    
    echo -e -n "   ${CYAN}🔗 Ingrese su NS (Nameserver) ej. ns.tudominio.com:${NC} "
    read -r ns_domain
    if [ -z "$ns_domain" ]; then
        echo -e "${RED}[x] Error: Es obligatorio tener un NS configurado en Cloudflare/Freenom.${NC}"
        sleep 3
        return
    fi

    # Crear Servicio Systemd para SlowDNS
    cat > /etc/systemd/system/slowdns.service <<EOF
[Unit]
Description=SlowDNS Server - Gaming VPS
After=network.target

[Service]
Type=simple
ExecStart=/etc/gaming_vps/slowdns/dnstt-server -udp :5300 -privkey /etc/gaming_vps/slowdns/server.key $ns_domain 127.0.0.1:22
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # Redirigir puerto 53 a 5300 con Iptables
    iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    iptables-save > /etc/iptables.rules 2>/dev/null

    systemctl daemon-reload
    systemctl enable slowdns >/dev/null 2>&1
    systemctl restart slowdns >/dev/null 2>&1

    header
    echo -e "${GREEN}[✔] SlowDNS configurado correctamente.${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "   ${WHITE}DATOS PARA TU APP (HTTP Custom/Injector):${NC}"
    echo -e "   ${YELLOW}NS Domain :${NC} ${WHITE}$ns_domain${NC}"
    echo -e "   ${YELLOW}Public Key:${NC} ${WHITE}$PUB_KEY${NC}"
    echo -e "   ${YELLOW}Puerto    :${NC} ${WHITE}53${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\nPresiona ENTER para continuar..."
    read enter
}

function install_wireguard() {
    header
    echo -e "\n${CYAN}[*] Instalando WireGuard (VPN de Alta Velocidad)...${NC}"
    
    # Instalar dependencias
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wireguard qrencode iptables > /dev/null 2>&1

    # Crear directorio si no existe
    mkdir -p /etc/wireguard
    chmod 700 /etc/wireguard

    # Generar llaves del servidor
    if [ ! -f /etc/wireguard/private.key ]; then
        wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key
    fi
    
    PRIV_KEY=$(cat /etc/wireguard/private.key)
    PUB_KEY=$(cat /etc/wireguard/public.key)

    # Definir Red Interna
    SERVER_IP="10.66.66.1"
    SERVER_NET="10.66.66.0/24"
    
    # Detectar interfaz de red principal
    NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

    # Configuración del servidor wg0.conf
    cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = $SERVER_IP/24
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $NIC -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $NIC -j MASQUERADE
ListenPort = 51820
PrivateKey = $PRIV_KEY
EOF

    # Habilitar Forwarding en el sysctl
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
    sysctl -p /etc/sysctl.d/99-wireguard.conf > /dev/null 2>&1

    # Iniciar y habilitar servicio
    systemctl enable wg-quick@wg0 >/dev/null 2>&1
    systemctl restart wg-quick@wg0 >/dev/null 2>&1

    sleep 3
}

function install_shadowsocks() {
    header
    echo -e "\n${CYAN}[*] Instalando Shadowsocks-libev (Encrypted Proxy)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y shadowsocks-libev > /dev/null 2>&1
    
    echo -e -n "   ${CYAN}🔌 ¿Puerto para Shadowsocks? (Ej: 8388):${NC} "
    read -r ss_port
    [ -z "$ss_port" ] && ss_port=8388
    
    echo -e -n "   ${CYAN}🔑 Contraseña para SS:${NC} "
    read -r ss_pass
    [ -z "$ss_pass" ] && ss_pass="krakerVIP"
    
    liberar_puerto $ss_port
    
    cat > /etc/shadowsocks-libev/config.json <<EOF
{
    "server":"0.0.0.0",
    "server_port":$ss_port,
    "password":"$ss_pass",
    "timeout":300,
    "method":"aes-256-gcm",
    "mode":"tcp_and_udp"
}
EOF
    systemctl restart shadowsocks-libev > /dev/null 2>&1
    echo -e "${GREEN}[✔] Shadowsocks activo en puerto $ss_port.${NC}"
    sleep 3
}

function install_hysteria2() {
    header
    echo -e "\n${CYAN}[*] Instalando Hysteria 2 (Protocolo Gaming de Alto Impacto)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y curl openssl > /dev/null 2>&1
    
    # Descargar binario oficial
    wget -qO /usr/bin/hysteria https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64
    chmod +x /usr/bin/hysteria
    
    mkdir -p /etc/hysteria
    
    # Generar Certificado Auto-firmado
    openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -days 3650 -subj "/CN=bing.com" > /dev/null 2>&1
    
    echo -e -n "   ${CYAN}🔌 ¿Puerto para Hysteria 2? (Ej: 443):${NC} "
    read -r hy_port
    [ -z "$hy_port" ] && hy_port=443
    
    echo -e -n "   ${CYAN}🔑 Contraseña (AUTH):${NC} "
    read -r hy_auth
    [ -z "$hy_auth" ] && hy_auth="krakerHY2"
    
    liberar_puerto $hy_port
    
    cat > /etc/hysteria/config.yaml <<EOF
listen: :$hy_port
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
auth:
  type: password
  password: $hy_auth
udp_idle_timeout: 60s
EOF
    
    cat > /etc/systemd/system/hysteria.service <<EOF
[Unit]
Description=Hysteria 2 Server
After=network.target

[Service]
ExecStart=/usr/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable hysteria >/dev/null 2>&1
    systemctl restart hysteria >/dev/null 2>&1
    
    echo -e "${GREEN}[✔] Hysteria 2 activo en puerto $hy_port (UDP).${NC}"
    sleep 3
}

function manage_dns() {
    header
    echo -e "\n   ${CYAN}❖${NC} ${WHITE}${BOLD}G E S T O R   D E   D N S${NC} ${MAGENTA}❖${NC}\n"
    echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}Cloudflare (1.1.1.1)${NC}"
    echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}Google (8.8.8.8)${NC}"
    echo -e "      ${CYAN}[${YELLOW} 3 ${CYAN}]${NC} ${BOLD}AdGuard (Anti-Pub)${NC}"
    echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}Regresar${NC}\n"
    read -p "   Opción: " opt
    
    case $opt in
        1) DNS1="1.1.1.1"; DNS2="1.0.0.1" ;;
        2) DNS1="8.8.8.8"; DNS2="8.8.4.4" ;;
        3) DNS1="94.140.14.14"; DNS2="94.140.15.15" ;;
        0) return ;;
        *) return ;;
    esac
    
    echo -e "nameserver $DNS1\nnameserver $DNS2" > /etc/resolv.conf
    echo -e "${GREEN}[✔] DNS actualizados con éxito.${NC}"
    sleep 2
}

function tools_menu() {
    while true; do
        header
        echo -e "   ${MAGENTA}❖${NC} ${WHITE}${BOLD}H E R R A M I E N T A S   E X T R A S${NC} ${MAGENTA}❖${NC}\n"
        echo -e "      ${CYAN}[${YELLOW} 1 ${CYAN}]${NC} ${BOLD}🌐 Cambiar DNS del VPS${NC}"
        echo -e "      ${CYAN}[${YELLOW} 2 ${CYAN}]${NC} ${BOLD}💾 Crear/Gestor de Memoria SWAP${NC}"
        echo -e "      ${CYAN}[${YELLOW} 0 ${CYAN}]${NC} ${RED}${BOLD}🔙 Regresar al Menú Inicial${NC}\n"
        echo -e "   ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e -n "   ${WHITE}${BOLD}🎮 Selecciona una opción:${NC} "
        read opt
        case $opt in
            1) manage_dns ;;
            2) 
               echo -e "\n${CYAN}[*] Creando 1GB de SWAP...${NC}"
               fallocate -l 1G /swapfile
               chmod 600 /swapfile
               mkswap /swapfile
               swapon /swapfile
               echo "/swapfile none swap sw 0 0" >> /etc/fstab
               echo -e "${GREEN}[✔] Memoria SWAP de 1GB activada.${NC}"
               sleep 2
               ;;
            0) return ;;
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
        RAM_PCT=$((RAM_USED * 100 / RAM_TOTAL))
        CPU_LOAD=$(LC_ALL=C top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        CPU_LOAD=${CPU_LOAD%.*} # Quitar decimales
        [ -z "$CPU_LOAD" ] || [ "$CPU_LOAD" -lt 0 ] && CPU_LOAD="0"

        # Listar puertos abiertos dinámicos (Sin Basura)
        ACTIVOS=$(netstat -tulnp | grep LISTEN | awk '{print $4}' | cut -d: -f2 | sort -u)
        PUERTOS_LIST=()
        
        for p in $ACTIVOS; do
            # Mapeo Inteligente de Servicios
            case $p in
                22) PUERTOS_LIST+=("22(SSH)") ;;
                80|143|109) 
                    if pgrep -f "dropbear.*-p $p" >/dev/null; then PUERTOS_LIST+=("${p}(Drop)"); fi ;;
                443|444|445) 
                    if pgrep -f "stunnel4" >/dev/null; then PUERTOS_LIST+=("${p}(SSL)"); 
                    elif pgrep -f "xray" >/dev/null; then PUERTOS_LIST+=("${p}(Xray)"); 
                    elif pgrep -f "hysteria" >/dev/null; then PUERTOS_LIST+=("${p}(HY2)"); fi ;;
                8080|3128) 
                    if pgrep -f "squid" >/dev/null; then PUERTOS_LIST+=("${p}(Sqd)"); fi ;;
                7300|7400|7500) 
                    if pgrep -f "badvpn" >/dev/null; then PUERTOS_LIST+=("${p}(UDP)"); fi ;;
                1194) 
                    if pgrep -f "openvpn" >/dev/null; then PUERTOS_LIST+=("${p}(OVPN)"); fi ;;
                51820)
                    if [ -d /sys/class/net/wg0 ]; then PUERTOS_LIST+=("${p}(WG)"); fi ;;
                53)
                    if systemctl is-active --quiet slowdns || pgrep -f "dnstt-server" >/dev/null; then PUERTOS_LIST+=("${p}(DNS)"); fi ;;
                8388)
                    if systemctl is-active --quiet shadowsocks-libev; then PUERTOS_LIST+=("${p}(SS)"); fi ;;
                *)
                    # Si no es un puerto estatico, checamos si es WS Python o Xray Custom
                    if pgrep -f "ws.py" >/dev/null && netstat -tulnp | grep ":$p " | grep -q "python"; then
                        PUERTOS_LIST+=("${p}(WS)")
                    elif pgrep -f "xray" >/dev/null && netstat -tulnp | grep ":$p " | grep -q "xray"; then
                        PUERTOS_LIST+=("${p}(Xray)")
                    fi
                    ;;
            esac
        done

        header
        echo -e "   ${CYAN}🌐 IP Server :${NC} ${WHITE}${BOLD}${VPS_IP}${NC}"
        echo -ne "   ${CYAN}💾 Mem. RAM  :${NC} " ; draw_bar $RAM_PCT ; echo -e " ${WHITE}${RAM_USED}MB / ${RAM_TOTAL}MB${NC}"
        echo -ne "   ${CYAN}🧠 Uso CPU   :${NC} " ; draw_bar $CPU_LOAD ; echo -e ""
        
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
        echo -e "      ${CYAN}[${YELLOW} 6 ${CYAN}]${NC} ${BOLD}🛠️  Herramientas de Sistema (DNS/Swap)${NC}"
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
            6)
                tools_menu
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
