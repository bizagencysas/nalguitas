import postgres from "postgres";

const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
  throw new Error("DATABASE_URL environment variable is required");
}

export const sql = postgres(DATABASE_URL, {
  ssl: "require",
  max: 10,
  idle_timeout: 20,
  connect_timeout: 10,
});

export async function migrate() {
  console.log("[DB] Running migrations...");

  await sql`
    CREATE TABLE IF NOT EXISTS devices (
      id SERIAL PRIMARY KEY,
      token TEXT NOT NULL,
      device_id TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'girlfriend',
      registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE(device_id, role)
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      content TEXT NOT NULL,
      subtitle TEXT NOT NULL DEFAULT 'Para ti',
      tone TEXT NOT NULL DEFAULT 'tierno',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      is_special BOOLEAN NOT NULL DEFAULT FALSE,
      scheduled_date TEXT,
      priority INTEGER NOT NULL DEFAULT 1
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS notification_history (
      id TEXT PRIMARY KEY,
      message TEXT NOT NULL,
      sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      status TEXT NOT NULL DEFAULT 'pending'
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS girlfriend_messages (
      id TEXT PRIMARY KEY,
      content TEXT NOT NULL,
      sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      read BOOLEAN NOT NULL DEFAULT FALSE
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS remote_config (
      key TEXT PRIMARY KEY,
      value JSONB NOT NULL
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS roles (
      device_id TEXT PRIMARY KEY,
      role TEXT NOT NULL,
      registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS gifts (
      id TEXT PRIMARY KEY,
      character_url TEXT NOT NULL,
      character_name TEXT NOT NULL DEFAULT 'capibara',
      message TEXT NOT NULL,
      subtitle TEXT NOT NULL DEFAULT 'Para ti',
      gift_type TEXT NOT NULL DEFAULT 'surprise',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      seen BOOLEAN NOT NULL DEFAULT FALSE
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS schedule_config (
      id INTEGER PRIMARY KEY DEFAULT 1,
      morning TEXT NOT NULL DEFAULT '08:00',
      midday TEXT NOT NULL DEFAULT '12:30',
      afternoon TEXT NOT NULL DEFAULT '17:00',
      night TEXT NOT NULL DEFAULT '21:30'
    )
  `;

  await sql`
    INSERT INTO schedule_config (id, morning, midday, afternoon, night)
    VALUES (1, '08:00', '12:30', '17:00', '21:30')
    ON CONFLICT (id) DO NOTHING
  `;

  console.log("[DB] Migrations complete");
}
