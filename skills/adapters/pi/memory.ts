/**
 * Pi Extension: Memory Harness
 *
 * Wires the harness-agnostic Memory skill (#10) into Pi's event system.
 * Injects Engram context at session start and saves session summaries on close.
 *
 * Requires: Engram CLI (`engram`) or Engram MCP server accessible via bash.
 * Install: copy to ~/.pi/agent/extensions/ or .pi/extensions/
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const ENGRAM_CLI = "engram"; // override with ENGRAM_CLI env var if needed
const MEMORY_FILE = path.join(os.homedir(), ".memory", "MEMORY.md");

// ─── Helpers ────────────────────────────────────────────────────────────────

async function runEngram(
  pi: ExtensionAPI,
  args: string[]
): Promise<string | null> {
  try {
    const result = await pi.exec(ENGRAM_CLI, args, { timeout: 5000 });
    return result.stdout?.trim() ?? null;
  } catch {
    return null;
  }
}

function readFilesystemMemory(): string | null {
  try {
    if (!fs.existsSync(MEMORY_FILE)) return null;
    return fs.readFileSync(MEMORY_FILE, "utf-8");
  } catch {
    return null;
  }
}

async function getMemoryContext(
  pi: ExtensionAPI,
  projectName: string
): Promise<string | null> {
  // 1. Try Engram CLI
  const engramContext = await runEngram(pi, [
    "mem-context",
    "--project",
    projectName,
    "--format",
    "markdown",
  ]);
  if (engramContext) return engramContext;

  // 2. Try filesystem fallback
  const fsMemory = readFilesystemMemory();
  if (fsMemory) {
    // Extract the most recent entry from MEMORY.md index
    const lines = fsMemory.split("\n").filter((l) => l.startsWith("-"));
    return lines.length > 0
      ? `## Memory Index (filesystem)\n${lines.slice(0, 10).join("\n")}`
      : null;
  }

  return null;
}

async function saveSessionSummary(
  pi: ExtensionAPI,
  projectName: string,
  sessionName: string | undefined
): Promise<void> {
  // Ask the LLM to generate a session summary via sendUserMessage
  // In practice, this triggers the agent to produce and save the summary
  pi.sendMessage({
    role: "user",
    content: `[AUTO] Session ending. Save a session summary to the memory backend now.
Project: ${projectName}
Session: ${sessionName ?? "unnamed"}

Follow the Session Close Protocol from the memory skill:
- Goal: what we worked on
- Discoveries: non-obvious learnings
- Accomplished: completed items
- Next Steps: what remains
- Relevant Files: changed paths`,
  });
}

function detectProjectName(cwd: string): string {
  try {
    const pkgPath = path.join(cwd, "package.json");
    if (fs.existsSync(pkgPath)) {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf-8"));
      if (pkg.name) return pkg.name;
    }
  } catch {}
  return path.basename(cwd);
}

// ─── Extension Entry Point ──────────────────────────────────────────────────

export default async function memoryExtension(pi: ExtensionAPI): Promise<void> {
  let projectName = "";
  let contextInjected = false;

  // ── Hook: session start ──────────────────────────────────────────────────
  pi.on("before_agent_start", async (ctx) => {
    if (contextInjected) return {};
    contextInjected = true;

    projectName = detectProjectName(ctx?.cwd ?? process.cwd());

    const context = await getMemoryContext(pi, projectName);
    if (!context) return {};

    return {
      systemPromptAdditions: `\n\n## Memory Context (from previous sessions)\n\n${context}\n\nUse this context to continue where the last session left off. Do NOT re-read files or re-discover decisions that are already captured above.`,
    };
  });

  // ── Hook: session end (settled = no more tool calls pending) ─────────────
  pi.on("settled", async () => {
    if (!projectName) return;
    const sessionName = pi.getSessionName?.();
    await saveSessionSummary(pi, projectName, sessionName);
  });

  // ── Command: manual memory context ──────────────────────────────────────
  pi.registerCommand("memory-context", {
    description: "Show current memory context from Engram",
    handler: async (ctx) => {
      const proj = detectProjectName(ctx.cwd ?? process.cwd());
      const context = await getMemoryContext(pi, proj);
      if (context) {
        pi.sendMessage({ role: "assistant", content: context });
      } else {
        pi.sendMessage({
          role: "assistant",
          content:
            "No memory context found. Engram CLI not available and no filesystem memory at ~/.memory/MEMORY.md",
        });
      }
    },
  });

  // ── Command: manual session summary ─────────────────────────────────────
  pi.registerCommand("memory-save", {
    description: "Save a session summary to the memory backend",
    handler: async (ctx) => {
      const proj = detectProjectName(ctx.cwd ?? process.cwd());
      await saveSessionSummary(pi, proj, pi.getSessionName?.());
    },
  });
}
