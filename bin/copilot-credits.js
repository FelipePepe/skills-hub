#!/usr/bin/env node
// copilot-credits — GitHub Copilot AI Credits usage tracker
//
// Reads ~/.copilot/session-state/<id>/events.jsonl and converts
// token counts to AI Credits using GitHub's published pricing.
// 1 AI Credit = $0.01 USD
//
// Usage: copilot-credits [--days=N] [--model=NAME] [--sessions] [--json]

import { readFileSync, readdirSync, statSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { parseArgs } from 'util';

// ─── Pricing table ────────────────────────────────────────────────────────────
// Source: https://docs.github.com/en/copilot/reference/copilot-billing/models-and-pricing
// Unit: AI credits per 1M tokens (1 credit = $0.01 USD)
const PRICING = {
  // Anthropic
  'claude-haiku-4.5':   { input: 100,  cachedInput: 10,   cacheWrite: 125,  output: 500  },
  'claude-sonnet-4':    { input: 300,  cachedInput: 30,   cacheWrite: 375,  output: 1500 },
  'claude-sonnet-4.5':  { input: 300,  cachedInput: 30,   cacheWrite: 375,  output: 1500 },
  'claude-sonnet-4.6':  { input: 300,  cachedInput: 30,   cacheWrite: 375,  output: 1500 },
  'claude-opus-4':      { input: 500,  cachedInput: 50,   cacheWrite: 625,  output: 2500 },
  'claude-opus-4.5':    { input: 500,  cachedInput: 50,   cacheWrite: 625,  output: 2500 },
  'claude-opus-4.6':    { input: 500,  cachedInput: 50,   cacheWrite: 625,  output: 2500 },
  // OpenAI
  'gpt-5-mini':         { input: 25,   cachedInput: 2.5,  cacheWrite: 0,    output: 200  },
  'gpt-5.3-codex':      { input: 175,  cachedInput: 17.5, cacheWrite: 0,    output: 1400 },
  'gpt-5.4':            { input: 250,  cachedInput: 25,   cacheWrite: 0,    output: 1500 },
  'gpt-5.4-mini':       { input: 75,   cachedInput: 7.5,  cacheWrite: 0,    output: 450  },
  'gpt-5.4-nano':       { input: 20,   cachedInput: 2,    cacheWrite: 0,    output: 125  },
  'gpt-5.5':            { input: 500,  cachedInput: 50,   cacheWrite: 0,    output: 3000 },
  // GPT-4.x (estimated from known API pricing — not in GitHub Docs table yet)
  'gpt-4.1':            { input: 200,  cachedInput: 20,   cacheWrite: 0,    output: 800  },
  'gpt-4o':             { input: 250,  cachedInput: 25,   cacheWrite: 0,    output: 1000 },
  // Google
  'gemini-2.5-pro':     { input: 125,  cachedInput: 12.5, cacheWrite: 0,    output: 1000 },
  'gemini-3-flash':     { input: 50,   cachedInput: 5,    cacheWrite: 0,    output: 300  },
  'gemini-3.1-pro':     { input: 200,  cachedInput: 20,   cacheWrite: 0,    output: 1200 },
  // Other
  'raptor-mini':        { input: 25,   cachedInput: 2.5,  cacheWrite: 0,    output: 200  },
  'mai-code-1-flash':   { input: 75,   cachedInput: 7.5,  cacheWrite: 0,    output: 450  },
};

const FALLBACK_PRICE = { input: 300, cachedInput: 30, cacheWrite: 375, output: 1500 };

// ─── Credit calculation ───────────────────────────────────────────────────────

function creditsForUsage(usage, modelId) {
  const price = PRICING[modelId] ?? FALLBACK_PRICE;
  const { inputTokens = 0, outputTokens = 0, cacheReadTokens = 0, cacheWriteTokens = 0 } = usage;
  return (
    inputTokens      * price.input +
    cacheReadTokens  * price.cachedInput +
    cacheWriteTokens * price.cacheWrite +
    outputTokens     * price.output
  ) / 1_000_000;
}

// ─── Data loading ─────────────────────────────────────────────────────────────

function loadSessions(daysBack) {
  const baseDir = join(homedir(), '.copilot', 'session-state');
  const cutoff = Date.now() - daysBack * 86_400_000;
  const sessions = [];

  let dirs;
  try {
    dirs = readdirSync(baseDir);
  } catch {
    return sessions;
  }

  for (const dir of dirs) {
    const eventsPath = join(baseDir, dir, 'events.jsonl');
    let content;
    try {
      content = readFileSync(eventsPath, 'utf8');
    } catch {
      continue;
    }

    let shutdown = null;
    let startTime = null;

    for (const line of content.split('\n')) {
      if (!line.trim()) continue;
      try {
        const event = JSON.parse(line);
        if (event.type === 'session.start') {
          startTime = event.data?.startTime ? new Date(event.data.startTime).getTime() : null;
        }
        if (event.type === 'session.shutdown') {
          shutdown = event;
        }
      } catch {
        continue;
      }
    }

    if (!shutdown) continue;

    const ts = startTime ?? new Date(shutdown.timestamp).getTime();
    if (ts < cutoff) continue;

    sessions.push({
      sessionId: dir,
      startTime: new Date(ts),
      shutdownTime: new Date(shutdown.timestamp),
      modelMetrics: shutdown.data?.modelMetrics ?? {},
      totalPremiumRequests: shutdown.data?.totalPremiumRequests ?? 0,
      codeChanges: shutdown.data?.codeChanges ?? {},
    });
  }

  return sessions.sort((a, b) => a.startTime - b.startTime);
}

// ─── Aggregation ──────────────────────────────────────────────────────────────

function aggregate(sessions, modelFilter) {
  const byModel = {};
  let totalCredits = 0;
  let totalRequests = 0;

  for (const session of sessions) {
    for (const [modelId, metrics] of Object.entries(session.modelMetrics)) {
      if (modelFilter && modelId !== modelFilter) continue;

      const usage = metrics.usage ?? {};
      const credits = creditsForUsage(usage, modelId);

      if (!byModel[modelId]) {
        byModel[modelId] = { requests: 0, inputTokens: 0, outputTokens: 0, cacheReadTokens: 0, cacheWriteTokens: 0, credits: 0 };
      }

      byModel[modelId].requests       += metrics.requests?.count ?? 0;
      byModel[modelId].inputTokens    += usage.inputTokens      ?? 0;
      byModel[modelId].outputTokens   += usage.outputTokens     ?? 0;
      byModel[modelId].cacheReadTokens  += usage.cacheReadTokens  ?? 0;
      byModel[modelId].cacheWriteTokens += usage.cacheWriteTokens ?? 0;
      byModel[modelId].credits        += credits;

      totalCredits  += credits;
      totalRequests += metrics.requests?.count ?? 0;
    }
  }

  return { byModel, totalCredits, totalRequests };
}

// ─── Formatting ───────────────────────────────────────────────────────────────

const fmt  = (n)    => Math.round(n).toLocaleString('en-US');
const fmtC = (n)    => n.toFixed(1);
const fmtD = (n)    => `$${(n * 0.01).toFixed(2)}`;
const pad  = (s, w) => String(s).padStart(w);
const padL = (s, w) => String(s).padEnd(w);

function printTable(byModel, totalCredits, totalRequests) {
  const COL = { model: 22, req: 9, input: 14, cache: 12, write: 12, output: 13, credits: 9, usd: 8 };
  const header = [
    padL('MODEL',         COL.model),
    pad('REQUESTS',       COL.req),
    pad('INPUT TOKENS',   COL.input),
    pad('CACHE READ',     COL.cache),
    pad('CACHE WRITE',    COL.write),
    pad('OUTPUT TOKENS',  COL.output),
    pad('CREDITS',        COL.credits),
    pad('USD',            COL.usd),
  ].join('  ');

  const sep = '─'.repeat(header.length);
  console.log(header);
  console.log(sep);

  let totalInput = 0, totalOutput = 0, totalCacheRead = 0, totalCacheWrite = 0;

  const rows = Object.entries(byModel).sort((a, b) => b[1].credits - a[1].credits);
  for (const [modelId, m] of rows) {
    const knownPricing = PRICING[modelId] ? '' : ' *';
    console.log([
      padL(modelId + knownPricing, COL.model),
      pad(fmt(m.requests),          COL.req),
      pad(fmt(m.inputTokens),       COL.input),
      pad(fmt(m.cacheReadTokens),   COL.cache),
      pad(fmt(m.cacheWriteTokens),  COL.write),
      pad(fmt(m.outputTokens),      COL.output),
      pad(fmtC(m.credits),          COL.credits),
      pad(fmtD(m.credits),          COL.usd),
    ].join('  '));
    totalInput      += m.inputTokens;
    totalOutput     += m.outputTokens;
    totalCacheRead  += m.cacheReadTokens;
    totalCacheWrite += m.cacheWriteTokens;
  }

  console.log(sep);
  console.log([
    padL('TOTAL',                COL.model),
    pad(fmt(totalRequests),      COL.req),
    pad(fmt(totalInput),         COL.input),
    pad(fmt(totalCacheRead),     COL.cache),
    pad(fmt(totalCacheWrite),    COL.write),
    pad(fmt(totalOutput),        COL.output),
    pad(fmtC(totalCredits),      COL.credits),
    pad(fmtD(totalCredits),      COL.usd),
  ].join('  '));
}

function printSessions(sessions, modelFilter) {
  const COL = { date: 20, session: 38, model: 22, req: 9, credits: 9, usd: 8 };
  const header = [
    padL('DATE',    COL.date),
    padL('SESSION', COL.session),
    padL('MODEL',   COL.model),
    pad('REQUESTS', COL.req),
    pad('CREDITS',  COL.credits),
    pad('USD',      COL.usd),
  ].join('  ');
  console.log('\n' + header);
  console.log('─'.repeat(header.length));

  for (const session of sessions) {
    for (const [modelId, metrics] of Object.entries(session.modelMetrics)) {
      if (modelFilter && modelId !== modelFilter) continue;
      const usage = metrics.usage ?? {};
      const credits = creditsForUsage(usage, modelId);
      console.log([
        padL(session.startTime.toISOString().slice(0, 16).replace('T', ' '), COL.date),
        padL(session.sessionId, COL.session),
        padL(modelId,           COL.model),
        pad(fmt(metrics.requests?.count ?? 0), COL.req),
        pad(fmtC(credits),      COL.credits),
        pad(fmtD(credits),      COL.usd),
      ].join('  '));
    }
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

const { values: args } = parseArgs({
  options: {
    days:     { type: 'string',  default: '30'   },
    model:    { type: 'string',  default: ''     },
    sessions: { type: 'boolean', default: false  },
    json:     { type: 'boolean', default: false  },
    help:     { type: 'boolean', default: false  },
  },
  strict: false,
});

if (args.help) {
  console.log(`
copilot-credits — GitHub Copilot AI Credits usage tracker

Usage: copilot-credits [options]

Options:
  --days=N       Show last N days (default: 30)
  --model=NAME   Filter by model ID (e.g. claude-sonnet-4.6)
  --sessions     Show per-session breakdown below the summary
  --json         Output raw JSON instead of tables
  --help         Show this help

Data source: ~/.copilot/session-state/*/events.jsonl
Pricing:     https://docs.github.com/en/copilot/reference/copilot-billing/models-and-pricing
             * = estimated pricing (model not in official table)
  `);
  process.exit(0);
}

const days        = parseInt(args.days, 10) || 30;
const modelFilter = args.model || null;

const sessions = loadSessions(days);

if (sessions.length === 0) {
  console.error('No sessions found in ~/.copilot/session-state/');
  process.exit(1);
}

const { byModel, totalCredits, totalRequests } = aggregate(sessions, modelFilter);

if (args.json) {
  console.log(JSON.stringify({ sessions: sessions.length, totalCredits, totalRequests, byModel }, null, 2));
  process.exit(0);
}

const oldest = sessions[0].startTime.toISOString().slice(0, 10);
const newest = sessions[sessions.length - 1].startTime.toISOString().slice(0, 10);

console.log(`\nGitHub Copilot AI Credits Usage`);
console.log(`Period : ${oldest} → ${newest} (last ${days} days)`);
console.log(`Sessions: ${sessions.length}  |  Plan monthly allotment: Pro=1,500  Pro+=7,000  Max=20,000`);
console.log('');

printTable(byModel, totalCredits, totalRequests);

if (args.sessions) {
  printSessions(sessions, modelFilter);
}

console.log('');
