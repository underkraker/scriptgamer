#!/usr/bin/python3
# -*- coding: utf-8 -*-
# KRAKER VPS - SSL GATEWAY (DUAL MODE: WS + DIRECT)
# Versión Avanzada 2.0 con Detección Automática
# Target: Forward to Port 80

import socket, threading, ssl, sys, select, time

# Configuración KRAKER VPS
LISTENING_ADDR = '0.0.0.0'
REMOTE_ADDR = '127.0.0.1'
REMOTE_PORT = 80 # Redirección fija a SSH/Dropbear
BUFFER_SIZE = 8192
HANDSHAKE_TIMEOUT = 0.5 # Tiempo para detectar si es WS o Directo

# Respuesta Handshake WebSocket (KRAKER VPS)
WS_RESPONSE = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"

def transfer(src, dst):
    try:
        while True:
            data = src.recv(BUFFER_SIZE)
            if not data: break
            dst.sendall(data)
    except: pass
    finally:
        try: src.close()
        except: pass
        try: dst.close()
        except: pass

def handler(client_socket, address):
    try:
        # 1. Intentar detectar si el cliente envía datos inmediatamente (WebSocket/Payload)
        client_socket.setblocking(False)
        time.sleep(HANDSHAKE_TIMEOUT)
        
        is_websocket = False
        try:
            data = client_socket.recv(BUFFER_SIZE)
            if data:
                # Si empieza con un método HTTP, es WebSocket/Payload
                if any(data.startswith(m) for m in [b"GET", b"POST", b"CONNECT", b"HEAD"]):
                    is_websocket = True
                    client_socket.sendall(WS_RESPONSE.encode())
                    print(f"[+] KRAKER VPS - [WS MODE] - Client: {address[0]}")
                else:
                    # Datos iniciales presentes pero no son HTTP (Raro en SSL, pero posible)
                    # Lo enviamos al SSH directamente
                    pass
        except BlockingIOError:
            # No hay datos inmediatos -> Modo SSL Directo (SNI Pure)
            print(f"[+] KRAKER VPS - [DIRECT MODE] - Client: {address[0]}")
            data = b""

        client_socket.setblocking(True)

        # 2. Conectar al SSH (Puerto 80)
        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.connect((REMOTE_ADDR, REMOTE_PORT))
        
        # 3. Si teníamos datos (que no eran el handshake WS), los enviamos al SSH
        if data and not is_websocket:
            remote_socket.sendall(data)

        # 4. Iniciar Puente Bidireccional
        threading.Thread(target=transfer, args=(client_socket, remote_socket), daemon=True).start()
        threading.Thread(target=transfer, args=(remote_socket, client_socket), daemon=True).start()

    except Exception as e:
        # print(f"[!] Error: {e}")
        pass

def main(port, cert, key):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=cert, keyfile=key)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind((LISTENING_ADDR, int(port)))
        server.listen(200)
        
        secure_server = context.wrap_socket(server, server_side=True)
        print(f"[*] KRAKER VPS - Gateway Dual Activo en Puerto {port}")
        print(f"[*] Modo: WS + SSL Direct | Destino: SSH Port {REMOTE_PORT}")
        
    except Exception as e:
        print(f"[!] Error al iniciar Gateway: {e}")
        sys.exit(1)

    while True:
        try:
            client, addr = secure_server.accept()
            threading.Thread(target=handler, args=(client, addr), daemon=True).start()
        except:
            pass

if __name__ == '__main__':
    if len(sys.argv) < 4:
        print("Uso: python3 KRAKER_SSL_Gateway.py <puerto> <cert> <key>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2], sys.argv[3])
