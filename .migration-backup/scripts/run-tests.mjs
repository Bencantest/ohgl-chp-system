import { readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const roots = process.argv.slice(2);
const searchRoots = roots.length ? roots : ['tests'];
const files = [];
function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    const stat = statSync(path);
    if (stat.isDirectory()) walk(path);
    else if (path.endsWith('.test.mjs')) files.push(path);
  }
}
for (const root of searchRoots) walk(root);
for (const file of files.sort()) {
  await import(`../${file.replace(/\\/g, '/')}`);
}
console.log(`Loaded ${files.length} test files.`);
