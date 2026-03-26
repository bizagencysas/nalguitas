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

  // Love Coupons
  await sql`
    CREATE TABLE IF NOT EXISTS love_coupons (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      emoji TEXT NOT NULL DEFAULT '🎟️',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      redeemed BOOLEAN NOT NULL DEFAULT FALSE,
      redeemed_at TIMESTAMPTZ
    )
  `;

  // Daily Questions
  await sql`
    CREATE TABLE IF NOT EXISTS daily_questions (
      id TEXT PRIMARY KEY,
      question TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'amor',
      answered BOOLEAN NOT NULL DEFAULT FALSE,
      answer TEXT,
      answered_at TIMESTAMPTZ,
      shown_date TEXT
    )
  `;

  // Moods
  await sql`
    CREATE TABLE IF NOT EXISTS moods (
      id TEXT PRIMARY KEY,
      mood TEXT NOT NULL,
      emoji TEXT NOT NULL,
      note TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // Special Dates
  await sql`
    CREATE TABLE IF NOT EXISTS special_dates (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      date TEXT NOT NULL,
      emoji TEXT NOT NULL DEFAULT '💕',
      reminder_days_before INTEGER NOT NULL DEFAULT 7,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // Songs
  await sql`
    CREATE TABLE IF NOT EXISTS songs (
      id TEXT PRIMARY KEY,
      youtube_url TEXT NOT NULL,
      title TEXT NOT NULL DEFAULT '',
      artist TEXT NOT NULL DEFAULT '',
      message TEXT NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      seen BOOLEAN NOT NULL DEFAULT FALSE
    )
  `;

  // Achievements
  await sql`
    CREATE TABLE IF NOT EXISTS achievements (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      emoji TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'general',
      unlocked BOOLEAN NOT NULL DEFAULT FALSE,
      unlocked_at TIMESTAMPTZ,
      progress INTEGER NOT NULL DEFAULT 0,
      target INTEGER NOT NULL DEFAULT 1
    )
  `;

  // Photos
  await sql`
    CREATE TABLE IF NOT EXISTS photos (
      id TEXT PRIMARY KEY,
      image_data TEXT NOT NULL,
      caption TEXT NOT NULL DEFAULT '',
      uploaded_by TEXT NOT NULL DEFAULT 'admin',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // Seed special dates
  await sql`
    INSERT INTO special_dates (id, title, date, emoji, reminder_days_before)
    VALUES 
      ('anniversary', 'Aniversario 💕', '2021-05-02', '💕', 7),
      ('valentines', 'San Valentín', '2026-02-14', '❤️', 7)
    ON CONFLICT (id) DO NOTHING
  `;

  // Seed achievements
  await sql`
    INSERT INTO achievements (id, title, description, emoji, category, target) VALUES
      ('first_message', 'Primer Mensaje', 'Envía tu primer mensaje de amor', '💌', 'mensajes', 1),
      ('msg_10', '10 Mensajes', 'Has enviado 10 mensajes', '📨', 'mensajes', 10),
      ('msg_50', '50 Mensajes', '¡50 mensajes de puro amor!', '💝', 'mensajes', 50),
      ('msg_100', 'Centenario', '¡100 mensajes de amor!', '🏆', 'mensajes', 100),
      ('msg_500', 'Leyenda del Amor', '500 mensajes... ¡increíble!', '👑', 'mensajes', 500),
      ('first_gift', 'Primera Sorpresa', 'Envía tu primera sorpresa con muñequito', '🎁', 'sorpresas', 1),
      ('gift_10', 'Rey de las Sorpresas', '10 sorpresas enviadas', '🎊', 'sorpresas', 10),
      ('gift_25', 'Sorpresólogo', '¡25 sorpresas! Eres un máquina', '🎉', 'sorpresas', 25),
      ('first_coupon', 'Primer Cupón', 'Crea tu primer cupón de amor', '🎟️', 'cupones', 1),
      ('coupon_5', 'Cupón Manía', '5 cupones creados', '🎫', 'cupones', 5),
      ('coupon_redeem', 'Cupón Canjeado', 'Tu novia canjeó un cupón', '✅', 'cupones', 1),
      ('first_song', 'DJ del Amor', 'Comparte tu primera canción', '🎵', 'canciones', 1),
      ('song_10', 'Playlist del Amor', '10 canciones compartidas', '🎶', 'canciones', 10),
      ('first_photo', 'Primer Recuerdo', 'Sube tu primera foto', '📸', 'fotos', 1),
      ('photo_10', 'Álbum de Amor', '10 fotos en tu galería', '📷', 'fotos', 10),
      ('photo_50', 'Fotógrafo Pro', '50 fotos juntos', '🏞️', 'fotos', 50),
      ('mood_streak_7', 'Semana Emocional', '7 días seguidos registrando tu mood', '🔥', 'rachas', 7),
      ('mood_streak_30', 'Mes Emocional', '30 días seguidos de moods', '⭐', 'rachas', 30),
      ('days_100', '100 Días Juntos', '¡100 días de amor!', '💯', 'tiempo', 100),
      ('days_365', '1 Año Juntos', '¡Un año completo!', '🎂', 'tiempo', 365),
      ('days_500', '500 Días', '¡500 días de puro amor!', '🌟', 'tiempo', 500),
      ('days_1000', '1000 Días', '¡Mil días juntos!', '💎', 'tiempo', 1000),
      ('days_1500', '1500 Días', '¡Mil quinientos días!', '🏅', 'tiempo', 1500),
      ('question_answer_1', 'Primera Respuesta', 'Responde tu primera pregunta del día', '❓', 'preguntas', 1),
      ('question_answer_10', 'Curiosos', '10 preguntas respondidas', '🤔', 'preguntas', 10),
      ('question_answer_50', 'Conociéndonos', '50 preguntas respondidas', '🧠', 'preguntas', 50),
      ('saved_msg_1', 'Favorito', 'Guarda tu primer mensaje favorito', '⭐', 'guardados', 1),
      ('saved_msg_10', 'Coleccionista', '10 mensajes guardados', '📚', 'guardados', 10),
      ('night_owl', 'Búho Nocturno', 'Usa la app después de las 11pm', '🦉', 'especiales', 1),
      ('early_bird', 'Madrugador', 'Usa la app antes de las 6am', '🐦', 'especiales', 1)
    ON CONFLICT (id) DO NOTHING
  `;

  // Seed daily questions pool
  await sql`
    INSERT INTO daily_questions (id, question, category) VALUES
      ('q1', '¿Qué es lo que más te enamora de mí?', 'amor'),
      ('q2', '¿Cuál fue nuestro mejor momento juntos?', 'recuerdos'),
      ('q3', '¿A dónde te gustaría viajar conmigo?', 'sueños'),
      ('q4', '¿Qué canción te recuerda a nosotros?', 'gustos'),
      ('q5', '¿Cuál es tu recuerdo favorito de nuestra relación?', 'recuerdos'),
      ('q6', '¿Qué admiras más de mí?', 'amor'),
      ('q7', '¿Cómo sería nuestro día perfecto juntos?', 'sueños'),
      ('q8', '¿Cuál fue la primera vez que supiste que me amabas?', 'recuerdos'),
      ('q9', '¿Qué cosa nueva te gustaría que hiciéramos juntos?', 'sueños'),
      ('q10', '¿Cuál es tu comida favorita para compartir conmigo?', 'gustos'),
      ('q11', '¿Qué es lo más gracioso que hemos vivido juntos?', 'recuerdos'),
      ('q12', '¿Cómo te imaginas nuestra vida en 5 años?', 'sueños'),
      ('q13', '¿Cuál es la mejor sorpresa que te he dado?', 'recuerdos'),
      ('q14', '¿Qué película nos representa como pareja?', 'gustos'),
      ('q15', '¿Qué es lo primero que notaste de mí?', 'recuerdos'),
      ('q16', '¿Hay algo que siempre quisiste decirme pero no te atreviste?', 'profundo'),
      ('q17', '¿Cuál es tu forma favorita de recibir amor?', 'amor'),
      ('q18', '¿Qué hago que te haga sentir especial?', 'amor'),
      ('q19', '¿Cuál es tu lugar favorito para estar conmigo?', 'gustos'),
      ('q20', '¿Qué superpoder te gustaría tener para nuestra relación?', 'divertido'),
      ('q21', '¿Me amas más que al café?', 'divertido'),
      ('q22', '¿Qué es lo más romántico que te gustaría vivir?', 'sueños'),
      ('q23', '¿Cuántos hijos/mascotas te gustaría tener conmigo?', 'futuro'),
      ('q24', '¿Qué nombre le pondrías a nuestra historia de amor?', 'divertido'),
      ('q25', '¿Qué es lo que más extrañas cuando no estamos juntos?', 'amor'),
      ('q26', '¿Cuál es tu foto favorita de nosotros?', 'recuerdos'),
      ('q27', '¿Qué tradición de pareja te gustaría crear?', 'sueños'),
      ('q28', '¿Cuál fue nuestra mejor cita?', 'recuerdos'),
      ('q29', '¿Qué serie o peli te gustaría ver conmigo?', 'gustos'),
      ('q30', '¿Qué te hace sonreír cuando piensas en mí?', 'amor')
    ON CONFLICT (id) DO NOTHING
  `;
  // Plans
  await sql`
    CREATE TABLE IF NOT EXISTS plans (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL DEFAULT 'cita',
      proposed_date TEXT NOT NULL DEFAULT '',
      proposed_time TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'pendiente',
      proposed_by TEXT NOT NULL DEFAULT 'admin',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;
  // Chat Messages
  await sql`
    CREATE TABLE IF NOT EXISTS chat_messages (
      id TEXT PRIMARY KEY,
      sender TEXT NOT NULL DEFAULT 'admin',
      type TEXT NOT NULL DEFAULT 'text',
      content TEXT NOT NULL DEFAULT '',
      media_data TEXT,
      media_url TEXT,
      reply_to TEXT,
      seen BOOLEAN NOT NULL DEFAULT FALSE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // AI Stickers (cached generated stickers)
  await sql`
    CREATE TABLE IF NOT EXISTS ai_stickers (
      id TEXT PRIMARY KEY,
      prompt TEXT NOT NULL,
      image_data TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // Custom Facts (admin-editable "sabías qué")
  await sql`
    CREATE TABLE IF NOT EXISTS custom_facts (
      id TEXT PRIMARY KEY,
      fact TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // English Word of the Day (365 words)
  await sql`
    CREATE TABLE IF NOT EXISTS english_words (
      id TEXT PRIMARY KEY,
      word TEXT NOT NULL,
      translation TEXT NOT NULL,
      example_en TEXT NOT NULL DEFAULT '',
      example_es TEXT NOT NULL DEFAULT '',
      pronunciation TEXT NOT NULL DEFAULT '',
      day_of_year INT UNIQUE NOT NULL,
      ai_example TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // Scratch Cards (admin creates prizes)
  await sql`
    CREATE TABLE IF NOT EXISTS scratch_cards (
      id TEXT PRIMARY KEY,
      prize TEXT NOT NULL,
      emoji TEXT NOT NULL DEFAULT '🎁',
      scratched BOOLEAN NOT NULL DEFAULT FALSE,
      scratched_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // Roulette Options
  await sql`
    CREATE TABLE IF NOT EXISTS roulette_options (
      id TEXT PRIMARY KEY,
      category TEXT NOT NULL DEFAULT 'general',
      option_text TEXT NOT NULL,
      added_by TEXT NOT NULL DEFAULT 'admin',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // Diary Entries
  await sql`
    CREATE TABLE IF NOT EXISTS diary_entries (
      id TEXT PRIMARY KEY,
      author TEXT NOT NULL,
      content TEXT NOT NULL,
      entry_date TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE(author, entry_date)
    )
  `;

  // Points Ledger
  await sql`
    CREATE TABLE IF NOT EXISTS points_ledger (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      points INT NOT NULL,
      reason TEXT NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // Rewards Catalog
  await sql`
    CREATE TABLE IF NOT EXISTS rewards (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      emoji TEXT NOT NULL DEFAULT '🎁',
      cost INT NOT NULL DEFAULT 10,
      redeemed BOOLEAN NOT NULL DEFAULT FALSE,
      redeemed_by TEXT,
      redeemed_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  // Experiences (Bucket List)
  await sql`
    CREATE TABLE IF NOT EXISTS experiences (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      emoji TEXT NOT NULL DEFAULT '✨',
      completed BOOLEAN NOT NULL DEFAULT FALSE,
      completed_photo TEXT,
      completed_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS profiles (
      username TEXT PRIMARY KEY,
      display_name TEXT NOT NULL DEFAULT '',
      avatar TEXT DEFAULT '',
      status_message TEXT DEFAULT '',
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `;

  console.log("[DB] Migrations complete");
}
