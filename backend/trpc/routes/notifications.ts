import * as z from "zod";
import { createTRPCRouter, publicProcedure } from "../create-context";
import { sendPushNotification } from "../../apns-service";
import { loadDevices, saveDevices, loadNotificationHistory, saveNotificationHistory, loadGirlfriendMessages, saveGirlfriendMessages } from "../../storage";

interface DeviceInfo {
  token: string;
  deviceId: string;
  registeredAt: string;
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

const stored = loadDevices();
let girlfriendDevices: DeviceInfo[] = stored.girlfriendDevices;
let adminDevices: DeviceInfo[] = stored.adminDevices;
const MAX_DEVICES = 10;
let notificationHistory: NotificationLog[] = loadNotificationHistory();
let girlfriendMessages: GirlfriendMessage[] = loadGirlfriendMessages();

const scheduleConfig = {
  morning: "08:00",
  midday: "12:30",
  afternoon: "17:00",
  night: "21:30",
};

function persistDevices() {
  saveDevices({ girlfriendDevices, adminDevices });
}

export const notificationsRouter = createTRPCRouter({
  registerDevice: publicProcedure
    .input(z.object({
      token: z.string(),
      deviceId: z.string(),
      isAdmin: z.boolean().optional(),
    }))
    .mutation(({ input }) => {
      const device: DeviceInfo = {
        token: input.token,
        deviceId: input.deviceId,
        registeredAt: new Date().toISOString(),
      };
      if (input.isAdmin) {
        adminDevices = adminDevices.filter(d => d.deviceId !== input.deviceId && d.token !== input.token);
        adminDevices.push(device);
        if (adminDevices.length > MAX_DEVICES) adminDevices = adminDevices.slice(-MAX_DEVICES);
        console.log(`[Register] Admin device: ${input.token.substring(0, 20)}... (total: ${adminDevices.length})`);
      } else {
        girlfriendDevices = girlfriendDevices.filter(d => d.deviceId !== input.deviceId && d.token !== input.token);
        girlfriendDevices.push(device);
        if (girlfriendDevices.length > MAX_DEVICES) girlfriendDevices = girlfriendDevices.slice(-MAX_DEVICES);
        console.log(`[Register] Girlfriend device: ${input.token.substring(0, 20)}... (total: ${girlfriendDevices.length})`);
      }
      persistDevices();
      return { success: true, message: "Device registered" };
    }),

  getDevice: publicProcedure.query(() => {
    return {
      girlfriend: girlfriendDevices.length > 0 ? girlfriendDevices[girlfriendDevices.length - 1] : null,
      admin: adminDevices.length > 0 ? adminDevices[adminDevices.length - 1] : null,
      girlfriendCount: girlfriendDevices.length,
      adminCount: adminDevices.length,
    };
  }),

  sendNow: publicProcedure
    .input(z.object({
      message: z.string().min(1),
    }))
    .mutation(async ({ input }) => {
      console.log(`[SendNow] Sending notification: "${input.message.substring(0, 50)}..."`);
      console.log(`[SendNow] Girlfriend devices: ${girlfriendDevices.length}, Admin devices: ${adminDevices.length}`);

      let pushStatus = "no_device";

      if (girlfriendDevices.length > 0) {
        const results = await Promise.all(
          girlfriendDevices.map(d => sendPushNotification(d.token, "Nalguitas 💕", input.message))
        );
        const successCount = results.filter(r => r.success).length;
        pushStatus = successCount > 0 ? `sent (${successCount}/${girlfriendDevices.length})` : `failed: ${results[0]?.error}`;
        console.log(`[SendNow] Push result: ${pushStatus}`);
      } else {
        console.log("[SendNow] No girlfriend devices registered - notification NOT sent");
      }

      const log: NotificationLog = {
        id: Date.now().toString(),
        message: input.message,
        sentAt: new Date().toISOString(),
        status: pushStatus,
      };
      notificationHistory.unshift(log);
      saveNotificationHistory(notificationHistory);

      return {
        success: true,
        message: pushStatus.startsWith("sent") ? "Notificación enviada" : "Mensaje guardado (sin push: " + pushStatus + ")",
        log,
      };
    }),

  testNotification: publicProcedure.mutation(async () => {
    console.log(`[Test] Girlfriend devices: ${girlfriendDevices.length}, Admin devices: ${adminDevices.length}`);
    
    if (girlfriendDevices.length === 0) {
      throw new Error("No girlfriend device registered. La novia debe abrir la app primero para registrar su dispositivo.");
    }

    const results = await Promise.all(
      girlfriendDevices.map(d => sendPushNotification(d.token, "Nalguitas 💕", "Esta es una notificación de prueba 💗"))
    );
    const successCount = results.filter(r => r.success).length;

    const log: NotificationLog = {
      id: Date.now().toString(),
      message: "Notificación de prueba",
      sentAt: new Date().toISOString(),
      status: successCount > 0 ? `sent (${successCount}/${girlfriendDevices.length})` : `failed: ${results[0]?.error}`,
    };
    notificationHistory.unshift(log);
    saveNotificationHistory(notificationHistory);

    return { success: successCount > 0, status: log.status };
  }),

  history: publicProcedure.query(() => {
    return notificationHistory;
  }),

  getSchedule: publicProcedure.query(() => {
    return scheduleConfig;
  }),

  girlfriendMessage: publicProcedure
    .input(z.object({
      content: z.string().min(1),
    }))
    .mutation(async ({ input }) => {
      const msg: GirlfriendMessage = {
        id: Date.now().toString(),
        content: input.content,
        sentAt: new Date().toISOString(),
        read: false,
      };
      girlfriendMessages.unshift(msg);
      saveGirlfriendMessages(girlfriendMessages);

      if (adminDevices.length > 0) {
        const results = await Promise.all(
          adminDevices.map(d => sendPushNotification(d.token, "Nalguitas 💝", `Tu novia dice: ${input.content}`))
        );
        const successCount = results.filter(r => r.success).length;
        console.log(`[Girlfriend] Push to admin: ${successCount}/${adminDevices.length} sent`);
      }

      return { success: true, message: msg };
    }),

  getGirlfriendMessages: publicProcedure.query(() => {
    return girlfriendMessages;
  }),

  updateSchedule: publicProcedure
    .input(z.object({
      morning: z.string().optional(),
      midday: z.string().optional(),
      afternoon: z.string().optional(),
      night: z.string().optional(),
    }))
    .mutation(({ input }) => {
      if (input.morning) scheduleConfig.morning = input.morning;
      if (input.midday) scheduleConfig.midday = input.midday;
      if (input.afternoon) scheduleConfig.afternoon = input.afternoon;
      if (input.night) scheduleConfig.night = input.night;
      return scheduleConfig;
    }),
});
