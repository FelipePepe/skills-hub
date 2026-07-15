#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const ROOT_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const PLATFORM = process.platform === "win32" ? "windows" : "linux";

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

export function loadCatalog(rootDir = ROOT_DIR) {
  const apps = readJson(path.join(rootDir, "config", "apps.json")).apps || [];
  const projects = readJson(path.join(rootDir, "config", "projects.json")).projects || [];
  const projectsById = new Map(projects.map((project) => [project.id, project]));
  return { apps, projects, projectsById };
}

export function resolveSkillSources(app, projectsById) {
  const variants = app.skillVariants || ["common"];
  const projectIds = app.projects || [];
  const resolved = [];

  for (const variant of variants) {
    for (const projectId of projectIds) {
      const project = projectsById.get(projectId);
      if (!project) throw new Error(`Proyecto no declarado en projects.json: ${projectId}`);
      const source = project.skillSources?.[variant];
      if (!source) {
        throw new Error(`Variante '${variant}' no declarada para el proyecto '${projectId}'`);
      }
      resolved.push(source);
    }
  }

  // Backward compatibility for temporary/custom app entries using explicit sources.
  resolved.push(...(app.sources || []));
  return [...new Set(resolved)];
}

export function validateCatalog(rootDir = ROOT_DIR) {
  const { apps, projects, projectsById } = loadCatalog(rootDir);
  if (projects.some((project) => !project.id)) throw new Error("Proyecto sin id");
  if (projects.length !== projectsById.size) throw new Error("IDs de proyectos duplicados");
  if (new Set(apps.map((app) => app.id)).size !== apps.length) {
    throw new Error("IDs de apps duplicados");
  }

  for (const project of projects) {
    if (!project.id || !project.root) throw new Error("Proyecto sin id o root");
    if (!fs.existsSync(path.join(rootDir, project.root))) {
      throw new Error(`Root de proyecto inexistente: ${project.root}`);
    }
    for (const [variant, source] of Object.entries(project.skillSources || {})) {
      if (!fs.existsSync(path.join(rootDir, source))) {
        throw new Error(`Fuente inexistente (${project.id}/${variant}): ${source}`);
      }
    }
  }

  for (const app of apps) {
    for (const source of resolveSkillSources(app, projectsById)) {
      if (!fs.existsSync(path.join(rootDir, source))) {
        throw new Error(`Fuente resuelta inexistente para '${app.id}': ${source}`);
      }
    }
  }
}

function printAppSources(rootDir, mode) {
  const { apps, projectsById } = loadCatalog(rootDir);
  for (const app of apps) {
    if (mode === "skills") {
      const sources = resolveSkillSources(app, projectsById);
      if (!sources.length) continue;
      const install = app.installPath?.[PLATFORM] || "";
      const detect = app.detectPaths?.[PLATFORM] || [];
      console.log([app.id, install, detect.join(","), sources.join(",")].join("\t"));
    } else if (mode === "agents") {
      const sources = Array.isArray(app.agentSources) ? app.agentSources : [];
      if (!sources.length) continue;
      const install = app.agentInstallPath?.[PLATFORM] || "";
      const detect = app.detectPaths?.[PLATFORM] || [];
      console.log([app.id, install, detect.join(","), sources.join(",")].join("\t"));
    }
  }
}

if (path.resolve(process.argv[1] || "") === fileURLToPath(import.meta.url)) {
  const command = process.argv[2] || "check";
  try {
    if (command === "check") {
      validateCatalog(ROOT_DIR);
      console.log("Catalog projects OK.");
    } else if (command === "app-sources") {
      printAppSources(ROOT_DIR, "skills");
    } else if (command === "agent-sources") {
      printAppSources(ROOT_DIR, "agents");
    } else {
      throw new Error(`Comando no soportado: ${command}`);
    }
  } catch (error) {
    console.error(`[catalog] ERROR: ${error.message}`);
    process.exit(1);
  }
}
