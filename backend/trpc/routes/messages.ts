import * as z from "zod";
import { createTRPCRouter, publicProcedure } from "../create-context";

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

let messages: LoveMessage[] = [];

function getTodayMessage(): LoveMessage | null {
  if (messages.length === 0) return null;
  const lastMessage = messages[messages.length - 1];
  return lastMessage;
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
      return messages[index];
    }),

  delete: publicProcedure
    .input(z.object({ id: z.string() }))
    .mutation(({ input }) => {
      messages = messages.filter((m) => m.id !== input.id);
      return { success: true };
    }),
});
