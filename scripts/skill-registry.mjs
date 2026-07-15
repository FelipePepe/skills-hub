#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const DEFAULT_OUTPUT = ".skills-hub/skill-registry.md";
const SKILL_FILE = "SKILL.md";

function usage() {
  return `skills-hub registry

Uso:
  skills-hub registry list [--json]
  skills-hub registry refresh [--output=<path>]
  skills-hub registry check [--json]

Notas:
  - El registry es un indice: conserva SKILL.md como fuente de verdad.
  - refresh escribe .skills-hub/skill-registry.md por defecto.
  - check valida el catalogo y reporta overrides por app (no bloquea).
`;
}

function parseArgs(argv) {
  const args = {
    command: argv[0] || "list",
    json: false,
    output: DEFAULT_OUTPUT,
  };

  for (const arg of argv.slice(1)) {
    if (arg === "--json") {
      args.json = true;
    } else if (arg.startsWith("--output=")) {
      args.output = arg.slice("--output=".length);
    } else if (arg === "--help" || arg === "-h") {
      args.command = "help";
    } else {
      throw new Error(`Argumento no soportado: ${arg}`);
    }
  }

  return args;
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function normalizeRel(filePath) {
  return filePath.split(path.sep).join("/");
}

function unique(values) {
  return [...new Set(values)].filter(Boolean);
}

function appSources(app) {
  return unique([...(app.sources || []), ...(app.agentSources || [])]);
}

function sourceScope(source) {
  const parts = source.split("/");
  return parts[parts.length - 1] || source;
}

function parseScalar(raw) {
  let value = raw.trim();
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    value = value.slice(1, -1);
  }
  return value.trim();
}

function parseFrontmatter(content) {
  if (!content.startsWith("---\n")) {
    return {};
  }

  const end = content.indexOf("\n---", 4);
  if (end === -1) {
    return {};
  }

  const lines = content.slice(4, end).split(/\r?\n/);
  const data = {};

  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!match) {
      continue;
    }

    const [, key, rawValue] = match;
    const value = rawValue.trim();

    if (value === ">" || value === "|") {
      const block = [];
      while (i + 1 < lines.length && /^\s+/.test(lines[i + 1])) {
        i += 1;
        block.push(lines[i].trim());
      }
      data[key] = block.join(value === ">" ? " " : "\n").trim();
      continue;
    }

    if (value === "") {
      const items = [];
      while (i + 1 < lines.length && /^\s+-\s+/.test(lines[i + 1])) {
        i += 1;
        items.push(parseScalar(lines[i].replace(/^\s+-\s+/, "")));
      }
      if (items.length > 0) {
        data[key] = items;
      }
      continue;
    }

    if (value.startsWith("[") && value.endsWith("]")) {
      data[key] = value
        .slice(1, -1)
        .split(",")
        .map(parseScalar)
        .filter(Boolean);
      continue;
    }

    data[key] = parseScalar(value);
  }

  return data;
}

function walkSkillFiles(rootDir, source) {
  const absSource = path.join(rootDir, source);
  if (!fs.existsSync(absSource)) {
    throw new Error(`Fuente declarada no existe: ${source}`);
  }

  const found = [];
  const stack = [absSource];

  while (stack.length > 0) {
    const current = stack.pop();
    const children = fs
      .readdirSync(current, { withFileTypes: true })
      .sort((a, b) => a.name.localeCompare(b.name));

    for (const child of children) {
      if (child.name.startsWith("_") || child.name === "references") {
        continue;
      }

      const childPath = path.join(current, child.name);
      if (child.isDirectory()) {
        stack.push(childPath);
      } else if (child.isFile() && child.name === SKILL_FILE) {
        found.push(childPath);
      }
    }
  }

  return found.sort();
}

function loadRegistry(rootDir) {
  const appsPath = path.join(rootDir, "config", "apps.json");
  const apps = readJson(appsPath).apps || [];

  // Ordered skill sources per app; install copies in this order, last wins.
  const appSkillSources = new Map();
  for (const app of apps) {
    const skillSources = appSources(app).filter((source) =>
      source.startsWith("skills/"),
    );
    if (skillSources.length > 0) {
      appSkillSources.set(app.id, skillSources);
    }
  }

  const sources = unique([...appSkillSources.values()].flat());
  const entriesBySource = new Map();

  for (const source of sources) {
    const entries = new Map();
    for (const skillFile of walkSkillFiles(rootDir, source)) {
      const relPath = normalizeRel(path.relative(rootDir, skillFile));
      const skillDir = path.dirname(skillFile);
      const dirName = path.basename(skillDir);
      const content = fs.readFileSync(skillFile, "utf8");
      const frontmatter = parseFrontmatter(content);
      const name = frontmatter.name || dirName;

      entries.set(name, {
        name,
        description: frontmatter.description || "",
        license: frontmatter.license || "",
        allowedTools: Array.isArray(frontmatter["allowed-tools"])
          ? frontmatter["allowed-tools"]
          : [],
        source,
        scope: sourceScope(source),
        path: relPath,
        lines: content.split("\n").length,
        approxTokens: Math.round(content.length / 4),
        exposedApps: [],
      });
    }
    entriesBySource.set(source, entries);
  }

  const collisions = [];

  for (const [appId, skillSources] of appSkillSources) {
    const candidatesByName = new Map();
    for (const source of skillSources) {
      for (const [name, entry] of entriesBySource.get(source)) {
        if (!candidatesByName.has(name)) {
          candidatesByName.set(name, []);
        }
        candidatesByName.get(name).push(entry);
      }
    }

    for (const [name, candidates] of candidatesByName) {
      const winner = candidates[candidates.length - 1];
      winner.exposedApps.push(appId);
      if (candidates.length > 1) {
        collisions.push({
          name,
          app: appId,
          winner: winner.path,
          shadowed: candidates.slice(0, -1).map((entry) => entry.path),
        });
      }
    }
  }

  const entries = [...entriesBySource.values()]
    .flatMap((bySource) => [...bySource.values()])
    .sort((a, b) => a.name.localeCompare(b.name) || a.path.localeCompare(b.path));

  collisions.sort(
    (a, b) => a.name.localeCompare(b.name) || a.app.localeCompare(b.app),
  );

  return {
    generatedAt: new Date().toISOString(),
    sources,
    entries,
    collisions,
    approxTokensTotal: entries.reduce((sum, entry) => sum + entry.approxTokens, 0),
  };
}

function markdownCell(value) {
  return String(value || "")
    .replace(/\|/g, "\\|")
    .replace(/\s+/g, " ")
    .trim();
}

function renderMarkdown(registry) {
  const lines = [
    "# skills-hub skill registry",
    "",
    "<!-- Auto-generated by `skills-hub registry refresh`. Do not edit manually. -->",
    "",
    `Generated: ${registry.generatedAt}`,
    "",
    "## Contract",
    "",
    "This file is an index, not a summary. `SKILL.md` remains the source of truth. Agents should use this registry to select relevant skills, then read the exact `SKILL.md` paths before acting.",
    "",
    `Loading every skill body would cost ~${registry.approxTokensTotal} tokens; this index costs a fraction of that. Read skills on demand, never in bulk.`,
    "",
    "## Sources",
    "",
    ...registry.sources.map((source) => `- ${source}`),
    "",
    "## Skills",
    "",
    "| Skill | Description | Scope | Apps | Allowed tools | ~Tokens | Path |",
    "| --- | --- | --- | --- | --- | --- | --- |",
  ];

  for (const entry of registry.entries) {
    lines.push(
      `| \`${markdownCell(entry.name)}\` | ${markdownCell(entry.description)} | ${markdownCell(entry.scope)} | ${markdownCell(entry.exposedApps.join(", "))} | ${markdownCell(entry.allowedTools.join(", "))} | ${entry.approxTokens} | \`${markdownCell(entry.path)}\` |`,
    );
  }

  if (registry.collisions.length > 0) {
    lines.push(
      "",
      "## Overrides",
      "",
      "Platform-specific sources override `skills/common` at install time (last source wins). For these apps, agents must read the winning `SKILL.md`:",
      "",
    );
    for (const collision of registry.collisions) {
      lines.push(
        `- \`${markdownCell(collision.name)}\` (app \`${markdownCell(collision.app)}\`): \`${markdownCell(collision.winner)}\` shadows ${collision.shadowed.map((p) => `\`${markdownCell(p)}\``).join(", ")}`,
      );
    }
  }

  return `${lines.join("\n")}\n`;
}

function printList(registry) {
  for (const entry of registry.entries) {
    console.log(
      [
        entry.name,
        entry.scope,
        entry.exposedApps.join(","),
        entry.path,
        entry.description,
      ].join("\t"),
    );
  }
}

// Copilot agent-skill discovery limits: skills que los violan se ignoran
// silenciosamente en VS Code (name: minusculas/digitos/guiones, max 64;
// description: obligatoria, max 1024).
const SKILL_NAME_PATTERN = /^[a-z0-9-]+$/;
const SKILL_NAME_MAX = 64;
const SKILL_DESCRIPTION_MAX = 1024;
// Convenciones del catalogo: description con triggers utiles para discovery
// progresivo, y cuerpo bajo 300 lineas (modularizar en references/ si crece).
const SKILL_DESCRIPTION_MIN = 40;
const SKILL_BODY_MAX_LINES = 300;

function checkRegistry(registry, json) {
  const warnings = [];

  for (const entry of registry.entries) {
    if (!entry.description) {
      warnings.push(`Skill sin description en frontmatter: ${entry.path}`);
    } else if (entry.description.length > SKILL_DESCRIPTION_MAX) {
      warnings.push(
        `Description supera ${SKILL_DESCRIPTION_MAX} caracteres (${entry.description.length}), Copilot la ignora: ${entry.path}`,
      );
    } else if (entry.description.length < SKILL_DESCRIPTION_MIN) {
      warnings.push(
        `Description debil (${entry.description.length} caracteres), dificulta el discovery progresivo: ${entry.path}`,
      );
    }

    if (entry.lines > SKILL_BODY_MAX_LINES) {
      warnings.push(
        `SKILL.md supera ${SKILL_BODY_MAX_LINES} lineas (${entry.lines}), modularizar en references/: ${entry.path}`,
      );
    }

    if (!SKILL_NAME_PATTERN.test(entry.name)) {
      warnings.push(
        `Name con caracteres no soportados (solo a-z, 0-9, '-'): ${entry.path}`,
      );
    } else if (entry.name.length > SKILL_NAME_MAX) {
      warnings.push(
        `Name supera ${SKILL_NAME_MAX} caracteres (${entry.name.length}): ${entry.path}`,
      );
    }
  }

  for (const collision of registry.collisions) {
    warnings.push(
      `Override en app '${collision.app}': '${collision.name}' usa ${collision.winner} (oculta ${collision.shadowed.join(", ")})`,
    );
  }

  if (json) {
    console.log(
      JSON.stringify(
        {
          skills: registry.entries.length,
          collisions: registry.collisions,
          warnings,
        },
        null,
        2,
      ),
    );
    return;
  }

  for (const warning of warnings) {
    console.warn(`[skills-hub registry] WARN: ${warning}`);
  }
  console.log(
    `Registry check OK: ${registry.entries.length} skills, ${registry.collisions.length} overrides, ${warnings.length} warnings`,
  );
}

function writeRegistry(rootDir, outputPath, registry) {
  const absOutput = path.resolve(rootDir, outputPath);
  fs.mkdirSync(path.dirname(absOutput), { recursive: true });
  fs.writeFileSync(absOutput, renderMarkdown(registry));
  return normalizeRel(path.relative(rootDir, absOutput));
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.command === "help") {
    process.stdout.write(usage());
    return;
  }

  const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
  const registry = loadRegistry(rootDir);

  if (args.command === "list") {
    if (args.json) {
      console.log(JSON.stringify(registry, null, 2));
    } else {
      printList(registry);
    }
    return;
  }

  if (args.command === "check") {
    checkRegistry(registry, args.json);
    return;
  }

  if (args.command === "refresh") {
    const output = writeRegistry(rootDir, args.output, registry);
    if (args.json) {
      console.log(JSON.stringify({ output, count: registry.entries.length }, null, 2));
    } else {
      console.log(`Registry written: ${output} (${registry.entries.length} skills)`);
    }
    return;
  }

  throw new Error(`Comando registry no soportado: ${args.command}`);
}

main().catch((error) => {
  console.error(`[skills-hub registry] ERROR: ${error.message}`);
  process.exit(1);
});
