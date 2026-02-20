import { serve } from "@hono/node-server";
import { Hono } from "hono";
import app from "./hono";

const server = new Hono();
server.route("/api", app);

server.get("/", (c) => {
  return c.json({ status: "ok", message: "Amor Rosa API running" });
});

const port = parseInt(process.env.PORT || "3000");

console.log(`Amor Rosa API starting on port ${port}...`);

serve({
  fetch: server.fetch,
  port,
});

console.log(`Server running at http://0.0.0.0:${port}`);
