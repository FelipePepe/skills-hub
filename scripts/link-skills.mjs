#!/usr/bin/env node

import path from "node:path";
import { fileURLToPath } from "node:url";
import { defaultConfigPath, runLinkSkillsCli } from "./lib/link-skills-cli.mjs";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
runLinkSkillsCli({
  rootDir,
  configPath: defaultConfigPath(rootDir),
  argv: process.argv.slice(2)
}).catch((error) => {
  console.error(`[skills-hub] ERROR: ${error.message}`);
  process.exit(1);
});
