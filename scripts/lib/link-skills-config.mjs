import fs from "node:fs/promises";
import path from "node:path";
import { backupFile, ensureDir, expandHome, pathExists } from "./link-skills-core.mjs";

export async function loadConfig(configPath) {
  const raw = await fs.readFile(configPath, "utf8");
  const parsed = JSON.parse(raw);
  if (!Array.isArray(parsed.apps)) throw new Error("config/apps.json no contiene una lista 'apps'");
  return parsed.apps;
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

async function loadJson(filePath, tokenMap) {
  return JSON.parse(replaceTokens(await fs.readFile(filePath, "utf8"), tokenMap));
}

async function loadText(filePath, tokenMap) {
  return replaceTokens(await fs.readFile(filePath, "utf8"), tokenMap);
}

export async function installConfigFiles(rootDir, app, args, tokenMap, platform) {
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
      const backup = await backupFile(targetPath, args.dryRun);
      if (!args.dryRun) await fs.writeFile(targetPath, next, "utf8");
      actions.push(`merge-config ${path.basename(targetPath)}${backup ? ` (backup ${path.basename(backup)})` : ""}`);
      continue;
    }

    actions.push(`skip-config ${item.source} (strategy desconocida)`);
  }

  return actions;
}
