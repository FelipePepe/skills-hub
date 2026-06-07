#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const rootDir = path.resolve(scriptDir, '..');
const manifestsDir = path.join(rootDir, 'manifests');
const apps = JSON.parse(fs.readFileSync(path.join(rootDir, 'config', 'apps.json'), 'utf8')).apps || [];
const validTargets = new Set(apps.map(app => app.id));
const errors = [];

function readJson(name) {
  const file = path.join(manifestsDir, name);
  if (!fs.existsSync(file)) {
    errors.push(`missing manifest: manifests/${name}`);
    return null;
  }
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (error) {
    errors.push(`invalid JSON in manifests/${name}: ${error.message}`);
    return null;
  }
}

function pathExists(relPath) {
  return fs.existsSync(path.join(rootDir, relPath));
}

const modulesDoc = readJson('install-modules.json');
const componentsDoc = readJson('install-components.json');
const profilesDoc = readJson('install-profiles.json');

const modules = new Map();
if (modulesDoc) {
  if (!Array.isArray(modulesDoc.modules)) errors.push('install-modules.json: modules must be an array');
  for (const module of modulesDoc.modules || []) {
    if (!module.id) errors.push('install-modules.json: module missing id');
    else if (modules.has(module.id)) errors.push(`install-modules.json: duplicate module '${module.id}'`);
    else modules.set(module.id, module);

    if (!['skills', 'agents', 'config', 'docs'].includes(module.kind)) {
      errors.push(`module '${module.id}': unsupported kind '${module.kind}'`);
    }
    if (!Array.isArray(module.paths) || module.paths.length === 0) {
      errors.push(`module '${module.id}': paths must be a non-empty array`);
    } else {
      for (const p of module.paths) {
        if (!pathExists(p)) errors.push(`module '${module.id}': missing path '${p}'`);
      }
    }
    for (const target of module.targets || []) {
      if (!validTargets.has(target)) errors.push(`module '${module.id}': unknown target '${target}'`);
    }
  }
  for (const module of modules.values()) {
    for (const dep of module.dependencies || []) {
      if (!modules.has(dep)) errors.push(`module '${module.id}': missing dependency '${dep}'`);
    }
  }
}

if (componentsDoc) {
  const seen = new Set();
  for (const component of componentsDoc.components || []) {
    if (!component.id) errors.push('install-components.json: component missing id');
    else if (seen.has(component.id)) errors.push(`install-components.json: duplicate component '${component.id}'`);
    else seen.add(component.id);
    for (const moduleId of component.modules || []) {
      if (!modules.has(moduleId)) errors.push(`component '${component.id}': missing module '${moduleId}'`);
    }
  }
}

if (profilesDoc) {
  for (const [profileId, profile] of Object.entries(profilesDoc.profiles || {})) {
    if (!Array.isArray(profile.modules) || profile.modules.length === 0) {
      errors.push(`profile '${profileId}': modules must be a non-empty array`);
    }
    for (const moduleId of profile.modules || []) {
      if (!modules.has(moduleId)) errors.push(`profile '${profileId}': missing module '${moduleId}'`);
    }
  }
}

if (errors.length > 0) {
  for (const error of errors) console.error(`ERROR: ${error}`);
  process.exit(1);
}
console.log(`Validated ${modules.size} install modules, ${(componentsDoc?.components || []).length} components, and ${Object.keys(profilesDoc?.profiles || {}).length} profiles`);
