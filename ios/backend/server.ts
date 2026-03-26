import { serve } from "@hono/node-server";
import { Hono } from "hono";
import app from "./hono";
import { migrate } from "./db";

const server = new Hono();
server.route("/api", app);

server.get("/", (c) => {
  return c.json({ status: "ok", message: "Nalguitas API running (PostgreSQL)" });
});

const port = parseInt(process.env.PORT || "3000");

async function start() {
  try {
    await migrate();
    console.log("[DB] Migration successful");
  } catch (e: any) {
    console.error("[DB] Migration failed:", e.message);
  }

  serve({
    fetch: server.fetch,
    port,
  });

  console.log(`Nalguitas API running at http://0.0.0.0:${port}`);
}

start();
