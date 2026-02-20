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

let registeredDevice: DeviceInfo | null = null;
let notificationHistory: NotificationLog[] = [];
let girlfriendMessages: GirlfriendMessage[] = [];
let adminDeviceToken: string | null = null;

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
      registeredDevice = {
        token: input.token,
        deviceId: input.deviceId,
        registeredAt: new Date().toISOString(),
      };
      if (input.isAdmin) {
        adminDeviceToken = input.token;
        console.log("Admin device registered:", input.token.substring(0, 20) + "...");
      }
      console.log("Device registered:", input.token.substring(0, 20) + "...");
      return { success: true, message: "Device registered" };
    }),

  getDevice: publicProcedure.query(() => {
    return registeredDevice;
  }),

  sendNow: publicProcedure
    .input(z.object({
      message: z.string().min(1),
    }))
    .mutation(async ({ input }) => {
      addMessageFromNotification(input.message);

      let pushStatus = "no_device";

      if (registeredDevice) {
        const result = await sendPushNotification(
          registeredDevice.token,
          "Nalguitas 💕",
          input.message
        );
        pushStatus = result.success ? "sent" : `failed: ${result.error}`;
        console.log("Push result:", pushStatus);
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
    if (!registeredDevice) {
      throw new Error("No device registered");
    }

    const result = await sendPushNotification(
      registeredDevice.token,
      "Nalguitas 💕",
      "Esta es una notificación de prueba 💗"
    );

    const log: NotificationLog = {
      id: Date.now().toString(),
      message: "Notificación de prueba",
      sentAt: new Date().toISOString(),
      status: result.success ? "sent" : `failed: ${result.error}`,
    };
    notificationHistory.unshift(log);

    return { success: result.success, status: log.status, deviceToken: registeredDevice.token };
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

      if (adminDeviceToken) {
        const result = await sendPushNotification(
          adminDeviceToken,
          "Nalguitas \u{1F49D}",
          `Tu novia dice: ${input.content}`
        );
        console.log("Push to admin:", result.success ? "sent" : result.error);
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
