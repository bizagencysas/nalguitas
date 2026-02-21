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

// --- Gifts ---

interface Gift {
  id: string;
  characterUrl: string;
  characterName: string;
  message: string;
  subtitle: string;
  giftType: string;
  createdAt: string;
  seen: boolean;
}

export async function saveGift(gift: Gift) {
  await sql`
    INSERT INTO gifts (id, character_url, character_name, message, subtitle, gift_type, created_at, seen)
    VALUES (${gift.id}, ${gift.characterUrl}, ${gift.characterName}, ${gift.message}, ${gift.subtitle}, ${gift.giftType}, ${gift.createdAt}, ${gift.seen})
  `;
  console.log(`[Gifts] Saved gift: "${gift.message.substring(0, 40)}"`);
}

export async function loadGifts(): Promise<Gift[]> {
  const rows = await sql`SELECT * FROM gifts ORDER BY created_at DESC`;
  return rows.map(r => ({
    id: r.id,
    characterUrl: r.character_url,
    characterName: r.character_name,
    message: r.message,
    subtitle: r.subtitle,
    giftType: r.gift_type,
    createdAt: r.created_at.toISOString(),
    seen: r.seen,
  }));
}

export async function loadLatestGift(): Promise<Gift | null> {
  const rows = await sql`SELECT * FROM gifts ORDER BY created_at DESC LIMIT 1`;
  if (rows.length === 0) return null;
  const r = rows[0];
  return {
    id: r.id,
    characterUrl: r.character_url,
    characterName: r.character_name,
    message: r.message,
    subtitle: r.subtitle,
    giftType: r.gift_type,
    createdAt: r.created_at.toISOString(),
    seen: r.seen,
  };
}

export async function loadUnseenGifts(): Promise<Gift[]> {
  const rows = await sql`SELECT * FROM gifts WHERE seen = FALSE ORDER BY created_at DESC`;
  return rows.map(r => ({
    id: r.id,
    characterUrl: r.character_url,
    characterName: r.character_name,
    message: r.message,
    subtitle: r.subtitle,
    giftType: r.gift_type,
    createdAt: r.created_at.toISOString(),
    seen: r.seen,
  }));
}

export async function markGiftSeen(id: string) {
  await sql`UPDATE gifts SET seen = TRUE WHERE id = ${id}`;
}

// --- Love Coupons ---

interface LoveCoupon {
  id: string;
  title: string;
  description: string;
  emoji: string;
  createdAt: string;
  redeemed: boolean;
  redeemedAt: string | null;
}

export async function saveCoupon(coupon: { id: string; title: string; description: string; emoji: string }) {
  await sql`INSERT INTO love_coupons (id, title, description, emoji) VALUES (${coupon.id}, ${coupon.title}, ${coupon.description}, ${coupon.emoji})`;
}

export async function loadCoupons(): Promise<LoveCoupon[]> {
  const rows = await sql`SELECT * FROM love_coupons ORDER BY created_at DESC`;
  return rows.map((r: any) => ({ id: r.id, title: r.title, description: r.description, emoji: r.emoji, createdAt: r.created_at?.toISOString?.() || r.created_at, redeemed: r.redeemed, redeemedAt: r.redeemed_at?.toISOString?.() || null }));
}

export async function redeemCoupon(id: string) {
  await sql`UPDATE love_coupons SET redeemed = TRUE, redeemed_at = NOW() WHERE id = ${id}`;
}

// --- Daily Questions ---

interface DailyQuestion {
  id: string;
  question: string;
  category: string;
  answered: boolean;
  answer: string | null;
  answeredAt: string | null;
  shownDate: string | null;
}

export async function getTodayQuestion(): Promise<DailyQuestion | null> {
  const today = new Date().toISOString().split("T")[0];
  // Check if there's already a question for today
  let rows = await sql`SELECT * FROM daily_questions WHERE shown_date = ${today} LIMIT 1`;
  if (rows.length > 0) {
    const r: any = rows[0];
    return { id: r.id, question: r.question, category: r.category, answered: r.answered, answer: r.answer, answeredAt: r.answered_at?.toISOString?.() || null, shownDate: r.shown_date };
  }
  // Pick a random unanswered question
  rows = await sql`SELECT * FROM daily_questions WHERE shown_date IS NULL ORDER BY RANDOM() LIMIT 1`;
  if (rows.length === 0) {
    // All questions used, reset
    await sql`UPDATE daily_questions SET shown_date = NULL WHERE answered = FALSE`;
    rows = await sql`SELECT * FROM daily_questions WHERE shown_date IS NULL ORDER BY RANDOM() LIMIT 1`;
  }
  if (rows.length === 0) return null;
  const r: any = rows[0];
  await sql`UPDATE daily_questions SET shown_date = ${today} WHERE id = ${r.id}`;
  return { id: r.id, question: r.question, category: r.category, answered: r.answered, answer: r.answer, answeredAt: null, shownDate: today };
}

export async function answerQuestion(id: string, answer: string) {
  await sql`UPDATE daily_questions SET answered = TRUE, answer = ${answer}, answered_at = NOW() WHERE id = ${id}`;
}

export async function loadAnsweredQuestions(): Promise<DailyQuestion[]> {
  const rows = await sql`SELECT * FROM daily_questions WHERE answered = TRUE ORDER BY answered_at DESC`;
  return rows.map((r: any) => ({ id: r.id, question: r.question, category: r.category, answered: r.answered, answer: r.answer, answeredAt: r.answered_at?.toISOString?.() || null, shownDate: r.shown_date }));
}

// --- Moods ---

interface MoodEntry {
  id: string;
  mood: string;
  emoji: string;
  note: string | null;
  createdAt: string;
}

export async function saveMood(mood: { id: string; mood: string; emoji: string; note?: string }) {
  await sql`INSERT INTO moods (id, mood, emoji, note) VALUES (${mood.id}, ${mood.mood}, ${mood.emoji}, ${mood.note || null})`;
}

export async function loadMoods(): Promise<MoodEntry[]> {
  const rows = await sql`SELECT * FROM moods ORDER BY created_at DESC LIMIT 90`;
  return rows.map((r: any) => ({ id: r.id, mood: r.mood, emoji: r.emoji, note: r.note, createdAt: r.created_at?.toISOString?.() || r.created_at }));
}

export async function getTodayMood(): Promise<MoodEntry | null> {
  const today = new Date().toISOString().split("T")[0];
  const rows = await sql`SELECT * FROM moods WHERE created_at::date = ${today}::date ORDER BY created_at DESC LIMIT 1`;
  if (rows.length === 0) return null;
  const r: any = rows[0];
  return { id: r.id, mood: r.mood, emoji: r.emoji, note: r.note, createdAt: r.created_at?.toISOString?.() || r.created_at };
}

// --- Special Dates ---

interface SpecialDate {
  id: string;
  title: string;
  date: string;
  emoji: string;
  reminderDaysBefore: number;
}

export async function loadSpecialDates(): Promise<SpecialDate[]> {
  const rows = await sql`SELECT * FROM special_dates ORDER BY date ASC`;
  return rows.map((r: any) => ({ id: r.id, title: r.title, date: r.date, emoji: r.emoji, reminderDaysBefore: r.reminder_days_before }));
}

export async function saveSpecialDate(d: { id: string; title: string; date: string; emoji: string; reminderDaysBefore?: number }) {
  await sql`INSERT INTO special_dates (id, title, date, emoji, reminder_days_before) VALUES (${d.id}, ${d.title}, ${d.date}, ${d.emoji}, ${d.reminderDaysBefore || 7}) ON CONFLICT (id) DO UPDATE SET title = ${d.title}, date = ${d.date}, emoji = ${d.emoji}`;
}

export async function deleteSpecialDate(id: string) {
  await sql`DELETE FROM special_dates WHERE id = ${id}`;
}

// --- Songs ---

interface Song {
  id: string;
  youtubeUrl: string;
  title: string;
  artist: string;
  message: string;
  createdAt: string;
  seen: boolean;
}

export async function saveSong(s: { id: string; youtubeUrl: string; title: string; artist: string; message: string }) {
  await sql`INSERT INTO songs (id, youtube_url, title, artist, message) VALUES (${s.id}, ${s.youtubeUrl}, ${s.title}, ${s.artist}, ${s.message})`;
}

export async function loadSongs(): Promise<Song[]> {
  const rows = await sql`SELECT * FROM songs ORDER BY created_at DESC`;
  return rows.map((r: any) => ({ id: r.id, youtubeUrl: r.youtube_url, title: r.title, artist: r.artist, message: r.message, createdAt: r.created_at?.toISOString?.() || r.created_at, seen: r.seen }));
}

export async function loadUnseenSongs(): Promise<Song[]> {
  const rows = await sql`SELECT * FROM songs WHERE seen = FALSE ORDER BY created_at DESC`;
  return rows.map((r: any) => ({ id: r.id, youtubeUrl: r.youtube_url, title: r.title, artist: r.artist, message: r.message, createdAt: r.created_at?.toISOString?.() || r.created_at, seen: r.seen }));
}

export async function markSongSeen(id: string) {
  await sql`UPDATE songs SET seen = TRUE WHERE id = ${id}`;
}

// --- Achievements ---

interface Achievement {
  id: string;
  title: string;
  description: string;
  emoji: string;
  category: string;
  unlocked: boolean;
  unlockedAt: string | null;
  progress: number;
  target: number;
}

export async function loadAchievements(): Promise<Achievement[]> {
  const rows = await sql`SELECT * FROM achievements ORDER BY category, target`;
  return rows.map((r: any) => ({ id: r.id, title: r.title, description: r.description, emoji: r.emoji, category: r.category, unlocked: r.unlocked, unlockedAt: r.unlocked_at?.toISOString?.() || null, progress: r.progress, target: r.target }));
}

export async function unlockAchievement(id: string) {
  await sql`UPDATE achievements SET unlocked = TRUE, unlocked_at = NOW(), progress = target WHERE id = ${id}`;
}

export async function updateAchievementProgress(id: string, progress: number) {
  await sql`UPDATE achievements SET progress = ${progress} WHERE id = ${id}`;
  // Auto-unlock if progress >= target
  await sql`UPDATE achievements SET unlocked = TRUE, unlocked_at = NOW() WHERE id = ${id} AND progress >= target AND unlocked = FALSE`;
}

// --- Photos ---

interface Photo {
  id: string;
  imageData: string;
  caption: string;
  uploadedBy: string;
  createdAt: string;
}

export async function savePhoto(p: { id: string; imageData: string; caption: string; uploadedBy: string }) {
  await sql`INSERT INTO photos (id, image_data, caption, uploaded_by) VALUES (${p.id}, ${p.imageData}, ${p.caption}, ${p.uploadedBy})`;
}

export async function loadPhotos(): Promise<Photo[]> {
  const rows = await sql`SELECT id, caption, uploaded_by, created_at FROM photos ORDER BY created_at DESC`;
  return rows.map((r: any) => ({ id: r.id, imageData: "", caption: r.caption, uploadedBy: r.uploaded_by, createdAt: r.created_at?.toISOString?.() || r.created_at }));
}

export async function loadPhotoById(id: string): Promise<Photo | null> {
  const rows = await sql`SELECT * FROM photos WHERE id = ${id}`;
  if (rows.length === 0) return null;
  const r: any = rows[0];
  return { id: r.id, imageData: r.image_data, caption: r.caption, uploadedBy: r.uploaded_by, createdAt: r.created_at?.toISOString?.() || r.created_at };
}

export async function deletePhoto(id: string) {
  await sql`DELETE FROM photos WHERE id = ${id}`;
}

// --- Plans ---

interface Plan {
  id: string;
  title: string;
  description: string;
  category: string;
  proposedDate: string;
  proposedTime: string;
  status: string;
  proposedBy: string;
  createdAt: string;
}

export async function savePlan(p: { id: string; title: string; description: string; category: string; proposedDate: string; proposedTime: string; proposedBy: string }) {
  await sql`INSERT INTO plans (id, title, description, category, proposed_date, proposed_time, proposed_by) VALUES (${p.id}, ${p.title}, ${p.description}, ${p.category}, ${p.proposedDate}, ${p.proposedTime}, ${p.proposedBy})`;
}

export async function loadPlans(): Promise<Plan[]> {
  const rows = await sql`SELECT * FROM plans ORDER BY created_at DESC`;
  return rows.map((r: any) => ({ id: r.id, title: r.title, description: r.description, category: r.category, proposedDate: r.proposed_date, proposedTime: r.proposed_time, status: r.status, proposedBy: r.proposed_by, createdAt: r.created_at?.toISOString?.() || r.created_at }));
}

export async function updatePlanStatus(id: string, status: string) {
  await sql`UPDATE plans SET status = ${status} WHERE id = ${id}`;
}

export async function deletePlan(id: string) {
  await sql`DELETE FROM plans WHERE id = ${id}`;
}

// --- Chat Messages ---

interface ChatMessage {
  id: string;
  sender: string;
  type: string;
  content: string;
  mediaData: string | null;
  mediaUrl: string | null;
  replyTo: string | null;
  seen: boolean;
  createdAt: string;
}

export async function saveChatMessage(m: { id: string; sender: string; type: string; content: string; mediaData?: string; mediaUrl?: string; replyTo?: string }) {
  await sql`INSERT INTO chat_messages (id, sender, type, content, media_data, media_url, reply_to) VALUES (${m.id}, ${m.sender}, ${m.type}, ${m.content}, ${m.mediaData || null}, ${m.mediaUrl || null}, ${m.replyTo || null})`;
}

export async function loadChatMessages(limit = 50, before?: string): Promise<ChatMessage[]> {
  let rows;
  if (before) {
    rows = await sql`SELECT * FROM chat_messages WHERE created_at < ${before}::timestamptz ORDER BY created_at DESC LIMIT ${limit}`;
  } else {
    rows = await sql`SELECT * FROM chat_messages ORDER BY created_at DESC LIMIT ${limit}`;
  }
  return rows.map((r: any) => ({ id: r.id, sender: r.sender, type: r.type, content: r.content, mediaData: r.media_data, mediaUrl: r.media_url, replyTo: r.reply_to, seen: r.seen, createdAt: r.created_at?.toISOString?.() || r.created_at })).reverse();
}

export async function loadUnseenChatMessages(sender: string): Promise<ChatMessage[]> {
  const rows = await sql`SELECT * FROM chat_messages WHERE sender != ${sender} AND seen = FALSE ORDER BY created_at ASC`;
  return rows.map((r: any) => ({ id: r.id, sender: r.sender, type: r.type, content: r.content, mediaData: r.media_data, mediaUrl: r.media_url, replyTo: r.reply_to, seen: r.seen, createdAt: r.created_at?.toISOString?.() || r.created_at }));
}

export async function markChatMessagesSeen(sender: string) {
  await sql`UPDATE chat_messages SET seen = TRUE WHERE sender != ${sender} AND seen = FALSE`;
}

export async function countUnseenMessages(forSender: string): Promise<number> {
  const rows = await sql`SELECT COUNT(*) as count FROM chat_messages WHERE sender != ${forSender} AND seen = FALSE`;
  return parseInt(rows[0]?.count || "0");
}

// --- AI Stickers ---

interface AISticker {
  id: string;
  prompt: string;
  imageData: string;
  createdAt: string;
}

export async function saveAISticker(s: { id: string; prompt: string; imageData: string }) {
  await sql`INSERT INTO ai_stickers (id, prompt, image_data) VALUES (${s.id}, ${s.prompt}, ${s.imageData})`;
}

export async function loadAIStickers(): Promise<AISticker[]> {
  const rows = await sql`SELECT * FROM ai_stickers ORDER BY created_at DESC LIMIT 50`;
  return rows.map((r: any) => ({ id: r.id, prompt: r.prompt, imageData: r.image_data, createdAt: r.created_at?.toISOString?.() || r.created_at }));
}
