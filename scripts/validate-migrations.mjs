import { readdirSync, readFileSync } from 'node:fs';

const files = readdirSync('supabase/migrations').filter(name => name.endsWith('.sql')).sort();
let failed = false;
const seen = new Set();
const byDate = new Map();
for (const file of files) {
  if (seen.has(file)) {
    console.error(`Duplicate migration filename: ${file}`);
    failed = true;
  }
  seen.add(file);
  const match = file.match(/^(\d{8})_(\d{6})_[a-z0-9_]+\.sql$/);
  if (!match) {
    console.error(`Invalid migration name: ${file}`);
    failed = true;
    continue;
  }
  const key = match[1];
  const seq = Number(match[2]);
  if (!byDate.has(key)) byDate.set(key, []);
  byDate.get(key).push(seq);
  const sql = readFileSync(`supabase/migrations/${file}`, 'utf8');
  if (/DROP\s+TABLE\s+(?!IF\s+EXISTS)/i.test(sql)) {
    console.error(`Potential unsafe DROP TABLE without IF EXISTS in ${file}`);
    failed = true;
  }
}
for (const [date, seqs] of byDate) {
  const sorted = [...seqs].sort((a, b) => a - b);
  for (let i = 1; i < sorted.length; i++) {
    if (sorted[i] <= sorted[i - 1]) {
      console.error(`Non-increasing sequence for ${date}`);
      failed = true;
    }
  }
}
if (failed) process.exit(1);
console.log(`Validated ${files.length} migrations.`);
