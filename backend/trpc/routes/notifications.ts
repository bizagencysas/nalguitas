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

let girlfriendDevice: DeviceInfo | null = null;
let adminDevice: DeviceInfo | null = null;
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
        adminDevice = device;
        console.log("Admin device registered:", input.token.substring(0, 20) + "...");
      } else {
        girlfriendDevice = device;
        console.log("Girlfriend device registered:", input.token.substring(0, 20) + "...");
      }
      return { success: true, message: "Device registered" };
    }),

  getDevice: publicProcedure.query(() => {
    return {
      girlfriend: girlfriendDevice,
      admin: adminDevice,
    };
  }),

  sendNow: publicProcedure
    .input(z.object({
      message: z.string().min(1),
    }))
    .mutation(async ({ input }) => {
      addMessageFromNotification(input.message);

      let pushStatus = "no_device";

      if (girlfriendDevice) {
        const result = await sendPushNotification(
          girlfriendDevice.token,
          "Nalguitas \u{1F495}",
          input.message
        );
        pushStatus = result.success ? "sent" : `failed: ${result.error}`;
        console.log("Push to girlfriend:", pushStatus);
      } else {
        console.log("No girlfriend device registered");
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
    if (!girlfriendDevice) {
      throw new Error("No girlfriend device registered");
    }

    const result = await sendPushNotification(
      girlfriendDevice.token,
      "Nalguitas \u{1F495}",
      "Esta es una notificación de prueba \u{1F497}"
    );

    const log: NotificationLog = {
      id: Date.now().toString(),
      message: "Notificación de prueba",
      sentAt: new Date().toISOString(),
      status: result.success ? "sent" : `failed: ${result.error}`,
    };
    notificationHistory.unshift(log);

    return { success: result.success, status: log.status, deviceToken: girlfriendDevice.token };
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

      if (adminDevice) {
        const result = await sendPushNotification(
          adminDevice.token,
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
