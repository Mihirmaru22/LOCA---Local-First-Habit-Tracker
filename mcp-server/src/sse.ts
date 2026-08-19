#!/usr/bin/env node
import http from "node:http";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import { CONFIG } from "./config.js";
import { registerTools } from "./tools/registry.js";
import { registerResources } from "./resources/registry.js";
import { registerPrompts } from "./prompts/registry.js";

const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 3333;

function createServer(): McpServer {
  const server = new McpServer({
    name: "loca-mcp-server",
    version: CONFIG.version,
  });

  registerTools(server);
  registerResources(server);
  registerPrompts(server);

  return server;
}

const transports: { [sessionId: string]: SSEServerTransport } = {};

const httpServer = http.createServer(async (req, res) => {
  // CORS Headers
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.writeHead(200);
    res.end();
    return;
  }

  const url = new URL(req.url || "/", `http://${req.headers.host}`);

  if (url.pathname === "/sse" && req.method === "GET") {
    const server = createServer();
    const transport = new SSEServerTransport("/messages", res);
    transports[transport.sessionId] = transport;

    transport.onclose = () => {
      delete transports[transport.sessionId];
      console.error(`[LOCA SSE] Session ${transport.sessionId} closed.`);
    };

    await server.connect(transport);
    console.error(`[LOCA SSE] New client connected. Session ID: ${transport.sessionId}`);
    return;
  }

  if (url.pathname === "/messages" && req.method === "POST") {
    const sessionId = url.searchParams.get("sessionId");
    if (!sessionId || !transports[sessionId]) {
      res.writeHead(400, { "Content-Type": "text/plain" });
      res.end("Missing or invalid sessionId");
      return;
    }

    const transport = transports[sessionId];
    await transport.handlePostMessage(req, res);
    return;
  }

  if (url.pathname === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "healthy", version: CONFIG.version, db: CONFIG.dbPath }));
    return;
  }

  res.writeHead(404, { "Content-Type": "text/plain" });
  res.end("Not Found");
});

httpServer.listen(PORT, () => {
  console.error(`=========================================`);
  console.error(`⚡️ LOCA MCP SSE Server listening on http://localhost:${PORT}/sse`);
  console.error(`💾 Active Database: ${CONFIG.dbPath}`);
  console.error(`=========================================`);
});
