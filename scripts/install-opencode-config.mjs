#!/usr/bin/env node

// Instala los archivos de configuración gestionados (hoy: OpenCode) que NO
// pueden copiarse con rsync porque requieren merge:
//   - json-merge: fusiona opencode.managed.json sobre el opencode.json existente
//   - markdown-managed-block: inyecta/actualiza un bloque gestionado en AGENTS.md
//
// Reemplaza a la antigua lógica de scripts/lib/link-skills-config.mjs, ahora
// que las skills se instalan por copia (rsync) y el motor de symlinks se retiró.

import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import process from "node:process";
import { fileURLToPath } from "node:url";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const dryRun = process.argv.slice(2).includes("--dry-run");

function expandHome(value) {
  const home = os.homedir();
  return value
    .replace(/^~(?=$|[\\/])/, home)
    .replace(/%USERPROFILE%/gi, home)
    .replace(/\$HOME/g, home);
}

async function pathExists(target) {
  try {
    await fs.lstat(target);
    return true;
  } catch {
    return false;
  }
}

async function ensureDir(target) {
  if (dryRun) return;
  await fs.mkdir(target, { recursive: true });
}

function timestampSuffix() {
  const now = new Date();
  const pad = (v) => String(v).padStart(2, "0");
  return `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}-${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
}

async function backupFile(target) {
  if (!(await pathExists(target))) return null;
  const backupPath = `${target}.bak-${timestampSuffix()}`;
  if (!dryRun) await fs.copyFile(target, backupPath);
  return backupPath;
}

function isPlainObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function deepEqual(a, b) {
  if (a === b) return true;
  if (typeof a !== typeof b) return false;
  if (Array.isArray(a) && Array.isArray(b)) {
    return a.length === b.length && a.every((item, i) => deepEqual(item, b[i]));
  }
  if (isPlainObject(a) && isPlainObject(b)) {
    const keysA = Object.keys(a).sort();
    const keysB = Object.keys(b).sort();
    return keysA.length === keysB.length && keysA.every((k, i) => k === keysB[i]) && keysA.every((k) => deepEqual(a[k], b[k]));
  }
  return false;
}

function mergeValues(existing, incoming) {
  if (Array.isArray(existing) && Array.isArray(incoming)) {
    const result = [...existing];
    for (const item of incoming) {
      if (!result.some((ex) => deepEqual(ex, item))) result.push(item);
    }
    return result;
  }
  if (isPlainObject(existing) && isPlainObject(incoming)) {
    const result = { ...existing };
    for (const [key, value] of Object.entries(incoming)) {
      result[key] = key in result ? mergeValues(result[key], value) : value;
    }
    return result;
  }
  return incoming;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function replaceTokens(content, tokenMap) {
  let result = content;
  for (const [token, value] of Object.entries(tokenMap)) {
    result = result.replace(new RegExp(escapeRegExp(token), "g"), value);
  }
  return result;
}

async function loadConfig(configPath) {
  const parsed = JSON.parse(await fs.readFile(configPath, "utf8"));
  if (!Array.isArray(parsed.apps)) throw new Error("config/apps.json no contiene una lista 'apps'");
  return parsed.apps;
}

function buildTokenMap(apps, platform) {
  const copilot = apps.find((a) => a.id === "copilot");
  const copilotSkillsDir = copilot?.installPath?.[platform]
    ? expandHome(copilot.installPath[platform])
    : expandHome("~/.copilot/skills");
  return { __COPILOT_SKILLS_DIR__: copilotSkillsDir };
}

async function installConfigFiles(app, tokenMap, platform) {
  const actions = [];
  const configFiles = Array.isArray(app.configFiles) ? app.configFiles : [];

  for (const item of configFiles) {
    const sourcePath = path.join(rootDir, item.source);
    const targetPath = expandHome(item.target?.[platform] ?? "");
    if (!targetPath) {
      actions.push(`skip-config ${item.source} (sin target para ${platform})`);
      continue;
    }

    await ensureDir(path.dirname(targetPath));

    if (item.strategy === "json-merge") {
      const managed = JSON.parse(replaceTokens(await fs.readFile(sourcePath, "utf8"), tokenMap));
      let existing = {};
      if (await pathExists(targetPath)) {
        try {
          existing = JSON.parse(await fs.readFile(targetPath, "utf8"));
        } catch {
          throw new Error(`JSON inválido en archivo destino: ${targetPath}`);
        }
      }
      const merged = mergeValues(existing, managed);
      if (JSON.stringify(existing, null, 2) === JSON.stringify(merged, null, 2)) {
        actions.push(`ok-config ${path.basename(targetPath)}`);
        continue;
      }
      const backup = await backupFile(targetPath);
      if (!dryRun) {
        await fs.writeFile(`${targetPath}.tmp`, `${JSON.stringify(merged, null, 2)}\n`, "utf8");
        await fs.rename(`${targetPath}.tmp`, targetPath);
      }
      actions.push(`merge-config ${path.basename(targetPath)}${backup ? ` (backup ${path.basename(backup)})` : ""}`);
      continue;
    }

    if (item.strategy === "markdown-managed-block") {
      const managedContent = replaceTokens(await fs.readFile(sourcePath, "utf8"), tokenMap).trimEnd();
      const blockId = item.blockId ?? "skills-hub";
      const startMarker = `<!-- skills-hub:managed ${blockId} start -->`;
      const endMarker = `<!-- skills-hub:managed ${blockId} end -->`;
      const block = `${startMarker}\n${managedContent}\n${endMarker}\n`;

      let existing = "";
      if (await pathExists(targetPath)) existing = await fs.readFile(targetPath, "utf8");

      let next = "";
      if (existing.includes(startMarker) && existing.includes(endMarker)) {
        const pattern = new RegExp(`${escapeRegExp(startMarker)}[\\s\\S]*?${escapeRegExp(endMarker)}\\n?`, "m");
        next = existing.replace(pattern, block);
      } else if (existing.trim().length === 0) {
        next = block;
      } else {
        next = `${existing.trimEnd()}\n\n${block}`;
      }

      if (existing === next) {
        actions.push(`ok-config ${path.basename(targetPath)}`);
        continue;
      }
      const backup = await backupFile(targetPath);
      if (!dryRun) await fs.writeFile(targetPath, next, "utf8");
      actions.push(`merge-config ${path.basename(targetPath)}${backup ? ` (backup ${path.basename(backup)})` : ""}`);
      continue;
    }

    actions.push(`skip-config ${item.source} (strategy desconocida)`);
  }

  return actions;
}

async function main() {
  const platform = process.platform === "win32" ? "windows" : "linux";
  const apps = await loadConfig(path.join(rootDir, "config", "apps.json"));
  const tokenMap = buildTokenMap(apps, platform);

  console.log(`[skills-hub] Config gestionada (${platform})${dryRun ? " [dry-run]" : ""}`);
  for (const app of apps) {
    if (!Array.isArray(app.configFiles) || app.configFiles.length === 0) continue;
    const actions = await installConfigFiles(app, tokenMap, platform);
    console.log(`- ${app.id}:`);
    for (const action of actions) console.log(`    - ${action}`);
  }
}

main().catch((error) => {
  console.error(`[skills-hub] ERROR: ${error.message}`);
  process.exit(1);
});
