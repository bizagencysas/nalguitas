import * as z from "zod";
import { createTRPCRouter, publicProcedure } from "../create-context";
import { loadMessages, saveMessages } from "../../storage";

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

let messages: LoveMessage[] = loadMessages();

function persist() {
  saveMessages(messages);
}

function getTodayMessage(): LoveMessage | null {
  if (messages.length === 0) return null;
  return messages[messages.length - 1];
}

export function addMessageFromNotification(content: string): LoveMessage {
  const msg: LoveMessage = {
    id: Date.now().toString(),
    content,
    subtitle: "Para ti",
    tone: "tierno",
    createdAt: new Date().toISOString(),
    isSpecial: false,
    priority: 1,
  };
  messages.push(msg);
  persist();
  return msg;
}

export const messagesRouter = createTRPCRouter({
  list: publicProcedure.query(() => {
    return { messages, todayMessage: getTodayMessage() };
  }),

  today: publicProcedure.query(() => {
    return getTodayMessage() ?? { id: "", content: "", subtitle: "", tone: "", createdAt: "", isSpecial: false, priority: 0 };
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
    .mutation(({ input }) => {
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
      messages.push(msg);
      persist();
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
    .mutation(({ input }) => {
      const index = messages.findIndex((m) => m.id === input.id);
      if (index === -1) throw new Error("Message not found");
      messages[index] = { ...messages[index], ...input };
      persist();
      return messages[index];
    }),

  delete: publicProcedure
    .input(z.object({ id: z.string() }))
    .mutation(({ input }) => {
      messages = messages.filter((m) => m.id !== input.id);
      persist();
      console.log(`[Messages] Deleted message ${input.id} (remaining: ${messages.length})`);
      return { success: true };
    }),
});
