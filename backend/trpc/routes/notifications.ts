import * as z from "zod";
import { createTRPCRouter, publicProcedure } from "../create-context";
import { addMessageFromNotification } from "./messages";
import { sendPushNotification } from "../../apns-service";

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

let girlfriendDevices: DeviceInfo[] = [];
let adminDevices: DeviceInfo[] = [];
const MAX_DEVICES = 10;
let notificationHistory: NotificationLog[] = [];
let girlfriendMessages: GirlfriendMessage[] = [];

const scheduleConfig = {
  morning: "08:00",
  midday: "12:30",
  afternoon: "17:00",
  night: "21:30",
};

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
        console.log("Admin device registered:", input.token.substring(0, 20) + "... (total:", adminDevices.length + ")");
      } else {
        girlfriendDevices = girlfriendDevices.filter(d => d.deviceId !== input.deviceId && d.token !== input.token);
        girlfriendDevices.push(device);
        if (girlfriendDevices.length > MAX_DEVICES) girlfriendDevices = girlfriendDevices.slice(-MAX_DEVICES);
        console.log("Girlfriend device registered:", input.token.substring(0, 20) + "... (total:", girlfriendDevices.length + ")");
      }
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
      addMessageFromNotification(input.message);

      let pushStatus = "no_device";

      if (girlfriendDevices.length > 0) {
        const results = await Promise.all(
          girlfriendDevices.map(d => sendPushNotification(d.token, "Nalguitas \u{1F495}", input.message))
        );
        const successCount = results.filter(r => r.success).length;
        pushStatus = successCount > 0 ? `sent (${successCount}/${girlfriendDevices.length})` : `failed: ${results[0]?.error}`;
        console.log("Push to girlfriend devices:", pushStatus);
      } else {
        console.log("No girlfriend devices registered");
      }

      const log: NotificationLog = {
        id: Date.now().toString(),
        message: input.message,
        sentAt: new Date().toISOString(),
        status: pushStatus,
      };
      notificationHistory.unshift(log);

      return {
        success: true,
        message: pushStatus === "sent" ? "Notificación enviada" : "Mensaje guardado (sin push: " + pushStatus + ")",
        log,
      };
    }),

  testNotification: publicProcedure.mutation(async () => {
    if (girlfriendDevices.length === 0) {
      throw new Error("No girlfriend device registered");
    }

    const results = await Promise.all(
      girlfriendDevices.map(d => sendPushNotification(d.token, "Nalguitas \u{1F495}", "Esta es una notificación de prueba \u{1F497}"))
    );
    const successCount = results.filter(r => r.success).length;

    const log: NotificationLog = {
      id: Date.now().toString(),
      message: "Notificación de prueba",
      sentAt: new Date().toISOString(),
      status: successCount > 0 ? `sent (${successCount}/${girlfriendDevices.length})` : `failed: ${results[0]?.error}`,
    };
    notificationHistory.unshift(log);

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

      if (adminDevices.length > 0) {
        const results = await Promise.all(
          adminDevices.map(d => sendPushNotification(d.token, "Nalguitas \u{1F49D}", `Tu novia dice: ${input.content}`))
        );
        const successCount = results.filter(r => r.success).length;
        console.log("Push to admin devices:", `${successCount}/${adminDevices.length} sent`);
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
