#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CONFIG } from "./config.js";
import { registerTools } from "./tools/registry.js";
import { registerResources } from "./resources/registry.js";
import { registerPrompts } from "./prompts/registry.js";

async function main(): Promise<void> {
  // Log startup diagnostics strictly to stderr to prevent stdio stream corruption
  console.error(`[LOCA MCP] Initializing server v${CONFIG.version}...`);
  console.error(`[LOCA MCP] Database: ${CONFIG.dbPath} ${CONFIG.isFallback ? "(Development Store)" : "(Production Store)"}`);

  const server = new McpServer(
    {
      name: CONFIG.serverName,
      version: CONFIG.version,
    },
    {
      capabilities: {
        tools: {
          listChanged: true,
        },
        resources: {
          subscribe: false,
          listChanged: true,
        },
        prompts: {
          listChanged: true,
        },
      },
    }
  );

  // Register all primitives
  registerTools(server);
  registerResources(server);
  registerPrompts(server);

  // Connect via standard Stdio transport
  const transport = new StdioServerTransport();
  await server.connect(transport);

  console.error("[LOCA MCP] Server connected via Stdio JSON-RPC. Ready for AI client interactions.");

  // Handle graceful termination
  process.on("SIGINT", async () => {
    console.error("[LOCA MCP] Shutting down...");
    await server.close();
    process.exit(0);
  });

  process.on("SIGTERM", async () => {
    console.error("[LOCA MCP] Terminating...");
    await server.close();
    process.exit(0);
  });
}

main().catch((err) => {
  console.error("[LOCA MCP] Fatal error starting server:", err);
  process.exit(1);
});
