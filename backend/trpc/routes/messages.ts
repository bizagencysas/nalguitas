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

const defaultMessages: LoveMessage[] = [
  { id: "1", content: "Te quería decir algo: hoy te ves preciosa.", subtitle: "Para ti", tone: "tierno", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "2", content: "Paso por aquí solo para recordarte que te quiero.", subtitle: "Un susurro", tone: "romántico", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "3", content: "Ojalá estés sonriendo ahora mismo.", subtitle: "Pensando en ti", tone: "tierno", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "4", content: "Eres mi lugar tranquilo.", subtitle: "Siempre", tone: "profundo", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "5", content: "Si pudiera elegir a alguien otra vez, te elegiría a ti.", subtitle: "Con todo", tone: "romántico", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "6", content: "No necesito un motivo para pensarte. Lo hago todo el tiempo.", subtitle: "De corazón", tone: "tierno", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "7", content: "Eres lo más bonito que me ha pasado.", subtitle: "Solo para ti", tone: "profundo", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "8", content: "Hoy no pude evitar sonreír pensando en ti.", subtitle: "Así de simple", tone: "divertido", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "9", content: "Cada día contigo es mejor que el anterior.", subtitle: "Siempre", tone: "romántico", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "10", content: "Me encanta cómo me haces sentir cuando estoy contigo.", subtitle: "Para ti", tone: "tierno", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "11", content: "Eres la razón por la que sonrío sin razón.", subtitle: "De corazón", tone: "divertido", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
  { id: "12", content: "Contigo todo es más bonito.", subtitle: "Siempre", tone: "profundo", createdAt: new Date().toISOString(), isSpecial: false, priority: 1 },
];

let messages: LoveMessage[] = [...defaultMessages];

function getTodayMessage(): LoveMessage {
  const today = new Date();
  const dayOfYear = Math.floor((today.getTime() - new Date(today.getFullYear(), 0, 0).getTime()) / 86400000);
  const index = dayOfYear % messages.length;
  return messages[index];
}

export const messagesRouter = createTRPCRouter({
  list: publicProcedure.query(() => {
    return { messages, todayMessage: getTodayMessage() };
  }),

  today: publicProcedure.query(() => {
    return getTodayMessage();
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
