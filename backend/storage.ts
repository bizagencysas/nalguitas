import { sql } from "./db";

interface DeviceInfo {
  token: string;
  deviceId: string;
  registeredAt: string;
}

interface StoredDevices {
  girlfriendDevices: DeviceInfo[];
  adminDevices: DeviceInfo[];
}

interface LoveMessage {
  id: string;
  content: string;
  subtitle: string;
  tone: string;
  createdAt: string;
  isSpecial: boolean;
  scheduledDate?: string;
  priority: number;
}

interface NotificationLog {
  id: string;
  message: string;
  sentAt: string;
  status: string;
}

interface GirlfriendMessage {
  id: string;
  content: string;
  sentAt: string;
  read: boolean;
}

interface RemoteConfig {
  popup: {
    enabled: boolean;
    type: string;
    title: string;
    subtitle: string;
    options: { id: string; label: string; emoji: string; role: string }[];
  } | null;
}

interface RoleRegistration {
  deviceId: string;
  role: string;
  registeredAt: string;
}

const DEFAULT_CONFIG: RemoteConfig = {
  popup: {
    enabled: true,
    type: "role_selection",
    title: "¿Quién eres?",
    subtitle: "Selecciona tu rol para personalizar tu experiencia",
    options: [
      { id: "admin", label: "Soy el Admin", emoji: "👑", role: "admin" },
      { id: "girlfriend", label: "Soy la Novia", emoji: "💖", role: "girlfriend" },
    ],
  },
};

export async function loadDevices(): Promise<StoredDevices> {
  const rows = await sql`SELECT token, device_id, role, registered_at FROM devices ORDER BY registered_at`;
  const girlfriendDevices: DeviceInfo[] = [];
  const adminDevices: DeviceInfo[] = [];
  for (const row of rows) {
    const dev: DeviceInfo = { token: row.token, deviceId: row.device_id, registeredAt: row.registered_at.toISOString() };
    if (row.role === "admin") adminDevices.push(dev);
    else girlfriendDevices.push(dev);
  }
  console.log(`[Storage] Loaded ${girlfriendDevices.length} girlfriend + ${adminDevices.length} admin devices`);
  return { girlfriendDevices, adminDevices };
}

export async function saveDevice(token: string, deviceId: string, role: string) {
  await sql`
    INSERT INTO devices (token, device_id, role, registered_at)
    VALUES (${token}, ${deviceId}, ${role}, NOW())
    ON CONFLICT (device_id, role) DO UPDATE SET token = ${token}, registered_at = NOW()
  `;
  console.log(`[Storage] Saved device ${deviceId.substring(0, 8)}... as ${role}`);
}

export async function loadMessages(): Promise<LoveMessage[]> {
  const rows = await sql`SELECT * FROM messages ORDER BY created_at ASC`;
  return rows.map(r => ({
    id: r.id,
    content: r.content,
    subtitle: r.subtitle,
    tone: r.tone,
    createdAt: r.created_at.toISOString(),
    isSpecial: r.is_special,
    scheduledDate: r.scheduled_date || undefined,
    priority: r.priority,
  }));
}

export async function saveMessage(msg: LoveMessage) {
  await sql`
    INSERT INTO messages (id, content, subtitle, tone, created_at, is_special, scheduled_date, priority)
    VALUES (${msg.id}, ${msg.content}, ${msg.subtitle}, ${msg.tone}, ${msg.createdAt}, ${msg.isSpecial}, ${msg.scheduledDate || null}, ${msg.priority})
    ON CONFLICT (id) DO UPDATE SET
      content = ${msg.content}, subtitle = ${msg.subtitle}, tone = ${msg.tone},
      is_special = ${msg.isSpecial}, scheduled_date = ${msg.scheduledDate || null}, priority = ${msg.priority}
  `;
}

export async function deleteMessage(id: string) {
  await sql`DELETE FROM messages WHERE id = ${id}`;
}

export async function loadNotificationHistory(): Promise<NotificationLog[]> {
  const rows = await sql`SELECT * FROM notification_history ORDER BY sent_at DESC LIMIT 100`;
  return rows.map(r => ({
    id: r.id,
    message: r.message,
    sentAt: r.sent_at.toISOString(),
    status: r.status,
  }));
}

export async function saveNotificationLog(log: NotificationLog) {
  await sql`
    INSERT INTO notification_history (id, message, sent_at, status)
    VALUES (${log.id}, ${log.message}, ${log.sentAt}, ${log.status})
  `;
}

export async function loadGirlfriendMessages(): Promise<GirlfriendMessage[]> {
  const rows = await sql`SELECT * FROM girlfriend_messages ORDER BY sent_at DESC`;
  return rows.map(r => ({
    id: r.id,
    content: r.content,
    sentAt: r.sent_at.toISOString(),
    read: r.read,
  }));
}

export async function saveGirlfriendMessage(msg: GirlfriendMessage) {
  await sql`
    INSERT INTO girlfriend_messages (id, content, sent_at, read)
    VALUES (${msg.id}, ${msg.content}, ${msg.sentAt}, ${msg.read})
  `;
}

export async function loadRemoteConfig(): Promise<RemoteConfig> {
  const rows = await sql`SELECT value FROM remote_config WHERE key = 'main'`;
  if (rows.length === 0) return DEFAULT_CONFIG;
  return rows[0].value as RemoteConfig;
}

export async function saveRemoteConfig(data: RemoteConfig) {
  await sql`
    INSERT INTO remote_config (key, value)
    VALUES ('main', ${JSON.stringify(data)}::jsonb)
    ON CONFLICT (key) DO UPDATE SET value = ${JSON.stringify(data)}::jsonb
  `;
}

export async function loadRoles(): Promise<RoleRegistration[]> {
  const rows = await sql`SELECT * FROM roles ORDER BY registered_at`;
  return rows.map(r => ({
    deviceId: r.device_id,
    role: r.role,
    registeredAt: r.registered_at.toISOString(),
  }));
}

export async function saveRole(deviceId: string, role: string) {
  await sql`
    INSERT INTO roles (device_id, role, registered_at)
    VALUES (${deviceId}, ${role}, NOW())
    ON CONFLICT (device_id) DO UPDATE SET role = ${role}, registered_at = NOW()
  `;
}

export async function loadSchedule() {
  const rows = await sql`SELECT * FROM schedule_config WHERE id = 1`;
  if (rows.length === 0) return { morning: "08:00", midday: "12:30", afternoon: "17:00", night: "21:30" };
  return { morning: rows[0].morning, midday: rows[0].midday, afternoon: rows[0].afternoon, night: rows[0].night };
}

export async function saveSchedule(config: { morning?: string; midday?: string; afternoon?: string; night?: string }) {
  const current = await loadSchedule();
  const updated = { ...current, ...config };
  await sql`
    UPDATE schedule_config SET
      morning = ${updated.morning}, midday = ${updated.midday},
      afternoon = ${updated.afternoon}, night = ${updated.night}
    WHERE id = 1
  `;
  return updated;
}
