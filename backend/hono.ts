import { trpcServer } from "@hono/trpc-server";
import { Hono } from "hono";
import { cors } from "hono/cors";

import { appRouter } from "./trpc/app-router";
import { createContext } from "./trpc/create-context";
import { loadRemoteConfig, saveRemoteConfig, loadRoles, saveRole, saveMessage, loadMessages, deleteMessage, saveGift, loadGifts, loadUnseenGifts, markGiftSeen, saveCoupon, loadCoupons, redeemCoupon, getTodayQuestion, answerQuestion, loadAnsweredQuestions, saveMood, loadMoods, getTodayMood, loadSpecialDates, saveSpecialDate, deleteSpecialDate, saveSong, loadSongs, loadUnseenSongs, markSongSeen, loadAchievements, unlockAchievement, updateAchievementProgress, savePhoto, loadPhotos, loadPhotoById, deletePhoto, loadDevices, savePlan, loadPlans, updatePlanStatus, deletePlan, saveChatMessage, loadChatMessages, markChatMessagesSeen, countUnseenMessages, saveAISticker, loadAIStickers, saveCustomFact, loadCustomFacts, loadRandomFact, deleteCustomFact, deleteDevice, getTodayWord, seedEnglishWords, updateWordAiExample, saveScratchCard, loadScratchCards, getUnscratched, scratchCard, saveRouletteOption, loadRouletteOptions, loadRouletteCategories, deleteRouletteOption, saveDiaryEntry, getDiaryEntry, loadDiaryEntries, addPoints, getPointsBalance, getPointsHistory, saveReward, loadRewards, redeemReward, deleteReward, saveExperience, loadExperiences, completeExperience, deleteExperience, getProfile, saveProfile, updateAvatar, updateStatus } from "./storage";
import { ENGLISH_WORDS } from "./words";
import { sendPushNotification } from "./apns-service";
import { migrate } from "./db";

const app = new Hono();

app.use("*", cors());

let migrated = false;
app.use("*", async (c, next) => {
  if (!migrated) {
    migrated = true;
    try {
      await migrate();
      console.log("[DB] Migration successful");
    } catch (e: any) {
      console.error("[DB] Migration failed:", e.message);
      migrated = false;
    }
  }
  await next();
});

app.onError((err, c) => {
  console.error("API Error:", err.message);
  return c.json({ error: err.message || "Internal Server Error" }, 500);
});

// Direct handler for messages.create - bypasses tRPC to handle both flat and wrapped JSON
// This runs BEFORE the tRPC middleware because it's registered first
app.post("/trpc/messages.create", async (c) => {
  try {
    const body = await c.req.json();
    // Accept both flat {"content":"..."} and tRPC-wrapped {"json":{"content":"..."}}
    const input = body?.json ?? body;
    const content = input?.content;
    if (!content || typeof content !== "string" || content.trim() === "") {
      return c.json({ error: { message: "content is required", code: -32600 } }, 400);
    }
    const msg = {
      id: Date.now().toString(),
      content: content.trim(),
      subtitle: input?.subtitle || "Para ti",
      tone: input?.tone || "tierno",
      createdAt: new Date().toISOString(),
      isSpecial: input?.isSpecial ?? false,
      scheduledDate: input?.scheduledDate,
      priority: input?.priority ?? 1,
    };
    await saveMessage(msg);
    console.log(`[Messages] Created via tRPC bypass: "${msg.content.substring(0, 40)}"`);
    // Return tRPC-compatible response format
    return c.json({ result: { data: { json: msg } } });
  } catch (e: any) {
    console.error("Error creating message (tRPC bypass):", e);
    return c.json({ error: { message: e.message } }, 500);
  }
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

app.post("/messages", async (c) => {
  try {
    const body = await c.req.json();
    // Accept both flat JSON {"content":"..."} and tRPC-wrapped {"json":{"content":"..."}}
    const input = body?.json ?? body;
    const content = input?.content;
    if (!content || typeof content !== "string" || content.trim() === "") {
      return c.json({ error: "content is required" }, 400);
    }
    const msg = {
      id: Date.now().toString(),
      content: content.trim(),
      subtitle: input?.subtitle || "Para ti",
      tone: input?.tone || "tierno",
      createdAt: new Date().toISOString(),
      isSpecial: input?.isSpecial ?? false,
      scheduledDate: input?.scheduledDate,
      priority: input?.priority ?? 1,
    };
    await saveMessage(msg);
    console.log(`[Messages] Created: "${msg.content.substring(0, 40)}"`);
    return c.json(msg);
  } catch (e: any) {
    console.error("Error creating message:", e);
    return c.json({ error: e.message }, 500);
  }
});

app.delete("/messages/:id", async (c) => {
  try {
    const id = c.req.param("id");
    await deleteMessage(id);
    return c.json({ success: true });
  } catch (e: any) {
    console.error("Error deleting message:", e);
    return c.json({ error: e.message }, 500);
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

// --- Gift Endpoints ---

app.post("/gifts", async (c) => {
  try {
    const body = await c.req.json();
    const message = body?.message;
    if (!message || typeof message !== "string" || message.trim() === "") {
      return c.json({ error: "message is required" }, 400);
    }
    const gift = {
      id: Date.now().toString(),
      characterUrl: body?.characterUrl || "",
      characterName: body?.characterName || "capibara",
      message: message.trim(),
      subtitle: body?.subtitle || "Para ti",
      giftType: body?.giftType || "surprise",
      createdAt: new Date().toISOString(),
      seen: false,
    };
    await saveGift(gift);
    console.log(`[Gifts] Created: "${gift.message.substring(0, 40)}" with ${gift.characterName}`);

    // Send push notification to girlfriend
    const { girlfriendDevices } = await loadDevices();
    if (girlfriendDevices.length > 0) {
      const pushTitle = "Isacc te envió algo... 💝";
      const pushBody = "Abre la app para ver tu sorpresa";
      await Promise.all(
        girlfriendDevices.map(d => sendPushNotification(d.token, pushTitle, pushBody))
      );
      console.log(`[Gifts] Push sent to ${girlfriendDevices.length} devices`);
    }

    return c.json(gift);
  } catch (e: any) {
    console.error("Error creating gift:", e);
    return c.json({ error: e.message }, 500);
  }
});

app.get("/gifts/unseen", async (c) => {
  try {
    const gifts = await loadUnseenGifts();
    return c.json(gifts);
  } catch (e: any) {
    return c.json([], 200);
  }
});

app.get("/gifts", async (c) => {
  try {
    const gifts = await loadGifts();
    return c.json(gifts);
  } catch (e: any) {
    return c.json([], 200);
  }
});

app.post("/gifts/:id/seen", async (c) => {
  try {
    const id = c.req.param("id");
    await markGiftSeen(id);
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

// --- Coupon Endpoints ---

app.post("/coupons", async (c) => {
  try {
    const body = await c.req.json();
    const title = body?.title;
    if (!title) return c.json({ error: "title is required" }, 400);
    const coupon = { id: Date.now().toString(), title, description: body?.description || "", emoji: body?.emoji || "🎟️" };
    await saveCoupon(coupon);
    // Push to girlfriend
    const { girlfriendDevices } = await loadDevices();
    await Promise.all(girlfriendDevices.map(d => sendPushNotification(d.token, "¡Nuevo cupón de amor! 🎟️", title)));
    return c.json(coupon);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/coupons", async (c) => {
  try { return c.json(await loadCoupons()); } catch { return c.json([], 200); }
});

app.post("/coupons/:id/redeem", async (c) => {
  try {
    const id = c.req.param("id");
    await redeemCoupon(id);
    // Notify admin
    const { adminDevices } = await loadDevices();
    await Promise.all(adminDevices.map(d => sendPushNotification(d.token, "¡Cupón canjeado! ✅", "Tu novia canjeó un cupón")));
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// --- Daily Question Endpoints ---

app.get("/questions/today", async (c) => {
  try {
    const q = await getTodayQuestion();
    return c.json(q || { id: null, question: "¡Todas las preguntas fueron respondidas! 🎉" });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/questions/:id/answer", async (c) => {
  try {
    const id = c.req.param("id");
    const body = await c.req.json();
    if (!body?.answer) return c.json({ error: "answer is required" }, 400);
    await answerQuestion(id, body.answer);
    // Notify admin that she answered
    const { adminDevices } = await loadDevices();
    await Promise.all(adminDevices.map(d => sendPushNotification(d.token, "📝 Tu novia respondió la pregunta del día", body.answer.substring(0, 50))));
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/questions/answered", async (c) => {
  try { return c.json(await loadAnsweredQuestions()); } catch { return c.json([], 200); }
});

// --- Mood Endpoints ---

app.post("/moods", async (c) => {
  try {
    const body = await c.req.json();
    if (!body?.mood || !body?.emoji) return c.json({ error: "mood and emoji are required" }, 400);
    const mood = { id: Date.now().toString(), mood: body.mood, emoji: body.emoji, note: body?.note };
    await saveMood(mood);
    // Notify admin
    const { adminDevices } = await loadDevices();
    await Promise.all(adminDevices.map(d => sendPushNotification(d.token, `Tu novia se siente ${body.emoji}`, body.mood)));
    return c.json(mood);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/moods", async (c) => {
  try { return c.json(await loadMoods()); } catch { return c.json([], 200); }
});

app.get("/moods/today", async (c) => {
  try { return c.json(await getTodayMood() || { id: null }); } catch { return c.json({ id: null }, 200); }
});

// --- Special Dates Endpoints ---

app.get("/dates", async (c) => {
  try { return c.json(await loadSpecialDates()); } catch { return c.json([], 200); }
});

app.post("/dates", async (c) => {
  try {
    const body = await c.req.json();
    if (!body?.title || !body?.date) return c.json({ error: "title and date are required" }, 400);
    const d = { id: body?.id || Date.now().toString(), title: body.title, date: body.date, emoji: body?.emoji || "💕", reminderDaysBefore: body?.reminderDaysBefore || 7 };
    await saveSpecialDate(d);
    return c.json(d);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.delete("/dates/:id", async (c) => {
  try { await deleteSpecialDate(c.req.param("id")); return c.json({ success: true }); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/days-together", async (c) => {
  const start = new Date("2021-05-02T00:00:00");
  const now = new Date();
  const diff = Math.floor((now.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
  const years = Math.floor(diff / 365);
  const months = Math.floor((diff % 365) / 30);
  const days = diff % 30;
  return c.json({ totalDays: diff, years, months, days, startDate: "2021-05-02" });
});

// --- Song Endpoints ---

app.post("/songs", async (c) => {
  try {
    const body = await c.req.json();
    if (!body?.youtubeUrl) return c.json({ error: "youtubeUrl is required" }, 400);
    const s = { id: Date.now().toString(), youtubeUrl: body.youtubeUrl, title: body?.title || "", artist: body?.artist || "", message: body?.message || "" };
    await saveSong(s);
    // Push to both (bidirectional)
    const { adminDevices, girlfriendDevices } = await loadDevices();
    const allDevices = [...adminDevices, ...girlfriendDevices];
    const pushTitle = body?.fromGirlfriend ? "🎵 Tu novia te envió una canción" : "🎵 Isacc te envió una canción";
    await Promise.all(allDevices.map(d => sendPushNotification(d.token, pushTitle, body?.title || "Escúchala 💕")));
    return c.json(s);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/songs", async (c) => {
  try { return c.json(await loadSongs()); } catch { return c.json([], 200); }
});

app.get("/songs/unseen", async (c) => {
  try { return c.json(await loadUnseenSongs()); } catch { return c.json([], 200); }
});

app.post("/songs/:id/seen", async (c) => {
  try { await markSongSeen(c.req.param("id")); return c.json({ success: true }); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// --- Achievement Endpoints ---

app.get("/achievements", async (c) => {
  try { return c.json(await loadAchievements()); } catch { return c.json([], 200); }
});

app.post("/achievements/:id/unlock", async (c) => {
  try { await unlockAchievement(c.req.param("id")); return c.json({ success: true }); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/achievements/:id/progress", async (c) => {
  try {
    const body = await c.req.json();
    await updateAchievementProgress(c.req.param("id"), body?.progress || 0);
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// --- Photo Endpoints ---

app.post("/photos", async (c) => {
  try {
    const body = await c.req.json();
    if (!body?.imageData) return c.json({ error: "imageData is required" }, 400);
    const p = { id: Date.now().toString(), imageData: body.imageData, caption: body?.caption || "", uploadedBy: body?.uploadedBy || "admin" };
    await savePhoto(p);
    // Push to the other person
    const { adminDevices, girlfriendDevices } = await loadDevices();
    const targets = p.uploadedBy === "admin" ? girlfriendDevices : adminDevices;
    const pushTitle = p.uploadedBy === "admin" ? "📸 Isacc compartió una foto" : "📸 Tu novia compartió una foto";
    await Promise.all(targets.map(d => sendPushNotification(d.token, pushTitle, p.caption || "Mira 💕")));
    return c.json({ id: p.id, caption: p.caption, uploadedBy: p.uploadedBy });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/photos", async (c) => {
  try { return c.json(await loadPhotos()); } catch { return c.json([], 200); }
});

app.get("/photos/:id", async (c) => {
  try {
    const photo = await loadPhotoById(c.req.param("id"));
    if (!photo) return c.json({ error: "not found" }, 404);
    return c.json(photo);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.delete("/photos/:id", async (c) => {
  try { await deletePhoto(c.req.param("id")); return c.json({ success: true }); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// --- Plans Endpoints ---

app.post("/plans", async (c) => {
  try {
    const body = await c.req.json();
    if (!body?.title) return c.json({ error: "title is required" }, 400);
    const p = { id: Date.now().toString(), title: body.title, description: body?.description || "", category: body?.category || "cita", proposedDate: body?.proposedDate || "", proposedTime: body?.proposedTime || "", proposedBy: body?.proposedBy || "admin" };
    await savePlan(p);
    const { adminDevices, girlfriendDevices } = await loadDevices();
    const targets = p.proposedBy === "admin" ? girlfriendDevices : adminDevices;
    const pushTitle = p.proposedBy === "admin" ? "📍 Isacc propone un plan" : "📍 Tu novia propone un plan";
    await Promise.all(targets.map(d => sendPushNotification(d.token, pushTitle, `${body.title} - ${body?.proposedDate || ""}`)));
    return c.json(p);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/plans", async (c) => {
  try { return c.json(await loadPlans()); } catch { return c.json([], 200); }
});

app.post("/plans/:id/status", async (c) => {
  try {
    const body = await c.req.json();
    await updatePlanStatus(c.req.param("id"), body?.status || "aceptado");
    const { adminDevices, girlfriendDevices } = await loadDevices();
    const all = [...adminDevices, ...girlfriendDevices];
    await Promise.all(all.map(d => sendPushNotification(d.token, `Plan ${body?.status || "actualizado"} ✅`, "")));
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.delete("/plans/:id", async (c) => {
  try { await deletePlan(c.req.param("id")); return c.json({ success: true }); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// --- Chat Endpoints ---

app.post("/chat/send", async (c) => {
  try {
    const body = await c.req.json();
    const msg = { id: Date.now().toString(), sender: body?.sender || "admin", type: body?.type || "text", content: body?.content || "", mediaData: body?.mediaData, mediaUrl: body?.mediaUrl, replyTo: body?.replyTo };
    await saveChatMessage(msg);
    const { adminDevices, girlfriendDevices } = await loadDevices();
    const targets = msg.sender === "admin" ? girlfriendDevices : adminDevices;
    const pushTitle = msg.sender === "admin" ? "💬 Isacc" : "💬 Mi amor";
    let pushBody = msg.content;
    if (msg.type === "image") pushBody = "📷 Foto";
    if (msg.type === "video") pushBody = "🎬 Video";
    if (msg.type === "sticker") pushBody = "🎨 Sticker";
    if (msg.type === "link") pushBody = `🔗 ${msg.content || "Link"}`;
    await Promise.all(targets.map((d: any) => sendPushNotification(d.token, pushTitle, pushBody)));
    return c.json(msg);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/chat/messages", async (c) => {
  try {
    const limit = parseInt(c.req.query("limit") || "50");
    const before = c.req.query("before");
    return c.json(await loadChatMessages(limit, before || undefined));
  } catch { return c.json([], 200); }
});

app.post("/chat/seen", async (c) => {
  try {
    const body = await c.req.json();
    await markChatMessagesSeen(body?.sender || "admin");
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/chat/unseen", async (c) => {
  try {
    const sender = c.req.query("sender") || "admin";
    return c.json({ count: await countUnseenMessages(sender) });
  } catch { return c.json({ count: 0 }, 200); }
});

// --- AI Sticker Generation (Rork Toolkit DALL-E 3) ---

app.post("/stickers/generate", async (c) => {
  try {
    const body = await c.req.json();
    if (!body?.prompt) return c.json({ error: "prompt required" }, 400);
    const res = await fetch("https://toolkit.rork.com/images/generate/", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt: `Cute 3D kawaii ${body.prompt}, transparent background, no background, PNG cutout style, Pixar quality 3D render, big sparkling eyes, blushing cheeks, isolated character only`, size: "1024x1024" })
    });
    const data = await res.json();
    if (data?.image) {
      const sticker = { id: Date.now().toString(), prompt: body.prompt, imageData: data.image };
      await saveAISticker(sticker);
      return c.json(sticker);
    }
    return c.json({ error: "Failed to generate" }, 500);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/stickers", async (c) => {
  try { return c.json(await loadAIStickers()); } catch { return c.json([], 200); }
});

// --- Character Images List ---

app.get("/characters", async (c) => {
  try {
    const fs = await import("fs");
    const path = await import("path");
    const dir = path.join(process.cwd(), "characters");
    if (!fs.existsSync(dir)) return c.json([]);
    const files = fs.readdirSync(dir).filter((f: string) => f.endsWith(".png"));
    return c.json(files.map((f: string) => ({ name: f.replace(".png", ""), url: `/characters/${f}` })));
  } catch { return c.json([], 200); }
});

// --- Custom Facts (admin-editable "sabías qué") ---

app.get("/facts/random", async (c) => {
  try {
    const fact = await loadRandomFact();
    if (!fact) return c.json({ id: "default", fact: "El amor verdadero crece cada día más fuerte 💕" });
    return c.json(fact);
  } catch { return c.json({ id: "default", fact: "El amor verdadero crece cada día más fuerte 💕" }); }
});

app.get("/facts", async (c) => {
  try { return c.json(await loadCustomFacts()); } catch { return c.json([], 200); }
});

app.post("/facts", async (c) => {
  try {
    const body = await c.req.json();
    if (!body?.fact) return c.json({ error: "fact required" }, 400);
    const id = Date.now().toString();
    await saveCustomFact(id, body.fact);
    return c.json({ id, fact: body.fact });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.delete("/facts/:id", async (c) => {
  try {
    await deleteCustomFact(c.req.param("id"));
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// --- Device Management ---

app.delete("/devices/:deviceId", async (c) => {
  try {
    await deleteDevice(c.req.param("deviceId"));
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/characters/:name", async (c) => {
  try {
    const fs = await import("fs");
    const path = await import("path");
    const name = c.req.param("name");
    const filePath = path.join(process.cwd(), "characters", name.endsWith(".png") ? name : `${name}.png`);
    if (!fs.existsSync(filePath)) return c.json({ error: "not found" }, 404);
    const data = fs.readFileSync(filePath);
    return new Response(data, { headers: { "Content-Type": "image/png", "Cache-Control": "public, max-age=86400" } });
  } catch { return c.json({ error: "not found" }, 404); }
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

// ===== ENGLISH WORD OF THE DAY =====

app.get("/words/today", async (c: any) => {
  try {
    await seedEnglishWords(ENGLISH_WORDS);
    const word = await getTodayWord();
    if (!word) return c.json({ error: "No word for today" }, 404);
    return c.json(word);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/words/ai-example", async (c: any) => {
  try {
    const { word, translation, dayOfYear } = await c.req.json();
    const resp = await fetch("https://toolkit.rork.com/agent/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt: `Create a fun, romantic, and short example sentence using the English word "${word}" (which means "${translation}" in Spanish). The sentence should be playful and cute, as if a boyfriend wrote it for his girlfriend. Reply with ONLY the sentence in English, then a line break, then the Spanish translation. Keep it under 15 words each.` })
    });
    const data: any = await resp.json();
    const aiText = data.response || data.text || data.message || "";
    if (aiText) await updateWordAiExample(dayOfYear, aiText);
    return c.json({ aiExample: aiText });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// ===== SCRATCH CARDS =====

app.get("/scratch-cards", async (c: any) => {
  try { return c.json(await loadScratchCards()); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/scratch-cards/available", async (c: any) => {
  try {
    const card = await getUnscratched();
    if (!card) return c.json({ available: false });
    return c.json({ available: true, card });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/scratch-cards", async (c: any) => {
  try {
    const { prize, emoji } = await c.req.json();
    const id = `sc-${Date.now()}`;
    await saveScratchCard(id, prize, emoji || "🎁");
    return c.json({ success: true, id });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/scratch-cards/:id/scratch", async (c: any) => {
  try {
    await scratchCard(c.req.param("id"));
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// ===== ROULETTE =====

app.get("/roulette/categories", async (c: any) => {
  try { return c.json(await loadRouletteCategories()); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/roulette/:category", async (c: any) => {
  try { return c.json(await loadRouletteOptions(c.req.param("category"))); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/roulette", async (c: any) => {
  try {
    const { category, optionText, addedBy } = await c.req.json();
    const id = `ro-${Date.now()}`;
    await saveRouletteOption(id, category || "general", optionText, addedBy || "admin");
    return c.json({ success: true, id });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.delete("/roulette/:id", async (c: any) => {
  try { await deleteRouletteOption(c.req.param("id")); return c.json({ success: true }); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// ===== DIARY =====

app.get("/diary/:author", async (c: any) => {
  try { return c.json(await loadDiaryEntries(c.req.param("author"))); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/diary/:author/today", async (c: any) => {
  try {
    const today = new Date().toISOString().split("T")[0];
    const entry = await getDiaryEntry(c.req.param("author"), today);
    return c.json(entry || { content: null });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/diary/:author/partner", async (c: any) => {
  try {
    const author = c.req.param("author");
    const partner = author === "admin" ? "girlfriend" : "admin";
    const yesterday = new Date(Date.now() - 86400000).toISOString().split("T")[0];
    const entries = await loadDiaryEntries(partner, 30);
    const visible = entries.filter((e: any) => e.entryDate <= yesterday);
    return c.json(visible);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/diary", async (c: any) => {
  try {
    const { author, content } = await c.req.json();
    const today = new Date().toISOString().split("T")[0];
    const id = `de-${Date.now()}`;
    await saveDiaryEntry(id, author, content, today);
    return c.json({ success: true, id, entryDate: today });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// ===== POINTS =====

app.get("/points/:username", async (c: any) => {
  try {
    const username = c.req.param("username");
    const balance = await getPointsBalance(username);
    return c.json({ username, balance });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.get("/points/:username/history", async (c: any) => {
  try { return c.json(await getPointsHistory(c.req.param("username"))); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/points", async (c: any) => {
  try {
    const { username, points, reason } = await c.req.json();
    const id = `pt-${Date.now()}`;
    await addPoints(id, username, points, reason || "");
    const balance = await getPointsBalance(username);
    return c.json({ success: true, balance });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// ===== REWARDS =====

app.get("/rewards", async (c: any) => {
  try { return c.json(await loadRewards()); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/rewards", async (c: any) => {
  try {
    const { title, emoji, cost } = await c.req.json();
    const id = `rw-${Date.now()}`;
    await saveReward(id, title, emoji || "🎁", cost || 10);
    return c.json({ success: true, id });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/rewards/:id/redeem", async (c: any) => {
  try {
    const { redeemedBy } = await c.req.json();
    const balance = await getPointsBalance(redeemedBy);
    const rewards = await loadRewards();
    const reward = rewards.find((r: any) => r.id === c.req.param("id"));
    if (!reward) return c.json({ error: "Reward not found" }, 404);
    if (reward.redeemed) return c.json({ error: "Already redeemed" }, 400);
    if (balance < reward.cost) return c.json({ error: "Not enough points" }, 400);
    await redeemReward(c.req.param("id"), redeemedBy);
    await addPoints(`pt-${Date.now()}`, redeemedBy, -reward.cost, `Canjeado: ${reward.title}`);
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.delete("/rewards/:id", async (c: any) => {
  try { await deleteReward(c.req.param("id")); return c.json({ success: true }); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

// ===== EXPERIENCES (BUCKET LIST) =====

app.get("/experiences", async (c: any) => {
  try { return c.json(await loadExperiences()); } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/experiences", async (c: any) => {
  try {
    const { title, description, emoji } = await c.req.json();
    const id = `exp-${Date.now()}`;
    await saveExperience(id, title, description || "", emoji || "✨");
    return c.json({ success: true, id });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.post("/experiences/:id/complete", async (c: any) => {
  try {
    const { photo } = await c.req.json();
    await completeExperience(c.req.param("id"), photo || null);
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.delete("/experiences/:id", async (c: any) => {
  try { await deleteExperience(c.req.param("id")); return c.json({ success: true }); } catch (e: any) { return c.json({ error: e.message }, 500); }
});
// ===== PROFILES (BBM-style) =====

app.get("/profiles/:username", async (c: any) => {
  try {
    const profile = await getProfile(c.req.param("username"));
    if (!profile) return c.json({ username: c.req.param("username"), displayName: "", avatar: "", statusMessage: "" });
    return c.json(profile);
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.put("/profiles/:username", async (c: any) => {
  try {
    const { displayName, avatar, statusMessage } = await c.req.json();
    await saveProfile(c.req.param("username"), displayName || "", avatar || "", statusMessage || "");
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.put("/profiles/:username/avatar", async (c: any) => {
  try {
    const { avatar } = await c.req.json();
    await updateAvatar(c.req.param("username"), avatar || "");
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

app.put("/profiles/:username/status", async (c: any) => {
  try {
    const { statusMessage } = await c.req.json();
    await updateStatus(c.req.param("username"), statusMessage || "");
    return c.json({ success: true });
  } catch (e: any) { return c.json({ error: e.message }, 500); }
});

export default app;
