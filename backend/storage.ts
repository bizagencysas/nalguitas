import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const DATA_DIR = path.join(__dirname, ".data");
const DEVICES_FILE = path.join(DATA_DIR, "devices.json");

interface StoredData {
  girlfriendDevices: { token: string; deviceId: string; registeredAt: string }[];
  adminDevices: { token: string; deviceId: string; registeredAt: string }[];
}

function ensureDir() {
  try {
    if (!fs.existsSync(DATA_DIR)) {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    }
  } catch {}
}

export function loadDevices(): StoredData {
  try {
    ensureDir();
    if (fs.existsSync(DEVICES_FILE)) {
      const raw = fs.readFileSync(DEVICES_FILE, "utf8");
      const data = JSON.parse(raw) as StoredData;
      console.log(`[Storage] Loaded ${data.girlfriendDevices?.length || 0} girlfriend + ${data.adminDevices?.length || 0} admin devices from disk`);
      return {
        girlfriendDevices: data.girlfriendDevices || [],
        adminDevices: data.adminDevices || [],
      };
    }
  } catch (e: any) {
    console.error("[Storage] Error loading devices:", e.message);
  }
  return { girlfriendDevices: [], adminDevices: [] };
}

export function saveDevices(data: StoredData) {
  try {
    ensureDir();
    fs.writeFileSync(DEVICES_FILE, JSON.stringify(data, null, 2), "utf8");
    console.log(`[Storage] Saved ${data.girlfriendDevices.length} girlfriend + ${data.adminDevices.length} admin devices to disk`);
  } catch (e: any) {
    console.error("[Storage] Error saving devices:", e.message);
  }
}
