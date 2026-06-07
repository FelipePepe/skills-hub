#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const rootDir = path.resolve(scriptDir, '..');
const agentsDir = path.join(rootDir, 'agents');
const skillsDir = path.join(rootDir, 'skills');
const appsFile = path.join(rootDir, 'config', 'apps.json');

const errors = [];
const warnings = [];
const requiredFields = ['name', 'description', 'model', 'tools'];
const validModels = new Set(['haiku', 'sonnet', 'opus', 'gpt-5', 'gpt-5.1', 'gpt-5.5']);

function rel(file) {
  return path.relative(rootDir, file).split(path.sep).join('/');
}

function walk(dir, predicate, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === '.git' || entry.name === 'node_modules') continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, predicate, out);
    else if (entry.isFile() && predicate(full)) out.push(full);
  }
  return out;
}

function parseFrontmatter(content, file) {
  if (!content.startsWith('---\n') && !content.startsWith('---\r\n')) {
    errors.push(`${rel(file)}: missing YAML frontmatter`);
    return { data: {}, body: content };
  }
  const normalized = content.replace(/\r\n/g, '\n');
  const end = normalized.indexOf('\n---\n', 4);
  if (end === -1) {
    errors.push(`${rel(file)}: unterminated YAML frontmatter`);
    return { data: {}, body: normalized };
  }
  const raw = normalized.slice(4, end).split('\n');
  const data = {};
  let currentKey = null;
  for (const line of raw) {
    if (!line.trim() || line.trimStart().startsWith('#')) continue;
    const listItem = line.match(/^\s*-\s*(.+?)\s*$/);
    if (listItem && currentKey) {
      if (!Array.isArray(data[currentKey])) data[currentKey] = [];
      data[currentKey].push(listItem[1].replace(/^['"]|['"]$/g, ''));
      continue;
    }
    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!match) continue;
    currentKey = match[1];
    const value = match[2].trim();
    data[currentKey] = value ? value.replace(/^['"]|['"]$/g, '') : '';
  }
  return { data, body: normalized.slice(end + 5) };
}

function listSkillNames() {
  return new Set(walk(skillsDir, file => path.basename(file) === 'SKILL.md')
    .map(file => path.basename(path.dirname(file))));
}

function validateAgentFile(file, skillNames) {
  const content = fs.readFileSync(file, 'utf8');
  const { data, body } = parseFrontmatter(content, file);
  const base = path.basename(file, '.md');

  for (const field of requiredFields) {
    if (!String(data[field] || '').trim()) {
      errors.push(`${rel(file)}: missing required frontmatter field '${field}'`);
    }
  }

  if (data.name && data.name !== base) {
    errors.push(`${rel(file)}: filename and frontmatter name mismatch (file=${base}, name=${data.name})`);
  }

  if (data.model && !validModels.has(String(data.model).trim())) {
    errors.push(`${rel(file)}: unsupported model '${data.model}'`);
  }

  const lineCount = content.split(/\r?\n/).length;
  if (lineCount > 220) {
    errors.push(`${rel(file)}: agent file exceeds 220 lines (${lineCount})`);
  }

  const skills = Array.isArray(data.skills) ? data.skills : [];
  for (const skill of skills) {
    if (!skillNames.has(skill)) {
      errors.push(`${rel(file)}: references missing skill '${skill}'`);
    }
  }

  if (body.length > 8000) {
    warnings.push(`${rel(file)}: large agent body (${body.length} bytes); consider moving detail to skills/references`);
  }
}

function validateExposure() {
  if (!fs.existsSync(appsFile)) return;
  const apps = JSON.parse(fs.readFileSync(appsFile, 'utf8'));
  for (const app of apps.apps || []) {
    const sources = Array.isArray(app.agentSources) ? app.agentSources : [];
    const seen = new Set();
    let count = 0;
    for (const source of sources) {
      const abs = path.join(rootDir, source);
      if (!fs.existsSync(abs)) {
        errors.push(`config/apps.json: app '${app.id}' agent source does not exist: ${source}`);
        continue;
      }
      for (const file of fs.readdirSync(abs).filter(name => name.endsWith('.md')).sort()) {
        const name = path.basename(file, '.md');
        if (seen.has(name)) {
          errors.push(`config/apps.json: app '${app.id}' exposes duplicate agent '${name}'`);
        }
        seen.add(name);
        count += 1;
      }
    }
    if (sources.length > 0) {
      console.log(`Validated app '${app.id}' agent exposure: ${count} agents`);
    }
  }
}

const agentFiles = walk(agentsDir, file => file.endsWith('.md')).sort();
if (agentFiles.length === 0) {
  errors.push('No agent files found under agents/');
}

const seenNames = new Set();
const skillNames = listSkillNames();
for (const file of agentFiles) {
  const name = path.basename(file, '.md');
  if (seenNames.has(name)) errors.push(`Duplicate agent filename basename: ${name}`);
  seenNames.add(name);
  validateAgentFile(file, skillNames);
}
validateExposure();

for (const warning of warnings) console.warn(`WARNING: ${warning}`);
if (errors.length > 0) {
  for (const error of errors) console.error(`ERROR: ${error}`);
  process.exit(1);
}
console.log(`Validated ${agentFiles.length} agent files`);
