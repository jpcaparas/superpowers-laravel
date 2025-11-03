/**
 * Validate skills structure and plugin conventions.
 *
 * What this checks:
 * - skills/ contains only one-level skill directories.
 * - Each skill directory contains exactly one file: SKILL.md.
 * - SKILL.md has frontmatter delimited by '---' with:
 *   - name: must exist and start with 'laravel:'
 *   - description: must exist and be non-empty
 * - No nested files or directories exist under skills/**.
 * - .claude-plugin/plugin.json has minimal required fields.
 * - commands/*.md have frontmatter with a description field.
 *
 * Usage (CI):
 *   npx tsx scripts/validate_skills.ts
 */

import * as fs from 'fs';
import * as path from 'path';

const repoRoot = process.cwd();
const skillsDir = path.join(repoRoot, 'skills');
const pluginJsonPath = path.join(repoRoot, '.claude-plugin', 'plugin.json');
const commandsDir = path.join(repoRoot, 'commands');

function fail(msg: string): void {
  console.error(`ERROR: ${msg}`);
  process.exitCode = 1;
}

function ok(msg: string): void {
  console.log(`OK: ${msg}`);
}

function assert(condition: unknown, message: string): void {
  if (!condition) fail(message);
}

/** Validate the structure of the skills directory and each skill's frontmatter. */
function validateSkills(): void {
  if (!fs.existsSync(skillsDir)) {
    fail('skills/ directory not found');
    return;
  }

  const entries = fs.readdirSync(skillsDir, { withFileTypes: true });
  for (const e of entries) {
    if (!e.isDirectory()) {
      fail(`skills/ must contain only directories; found file: ${e.name}`);
      continue;
    }
    const skillPath = path.join(skillsDir, e.name);
    const sub = fs.readdirSync(skillPath, { withFileTypes: true });
    const skillMd = sub.find((d) => d.isFile() && d.name === 'SKILL.md');
    assert(!!skillMd, `Missing SKILL.md in ${path.relative(repoRoot, skillPath)}`);

    // Ensure only SKILL.md exists
    const extra = sub.filter((d) => !(d.isFile() && d.name === 'SKILL.md'));
    if (extra.length) {
      fail(`Only SKILL.md allowed in ${e.name}; found: ${extra.map((d) => d.name).join(', ')}`);
    }

    // Validate frontmatter
    const mdPath = path.join(skillPath, 'SKILL.md');
    const text = fs.readFileSync(mdPath, 'utf8');
    const lines = text.split(/\r?\n/);
    assert(lines[0]?.trim() === '---', `${e.name}/SKILL.md must start with frontmatter '---'`);
    const fmEnd = lines.indexOf('---', 1);
    assert(fmEnd > 0, `${e.name}/SKILL.md frontmatter must be closed with '---'`);
    const front = lines.slice(1, fmEnd).join('\n');
    const nameMatch = front.match(/\bname:\s*(.+)/);
    const descMatch = front.match(/\bdescription:\s*(.+)/);
    assert(!!nameMatch, `${e.name}/SKILL.md missing 'name:' in frontmatter`);
    assert(!!descMatch, `${e.name}/SKILL.md missing 'description:' in frontmatter`);
    const nameVal = (nameMatch?.[1] || '').trim();
    assert(nameVal.startsWith('laravel:'), `${e.name}/SKILL.md name must start with 'laravel:' (got: ${nameVal || 'empty'})`);
  }
  ok('skills structure and frontmatter look good');
}

/** Validate minimal plugin manifest conventions. */
function validatePluginJson(): void {
  if (!fs.existsSync(pluginJsonPath)) {
    fail('.claude-plugin/plugin.json not found');
    return;
  }
  const raw = fs.readFileSync(pluginJsonPath, 'utf8');
  let json: any;
  try { json = JSON.parse(raw); } catch {
    fail(`Invalid JSON: ${pluginJsonPath}`);
    return;
  }
  for (const key of ['name', 'description', 'version']) {
    assert(json[key], `.claude-plugin/plugin.json missing '${key}'`);
  }
  assert(typeof json.name === 'string' && json.name.length > 0, 'plugin name must be a non-empty string');
  ok('plugin.json minimal conventions satisfied');
}

/** Validate command frontmatter includes a description. */
function validateCommands(): void {
  if (!fs.existsSync(commandsDir)) {
    fail('commands/ directory not found');
    return;
  }
  const files = fs.readdirSync(commandsDir).filter((f) => f.endsWith('.md'));
  for (const f of files) {
    const p = path.join(commandsDir, f);
    const text = fs.readFileSync(p, 'utf8');
    const lines = text.split(/\r?\n/);
    assert(lines[0]?.trim() === '---', `${f} must start with frontmatter '---'`);
    const fmEnd = lines.indexOf('---', 1);
    assert(fmEnd > 0, `${f} frontmatter must be closed with '---'`);
    const front = lines.slice(1, fmEnd).join('\n');
    const descMatch = front.match(/\bdescription:\s*(.+)/);
    assert(!!descMatch, `${f} missing 'description:' in frontmatter`);
  }
  ok('commands frontmatter validated');
}

try {
  validateSkills();
  validatePluginJson();
  validateCommands();
} catch (e: any) {
  fail(`Unexpected validator error: ${e?.message || String(e)}`);
}

process.exit(process.exitCode || 0);

