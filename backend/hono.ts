import { trpcServer } from "@hono/trpc-server";
import { Hono } from "hono";
import { cors } from "hono/cors";

import { appRouter } from "./trpc/app-router";
import { createContext } from "./trpc/create-context";
import { loadRemoteConfig, saveRemoteConfig, loadRoles, saveRole } from "./storage";
import { migrate } from "./db";

const app = new Hono();

app.use("*", cors());

app.onError((err, c) => {
  console.error("API Error:", err.message);
  return c.json({ error: err.message || "Internal Server Error" }, 500);
});

app.use(
  "/trpc/*",
  trpcServer({
    endpoint: "/api/trpc",
    router: appRouter,
    createContext,
  }),
);

app.get("/", (c) => {
  return c.json({ status: "ok", message: "Nalguitas API (PostgreSQL)", v: "2.1" });
});

app.get("/messages/today", async (c) => {
  try {
    const caller = appRouter.createCaller({ req: c.req.raw });
    const msg = await caller.messages.today();
    return c.json(msg);
  } catch (e: any) {
    console.error("Error fetching today message:", e);
    return c.json({ id: "", content: "", subtitle: "", tone: "", createdAt: "", isSpecial: false, priority: 0 }, 200);
  }
});

app.get("/messages", async (c) => {
  try {
    const caller = appRouter.createCaller({ req: c.req.raw });
    const data = await caller.messages.list();
    return c.json(data);
  } catch (e: any) {
    console.error("Error fetching messages:", e);
    return c.json({ messages: [], todayMessage: null }, 200);
  }
});

app.post("/device/register", async (c) => {
  try {
    const body = await c.req.json();
    const caller = appRouter.createCaller({ req: c.req.raw });
    const result = await caller.notifications.registerDevice(body);
    return c.json(result);
  } catch (e: any) {
    console.error("Error registering device:", e);
    return c.json({ error: e.message || "Failed to register device" }, 500);
  }
});

app.post("/notifications/test", async (c) => {
  try {
    const caller = appRouter.createCaller({ req: c.req.raw });
    const result = await caller.notifications.testNotification();
    return c.json(result);
  } catch (e: any) {
    console.error("Error sending test notification:", e);
    return c.json({ error: e.message || "Failed to send test notification" }, 500);
  }
});

app.post("/notifications/send", async (c) => {
  try {
    const body = await c.req.json();
    const caller = appRouter.createCaller({ req: c.req.raw });
    const result = await caller.notifications.sendNow(body);
    return c.json(result);
  } catch (e: any) {
    console.error("Error sending notification:", e);
    return c.json({ error: e.message || "Failed to send notification" }, 500);
  }
});

app.post("/girlfriend/send", async (c) => {
  try {
    const body = await c.req.json();
    const caller = appRouter.createCaller({ req: c.req.raw });
    const result = await caller.notifications.girlfriendMessage(body);
    return c.json(result);
  } catch (e: any) {
    console.error("Error sending girlfriend message:", e);
    return c.json({ error: e.message || "Failed to send message" }, 500);
  }
});

app.get("/girlfriend/messages", async (c) => {
  try {
    const caller = appRouter.createCaller({ req: c.req.raw });
    const result = await caller.notifications.getGirlfriendMessages();
    return c.json(result);
  } catch (e: any) {
    console.error("Error fetching girlfriend messages:", e);
    return c.json([], 200);
  }
});

app.get("/config", async (c) => {
  try {
    const config = await loadRemoteConfig();
    return c.json(config);
  } catch (e: any) {
    console.error("Error loading remote config:", e);
    return c.json({ popup: null }, 200);
  }
});

app.post("/config", async (c) => {
  try {
    const body = await c.req.json();
    await saveRemoteConfig(body);
    return c.json({ success: true });
  } catch (e: any) {
    console.error("Error saving remote config:", e);
    return c.json({ error: e.message }, 500);
  }
});

app.post("/role/register", async (c) => {
  try {
    const body = await c.req.json();
    const { deviceId, role } = body;
    if (!deviceId || !role) {
      return c.json({ error: "deviceId and role are required" }, 400);
    }
    await saveRole(deviceId, role);
    console.log(`[Role] Registered ${deviceId.substring(0, 8)}... as ${role}`);
    return c.json({ success: true, role });
  } catch (e: any) {
    console.error("Error registering role:", e);
    return c.json({ error: e.message }, 500);
  }
});

app.get("/role/:deviceId", async (c) => {
  try {
    const deviceId = c.req.param("deviceId");
    const roles = await loadRoles();
    const found = roles.find((r: any) => r.deviceId === deviceId);
    return c.json({ role: found?.role || null });
  } catch (e: any) {
    return c.json({ role: null }, 200);
  }
});

app.get("/admin", (c) => {
  return c.html(adminHTML());
});

function adminHTML(): string {
  return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Nalguitas - Admin</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:linear-gradient(135deg,#fff9f9,#fde8ec,#fdf0f2);min-height:100vh;color:#4d3337}
.container{max-width:800px;margin:0 auto;padding:20px}
h1{font-size:28px;font-weight:700;color:#4d3337;text-align:center;padding:24px 0}
h1 span{color:#e894a6}
.card{background:rgba(255,255,255,0.85);border-radius:20px;padding:24px;margin-bottom:20px;box-shadow:0 4px 20px rgba(232,148,166,0.1);border:1px solid rgba(232,148,166,0.15)}
.card h2{font-size:18px;font-weight:600;margin-bottom:16px;color:#4d3337;display:flex;align-items:center;gap:8px}
.card h2 .icon{font-size:20px}
textarea,input[type=text],input[type=time],select{width:100%;padding:12px 16px;border:1.5px solid #fde8ec;border-radius:12px;font-size:15px;font-family:inherit;background:#fff;color:#4d3337;outline:none;transition:border-color 0.2s}
textarea:focus,input:focus,select:focus{border-color:#e894a6}
textarea{min-height:80px;resize:vertical}
.btn{display:inline-flex;align-items:center;gap:6px;padding:12px 24px;border:none;border-radius:12px;font-size:15px;font-weight:600;cursor:pointer;transition:all 0.2s}
.btn-primary{background:linear-gradient(135deg,#e894a6,#f2b5c3);color:#fff;box-shadow:0 4px 12px rgba(232,148,166,0.3)}
.btn-primary:hover{transform:translateY(-1px);box-shadow:0 6px 16px rgba(232,148,166,0.4)}
.btn-danger{background:#fff;color:#d44;border:1.5px solid #fdd}
.btn-danger:hover{background:#fef0f0}
.btn-sm{padding:8px 16px;font-size:13px}
.form-group{margin-bottom:16px}
.form-group label{display:block;font-size:13px;font-weight:600;color:#8b6b70;margin-bottom:6px}
.row{display:flex;gap:12px;flex-wrap:wrap}
.row>*{flex:1;min-width:140px}
.schedule-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.schedule-item{display:flex;align-items:center;justify-content:space-between;padding:12px 16px;background:#fdf5f7;border-radius:12px}
.schedule-item .label{font-weight:600;font-size:14px}
.schedule-item input{width:100px;text-align:center}
.msg-list{max-height:400px;overflow-y:auto}
.msg-item{display:flex;align-items:flex-start;justify-content:space-between;padding:12px 16px;border-bottom:1px solid #fde8ec;gap:12px}
.msg-item:last-child{border-bottom:none}
.msg-content{flex:1}
.msg-content p{font-size:14px;line-height:1.5}
.msg-content .meta{font-size:12px;color:#8b6b70;margin-top:4px}
.tag{display:inline-block;padding:2px 8px;border-radius:20px;font-size:11px;font-weight:600;background:#fde8ec;color:#c77b8a}
.status{display:inline-flex;align-items:center;gap:4px;font-size:12px}
.status .dot{width:6px;height:6px;border-radius:50%}
.status .dot.green{background:#4a4}
.status .dot.gray{background:#999}
.log-item{padding:10px 16px;border-bottom:1px solid #fde8ec;font-size:13px}
.log-item .time{color:#8b6b70;font-size:11px}
.toast{position:fixed;top:20px;right:20px;background:#fff;padding:16px 24px;border-radius:12px;box-shadow:0 8px 24px rgba(0,0,0,0.12);border-left:4px solid #e894a6;transform:translateX(120%);transition:transform 0.3s;z-index:100}
.toast.show{transform:translateX(0)}
.empty{text-align:center;padding:32px;color:#8b6b70;font-size:14px}
@media(max-width:600px){.schedule-grid{grid-template-columns:1fr}.row{flex-direction:column}}
</style>
</head>
<body>
<div class="container">
<h1>&#x1F49D; <span>Nalguitas</span> Admin</h1>

<div class="card">
<h2><span class="icon">&#x1F4E8;</span> Enviar Ahora</h2>
<div class="form-group">
<label>Mensaje</label>
<textarea id="sendMsg" placeholder="Escribe un mensaje bonito..."></textarea>
</div>
<button class="btn btn-primary" onclick="sendNow()">&#x1F49D; Enviar notificaci&oacute;n</button>
</div>

<div class="card">
<h2><span class="icon">&#x23F0;</span> Horarios Diarios</h2>
<div class="schedule-grid">
<div class="schedule-item"><span class="label">&#x1F305; Ma&ntilde;ana</span><input type="time" id="sch-morning" value="08:00"></div>
<div class="schedule-item"><span class="label">&#x2600;&#xFE0F; Mediod&iacute;a</span><input type="time" id="sch-midday" value="12:30"></div>
<div class="schedule-item"><span class="label">&#x1F31C; Tarde</span><input type="time" id="sch-afternoon" value="17:00"></div>
<div class="schedule-item"><span class="label">&#x1F319; Noche</span><input type="time" id="sch-night" value="21:30"></div>
</div>
<div style="margin-top:12px"><button class="btn btn-primary btn-sm" onclick="updateSchedule()">Guardar horarios</button></div>
</div>

<div class="card">
<h2><span class="icon">&#x1F48C;</span> Crear Mensaje</h2>
<div class="form-group">
<label>Contenido</label>
<textarea id="newContent" placeholder="El mensaje que ella ver&aacute;..."></textarea>
</div>
<div class="row">
<div class="form-group">
<label>Subtitulo</label>
<input type="text" id="newSubtitle" placeholder="Para ti" value="Para ti">
</div>
<div class="form-group">
<label>Tono</label>
<select id="newTone">
<option value="tierno">Tierno</option>
<option value="rom&aacute;ntico">Rom&aacute;ntico</option>
<option value="profundo">Profundo</option>
<option value="divertido">Divertido</option>
</select>
</div>
</div>
<button class="btn btn-primary" onclick="createMsg()">&#x2795; Agregar mensaje</button>
</div>

<div class="card">
<h2><span class="icon">&#x1F4DD;</span> Mensajes <span id="msgCount" style="font-weight:400;font-size:14px;color:#8b6b70"></span></h2>
<div class="msg-list" id="msgList"><div class="empty">Cargando...</div></div>
</div>

<div class="card">
<h2><span class="icon">&#x1F4CA;</span> Historial de Env&iacute;os</h2>
<div id="historyList"><div class="empty">Sin env&iacute;os a&uacute;n</div></div>
</div>

<div class="card">
<h2><span class="icon">&#x1F4F1;</span> Dispositivo</h2>
<div id="deviceInfo"><div class="empty">Cargando...</div></div>
</div>
</div>

<div class="toast" id="toast"></div>

<script>
const API = window.location.origin + '/api';

function toast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 3000);
}

async function api(path, opts) {
  const r = await fetch(API + path, opts);
  return r.json();
}

async function sendNow() {
  const msg = document.getElementById('sendMsg').value.trim();
  if (!msg) return toast('Escribe un mensaje primero');
  try {
    await api('/notifications/send', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({message: msg}) });
    toast('Notificaci\\u00f3n enviada');
    document.getElementById('sendMsg').value = '';
    loadHistory();
  } catch(e) { toast('Error: ' + e.message); }
}

async function createMsg() {
  const content = document.getElementById('newContent').value.trim();
  if (!content) return toast('Escribe el contenido');
  const subtitle = document.getElementById('newSubtitle').value || 'Para ti';
  const tone = document.getElementById('newTone').value;
  try {
    await api('/trpc/messages.create', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({json:{content,subtitle,tone,isSpecial:false,priority:1}}) });
    toast('Mensaje creado');
    document.getElementById('newContent').value = '';
    loadMessages();
  } catch(e) { toast('Error: ' + e.message); }
}

async function deleteMsg(id) {
  if (!confirm('Eliminar este mensaje?')) return;
  try {
    await api('/trpc/messages.delete', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({json:{id}}) });
    toast('Mensaje eliminado');
    loadMessages();
  } catch(e) { toast('Error: ' + e.message); }
}

async function updateSchedule() {
  const s = {
    morning: document.getElementById('sch-morning').value,
    midday: document.getElementById('sch-midday').value,
    afternoon: document.getElementById('sch-afternoon').value,
    night: document.getElementById('sch-night').value,
  };
  try {
    await api('/trpc/notifications.updateSchedule', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify({json:s}) });
    toast('Horarios actualizados');
  } catch(e) { toast('Error: ' + e.message); }
}

async function loadMessages() {
  try {
    const r = await api('/messages');
    const msgs = r.messages || [];
    document.getElementById('msgCount').textContent = '(' + msgs.length + ')';
    if (!msgs.length) { document.getElementById('msgList').innerHTML = '<div class="empty">No hay mensajes</div>'; return; }
    document.getElementById('msgList').innerHTML = msgs.map(m => 
      '<div class="msg-item"><div class="msg-content"><p>' + esc(m.content) + '</p><div class="meta">' + esc(m.subtitle) + ' &middot; <span class="tag">' + esc(m.tone) + '</span></div></div><button class="btn btn-danger btn-sm" onclick="deleteMsg(\\'' + m.id + '\\')">&#x1F5D1;</button></div>'
    ).join('');
  } catch(e) { console.error(e); }
}

async function loadHistory() {
  try {
    const r = await fetch(API + '/trpc/notifications.history');
    const data = await r.json();
    const logs = data?.result?.data?.json || [];
    if (!logs.length) { document.getElementById('historyList').innerHTML = '<div class="empty">Sin env\\u00edos a\\u00fan</div>'; return; }
    document.getElementById('historyList').innerHTML = logs.slice(0, 20).map(l =>
      '<div class="log-item"><strong>' + esc(l.message) + '</strong> <span class="time">' + new Date(l.sentAt).toLocaleString('es') + ' &middot; ' + l.status + '</span></div>'
    ).join('');
  } catch(e) { console.error(e); }
}

async function loadDevice() {
  try {
    const r = await fetch(API + '/trpc/notifications.getDevice');
    const data = await r.json();
    const dev = data?.result?.data?.json;
    if (!dev) { document.getElementById('deviceInfo').innerHTML = '<div class="status"><span class="dot gray"></span> Ning\\u00fan dispositivo registrado</div>'; return; }
    document.getElementById('deviceInfo').innerHTML = '<div class="status"><span class="dot green"></span> Registrado</div><div style="font-size:12px;color:#8b6b70;margin-top:8px">Token: ' + dev.token.substring(0,20) + '...<br>Desde: ' + new Date(dev.registeredAt).toLocaleString('es') + '</div>';
  } catch(e) { console.error(e); }
}

async function loadSchedule() {
  try {
    const r = await fetch(API + '/trpc/notifications.getSchedule');
    const data = await r.json();
    const s = data?.result?.data?.json;
    if (s) {
      document.getElementById('sch-morning').value = s.morning;
      document.getElementById('sch-midday').value = s.midday;
      document.getElementById('sch-afternoon').value = s.afternoon;
      document.getElementById('sch-night').value = s.night;
    }
  } catch(e) { console.error(e); }
}

function esc(s) { const d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

loadMessages();
loadHistory();
loadDevice();
loadSchedule();
</script>
</body>
</html>`;
}

export default app;
