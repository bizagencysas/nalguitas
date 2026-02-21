import * as fs from "node:fs";
import * as path from "node:path";

const DATA_DIR = "/tmp/nalguitas-data";

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

interface AllData {
  devices: StoredDevices;
  messages: LoveMessage[];
  notificationHistory: NotificationLog[];
  girlfriendMessages: GirlfriendMessage[];
  remoteConfig: RemoteConfig;
  roles: RoleRegistration[];
}

function ensureDir() {
  try {
    if (!fs.existsSync(DATA_DIR)) {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    }
  } catch {}
}

function readFile<T>(filename: string, fallback: T): T {
  try {
    ensureDir();
    const filePath = path.join(DATA_DIR, filename);
    if (fs.existsSync(filePath)) {
      const raw = fs.readFileSync(filePath, "utf8");
      return JSON.parse(raw) as T;
    }
  } catch (e: any) {
    console.error(`[Storage] Error reading ${filename}:`, e.message);
  }
  return fallback;
}

function writeFile<T>(filename: string, data: T) {
  try {
    ensureDir();
    const filePath = path.join(DATA_DIR, filename);
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), "utf8");
  } catch (e: any) {
    console.error(`[Storage] Error writing ${filename}:`, e.message);
  }
}

export function loadDevices(): StoredDevices {
  const data = readFile<StoredDevices>("devices.json", { girlfriendDevices: [], adminDevices: [] });
  console.log(`[Storage] Loaded ${data.girlfriendDevices?.length || 0} girlfriend + ${data.adminDevices?.length || 0} admin devices`);
  return {
    girlfriendDevices: data.girlfriendDevices || [],
    adminDevices: data.adminDevices || [],
  };
}

export function saveDevices(data: StoredDevices) {
  writeFile("devices.json", data);
  console.log(`[Storage] Saved ${data.girlfriendDevices.length} girlfriend + ${data.adminDevices.length} admin devices`);
}

export function loadMessages(): LoveMessage[] {
  const data = readFile<LoveMessage[]>("messages.json", []);
  console.log(`[Storage] Loaded ${data.length} messages`);
  return data;
}

export function saveMessages(data: LoveMessage[]) {
  writeFile("messages.json", data);
}

export function loadNotificationHistory(): NotificationLog[] {
  return readFile<NotificationLog[]>("notification-history.json", []);
}

export function saveNotificationHistory(data: NotificationLog[]) {
  writeFile("notification-history.json", data);
}

export function loadGirlfriendMessages(): GirlfriendMessage[] {
  return readFile<GirlfriendMessage[]>("girlfriend-messages.json", []);
}

export function saveGirlfriendMessages(data: GirlfriendMessage[]) {
  writeFile("girlfriend-messages.json", data);
}

export function loadRemoteConfig(): RemoteConfig {
  return readFile<RemoteConfig>("remote-config.json", {
    popup: {
      enabled: true,
      type: "role_selection",
      title: "\u00bfQui\u00e9n eres?",
      subtitle: "Selecciona tu rol para personalizar tu experiencia",
      options: [
        { id: "admin", label: "Soy el Admin", emoji: "\ud83d\udc51", role: "admin" },
        { id: "girlfriend", label: "Soy la Novia", emoji: "\ud83d\udc96", role: "girlfriend" },
      ],
    },
  });
}

export function saveRemoteConfig(data: RemoteConfig) {
  writeFile("remote-config.json", data);
}

export function loadRoles(): RoleRegistration[] {
  return readFile<RoleRegistration[]>("roles.json", []);
}

export function saveRoles(data: RoleRegistration[]) {
  writeFile("roles.json", data);
}
