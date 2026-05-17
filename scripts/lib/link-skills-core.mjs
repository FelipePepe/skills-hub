import fs from "node:fs/promises";
import path from "node:path";
import os from "node:os";

export function expandHome(value) {
  const home = os.homedir();
  return value
    .replace(/^~(?=$|[\\/])/, home)
    .replace(/%USERPROFILE%/gi, home)
    .replace(/\$HOME/g, home);
}

export async function pathExists(target) {
  try {
    await fs.lstat(target);
    return true;
  } catch {
    return false;
  }
}

export function buildTokenMap(apps, platform) {
  const copilot = apps.find((a) => a.id === "copilot");
  const copilotSkillsDir = copilot?.installPath?.[platform]
    ? expandHome(copilot.installPath[platform])
    : expandHome("~/.copilot/skills");
  return { __COPILOT_SKILLS_DIR__: copilotSkillsDir };
}

export async function appStatus(app, platform) {
  const detectPaths = (app.detectPaths?.[platform] ?? []).map(expandHome);
  const installPath = expandHome(app.installPath?.[platform] ?? "");

  if (!installPath) {
    return { ...app, supported: false, detected: false, installPath: null, detectPaths };
  }

  let detected = false;
  for (const candidate of detectPaths) {
    if (await pathExists(candidate)) {
      detected = true;
      break;
    }
  }

  return { ...app, supported: true, detected, installPath, detectPaths };
}

export async function collectSourceEntries(rootDir, sourceDirs) {
  const entries = new Map();

  for (const sourceDir of sourceDirs) {
    const absSourceDir = path.join(rootDir, sourceDir);
    if (!(await pathExists(absSourceDir))) continue;

    const children = await fs.readdir(absSourceDir, { withFileTypes: true });
    for (const child of children) {
      if (child.name.startsWith(".") || child.name.startsWith("_")) continue;
      entries.set(child.name, {
        name: child.name,
        sourceDir,
        sourcePath: path.join(absSourceDir, child.name),
        dirent: child
      });
    }
  }

  return [...entries.values()].sort((a, b) => a.name.localeCompare(b.name));
}

export async function describeTarget(targetPath) {
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

    return { exists: true, isDirectory: stat.isDirectory(), isLink, linkTarget };
  } catch {
    return { exists: false, isDirectory: false, isLink: false, linkTarget: null };
  }
}

export function normalizeLinkTarget(targetPath, rawLinkTarget) {
  if (!rawLinkTarget) return null;
  return path.resolve(path.dirname(targetPath), rawLinkTarget);
}

export async function ensureDir(target, dryRun) {
  if (dryRun) return;
  await fs.mkdir(target, { recursive: true });
}

function timestampSuffix() {
  const now = new Date();
  const pad = (value) => String(value).padStart(2, "0");
  return `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}-${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
}

export async function backupFile(target, dryRun) {
  if (!(await pathExists(target))) return null;
  const backupPath = `${target}.bak-${timestampSuffix()}`;
  if (!dryRun) await fs.copyFile(target, backupPath);
  return backupPath;
}

export async function removePath(target, dryRun) {
  if (dryRun) return;
  await fs.rm(target, { recursive: true, force: true });
}

export async function createLink(sourcePath, targetPath, dirent, dryRun, platform) {
  const type = dirent.isDirectory() ? (platform === "windows" ? "junction" : "dir") : "file";
  if (dryRun) return;
  await fs.symlink(sourcePath, targetPath, type);
}

export async function installForApp(rootDir, app, args, platform) {
  const sourceEntries = await collectSourceEntries(rootDir, app.sources);
  const actions = [];

  if (!app.detected && !args.includeMissing) {
    return { app, actions, skipped: true, reason: "app no detectada" };
  }

  await ensureDir(app.installPath, args.dryRun);

  for (const entry of sourceEntries) {
    const targetPath = path.join(app.installPath, entry.name);
    const targetInfo = await describeTarget(targetPath);

    if (!targetInfo.exists) {
      actions.push(`link ${entry.name} -> ${entry.sourceDir}`);
      await createLink(entry.sourcePath, targetPath, entry.dirent, args.dryRun, platform);
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
      await createLink(entry.sourcePath, targetPath, entry.dirent, args.dryRun, platform);
      continue;
    }

    actions.push(`skip ${entry.name} (ruta real existente)`);
  }

  return { app, actions, skipped: false, reason: null };
}
