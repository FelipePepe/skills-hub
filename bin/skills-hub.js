#!/usr/bin/env node

import path from "node:path";
import process from "node:process";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { defaultConfigPath, runLinkSkillsCli } from "../scripts/lib/link-skills-cli.mjs";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const argv = process.argv.slice(2);

function printHelp() {
  console.log(`skills-hub

CLI del catalogo de skills y su exposicion local.

Uso:
  skills-hub status [--app=<id>] [--include-missing]
  skills-hub install [--app=<id>] [--dry-run] [--replace] [--include-missing]
  skills-hub doctor
  skills-hub doctor-skills
  skills-hub lint
  skills-hub check
  skills-hub sync [--dry-run]

Notas:
  - status/install usan la CLI nativa del instalador
  - doctor/lint/check/sync reutilizan los scripts del repo
`);
}

function runRepoScript(scriptName, args = []) {
  return new Promise((resolve, reject) => {
    const scriptPath = path.join(rootDir, "scripts", scriptName);
    const child = spawn(scriptPath, args, { stdio: "inherit" });
    child.on("exit", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${scriptName} termino con codigo ${code ?? 1}`));
    });
    child.on("error", reject);
  });
}

async function main() {
  const [command, ...rest] = argv;

  if (!command || command === "--help" || command === "-h") {
    printHelp();
    return;
  }

  if (command === "status" || command === "install") {
    await runLinkSkillsCli({
      rootDir,
      configPath: defaultConfigPath(rootDir),
      argv
    });
    return;
  }

  if (command === "doctor") {
    await runRepoScript("doctor.sh", rest);
    return;
  }

  if (command === "doctor-skills") {
    await runRepoScript("doctor-skills.sh", rest);
    return;
  }

  if (command === "lint") {
    await runRepoScript("lint.sh", rest);
    return;
  }

  if (command === "check") {
    await runRepoScript("check.sh", rest);
    return;
  }

  if (command === "sync") {
    await runRepoScript("sync.sh", rest);
    return;
  }

  throw new Error(`Comando no soportado: ${command}`);
}

main().catch((error) => {
  console.error(`[skills-hub] ERROR: ${error.message}`);
  process.exit(1);
});
