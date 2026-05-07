#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import process from "node:process";
import { fileURLToPath } from "node:url";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const configPath = path.join(rootDir, "config", "apps.json");
const platform = process.platform === "win32" ? "windows" : "linux";

function parseArgs(argv) {
  const args = {
    command: "status",
    appFilter: null,
    dryRun: false,
    replace: false,
    includeMissing: false
  };

  for (const arg of argv) {
    if (arg === "status" || arg === "install") {
      args.command = arg;
      continue;
    }
    if (arg === "--dry-run") {
      args.dryRun = true;
      continue;
    }
    if (arg === "--replace") {
      args.replace = true;
      continue;
    }
    if (arg === "--include-missing") {
      args.includeMissing = true;
      continue;
    }
    if (arg.startsWith("--app=")) {
      args.appFilter = arg.slice("--app=".length);
      continue;
    }
    if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    }
    throw new Error(`Argumento no soportado: ${arg}`);
  }

  return args;
}

function printHelp() {
  console.log(`skills-hub link installer

Uso:
  node scripts/link-skills.mjs status [--app=<id>] [--include-missing]
  node scripts/link-skills.mjs install [--app=<id>] [--dry-run] [--replace] [--include-missing]

Opciones:
  --app=<id>          Limita la operacion a una app concreta
  --dry-run           Muestra el plan sin tocar el filesystem
  --replace           Reemplaza enlaces existentes que apuntan a otra ruta
  --include-missing   Crea la ruta de instalacion aunque la app no se detecte
`);
}

function expandHome(value) {
  const home = os.homedir();
  return value
    .replace(/^~(?=$|[\\/])/, home)
    .replace(/%USERPROFILE%/gi, home)
    .replace(/\$HOME/g, home);
}

function buildTokenMap(apps) {
  const copilot = apps.find((a) => a.id === "copilot");
  const copilotSkillsDir = copilot?.installPath?.[platform]
    ? expandHome(copilot.installPath[platform])
    : expandHome("~/.copilot/skills");
  return { __COPILOT_SKILLS_DIR__: copilotSkillsDir };
}

async function pathExists(target) {
  try {
    await fs.lstat(target);
    return true;
  } catch {
    return false;
  }
}

async function loadConfig() {
  const raw = await fs.readFile(configPath, "utf8");
  const parsed = JSON.parse(raw);
  if (!Array.isArray(parsed.apps)) {
    throw new Error("config/apps.json no contiene una lista 'apps'");
  }
  return parsed.apps;
}

async function appStatus(app) {
  const detectPaths = (app.detectPaths?.[platform] ?? []).map(expandHome);
  const installPath = expandHome(app.installPath?.[platform] ?? "");

  if (!installPath) {
    return {
      ...app,
      supported: false,
      detected: false,
      installPath: null,
      detectPaths
    };
  }

  let detected = false;
  for (const candidate of detectPaths) {
    if (await pathExists(candidate)) {
      detected = true;
      break;
    }
  }

  return {
    ...app,
    supported: true,
    detected,
    installPath,
    detectPaths
  };
}

async function collectSourceEntries(sourceDirs) {
  const entries = new Map();

  for (const sourceDir of sourceDirs) {
    const absSourceDir = path.join(rootDir, sourceDir);
    if (!(await pathExists(absSourceDir))) continue;

    const children = await fs.readdir(absSourceDir, { withFileTypes: true });
    for (const child of children) {
      if (child.name.startsWith(".")) continue;
      const childPath = path.join(absSourceDir, child.name);
      entries.set(child.name, {
        name: child.name,
        sourceDir,
        sourcePath: childPath,
        dirent: child
      });
    }
  }

  return [...entries.values()].sort((a, b) => a.name.localeCompare(b.name));
}

async function describeTarget(targetPath) {
  try {
    const stat = await fs.lstat(targetPath);
    const isLink = stat.isSymbolicLink();
    let linkTarget = null;

    if (isLink) {
      try {
        linkTarget = await fs.readlink(targetPath);
      } catch {
        linkTarget = null;
      }
    }

    return {
      exists: true,
      isDirectory: stat.isDirectory(),
      isLink,
      linkTarget
    };
  } catch {
    return {
      exists: false,
      isDirectory: false,
      isLink: false,
      linkTarget: null
    };
  }
}

function normalizeLinkTarget(targetPath, rawLinkTarget) {
  if (!rawLinkTarget) return null;
  return path.resolve(path.dirname(targetPath), rawLinkTarget);
}

async function ensureDir(target, dryRun) {
  if (dryRun) return;
  await fs.mkdir(target, { recursive: true });
}

function timestampSuffix() {
  const now = new Date();
  const pad = (value) => String(value).padStart(2, "0");
  return `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}-${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
}

async function backupFile(target, dryRun) {
  if (!(await pathExists(target))) return null;
  const backupPath = `${target}.bak-${timestampSuffix()}`;
  if (!dryRun) {
    await fs.copyFile(target, backupPath);
  }
  return backupPath;
}

async function removePath(target, dryRun) {
  if (dryRun) return;
  await fs.rm(target, { recursive: true, force: true });
}

async function createLink(sourcePath, targetPath, dirent, dryRun) {
  const type = dirent.isDirectory() ? (platform === "windows" ? "junction" : "dir") : "file";
  if (dryRun) return;
  await fs.symlink(sourcePath, targetPath, type);
}

async function installForApp(app, args) {
  const sourceEntries = await collectSourceEntries(app.sources);
  const actions = [];

  if (!app.detected && !args.includeMissing) {
    return {
      app,
      actions,
      skipped: true,
      reason: "app no detectada"
    };
  }

  await ensureDir(app.installPath, args.dryRun);

  for (const entry of sourceEntries) {
    const targetPath = path.join(app.installPath, entry.name);
    const targetInfo = await describeTarget(targetPath);

    if (!targetInfo.exists) {
      actions.push(`link ${entry.name} -> ${entry.sourceDir}`);
      await createLink(entry.sourcePath, targetPath, entry.dirent, args.dryRun);
      continue;
    }

    if (targetInfo.isLink) {
      const normalized = normalizeLinkTarget(targetPath, targetInfo.linkTarget);
      if (normalized === path.resolve(entry.sourcePath)) {
        actions.push(`ok ${entry.name}`);
        continue;
      }
      if (!args.replace) {
        actions.push(`skip ${entry.name} (enlace existente a otra ruta)`);
        continue;
      }
      actions.push(`replace-link ${entry.name}`);
      await removePath(targetPath, args.dryRun);
      await createLink(entry.sourcePath, targetPath, entry.dirent, args.dryRun);
      continue;
    }

    actions.push(`skip ${entry.name} (ruta real existente)`);
  }

  return {
    app,
    actions,
    skipped: false,
    reason: null
  };
}

function deepEqual(a, b) {
  if (a === b) return true;
  if (typeof a !== typeof b) return false;
  if (Array.isArray(a) && Array.isArray(b)) {
    if (a.length !== b.length) return false;
    return a.every((item, i) => deepEqual(item, b[i]));
  }
  if (isPlainObject(a) && isPlainObject(b)) {
    const keysA = Object.keys(a).sort();
    const keysB = Object.keys(b).sort();
    if (keysA.length !== keysB.length) return false;
    if (!keysA.every((k, i) => k === keysB[i])) return false;
    return keysA.every((k) => deepEqual(a[k], b[k]));
  }
  return false;
}

function mergeValues(existing, incoming) {
  if (Array.isArray(existing) && Array.isArray(incoming)) {
    const result = [...existing];
    for (const item of incoming) {
      if (!result.some((ex) => deepEqual(ex, item))) {
        result.push(item);
      }
    }
    return result;
  }

  if (isPlainObject(existing) && isPlainObject(incoming)) {
    const result = { ...existing };
    for (const [key, value] of Object.entries(incoming)) {
      if (key in result) {
        result[key] = mergeValues(result[key], value);
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  return incoming;
}

function isPlainObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function replaceTokens(content, tokenMap) {
  let result = content;
  for (const [token, value] of Object.entries(tokenMap)) {
    result = result.replace(new RegExp(escapeRegExp(token), "g"), value);
  }
  return result;
}

async function loadJson(filePath, tokenMap) {
  const raw = await fs.readFile(filePath, "utf8");
  return JSON.parse(replaceTokens(raw, tokenMap));
}

async function loadText(filePath, tokenMap) {
  const raw = await fs.readFile(filePath, "utf8");
  return replaceTokens(raw, tokenMap);
}

async function installConfigFiles(app, args, tokenMap) {
  const actions = [];
  const configFiles = Array.isArray(app.configFiles) ? app.configFiles : [];

  for (const item of configFiles) {
    const sourcePath = path.join(rootDir, item.source);
    const targetPath = expandHome(item.target?.[platform] ?? "");
    if (!targetPath) {
      actions.push(`skip-config ${item.source} (sin target para ${platform})`);
      continue;
    }
    await ensureDir(path.dirname(targetPath), args.dryRun);

    if (item.strategy === "json-merge") {
      const managed = await loadJson(sourcePath, tokenMap);
      let existing = {};
      if (await pathExists(targetPath)) {
        try {
          const rawExisting = await fs.readFile(targetPath, "utf8");
          existing = JSON.parse(rawExisting);
        } catch {
          throw new Error(`JSON inválido en archivo destino: ${targetPath}`);
        }
      }
      const merged = mergeValues(existing, managed);
      if (JSON.stringify(existing, null, 2) === JSON.stringify(merged, null, 2)) {
        actions.push(`ok-config ${path.basename(targetPath)}`);
        continue;
      }
      const backup = await backupFile(targetPath, args.dryRun);
      if (!args.dryRun) {
        await fs.writeFile(`${targetPath}.tmp`, `${JSON.stringify(merged, null, 2)}\n`, "utf8");
        await fs.rename(`${targetPath}.tmp`, targetPath);
      }
      actions.push(`merge-config ${path.basename(targetPath)}${backup ? ` (backup ${path.basename(backup)})` : ""}`);
      continue;
    }

    if (item.strategy === "markdown-managed-block") {
      const managedContent = (await loadText(sourcePath, tokenMap)).trimEnd();
      const blockId = item.blockId ?? "skills-hub";
      const startMarker = `<!-- skills-hub:managed ${blockId} start -->`;
      const endMarker = `<!-- skills-hub:managed ${blockId} end -->`;
      const block = `${startMarker}\n${managedContent}\n${endMarker}\n`;

      let existing = "";
      if (await pathExists(targetPath)) {
        existing = await fs.readFile(targetPath, "utf8");
      }

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
      const backup = await backupFile(targetPath, args.dryRun);
      if (!args.dryRun) {
        await fs.writeFile(targetPath, next, "utf8");
      }
      actions.push(`merge-config ${path.basename(targetPath)}${backup ? ` (backup ${path.basename(backup)})` : ""}`);
      continue;
    }

    actions.push(`skip-config ${item.source} (strategy desconocida)`);
  }

  return actions;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function printStatus(results) {
  console.log(`[skills-hub] Plataforma: ${platform}`);
  for (const result of results) {
    const { app } = result;
    const state = !app.supported ? "unsupported" : app.detected ? "detected" : "missing";
    console.log(`- ${app.id}: ${state}`);
    if (app.installPath) console.log(`  install: ${app.installPath}`);
    if (app.detectPaths.length > 0) console.log(`  detect: ${app.detectPaths.join(", ")}`);
    if (result.actions && result.actions.length > 0) {
      console.log(`  actions:`);
      for (const action of result.actions) console.log(`    - ${action}`);
    }
    if (result.reason) console.log(`  note: ${result.reason}`);
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const config = await loadConfig();
  const tokenMap = buildTokenMap(config);

  const selectedApps = [];
  for (const app of config) {
    if (args.appFilter && app.id !== args.appFilter) continue;
    selectedApps.push(await appStatus(app));
  }

  if (selectedApps.length === 0) {
    throw new Error("No hay apps seleccionadas para esta plataforma o filtro");
  }

  if (args.command === "status") {
    printStatus(selectedApps.map((app) => ({ app, actions: [], skipped: false, reason: null })));
    return;
  }

  const results = [];
  for (const app of selectedApps) {
    const skillResult = await installForApp(app, args);
    const configActions = await installConfigFiles(app, args, tokenMap);
    skillResult.actions.push(...configActions);
    results.push(skillResult);
  }
  printStatus(results);
}

main().catch((error) => {
  console.error(`[skills-hub] ERROR: ${error.message}`);
  process.exit(1);
});
