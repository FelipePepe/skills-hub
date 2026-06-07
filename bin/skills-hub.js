#!/usr/bin/env node

import path from "node:path";
import process from "node:process";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const argv = process.argv.slice(2);

function printHelp() {
  console.log(`skills-hub

CLI del catalogo de skills/agents y su instalacion local por copia.

Uso:
  skills-hub install [--app=<id>] [--dry-run] [--include-missing] [--verbose]
  skills-hub sync    [--app=<id>] [--dry-run] [--include-missing] [--verbose]
  skills-hub status  [--app=<id>] [--include-missing]
  skills-hub plan    [--profile=<id>|--component=<id>|--list-profiles]
  skills-hub doctor
  skills-hub doctor-skills
  skills-hub doctor-agents
  skills-hub lint
  skills-hub check

Notas:
  - install y sync son equivalentes: copian skills y agents del repo a cada app local.
  - Las skills se COPIAN (no symlinks) y todo debe vivir en disco local (sin NAS).
  - status/doctor reutilizan la deteccion de doctor.sh.
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

  switch (command) {
    case "install":
    case "sync":
      await runRepoScript("sync.sh", rest);
      return;
    case "status":
    case "doctor":
      await runRepoScript("doctor.sh", rest);
      return;
    case "plan":
    case "install-plan":
      await runRepoScript("install-plan.mjs", rest);
      return;
    case "doctor-skills":
      await runRepoScript("doctor-skills.sh", rest);
      return;
    case "doctor-agents":
      await runRepoScript("doctor-agents.sh", rest);
      return;
    case "lint":
      await runRepoScript("lint.sh", rest);
      return;
    case "check":
      await runRepoScript("check.sh", rest);
      return;
    default:
      throw new Error(`Comando no soportado: ${command}`);
  }
}

main().catch((error) => {
  console.error(`[skills-hub] ERROR: ${error.message}`);
  process.exit(1);
});
