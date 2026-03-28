import telebot
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
from flask import Flask, request, jsonify
import threading
import time
import uuid
import os
import io
import paramiko
import subprocess
from datetime import datetime
from database import init_db, can_user_generate, generate_install_key, validate_and_burn_install_key, add_membership_key, redeem_membership, get_user, get_active_vps_ips, get_expiring_users, create_ticket, add_vps, get_user_vps, get_vps_by_id, delete_vps
from config import TOKEN, ADMIN_ID, VERSION, INSTALL_CMD, API_KEY
VERSION = "V3.9.6 🔐"

bot = telebot.TeleBot(TOKEN)
app = Flask(__name__)

# --- MEMORIA VOLATIL ---
temp_vps = {}
temp_creation = {}
temp_edit = {}
temp_admin = {}

# --- API ---
@app.route('/api/validar', methods=['GET'])
def validar_key():
    key = request.args.get('key'); ip = request.remote_addr
    is_valid, creator_id, install_id = validate_and_burn_install_key(key, ip)
    if is_valid:
        creator = get_user(creator_id); c_username = creator['username'] if creator else "Admin"
        uid = str(uuid.uuid4()); ahora = datetime.now().strftime("%H:%M:%S")
        msg = (
            "=======================================\n"
            "========📩 🅼🅴🅽🆂🅰🅹🅴 🆁🅴🅲🅸🅱🅸🅳🅾 📩========\n"
            "=======================================\n"
            f"`{key}`\n"
            "============= ☝️ ✅ ☝ ==============\n"
            f"🌐 IP: {ip}\n"
            "=======================================\n"
            f"📦 UUID: {uid}\n"
            f"👤 DUEÑO: @{c_username}\n"
            "=======================================\n"
            f"⏰ HORA: {ahora} <-> 📑 INSTALL N° {install_id}\n"
            "======================================="
        )
        try: bot.send_message(ADMIN_ID, msg, parse_mode="Markdown")
        except: pass
        return jsonify({"status": "success", "msg": "valid", "owner": c_username}), 200
    return jsonify({"status": "error", "msg": "invalid"}), 403

def run_flask(): app.run(host='0.0.0.0', port=5000)

# --- SSH ENGINE ---
def ssh_connect_client(vps):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    if vps['auth_type'] == 'key':
        key_file = io.StringIO(vps['vps_key_content'])
        try: pkey = paramiko.RSAKey.from_private_key(key_file)
        except: 
            key_file.seek(0); pkey = paramiko.Ed25519Key.from_private_key(key_file)
        ssh.connect(vps['vps_ip'], username=vps['vps_user'], pkey=pkey, timeout=12)
    else:
        ssh.connect(vps['vps_ip'], username=vps['vps_user'], password=vps['vps_pass'], timeout=12)
    return ssh

def ssh_execute_master(vps, cmd_list):
    try:
        ssh = ssh_connect_client(vps); pre = "sudo " if vps['use_sudo'] else ""
        full_cmd = " && ".join([c if "grep" in c or "echo" in c or pre in c else f"{pre}{c}" for c in cmd_list])
        stdin, stdout, stderr = ssh.exec_command(full_cmd)
        out = stdout.read().decode(); err = stderr.read().decode(); ssh.close()
        return True, out, err
    except Exception as e: return False, "", str(e)

# --- BOT HANDLERS ---
@bot.message_handler(commands=['start', 'menu'])
@bot.message_handler(func=lambda m: m.text.lower() in [".menu", ".start"])
def send_welcome(message):
    uid = message.from_user.id; is_vip = can_user_generate(uid) or uid == ADMIN_ID
    markup = InlineKeyboardMarkup()
    if is_vip:
        markup.row(InlineKeyboardButton("🖥️ GESTIONAR VPS", callback_data="vps_list"))
        markup.row(InlineKeyboardButton("🔑 KEY VPS", callback_data="btn_key"), InlineKeyboardButton("🛰️ MONITOR", callback_data="btn_monitor"))
    markup.row(InlineKeyboardButton("👤 MI PERFIL", callback_data="btn_perfil"))
    markup.row(InlineKeyboardButton("📚 GUÍAS", callback_data="btn_guias"), InlineKeyboardButton("🛠️ SOPORTE", callback_data="btn_soporte"))
    if uid == ADMIN_ID: markup.row(InlineKeyboardButton("🎟️ CREAR MEMBRESIA VIP", callback_data="btn_p_admin"))
    
    msg = (
        "🔥 **MAESTRO UNDERKRAKER** 🔥\n"
        f"🚀 Version: `{VERSION}`\n"
        "━━━━━━━━━━━━━━━━━━━━━━━━\n"
        "Bienvenido al Centro de Mando Gamer Master.\n"
        "Gestiona tus servidores y licencias con un click."
    )
    bot.reply_to(message, msg, reply_markup=markup, parse_mode="Markdown")

@bot.message_handler(commands=['canjear'])
def cnj(message):
    try:
        key = message.text.split()[1]
        ok, duration = redeem_membership(message.from_user.id, message.from_user.username, key)
        if ok: bot.reply_to(message, f"✅ **Felicidades!**\nHas canjeado un pase VIP de **{duration} días**.")
        else: bot.reply_to(message, "❌ Key inválida o ya canjeada.")
    except: bot.reply_to(message, "❌ Uso: `/canjear CLAVE-AQUI`", parse_mode="Markdown")

@bot.callback_query_handler(func=lambda call: True)
def callback_master(call):
    uid = call.from_user.id; data = call.data
    
    # 📋 MODULO VPS
    if data == "vps_list":
        markup = InlineKeyboardMarkup()
        for v in get_user_vps(uid): markup.row(InlineKeyboardButton(f"🌐 {v['vps_name']} ({v['vps_ip']})", callback_data=f"v_view_{v['id']}"))
        markup.row(InlineKeyboardButton("➕ AÑADIR VPS", callback_data="v_add_template"), InlineKeyboardButton("🔙 BACK", callback_data="back"))
        bot.edit_message_text("🖥️ **TUS SERVIDORES:**", call.message.chat.id, call.message.message_id, reply_markup=markup)
    
    elif data.startswith("v_view_"):
        vid = data.split("_")[2]; v = get_vps_by_id(vid); markup = InlineKeyboardMarkup()
        markup.row(InlineKeyboardButton("➕ CREAR USER SSH", callback_data=f"v_cu_{vid}"))
        markup.row(InlineKeyboardButton("👥 GESTIONAR USERS", callback_data=f"v_lu_{vid}"))
        markup.row(InlineKeyboardButton("🗑️ BORRAR VPS", callback_data=f"v_del_{vid}"), InlineKeyboardButton("🔙 VOLVER", callback_data="vps_list"))
        at = "Llave (.pem)" if v['auth_type'] == 'key' else "Pass"
        text = f"🖥️ **VPS:** {v['vps_name']}\n🌐 **IP:** `{v['vps_ip']}`\n👤: `{v['vps_user']}`\n🔐: `{at}`"
        bot.edit_message_text(text, call.message.chat.id, call.message.message_id, reply_markup=markup, parse_mode="Markdown")

    elif data.startswith("v_lu_"):
        vid = data.split("_")[2]; v = get_vps_by_id(vid)
        bot.answer_callback_query(call.id, "⏳ Consultando VPS...")
        ok, out, err = ssh_execute_master(v, ["ls /etc/gaming_vps/*.limit"])
        if ok:
            users = [f.split("/")[-1].replace(".limit", "") for f in out.split() if ".limit" in f]
            markup = InlineKeyboardMarkup()
            for u in users: markup.row(InlineKeyboardButton(f"👤 {u}", callback_data=f"u_opt_{vid}_{u}"))
            markup.row(InlineKeyboardButton("🔙 VOLVER", callback_data=f"v_view_{vid}"))
            bot.edit_message_text(f"👥 **CLIENTES EN {v['vps_name']}:**", call.message.chat.id, call.message.message_id, reply_markup=markup)
        else: bot.send_message(call.message.chat.id, f"❌ Error SSH: {err}")

    elif data.startswith("u_opt_"):
        _, _, vid, user = data.split("_"); v = get_vps_by_id(vid); markup = InlineKeyboardMarkup()
        markup.row(InlineKeyboardButton("🗑️ BORRAR", callback_data=f"u_del_{vid}_{user}"), InlineKeyboardButton("✏️ EDITAR PASS", callback_data=f"u_edit_{vid}_{user}"))
        markup.row(InlineKeyboardButton("🔙 VOLVER", callback_data=f"v_lu_{vid}"))
        bot.edit_message_text(f"👤 **GESTIÓN DE USUARIO:** `{user}`\n¿Qué deseas hacer?", call.message.chat.id, call.message.message_id, reply_markup=markup, parse_mode="Markdown")

    elif data.startswith("u_del_"):
        _, _, vid, user = data.split("_"); v = get_vps_by_id(vid)
        bot.answer_callback_query(call.id, "⏳ Eliminando...")
        ok, out, err = ssh_execute_master(v, [f"userdel -f {user}", f"rm -f /etc/gaming_vps/{user}.limit"])
        bot.send_message(call.message.chat.id, f"✅ Usuario `{user}` eliminado de la VPS.")
        callback_master(telebot.types.CallbackQuery(call.id, call.from_user, call.message, data=f"v_lu_{vid}", chat_instance=None))

    elif data.startswith("u_edit_"):
        _, _, vid, user = data.split("_"); temp_edit[uid] = {"vid": vid, "user": user}
        msg = bot.send_message(call.message.chat.id, f"✏️ **Nueva Contraseña para {user}:**")
        bot.register_next_step_handler(msg, u_edit_final)

    elif data == "btn_perfil":
        user = get_user(uid)
        if uid == ADMIN_ID: status = "👑 **MAESTRO / ADMIN**"; exp = "♾️ Inmortal"
        elif user:
            status = "🌟 **VIP / MIEMBRO**"
            exp = datetime.fromtimestamp(user['expiry_date']).strftime("%d/%m/%Y %H:%M")
        else: status = "👤 **USUARIO BASE**"; exp = "❌ Sin Membresía"
        bot.send_message(call.message.chat.id, f"👤 **TU PERFIL:**\n📌 Status: {status}\n📅 Expiración: `{exp}`", parse_mode="Markdown")

    elif data == "btn_key":
        if can_user_generate(uid) or uid == ADMIN_ID:
            k, c = generate_install_key(uid)
            u_name = call.from_user.username or "Usuario"
            msg = (
                "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••\n"
                f"KEY {{ {c} }} DE @{u_name} con ID: {uid}\n"
                "⚠️ VENCE EN 4 HORAS O AL SER USADA ⚠️\n"
                "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••\n"
                f"🛡️ SloganKEY 🛡️ : Klk {u_name}\n"
                "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••\n"
                f"🗝️ `{k}` 🗝️\n"
                "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••\n"
                f"🛡️ 𝙸𝚗𝚜𝚝𝚊𝚕𝚊𝚍𝚘𝚛 𝙾𝚏𝚒𝚌𝚒𝚊𝚕 {VERSION} 🔐\n"
                "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••\n"
                f"`{INSTALL_CMD}`\n"
                "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••\n"
                "𝙍𝙚𝙘𝙤𝙢𝙚𝙣𝙙𝙖𝙙𝙤 𝙐𝙗𝙪𝙣𝙩𝙪 20.04 LTS\n"
                "🧬🧬 S.O Ubuntu 18.04 a 24.04 X64 🧬🧬\n"
                "Debian 8 a 12 (x64)\n"
                "🪦 ACCESOS OFICIALES CON @underkraker\n"
                "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••"
            )
            bot.send_message(call.message.chat.id, msg, parse_mode="Markdown")
        else: bot.answer_callback_query(call.id, "No tienes permiso VIP.")

    elif data == "btn_monitor":
        vips = get_active_vps_ips(); msg = "🛰️ **IPS ACTIVAS:**\n"
        if not vips: msg += "⚠️ Ninguna IP registrada."
        else:
            for v in vips: msg += f"• `{v['ip']}` (@{v['username']})\n"
        bot.send_message(call.message.chat.id, msg, parse_mode="Markdown")

    elif data == "btn_guias":
        bot.send_message(call.message.chat.id, "📚 **CENTRO DE AYUDA:**\n• Usa `/canjear CLAVE` para ser VIP.\n• Registra tu VPS con IP y Pass/Key.\n• Crea usuarios SSH ilimitados.")

    elif data == "btn_soporte":
        bot.send_message(call.message.chat.id, "🛠️ **SOPORTE TÉCNICO:**\nContáctame en @underkraker para reportar fallos o comprar membresías.")

    elif data == "btn_p_admin":
        if uid == ADMIN_ID:
            msg = bot.send_message(call.message.chat.id, "🎟️ **ADMIN:** Escribe la duración en días para la nueva llave VIP (ej: 30):")
            bot.register_next_step_handler(msg, step_p_admin_1)

    elif data == "v_add_template":
        markup = InlineKeyboardMarkup()
        markup.row(InlineKeyboardButton("📂 AWS", callback_data="tpl_aws"), InlineKeyboardButton("📂 Oracle", callback_data="tpl_ora"))
        markup.row(InlineKeyboardButton("📂 Root", callback_data="tpl_root"), InlineKeyboardButton("⚙️ Manual", callback_data="tpl_man"))
        bot.edit_message_text("🚀 **PLANTILLAS:**", call.message.chat.id, call.message.message_id, reply_markup=markup)
    elif data.startswith("tpl_"):
        temp_vps[uid] = {"template": data.split("_")[1]}
        msg = bot.send_message(call.message.chat.id, "🏷️ **Nombre VPS:**"); bot.register_next_step_handler(msg, v_step1_name)
    elif data.startswith("v_del_"):
        delete_vps(data.split("_")[2], uid); send_welcome(call.message)
    elif data.startswith("vpsudo_"): finish_vps_reg(call, int(data.split("_")[1]))
    elif data == "back": send_welcome(call.message)
    elif data.startswith("v_cu_"):
        temp_creation[uid] = {"vid": data.split("_")[2]}
        msg = bot.send_message(call.message.chat.id, "👤 **User:**"); bot.register_next_step_handler(msg, cu_step1)

# --- STEPS ---
def step_p_admin_1(m):
    try:
        duration = int(m.text); key = add_membership_key(duration)
        bot.send_message(m.chat.id, f"✅ **PASE VIP CREADO:**\n🔑 `{key}`\n⏳ Duración: {duration} días.\nCanjear con: `/canjear {key}`", parse_mode="Markdown")
    except: bot.send_message(m.chat.id, "❌ Duración inválida.")

def cu_step1(m): temp_creation[m.from_user.id]["un"] = m.text; msg = bot.send_message(m.chat.id, "🔑 **Pass:**"); bot.register_next_step_handler(msg, cu_step2)
def cu_step2(m): temp_creation[m.from_user.id]["pw"] = m.text; msg = bot.send_message(m.chat.id, "📅 **Días:**"); bot.register_next_step_handler(msg, cu_step3)
def cu_step3(m): 
    try:
        temp_creation[m.from_user.id]["ds"] = int(m.text)
        msg = bot.send_message(m.chat.id, "🔄 **Límite de Conexiones:**")
        bot.register_next_step_handler(msg, cu_final)
    except: bot.send_message(m.chat.id, "❌ Error: Pon un número."); send_welcome(m)

def cu_final(m):
    try:
        limit = int(m.text); uid = m.from_user.id; data = temp_creation[uid]; v = get_vps_by_id(data['vid'])
        pre = "sudo " if v['use_sudo'] else ""
        bot.send_message(m.chat.id, "⏳ **Configurando usuario en la VPS...**")
        cmds = [
            f"grep -q '/bin/false' /etc/shells || echo '/bin/false' | {pre}tee -a /etc/shells",
            f"useradd -e $(date -d '{data['ds']} days' +%Y-%m-%d) -s /bin/false -M {data['un']}",
            f"echo '{data['un']}:{data['pw']}' | chpasswd",
            f"mkdir -p /etc/gaming_vps",
            f"echo '{limit}' | tee /etc/gaming_vps/{data['un']}.limit",
            f"sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config",
            f"systemctl restart sshd 2>/dev/null", f"systemctl restart dropbear 2>/dev/null"
        ]
        ok, out, err = ssh_execute_master(v, cmds)
        if ok: bot.send_message(m.chat.id, f"✅ **CLIENTE CREADO!**\nUser: `{data['un']}`\nPass: `{data['pw']}`\nLímite: `{limit}`")
        else: bot.send_message(m.chat.id, f"❌ Error: {err}")
    except: bot.send_message(m.chat.id, "❌ Límite inválido."); send_welcome(m)

def u_edit_final(m):
    uid = m.from_user.id; data = temp_edit.get(uid)
    if not data: return
    v = get_vps_by_id(data['vid']); new_pw = m.text
    bot.send_message(m.chat.id, "⏳ Actualizando contraseña...")
    ok, out, err = ssh_execute_master(v, [f"echo '{data['user']}:{new_pw}' | chpasswd"])
    if ok: bot.send_message(m.chat.id, f"✅ Password de `{data['user']}` actualizado.")
    else: bot.send_message(m.chat.id, f"❌ Error: {err}")
    send_welcome(m)

def v_step1_name(m): temp_vps[m.from_user.id]["n"] = m.text; msg = bot.send_message(m.chat.id, "🌐 **IP:**"); bot.register_next_step_handler(msg, v_step2_ip)
def v_step2_ip(m):
    uid = m.from_user.id; temp_vps[uid]["i"] = m.text; tpl = temp_vps[uid]["template"]
    if tpl in ["aws", "ora"]:
        temp_vps[uid]["u"] = "ubuntu"; temp_vps[uid]["auth_type"] = "key"
        bot.send_message(m.chat.id, "📂 **Sube archivo .pem:**")
    elif tpl == "root":
        temp_vps[uid]["u"] = "root"; temp_vps[uid]["auth_type"] = "pass"
        msg = bot.send_message(m.chat.id, "🔑 **Root Pass:**"); bot.register_next_step_handler(msg, v_step_pass_direct)
    else:
        msg = bot.send_message(m.chat.id, "👤 **User:**"); bot.register_next_step_handler(msg, v_step_user_manual)

@bot.message_handler(content_types=['document'])
def handle_ssh_final(message):
    uid = message.from_user.id
    if uid in temp_vps and temp_vps[uid].get("auth_type") == "key":
        f = bot.download_file(bot.get_file(message.document.file_id).file_path)
        temp_vps[uid]["val"] = f.decode('utf-8')
        if temp_vps[uid].get("template") in ["aws", "ora"]: finish_vps_reg_msg(message, 1)
        else: v_step_sudo_markup(message)

def v_step_pass_direct(m): uid = m.from_user.id; d = temp_vps[uid]; add_vps(uid, d['n'], d['i'], d['u'], 'pass', m.text, 0); send_welcome(m)
def v_step_sudo_markup(m):
    markup = InlineKeyboardMarkup(); markup.row(InlineKeyboardButton("SUDO", callback_data="vpsudo_1"), InlineKeyboardButton("NO", callback_data="vpsudo_0"))
    bot.send_message(m.chat.id, "❓ **Sudo?**", reply_markup=markup)
def finish_vps_reg(call, sudo):
    uid = call.from_user.id; d = temp_vps.get(uid); add_vps(uid, d['n'], d['i'], d['u'], d['auth_type'], d['val'], sudo); send_welcome(call.message)
def finish_vps_reg_msg(m, sudo):
    uid = m.from_user.id; d = temp_vps.get(uid); add_vps(uid, d['n'], d['i'], d['u'], d['auth_type'], d['val'], sudo); send_welcome(m)

# --- COMANDO .CMD (SHELL EXPLORER) ---
@bot.message_handler(func=lambda m: m.text.startswith(".cmd"))
def handle_cmd_raw(m):
    uid = m.from_user.id
    if uid != ADMIN_ID:
        bot.reply_to(m, "🚫 **Acceso denegado.**")
        return
    
    cmd = m.text[5:].strip()
    if not cmd:
        bot.reply_to(m, "🔑 **Uso:** `.cmd COMANDO`")
        return
        
    try:
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        res = (out.decode() + err.decode()).strip()
        if not res: res = "✅ Comando ejecutado (Sin salida)."
        
        if len(res) > 3800:
            f = io.BytesIO(res.encode())
            f.name = "output.txt"
            bot.send_document(m.chat.id, f, caption="📄 Salida demasiado larga.")
        else:
            bot.reply_to(m, f"💻 **SHELL:**\n```\n{res}\n```", parse_mode="Markdown")
    except Exception as e:
        bot.reply_to(m, f"❌ Error: {str(e)}")

if __name__ == '__main__':
    init_db()
    threading.Thread(target=run_flask, daemon=True).start()
    while True:
        try:
            bot.polling(non_stop=True, interval=3, timeout=20)
        except:
            time.sleep(5)
