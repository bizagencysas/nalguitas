import * as z from "zod";
import { createTRPCRouter, publicProcedure } from "../create-context";

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

let registeredDevice: DeviceInfo | null = null;
let notificationHistory: NotificationLog[] = [];

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
    }))
    .mutation(({ input }) => {
      registeredDevice = {
        token: input.token,
        deviceId: input.deviceId,
        registeredAt: new Date().toISOString(),
      };
      return { success: true, message: "Device registered" };
    }),

  getDevice: publicProcedure.query(() => {
    return registeredDevice;
  }),

  sendNow: publicProcedure
    .input(z.object({
      message: z.string().min(1),
    }))
    .mutation(({ input }) => {
      if (!registeredDevice) {
        throw new Error("No device registered");
      }

      const log: NotificationLog = {
        id: Date.now().toString(),
        message: input.message,
        sentAt: new Date().toISOString(),
        status: "queued",
      };
      notificationHistory.unshift(log);

      return {
        success: true,
        message: "Notification queued",
        deviceToken: registeredDevice.token,
        log,
      };
    }),

  testNotification: publicProcedure.mutation(() => {
    if (!registeredDevice) {
      throw new Error("No device registered");
    }

    const log: NotificationLog = {
      id: Date.now().toString(),
      message: "Esta es una notificación de prueba",
      sentAt: new Date().toISOString(),
      status: "test",
    };
    notificationHistory.unshift(log);

    return { success: true, deviceToken: registeredDevice.token };
  }),

  history: publicProcedure.query(() => {
    return notificationHistory;
  }),

  getSchedule: publicProcedure.query(() => {
    return scheduleConfig;
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
