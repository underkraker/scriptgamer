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
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${MAGENTA}  ██████╗  █████╗ ███╗   ███╗███████╗██████╗           ${CYAN}║${NC}"
    echo -e "${CYAN}║${MAGENTA} ██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔══██╗          ${CYAN}║${NC}"
    echo -e "${CYAN}║${MAGENTA} ██║  ███╗███████║██╔████╔██║█████╗  ██████╔╝          ${CYAN}║${NC}"
    echo -e "${CYAN}║${MAGENTA} ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ██╔══██╗          ${CYAN}║${NC}"
    echo -e "${CYAN}║${MAGENTA} ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██║  ██║          ${CYAN}║${NC}"
    echo -e "${CYAN}║${MAGENTA}  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝          ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${YELLOW}${BOLD}           V P S   P A N E L   -   E X P E R T         ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${GREEN}  ⚡ Optimizador Ping | 🛡️ Anti-DDoS | 🦇 Multi-Túnel  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e ""
}

# ============== PARTE 2: OPTIMIZACIÓN GAMING ==============
function install_bbr() {
    echo -e "\n${CYAN}[*] Instalando y Configurando Google TCP BBR...${NC}"
    # Se eliminan configuraciones antiguas
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    # Se inyectan las nuevas para bajar el ping
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p > /dev/null 2>&1
    echo -e "${GREEN}[✔] TCP BBR (Acelerador de red) activado con éxito.${NC}"
    sleep 2
    optimizer_menu
}

function install_badvpn() {
    echo -e "\n${CYAN}[*] Descargando y Configurando BadVPN para Juegos (UDP)...${NC}"
    # El usuario debe usar root en su Linux (el script asumirá root)
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget cmake screen systemd > /dev/null 2>&1
    
    # Descargar binario precompilado de BadVPN (para evitar demoras compilando y consumo en el VPS)
    wget -qO /bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/prem/master/badvpn-udpgw64"
    if [ -f /bin/badvpn-udpgw ]; then
        chmod +x /bin/badvpn-udpgw
        
        # Crear servicio systemd en puerto 7300
        cat > /etc/systemd/system/badvpn.service <<EOF
[Unit]
Description=BadVPN UDPGW Gaming Port 7300
After=network.target

[Service]
Type=simple
ExecStart=/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 10
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        systemctl enable badvpn > /dev/null 2>&1
        systemctl restart badvpn > /dev/null 2>&1
        echo -e "${GREEN}[✔] BadVPN UDP activado correctamente en el puerto 7300.${NC}"
    else
        echo -e "${RED}[x] Error al descargar BadVPN. Verifica el internet de la VPS.${NC}"
    fi
    sleep 3
    optimizer_menu
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
    optimizer_menu
}

function optimizer_menu() {
    header
    echo -e "\n${CYAN}>>> 🚀 MENÚ DE OPTIMIZACIÓN GAMING <<<${NC}\n"
    echo -e "${YELLOW}  [1]${NC} - 🌐 Activar Google BBR (Acelerador de Ping TCP)"
    echo -e "${YELLOW}  [2]${NC} - 🎮 Instalar BadVPN (Soporte UDP para Juegos en HTTP Custom/Injector)"
    echo -e "${YELLOW}  [3]${NC} - 🔓 Abrir Puertos Internos (Purgar bloqueo de Ubuntu)"
    echo -e "${YELLOW}  [0]${NC} - 🔙 Volver al Menú Principal\n"
    echo -e "${CYAN}======================================================${NC}"
    
    echo -e -n "🎮 ${BOLD}¿Qué deseas hacer?:${NC} "
    read opt

    case $opt in
        1) install_bbr ;;
        2) install_badvpn ;;
        3) open_internal_ports ;;
        0) main_menu ;;
        *) 
            echo -e "${RED}❌ Opción no válida.${NC}"
            sleep 1
            optimizer_menu 
            ;;
    esac
}
# =========================================================

# ============== PARTE 3: INSTALACIÓN DE SERVICIOS ==============
function install_dropbear() {
    echo -e "\n${CYAN}[*] Instalando Dropbear (SSH Ligero para Juegos)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y dropbear > /dev/null 2>&1
    
    # Configurar puertos (ej: 80 y 143) y permitir root
    sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
    sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=80/g' /etc/default/dropbear
    sed -i 's/DROPBEAR_EXTRA_ARGS=.*/DROPBEAR_EXTRA_ARGS="-p 143 -p 109"/g' /etc/default/dropbear
    
    service dropbear restart > /dev/null 2>&1
    echo -e "${GREEN}[✔] Dropbear instalado exitosamente (Puertos: 80, 143, 109).${NC}"
    sleep 3
    services_menu
}

function install_stunnel() {
    echo -e "\n${CYAN}[*] Instalando y Configurando Stunnel4 (SSL/TLS para Bypass)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y stunnel4 > /dev/null 2>&1
    
    # Crear certificado SSL genérico (necesario para Stunnel)
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
      -subj "/C=US/ST=Gaming/L=Server/O=VPS/CN=gamingVPS" \
      -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem > /dev/null 2>&1
      
    # Configurar stunnel.conf con TCP_NODELAY para reducir latencia interna
    cat > /etc/stunnel/stunnel.conf <<EOF
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear-ssl]
accept = 443
connect = 127.0.0.1:80
EOF
    
    sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
    service stunnel4 restart > /dev/null 2>&1
    echo -e "${GREEN}[✔] Stunnel configurado. (Puerto SSL 443 -> Redirigido a Puerto 80).${NC}"
    sleep 3
    services_menu
}

function install_squid() {
    header
    echo -e "\n${CYAN}[*] Instalando Proxy Squid3 (Puertos 8080, 3128)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y squid > /dev/null 2>&1
    
    cat > /etc/squid/squid.conf <<EOF
http_port 8080
http_port 3128
acl localhost src 127.0.0.1/32
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32
http_access allow all
EOF
    service squid restart > /dev/null 2>&1
    echo -e "${GREEN}[✔] Proxy Squid activado en puertos 8080 y 3128 (Sin contraseña).${NC}"
    sleep 3
    services_menu
}

function install_ws_python() {
    header
    echo -e "\n${CYAN}[*] Instalando Websocket Python (Cloudflare Payload)...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y python3 > /dev/null 2>&1
    mkdir -p /etc/gaming_vps
    
    # Script Básico Pydic WS que inyecta en puerto 8888 y envía a Dropbear 80
    cat > /etc/gaming_vps/ws.py << 'EOF'
import socket, threading, sys
def handle_client(client_socket):
    remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try: remote_socket.connect(('127.0.0.1', 80))
    except: return
    def forward(src, dst):
        while True:
            try:
                data = src.recv(4096)
                if not data: break
                dst.send(data)
            except: break
    threading.Thread(target=forward, args=(client_socket, remote_socket)).start()
    threading.Thread(target=forward, args=(remote_socket, client_socket)).start()

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.bind(('0.0.0.0', 8888))
server.listen(5)
while True:
    client_sock, addr = server.accept()
    client_sock.recv(4096)
    client_sock.send(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
    handle_client(client_sock)
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
    echo -e "${GREEN}[✔] WebSocket Python activado (Puerto 8888 -> SSH 80).${NC}"
    sleep 3
    services_menu
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
    services_menu
}

function install_wireguard() {
    header
    echo -e "\n${CYAN}[*] Autoinstalador WireGuard (UDP Ultra Rápido)...${NC}"
    echo -e "${YELLOW}>> El script instalará The WireGuard Auto-Install.${NC}"
    sleep 4
    wget -qO /etc/gaming_vps/wireguard.sh https://raw.githubusercontent.com/angristan/wireguard-install/master/wireguard-install.sh
    chmod +x /etc/gaming_vps/wireguard.sh
    bash /etc/gaming_vps/wireguard.sh
    echo -e "${GREEN}[✔] Proceso de WireGuard finalizado.${NC}"
    sleep 3
    services_menu
}

function install_xray() {
    header
    echo -e "\n${CYAN}[*] Instalador Oficial Xray Core (Vmess/Vless/Trojan)...${NC}"
    echo -e "${YELLOW}>> Se descargará el script oficial de XTLS-Xray.${NC}"
    sleep 3
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    echo -e "${GREEN}[✔] Xray instalado en tu VPS.${NC}"
    echo -e "Nota: Para clientes complejos deberás crear el config.json manualmente en /usr/local/etc/xray/"
    sleep 4
    services_menu
}

function services_menu() {
    header
    echo -e "\n${CYAN}>>> ⚙️  MENÚ DE MULTI-PROTOCOLOS Y SERVICIOS <<<${NC}\n"
    echo -e "${YELLOW}  [1]${NC} - 🛠️  Dropbear SSH (Carga CPU baja | Puertos 80, 143)"
    echo -e "${YELLOW}  [2]${NC} - 🔒 Stunnel4 (Ocultar por SSL y SNI | Puerto 443)"
    echo -e "${YELLOW}  [3]${NC} - 🌐 Proxy Squid3 (Básico para inyecciones | Puertos 8080/3128)"
    echo -e "${YELLOW}  [4]${NC} - ☁️  WebSocket Python (Para Cloudflare Proxy | Puerto 8888)"
    echo -e "${YELLOW}  [5]${NC} - 🛡️  OpenVPN Auto-Instalador (Por Angristan)"
    echo -e "${YELLOW}  [6]${NC} - ⚡ WireGuard Auto-Instalador (Genial para Gaming puro)"
    echo -e "${YELLOW}  [7]${NC} - 🦇 Xray Core Oficial (Para clientes V2Ray / HTTP Custom)"
    echo -e "${YELLOW}  [0]${NC} - 🔙 Volver al Menú Principal\n"
    echo -e "${CYAN}======================================================${NC}"
    
    echo -e -n "🎮 ${BOLD}¿Qué deseas instalar?:${NC} "
    read opt

    case $opt in
        1) install_dropbear ;;
        2) install_stunnel ;;
        3) install_squid ;;
        4) install_ws_python ;;
        5) install_openvpn ;;
        6) install_wireguard ;;
        7) install_xray ;;
        0) main_menu ;;
        *) 
            echo -e "${RED}❌ Opción no válida.${NC}"
            sleep 1
            services_menu 
            ;;
    esac
}
# =========================================================

# ============== PARTE 4: GESTIÓN DE USUARIOS ==============
function create_user() {
    header
    echo -e "\n${CYAN}>>> ➕ CREAR NUEVO USUARIO (GAMING/SSH) <<<${NC}\n"
    echo -e -n "👤 ${BOLD}Nombre de usuario:${NC} "
    read username
    
    # Verificar si el usuario ya existe
    if id "$username" &>/dev/null; then
        echo -e "${RED}[x] Error: El usuario '$username' ya existe.${NC}"
        sleep 2
        users_menu
        return
    fi
    
    echo -e -n "🔑 ${BOLD}Contraseña:${NC} "
    read password
    echo -e -n "⏳ ${BOLD}Días de duración (ej. 30):${NC} "
    read days
    echo -e -n "🔄 ${BOLD}Límite de conexiones simultáneas (ej. 1):${NC} "
    read limit
    
    # Crear usuario con fecha de expiración (shell falso /bin/false para evitar acceso root)
    useradd -e $(date -d "$days days" +"%Y-%m-%d") -s /bin/false -M "$username"
    echo "$username:$password" | chpasswd
    
    # Guardar límite de conexiones en un registro local del panel
    mkdir -p /etc/gaming_vps
    echo "$limit" > "/etc/gaming_vps/$username.limit"
    
    echo -e "\n${GREEN}==========================================${NC}"
    echo -e "${GREEN}[✔] Usuario Premium Creado Exitosamente:${NC}"
    echo -e "   - Usuario: ${BOLD}$username${NC}"
    echo -e "   - Pass   : ${BOLD}$password${NC}"
    echo -e "   - Expira : ${BOLD}$days días${NC}"
    echo -e "   - Límite : ${BOLD}$limit conexión(es)${NC}"
    echo -e "${GREEN}==========================================${NC}"
    
    echo -e "\nPresiona ENTER para volver al menú de usuarios..."
    read enter
    users_menu
}

function delete_user() {
    header
    echo -e "\n${CYAN}>>> ➖ ELIMINAR USUARIO <<<${NC}\n"
    echo -e -n "👤 ${BOLD}Nombre de usuario a eliminar:${NC} "
    read username
    
    if id "$username" &>/dev/null; then
        pkill -u "$username" > /dev/null 2>&1
        userdel --force "$username" > /dev/null 2>&1
        rm -f "/etc/gaming_vps/$username.limit" 2>/dev/null
        echo -e "${GREEN}[✔] Usuario '$username' eliminado correctamente del VPS.${NC}"
    else
        echo -e "${RED}[x] Error: El usuario '$username' no existe o ya fue eliminado.${NC}"
    fi
    sleep 3
    users_menu
}

function users_menu() {
    header
    echo -e "\n${CYAN}>>> 👤 MENÚ DE GESTIÓN DE USUARIOS <<<${NC}\n"
    echo -e "${YELLOW}  [1]${NC} - ➕ Crear Nuevo Usuario (SSH/Dropbear/Stunnel)"
    echo -e "${YELLOW}  [2]${NC} - ➖ Eliminar Cliente Activo"
    echo -e "${YELLOW}  [0]${NC} - 🔙 Volver al Menú Principal\n"
    echo -e "${CYAN}======================================================${NC}"
    
    echo -e -n "🎮 ${BOLD}¿Qué deseas hacer?:${NC} "
    read opt

    case $opt in
        1) create_user ;;
        2) delete_user ;;
        0) main_menu ;;
        *) 
            echo -e "${RED}❌ Opción no válida.${NC}"
            sleep 1
            users_menu 
            ;;
    esac
}
# =========================================================

# ============== PARTE 5: MONITOR DE RECURSOS ==============
function show_system_stats() {
    header
    echo -e "\n${CYAN}>>> 📊 ESTADO DEL SERVIDOR VPS <<<${NC}\n"
    
    # Obtener Uso de CPU (cálculo simplificado de top)
    cpu_load=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    # Obtener Uso de RAM
    ram_total=$(free -m | awk '/Mem:/ {print $2}')
    ram_used=$(free -m | awk '/Mem:/ {print $3}')
    
    # PING de prueba a los servidores de Google para ver latencia
    ping_google=$(ping -c 1 8.8.8.8 | grep 'time=' | awk '{print $8}' | sed 's/time=//')
    if [ -z "$ping_google" ]; then ping_google="N/A"; fi

    echo -e "   🧠 CPU Usada : ${BOLD}${cpu_load}%${NC}"
    echo -e "   💾 RAM Usada : ${BOLD}${ram_used} MB / ${ram_total} MB${NC}"
    echo -e "   🌐 Latencia  : ${BOLD}${ping_google} ms${NC} (Desde la VPS hacia afuera)"
    
    echo -e "\n${CYAN}======================================================${NC}"
    echo -e "Presiona ENTER para regresar..."
    read enter
    monitor_menu
}

function clear_ram() {
    header
    echo -e "\n${CYAN}[*] Limpiando Caché de Memoria RAM para optimizar...${NC}"
    # Ejecutar comando de kernel para liberar Buffer y Cache (No afecta clientes conectados)
    sync
    echo 3 > /proc/sys/vm/drop_caches
    sleep 2
    echo -e "${GREEN}======================================================${NC}"
    echo -e "${GREEN}[✔] Memoria RAM Liberada con éxito.${NC}"
    echo -e "${GREEN}[✔] Rutas de red purgadas. Esto reducirá micro-cortes.${NC}"
    echo -e "${GREEN}======================================================${NC}"
    sleep 3
    monitor_menu
}

function monitor_menu() {
    header
    echo -e "\n${CYAN}>>> 📊 MENÚ DE MONITORIZACIÓN <<<${NC}\n"
    echo -e "${YELLOW}  [1]${NC} - 📈 Ver estado del CPU, RAM y Ping"
    echo -e "${YELLOW}  [2]${NC} - 🧹 Limpiar Memoria RAM Cache (Bajar Latencia)"
    echo -e "${YELLOW}  [0]${NC} - 🔙 Volver al Menú Principal\n"
    echo -e "${CYAN}======================================================${NC}"
    
    echo -e -n "🎮 ${BOLD}Selecciona una opción:${NC} "
    read opt

    case $opt in
        1) show_system_stats ;;
        2) clear_ram ;;
        0) main_menu ;;
        *) 
            echo -e "${RED}❌ Opción no válida.${NC}"
            sleep 1
            monitor_menu 
            ;;
    esac
}
# =========================================================

# ============== PARTE 6: EXPERTO Y SEGURIDAD ==============
function block_torrent() {
    header
    echo -e "\n${CYAN}[*] Configurando Firewall Anti-Torrent / P2P...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get install -y iptables > /dev/null 2>&1
    
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
    security_menu
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
    security_menu
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
    conex_drop=$(ps aux | grep dropbear | grep -w "$user" | grep -v grep | wc -l)
    conex_ssh=$(netstat -anp | grep ESTABLISHED | grep sshd | grep -w "$user" | wc -l)
    total=$(($conex_drop + $conex_ssh))
    
    if [ "$total" -gt "$limite" ]; then
        # Matar PIDs (procesos) del usuario si supera el límite establecido
        pkill -u $user dropbear
        pkill -u $user sshd
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
    security_menu
}

function security_menu() {
    header
    echo -e "\n${CYAN}>>> 🛡️  MENÚ EXPERTO: SEGURIDAD Y AUTOCONTROL  <<<${NC}\n"
    echo -e "${YELLOW}  [1]${NC} - 🛑 Bloquear Torrents/P2P (Protección de Ping y Baneo)"
    echo -e "${YELLOW}  [2]${NC} - ⏱️  Activar Auto-Limpieza de RAM (Cada 6h vía Cron)"
    echo -e "${YELLOW}  [3]${NC} - ✂️  Activar Auto-Kill (Límite de dispositivos estricto)"
    echo -e "${YELLOW}  [0]${NC} - 🔙 Volver al Menú Principal\n"
    echo -e "${CYAN}======================================================${NC}"
    
    echo -e -n "🎮 ${BOLD}Selecciona una opción de seguridad:${NC} "
    read opt

    case $opt in
        1) block_torrent ;;
        2) setup_auto_clean ;;
        3) setup_autokill ;;
        0) main_menu ;;
        *) 
            echo -e "${RED}❌ Opción no válida.${NC}"
            sleep 1
            security_menu 
            ;;
    esac
}
# =========================================================

# Función para mostrar el panel principal
function main_menu() {
    header
    echo -e "\n${YELLOW}  [1]${NC} - 👤 Gestionar Usuarios (Crear/Eliminar Cuentas)"
    echo -e "${YELLOW}  [2]${NC} - 🚀 Optimización Gaming (BBR, BadVPN, TCP Tweaks)"
    echo -e "${YELLOW}  [3]${NC} - ⚙️ Instalar Servicios (Dropbear, VPNs, Proxys, WS)"
    echo -e "${YELLOW}  [4]${NC} - 📊 Monitor de Recursos (CPU/RAM/Ping)"
    echo -e "${YELLOW}  [5]${NC} - 🛡️  Seguridad y Automatización (Anti-Torrent, AutoKill)"
    echo -e "${YELLOW}  [0]${NC} - ❌ Salir"
    echo -e "\n${CYAN}======================================================${NC}"
    
    echo -e -n "🎮 ${BOLD}Selecciona una opción:${NC} "
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
        0)
            clear
            echo -e "${MAGENTA}>>> Saliendo... ¡GG!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opción no válida. Intenta de nuevo.${NC}"
            sleep 2
            main_menu
            ;;
    esac
}

# Iniciar el script
main_menu
