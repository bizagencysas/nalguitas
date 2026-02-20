import { createTRPCRouter } from "./create-context";
import { messagesRouter } from "./routes/messages";
import { notificationsRouter } from "./routes/notifications";

export const appRouter = createTRPCRouter({
  messages: messagesRouter,
  notifications: notificationsRouter,
});

export type AppRouter = typeof appRouter;
