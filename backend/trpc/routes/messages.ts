import * as z from "zod";
import { createTRPCRouter, publicProcedure } from "../create-context";
import { loadMessages, saveMessage, deleteMessage } from "../../storage";

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

async function getTodayMessage(): Promise<LoveMessage | null> {
  const messages = await loadMessages();
  if (messages.length === 0) return null;
  return messages[messages.length - 1];
}

export async function addMessageFromNotification(content: string): Promise<LoveMessage> {
  const msg: LoveMessage = {
    id: Date.now().toString(),
    content,
    subtitle: "Para ti",
    tone: "tierno",
    createdAt: new Date().toISOString(),
    isSpecial: false,
    priority: 1,
  };
  await saveMessage(msg);
  return msg;
}

export const messagesRouter = createTRPCRouter({
  list: publicProcedure.query(async () => {
    const messages = await loadMessages();
    const todayMessage = messages.length > 0 ? messages[messages.length - 1] : null;
    return { messages, todayMessage };
  }),

  today: publicProcedure.query(async () => {
    const msg = await getTodayMessage();
    return msg ?? { id: "", content: "", subtitle: "", tone: "", createdAt: "", isSpecial: false, priority: 0 };
  }),

  create: publicProcedure
    .input(z.object({
      content: z.string().min(1),
      subtitle: z.string().default("Para ti"),
      tone: z.string().default("tierno"),
      isSpecial: z.boolean().default(false),
      scheduledDate: z.string().optional(),
      priority: z.number().default(1),
    }))
    .mutation(async ({ input }) => {
      const msg: LoveMessage = {
        id: Date.now().toString(),
        content: input.content,
        subtitle: input.subtitle,
        tone: input.tone,
        createdAt: new Date().toISOString(),
        isSpecial: input.isSpecial,
        scheduledDate: input.scheduledDate,
        priority: input.priority,
      };
      await saveMessage(msg);
      const messages = await loadMessages();
      console.log(`[Messages] Created message: "${msg.content.substring(0, 40)}..." (total: ${messages.length})`);
      return msg;
    }),

  update: publicProcedure
    .input(z.object({
      id: z.string(),
      content: z.string().min(1).optional(),
      subtitle: z.string().optional(),
      tone: z.string().optional(),
      isSpecial: z.boolean().optional(),
      scheduledDate: z.string().optional(),
      priority: z.number().optional(),
    }))
    .mutation(async ({ input }) => {
      const messages = await loadMessages();
      const existing = messages.find((m) => m.id === input.id);
      if (!existing) throw new Error("Message not found");
      const updated = { ...existing, ...input };
      await saveMessage(updated);
      return updated;
    }),

  delete: publicProcedure
    .input(z.object({ id: z.string() }))
    .mutation(async ({ input }) => {
      await deleteMessage(input.id);
      const messages = await loadMessages();
      console.log(`[Messages] Deleted message ${input.id} (remaining: ${messages.length})`);
      return { success: true };
    }),
});
