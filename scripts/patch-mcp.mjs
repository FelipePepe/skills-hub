#!/usr/bin/env node
/**
 * Idempotently registers external MCP servers into ~/.claude.json
 * and ~/.vscode/mcp/config.json.
 *
 * Usage:
 *   node scripts/patch-mcp.mjs --grafos-dir /path/to/grafos
 */
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { homedir } from 'node:os'

// ── Args ──────────────────────────────────────────────────────────────────────

let grafosDir = null

for (let i = 2; i < process.argv.length; i++) {
  const arg = process.argv[i]
  if (arg === '--grafos-dir' && process.argv[i + 1]) {
    grafosDir = process.argv[++i]
  } else if (arg.startsWith('--grafos-dir=')) {
    grafosDir = arg.slice('--grafos-dir='.length)
  }
}

if (!grafosDir) {
  console.error('ERROR: --grafos-dir is required')
  process.exit(1)
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function readJson(path) {
  if (!existsSync(path)) return {}
  try { return JSON.parse(readFileSync(path, 'utf8')) } catch { return {} }
}

function writeJson(path, data) {
  mkdirSync(dirname(path), { recursive: true })
  writeFileSync(path, JSON.stringify(data, null, 2) + '\n', 'utf8')
}

function patchMcpServers(configPath, name, entry, label) {
  const config = readJson(configPath)
  config.mcpServers ??= {}

  if (config.mcpServers[name]) {
    console.log(`[skills-hub] ${label} — ${name} already registered, skipping`)
    return
  }

  config.mcpServers[name] = entry
  writeJson(configPath, config)
  console.log(`[skills-hub] ${label} — added ${name} MCP`)
}

// ── Grafos entry ──────────────────────────────────────────────────────────────

const grafosEntrypoint = join(grafosDir, 'mcp/dist/mcp/src/index.js')

const grafosEntry = {
  type: 'stdio',
  command: 'node',
  args: ['--experimental-sqlite', grafosEntrypoint],
}

// ── Patch targets ─────────────────────────────────────────────────────────────

patchMcpServers(
  join(homedir(), '.claude.json'),
  'grafos',
  grafosEntry,
  '~/.claude.json',
)

patchMcpServers(
  join(homedir(), '.vscode/mcp/config.json'),
  'grafos',
  grafosEntry,
  '~/.vscode/mcp/config.json',
)
