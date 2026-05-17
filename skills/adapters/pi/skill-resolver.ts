/**
 * Pi Extension: Skill Resolver
 *
 * Wires Harness #14/#15/#16 (Skill Registry, Digestion, Feedback) into Pi.
 * Reads the project skill registry from Engram or filesystem, resolves compact
 * rules matching the current working directory, and injects them into the
 * system prompt so Pi sub-agents receive pre-digested standards.
 *
 * Requires: Engram CLI (`engram`) accessible via bash, OR `.atl/skill-registry.md`
 * Install: copy to ~/.pi/agent/extensions/ or .pi/extensions/
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";

const ENGRAM_CLI = process.env.ENGRAM_CLI ?? "engram";
const REGISTRY_PATH = ".atl/skill-registry.md";
const REGISTRY_TOPIC_KEY = "skill-registry";

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

async function loadRegistry(
  pi: ExtensionAPI,
  projectName: string
): Promise<string | null> {
  // 1. Try Engram
  const searchResult = await runEngram(pi, [
    "mem-search",
    "--query",
    REGISTRY_TOPIC_KEY,
    "--project",
    projectName,
    "--format",
    "json",
    "--limit",
    "1",
  ]);

  if (searchResult) {
    try {
      const parsed = JSON.parse(searchResult);
      const id = parsed?.[0]?.id;
      if (id) {
        const obs = await runEngram(pi, ["mem-get-observation", "--id", id]);
        if (obs) return obs;
      }
    } catch {}
  }

  // 2. Filesystem fallback: .atl/skill-registry.md relative to cwd
  try {
    const registryPath = path.resolve(REGISTRY_PATH);
    if (fs.existsSync(registryPath)) {
      return fs.readFileSync(registryPath, "utf-8");
    }
  } catch {}

  return null;
}

/**
 * Extract the "Compact Rules" section from a skill registry markdown file.
 * Returns only the text under the first `## Compact Rules` heading.
 */
function extractCompactRules(registry: string): string | null {
  const idx = registry.search(/^## Compact Rules/im);
  if (idx === -1) return null;
  const after = registry.slice(idx);
  // Stop at the next top-level heading (##) if any
  const nextHeading = after.slice(1).search(/^## /im);
  const section = nextHeading !== -1 ? after.slice(0, nextHeading + 1) : after;
  return section.trim() || null;
}

/**
 * Check the returned envelope from a delegation for `skill_resolution` field.
 * If it's a fallback signal, return true so the caller can re-read the registry.
 */
function isSkillResolutionFallback(message: string): boolean {
  const FALLBACK_SIGNALS = [
    '"skill_resolution":"fallback-registry"',
    '"skill_resolution":"fallback-path"',
    '"skill_resolution":"none"',
    "skill_resolution: fallback",
  ];
  return FALLBACK_SIGNALS.some((sig) => message.includes(sig));
}

// ─── Extension Entry Point ──────────────────────────────────────────────────

export default async function skillResolverExtension(
  pi: ExtensionAPI
): Promise<void> {
  let compactRulesCache: string | null = null;
  let projectName = "";
  let injected = false;

  // ── Hook: session start — load registry and inject compact rules ──────────
  pi.on("before_agent_start", async (ctx) => {
    if (injected) return {};
    injected = true;

    const cwd = ctx?.cwd ?? process.cwd();
    projectName =
      (() => {
        try {
          const pkgPath = path.join(cwd, "package.json");
          if (fs.existsSync(pkgPath)) {
            const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf-8"));
            if (pkg.name) return pkg.name as string;
          }
        } catch {}
        return path.basename(cwd);
      })() ?? path.basename(cwd);

    const registry = await loadRegistry(pi, projectName);
    if (!registry) return {};

    const compactRules = extractCompactRules(registry);
    if (!compactRules) return {};

    compactRulesCache = compactRules;

    return {
      systemPromptAdditions: `\n\n## Project Standards (auto-resolved)\n\n${compactRules}\n\nApply these standards to ALL code you write in this session. Do NOT re-read SKILL.md files — rules are pre-digested above.`,
    };
  });

  // ── Hook: watch delegation results for skill_resolution fallback ──────────
  pi.on("message", async (msg) => {
    if (msg?.role !== "tool" && msg?.role !== "assistant") return;
    const content =
      typeof msg?.content === "string" ? msg.content : JSON.stringify(msg?.content ?? "");

    if (isSkillResolutionFallback(content)) {
      // Cache was lost — reload registry so next delegation gets fresh rules
      const registry = await loadRegistry(pi, projectName);
      if (registry) {
        const freshRules = extractCompactRules(registry);
        if (freshRules) compactRulesCache = freshRules;
      }
    }
  });

  // ── Command: show current compact rules ──────────────────────────────────
  pi.registerCommand("skill-rules", {
    description: "Show the current project compact rules from the skill registry",
    handler: async (ctx) => {
      if (compactRulesCache) {
        pi.sendMessage({ role: "assistant", content: compactRulesCache });
      } else {
        const cwd = ctx.cwd ?? process.cwd();
        const proj = path.basename(cwd);
        const registry = await loadRegistry(pi, proj);
        const rules = registry ? extractCompactRules(registry) : null;
        pi.sendMessage({
          role: "assistant",
          content: rules
            ? rules
            : "No skill registry found. Create `.atl/skill-registry.md` or add it to Engram via `mem_save`.",
        });
      }
    },
  });

  // ── Command: reload registry ──────────────────────────────────────────────
  pi.registerCommand("skill-reload", {
    description: "Force-reload the skill registry from Engram or filesystem",
    handler: async (ctx) => {
      const cwd = ctx.cwd ?? process.cwd();
      const proj = path.basename(cwd);
      const registry = await loadRegistry(pi, proj);
      if (registry) {
        const rules = extractCompactRules(registry);
        compactRulesCache = rules;
        pi.sendMessage({
          role: "assistant",
          content: rules
            ? `Registry reloaded. Compact rules updated (${rules.length} chars).`
            : "Registry found but no Compact Rules section detected.",
        });
      } else {
        pi.sendMessage({
          role: "assistant",
          content: "No registry found. Checked Engram and `.atl/skill-registry.md`.",
        });
      }
    },
  });
}
