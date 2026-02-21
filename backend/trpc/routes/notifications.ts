import * as z from "zod";
import { createTRPCRouter, publicProcedure } from "../create-context";
import { sendPushNotification } from "../../apns-service";
import { loadDevices, saveDevice, loadNotificationHistory, saveNotificationLog, loadGirlfriendMessages, saveGirlfriendMessage, loadSchedule, saveSchedule } from "../../storage";

const MAX_DEVICES = 10;

export const notificationsRouter = createTRPCRouter({
  registerDevice: publicProcedure
    .input(z.object({
      token: z.string(),
      deviceId: z.string(),
      isAdmin: z.boolean().optional(),
    }))
    .mutation(async ({ input }) => {
      const role = input.isAdmin ? "admin" : "girlfriend";
      await saveDevice(input.token, input.deviceId, role);
      console.log(`[Register] ${role} device: ${input.token.substring(0, 20)}...`);
      return { success: true, message: "Device registered" };
    }),

  getDevice: publicProcedure.query(async () => {
    const { girlfriendDevices, adminDevices } = await loadDevices();
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
      const { girlfriendDevices, adminDevices } = await loadDevices();
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

      const log = {
        id: Date.now().toString(),
        message: input.message,
        sentAt: new Date().toISOString(),
        status: pushStatus,
      };
      await saveNotificationLog(log);

      return {
        success: true,
        message: pushStatus.startsWith("sent") ? "Notificación enviada" : "Mensaje guardado (sin push: " + pushStatus + ")",
        log,
      };
    }),

  testNotification: publicProcedure.mutation(async () => {
    const { girlfriendDevices, adminDevices } = await loadDevices();
    console.log(`[Test] Girlfriend devices: ${girlfriendDevices.length}, Admin devices: ${adminDevices.length}`);

    if (girlfriendDevices.length === 0) {
      throw new Error("No girlfriend device registered. La novia debe abrir la app primero para registrar su dispositivo.");
    }

    const results = await Promise.all(
      girlfriendDevices.map(d => sendPushNotification(d.token, "Nalguitas 💕", "Esta es una notificación de prueba 💗"))
    );
    const successCount = results.filter(r => r.success).length;

    const log = {
      id: Date.now().toString(),
      message: "Notificación de prueba",
      sentAt: new Date().toISOString(),
      status: successCount > 0 ? `sent (${successCount}/${girlfriendDevices.length})` : `failed: ${results[0]?.error}`,
    };
    await saveNotificationLog(log);

    return { success: successCount > 0, status: log.status };
  }),

  history: publicProcedure.query(async () => {
    return await loadNotificationHistory();
  }),

  getSchedule: publicProcedure.query(async () => {
    return await loadSchedule();
  }),

  girlfriendMessage: publicProcedure
    .input(z.object({
      content: z.string().min(1),
    }))
    .mutation(async ({ input }) => {
      const msg = {
        id: Date.now().toString(),
        content: input.content,
        sentAt: new Date().toISOString(),
        read: false,
      };
      await saveGirlfriendMessage(msg);

      const { adminDevices } = await loadDevices();
      if (adminDevices.length > 0) {
        const results = await Promise.all(
          adminDevices.map(d => sendPushNotification(d.token, "Nalguitas 💝", `Tu novia dice: ${input.content}`))
        );
        const successCount = results.filter(r => r.success).length;
        console.log(`[Girlfriend] Push to admin: ${successCount}/${adminDevices.length} sent`);
      }

      return { success: true, message: msg };
    }),

  getGirlfriendMessages: publicProcedure.query(async () => {
    return await loadGirlfriendMessages();
  }),

  updateSchedule: publicProcedure
    .input(z.object({
      morning: z.string().optional(),
      midday: z.string().optional(),
      afternoon: z.string().optional(),
      night: z.string().optional(),
    }))
    .mutation(async ({ input }) => {
      return await saveSchedule(input);
    }),
});
