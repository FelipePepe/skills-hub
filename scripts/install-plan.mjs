#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const rootDir = path.resolve(scriptDir, '..');
const manifestsDir = path.join(rootDir, 'manifests');

function readJson(name) {
  return JSON.parse(fs.readFileSync(path.join(manifestsDir, name), 'utf8'));
}

function usage() {
  console.log(`skills-hub install-plan

Usage:
  node scripts/install-plan.mjs --list-profiles
  node scripts/install-plan.mjs --list-components [--family <family>] [--json]
  node scripts/install-plan.mjs --list-modules [--json]
  node scripts/install-plan.mjs --profile <id> [--target <app>] [--json]
  node scripts/install-plan.mjs --component <id> [--target <app>] [--json]

This is a read-only planner. sync.sh remains the current apply path.
`);
}

function parseArgs(argv) {
  const args = argv.slice(2);
  const out = { json: false, listProfiles: false, listComponents: false, listModules: false, profile: null, component: null, target: null, family: null, help: false };
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === '--help' || arg === '-h') out.help = true;
    else if (arg === '--json') out.json = true;
    else if (arg === '--list-profiles') out.listProfiles = true;
    else if (arg === '--list-components') out.listComponents = true;
    else if (arg === '--list-modules') out.listModules = true;
    else if (arg === '--profile') out.profile = args[++i];
    else if (arg === '--component') out.component = args[++i];
    else if (arg === '--target') out.target = args[++i];
    else if (arg === '--family') out.family = args[++i];
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return out;
}

function expandModules(seedIds, modulesById) {
  const selected = new Map();
  function visit(id) {
    const module = modulesById.get(id);
    if (!module) throw new Error(`Unknown module: ${id}`);
    for (const dep of module.dependencies || []) visit(dep);
    selected.set(id, module);
  }
  for (const id of seedIds) visit(id);
  return [...selected.values()];
}

function buildPlan({ moduleIds, target }) {
  const modulesDoc = readJson('install-modules.json');
  const modulesById = new Map(modulesDoc.modules.map(module => [module.id, module]));
  const modules = expandModules(moduleIds, modulesById);
  const selectedModules = target
    ? modules.filter(module => (module.targets || []).includes(target))
    : modules;
  const skippedModules = target
    ? modules.filter(module => !(module.targets || []).includes(target))
    : [];
  const operations = [];
  for (const module of selectedModules) {
    for (const sourcePath of module.paths || []) {
      operations.push({ moduleId: module.id, kind: module.kind, sourcePath });
    }
  }
  return {
    target: target || null,
    requestedModuleIds: moduleIds,
    selectedModuleIds: selectedModules.map(module => module.id),
    skippedModuleIds: skippedModules.map(module => module.id),
    operations,
  };
}

function printProfiles(profiles) {
  console.log('Install profiles:\n');
  for (const [id, profile] of Object.entries(profiles)) {
    console.log(`- ${id}: ${profile.description}`);
    console.log(`  modules: ${profile.modules.join(', ')}`);
  }
}

function printComponents(components) {
  console.log('Install components:\n');
  for (const component of components) {
    console.log(`- ${component.id} [${component.family}]`);
    console.log(`  modules: ${component.modules.join(', ')}`);
    console.log(`  ${component.description}`);
  }
}

function printModules(modules) {
  console.log('Install modules:\n');
  for (const module of modules) {
    console.log(`- ${module.id} [${module.kind}] targets=${module.targets.join(', ')}`);
    console.log(`  ${module.description}`);
  }
}

function printPlan(plan) {
  console.log('Install plan (read-only):\n');
  console.log(`Target: ${plan.target || '(all)'}`);
  console.log(`Requested modules: ${plan.requestedModuleIds.join(', ')}`);
  console.log(`Selected modules: ${plan.selectedModuleIds.join(', ')}`);
  if (plan.skippedModuleIds.length) console.log(`Skipped modules: ${plan.skippedModuleIds.join(', ')}`);
  console.log('\nOperations:');
  for (const op of plan.operations) console.log(`- ${op.moduleId}: ${op.sourcePath} [${op.kind}]`);
}

function main() {
  const opts = parseArgs(process.argv);
  if (opts.help) return usage();
  const modulesDoc = readJson('install-modules.json');
  const componentsDoc = readJson('install-components.json');
  const profilesDoc = readJson('install-profiles.json');

  if (opts.listProfiles) {
    if (opts.json) console.log(JSON.stringify({ profiles: profilesDoc.profiles }, null, 2));
    else printProfiles(profilesDoc.profiles);
    return;
  }
  if (opts.listComponents) {
    const components = opts.family
      ? componentsDoc.components.filter(component => component.family === opts.family)
      : componentsDoc.components;
    if (opts.json) console.log(JSON.stringify({ components }, null, 2));
    else printComponents(components);
    return;
  }
  if (opts.listModules) {
    if (opts.json) console.log(JSON.stringify({ modules: modulesDoc.modules }, null, 2));
    else printModules(modulesDoc.modules);
    return;
  }
  if (opts.profile) {
    const profile = profilesDoc.profiles[opts.profile];
    if (!profile) throw new Error(`Unknown profile: ${opts.profile}`);
    const plan = { profileId: opts.profile, ...buildPlan({ moduleIds: profile.modules, target: opts.target }) };
    if (opts.json) console.log(JSON.stringify(plan, null, 2));
    else printPlan(plan);
    return;
  }
  if (opts.component) {
    const component = componentsDoc.components.find(item => item.id === opts.component);
    if (!component) throw new Error(`Unknown component: ${opts.component}`);
    const plan = { componentId: opts.component, ...buildPlan({ moduleIds: component.modules, target: opts.target }) };
    if (opts.json) console.log(JSON.stringify(plan, null, 2));
    else printPlan(plan);
    return;
  }
  usage();
}

try {
  main();
} catch (error) {
  console.error(`ERROR: ${error.message}`);
  process.exit(1);
}
