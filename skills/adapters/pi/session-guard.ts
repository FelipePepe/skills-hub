/**
 * Pi Extension: Session Guard
 *
 * Harness #2 (Delegation Decision) enforcement for Pi.
 * Intercepts destructive shell commands before execution and asks the user
 * for explicit confirmation. Covers: rm -rf, git reset --hard, force push,
 * DROP TABLE, truncate, and other irreversible operations.
 *
 * Install: copy to ~/.pi/agent/extensions/ or .pi/extensions/
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// ─── Destructive command patterns ───────────────────────────────────────────

interface GuardRule {
  pattern: RegExp;
  label: string;
  severity: "critical" | "warning";
}

const GUARD_RULES: GuardRule[] = [
  // Filesystem
  { pattern: /rm\s+(-[a-z]*r[a-z]*f|--recursive.*--force|-f.*-r)/i, label: "rm -rf (recursive force delete)", severity: "critical" },
  { pattern: /rm\s+-[a-z]*f[a-z]*\s+/i, label: "rm -f (force delete)", severity: "warning" },
  { pattern: /rmdir\s+--ignore-fail/i, label: "rmdir force", severity: "warning" },
  { pattern: /find\s+.*-delete/i, label: "find -delete", severity: "warning" },
  { pattern: /truncate\s+-s\s+0/i, label: "truncate file to zero", severity: "warning" },

  // Git
  { pattern: /git\s+reset\s+--hard/i, label: "git reset --hard", severity: "critical" },
  { pattern: /git\s+push\s+.*--force(?!-with-lease)/i, label: "git push --force (no lease)", severity: "critical" },
  { pattern: /git\s+push\s+.*-f\b/i, label: "git push -f", severity: "critical" },
  { pattern: /git\s+checkout\s+\./i, label: "git checkout . (discard all changes)", severity: "critical" },
  { pattern: /git\s+restore\s+\./i, label: "git restore . (discard all changes)", severity: "critical" },
  { pattern: /git\s+clean\s+-[a-z]*f/i, label: "git clean -f (delete untracked)", severity: "critical" },
  { pattern: /git\s+branch\s+-D\s+/i, label: "git branch -D (force delete branch)", severity: "warning" },
  { pattern: /git\s+rebase\s+.*--abort/i, label: "git rebase --abort", severity: "warning" },
  { pattern: /git\s+commit\s+.*--amend/i, label: "git commit --amend (rewrite history)", severity: "warning" },
  { pattern: /git\s+push\s+.*main|git\s+push\s+.*master/i, label: "push to protected branch (main/master)", severity: "warning" },

  // SQL
  { pattern: /DROP\s+TABLE/i, label: "DROP TABLE", severity: "critical" },
  { pattern: /DROP\s+DATABASE/i, label: "DROP DATABASE", severity: "critical" },
  { pattern: /DROP\s+SCHEMA/i, label: "DROP SCHEMA", severity: "critical" },
  { pattern: /TRUNCATE\s+TABLE/i, label: "TRUNCATE TABLE", severity: "critical" },
  { pattern: /DELETE\s+FROM\s+\w+\s*;/i, label: "DELETE FROM without WHERE clause", severity: "critical" },

  // System
  { pattern: /systemctl\s+(stop|disable|mask)\s+/i, label: "systemctl stop/disable service", severity: "warning" },
  { pattern: /pkill\s+(-9|-KILL)/i, label: "pkill -9 (force kill)", severity: "warning" },
  { pattern: /kill\s+-9/i, label: "kill -9 (force kill)", severity: "warning" },
  { pattern: /chmod\s+777/i, label: "chmod 777 (world-writable)", severity: "warning" },
  { pattern: /chown\s+.*-R.*root/i, label: "chown -R root (recursive ownership change)", severity: "warning" },
  { pattern: /dd\s+if=.*of=/i, label: "dd (disk write)", severity: "critical" },
  { pattern: /mkfs\./i, label: "mkfs (format filesystem)", severity: "critical" },
];

// ─── Helpers ────────────────────────────────────────────────────────────────

interface MatchResult {
  rule: GuardRule;
  matched: string;
}

function detectDestructive(command: string): MatchResult | null {
  for (const rule of GUARD_RULES) {
    const match = rule.pattern.exec(command);
    if (match) {
      return { rule, matched: match[0] };
    }
  }
  return null;
}

function buildWarningMessage(
  command: string,
  detection: MatchResult
): string {
  const icon = detection.rule.severity === "critical" ? "🚨" : "⚠️";
  const severityLabel =
    detection.rule.severity === "critical" ? "CRITICAL" : "WARNING";

  return `${icon} **[Session Guard — ${severityLabel}]**

The agent wants to run a potentially destructive command:

\`\`\`
${command.trim()}
\`\`\`

**Detected**: \`${detection.rule.label}\`
**Match**: \`${detection.matched}\`

**Reply to proceed:**
- \`yes\` / \`si\` → allow this command
- \`no\` / \`cancel\` → block it and ask the agent to take a different approach
- \`skip\` → allow this one time and disable guard for this session`;
}

// ─── Extension Entry Point ──────────────────────────────────────────────────

export default async function sessionGuardExtension(
  pi: ExtensionAPI
): Promise<void> {
  let guardDisabled = false;
  let pendingCommand: string | null = null;
  let pendingResolve: ((allow: boolean) => void) | null = null;

  // ── Hook: intercept tool calls before execution ───────────────────────────
  pi.on("before_tool_call", async (toolCall) => {
    if (guardDisabled) return {};

    const toolName: string = toolCall?.name ?? "";
    const args: Record<string, unknown> = toolCall?.input ?? {};

    // Only guard bash/shell execution tools
    const isShellTool = ["bash", "shell", "exec", "run_command"].includes(
      toolName.toLowerCase()
    );
    if (!isShellTool) return {};

    const command: string =
      typeof args.command === "string"
        ? args.command
        : typeof args.cmd === "string"
        ? args.cmd
        : "";

    if (!command) return {};

    const detection = detectDestructive(command);
    if (!detection) return {};

    // Send warning to user and wait for confirmation
    pi.sendMessage({
      role: "assistant",
      content: buildWarningMessage(command, detection),
    });

    pendingCommand = command;

    // Return a block signal — Pi should pause and wait for user reply
    // The actual resolution happens in the user_message hook below
    return {
      block: true,
      reason: `Session Guard: destructive command detected (${detection.rule.label}). Waiting for user confirmation.`,
    };
  });

  // ── Hook: handle user response to guard prompt ────────────────────────────
  pi.on("before_user_message", async (msg) => {
    if (!pendingCommand) return {};

    const text =
      typeof msg?.content === "string" ? msg.content.trim().toLowerCase() : "";

    if (["yes", "si", "sí", "y", "allow", "proceed"].includes(text)) {
      const cmd = pendingCommand;
      pendingCommand = null;
      return { unblock: true, resumeWith: cmd };
    }

    if (text === "skip") {
      guardDisabled = true;
      pendingCommand = null;
      pi.sendMessage({
        role: "assistant",
        content: "Session Guard disabled for this session. Proceeding.",
      });
      return { unblock: true };
    }

    // Default: block and ask agent to change approach
    pendingCommand = null;
    return {
      unblock: false,
      injectMessage: {
        role: "user",
        content:
          "The user blocked that command. Do NOT retry it. Find an alternative approach that does not use destructive operations.",
      },
    };
  });

  // ── Command: toggle guard ────────────────────────────────────────────────
  pi.registerCommand("guard-off", {
    description: "Disable session guard for this session (allow destructive commands)",
    handler: async () => {
      guardDisabled = true;
      pi.sendMessage({
        role: "assistant",
        content: "⚠️ Session Guard disabled. Destructive commands will NOT be intercepted for the rest of this session.",
      });
    },
  });

  pi.registerCommand("guard-on", {
    description: "Re-enable session guard for this session",
    handler: async () => {
      guardDisabled = false;
      pi.sendMessage({
        role: "assistant",
        content: "✅ Session Guard re-enabled. Destructive commands will be intercepted again.",
      });
    },
  });

  pi.registerCommand("guard-status", {
    description: "Show session guard status",
    handler: async () => {
      pi.sendMessage({
        role: "assistant",
        content: guardDisabled
          ? "Session Guard: DISABLED"
          : `Session Guard: ACTIVE (${GUARD_RULES.length} rules loaded)`,
      });
    },
  });
}
