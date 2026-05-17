import path from "node:path";
import process from "node:process";
import { appStatus, buildTokenMap, installAdapter, installForApp } from "./link-skills-core.mjs";
import { installConfigFiles, loadConfig } from "./link-skills-config.mjs";

export function parseArgs(argv) {
  const args = { command: "status", appFilter: null, dryRun: false, replace: false, includeMissing: false };

  for (const arg of argv) {
    if (arg === "status" || arg === "install") args.command = arg;
    else if (arg === "--dry-run") args.dryRun = true;
    else if (arg === "--replace") args.replace = true;
    else if (arg === "--include-missing") args.includeMissing = true;
    else if (arg.startsWith("--app=")) args.appFilter = arg.slice("--app=".length);
    else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Argumento no soportado: ${arg}`);
    }
  }

  return args;
}

export function printHelp(programName = "skills-hub") {
  console.log(`${programName} installer

Uso:
  ${programName} status [--app=<id>] [--include-missing]
  ${programName} install [--app=<id>] [--dry-run] [--replace] [--include-missing]

Opciones:
  --app=<id>          Limita la operacion a una app concreta
  --dry-run           Muestra el plan sin tocar el filesystem
  --replace           Reemplaza enlaces existentes que apuntan a otra ruta
  --include-missing   Crea la ruta de instalacion aunque la app no se detecte
`);
}

export function printStatus(results, platform) {
  console.log(`[skills-hub] Plataforma: ${platform}`);
  for (const result of results) {
    const { app } = result;
    const state = !app.supported ? "unsupported" : app.detected ? "detected" : "missing";
    console.log(`- ${app.id}: ${state}`);
    if (app.installPath) console.log(`  install: ${app.installPath}`);
    if (app.detectPaths.length > 0) console.log(`  detect: ${app.detectPaths.join(", ")}`);
    if (result.actions?.length > 0) {
      console.log("  actions:");
      for (const action of result.actions) console.log(`    - ${action}`);
    }
    if (result.reason) console.log(`  note: ${result.reason}`);
  }
}

export async function runLinkSkillsCli({ rootDir, configPath, argv = process.argv.slice(2) }) {
  const platform = process.platform === "win32" ? "windows" : "linux";
  const args = parseArgs(argv);
  const config = await loadConfig(configPath);
  const tokenMap = buildTokenMap(config, platform);

  const selectedApps = [];
  for (const app of config) {
    if (args.appFilter && app.id !== args.appFilter) continue;
    selectedApps.push(await appStatus(app, platform));
  }

  if (selectedApps.length === 0) throw new Error("No hay apps seleccionadas para esta plataforma o filtro");

  if (args.command === "status") {
    printStatus(selectedApps.map((app) => ({ app, actions: [], skipped: false, reason: null })), platform);
    return;
  }

  const results = [];
  for (const app of selectedApps) {
    const skillResult = await installForApp(rootDir, app, args, platform);
    const adapterActions = await installAdapter(rootDir, app, args, platform);
    const configActions = await installConfigFiles(rootDir, app, args, tokenMap, platform);
    skillResult.actions.push(...adapterActions, ...configActions);
    results.push(skillResult);
  }

  printStatus(results, platform);
}

export function defaultConfigPath(rootDir) {
  return path.join(rootDir, "config", "apps.json");
}
