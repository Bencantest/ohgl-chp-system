import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, extname, join, normalize } from 'node:path';

const required = [
  'README.md',
  'docs/README.md',
  'docs/architecture/SYSTEM_ARCHITECTURE.md',
  'docs/architecture/DOMAIN_MODEL.md',
  'docs/workflows/WORKFLOW_ENGINE.md',
  'docs/security/SECURITY_MODEL.md',
  'docs/database/DATABASE_GUIDELINES.md',
  'docs/api/API_CONTRACTS.md',
  'docs/workflows/WORKFLOWS.md',
  'docs/architecture/ROADMAP.md',
  'docs/architecture/CONTRIBUTING.md',
];
for (let i = 1; i <= 15; i++) {
  const n = String(i).padStart(3, '0');
  if (!readdirSync('docs/adr').some(name => name.startsWith(`ADR-${n}-`) && name.endsWith('.md'))) {
    required.push(`docs/adr/ADR-${n}-*.md`);
  }
}

const missing = required.filter(file => file.includes('*') ? true : !existsSync(file));
if (missing.length) {
  console.error('Missing required documentation files:');
  for (const file of missing) console.error(`- ${file}`);
  process.exit(1);
}

const mdFiles = [];
function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    const stat = statSync(path);
    if (stat.isDirectory()) walk(path);
    else if (extname(path) === '.md') mdFiles.push(path);
  }
}
walk('docs');
mdFiles.push('README.md');

let failed = false;
const linkRe = /\[[^\]]+\]\((?!https?:|mailto:|#)([^)]+)\)/g;
for (const file of mdFiles) {
  const text = readFileSync(file, 'utf8');
  const fences = [...text.matchAll(/```mermaid/g)].length;
  const fenceEnds = [...text.matchAll(/```/g)].length;
  if (fences && fenceEnds % 2 !== 0) {
    console.error(`Unbalanced markdown fences in ${file}`);
    failed = true;
  }
  for (const match of text.matchAll(linkRe)) {
    const target = match[1].split('#')[0].trim();
    if (!target) continue;
    const resolved = normalize(join(dirname(file), target));
    if (!existsSync(resolved)) {
      console.error(`Broken local link in ${file}: ${match[1]}`);
      failed = true;
    }
  }
}
if (failed) process.exit(1);
console.log(`Validated ${mdFiles.length} markdown files.`);
