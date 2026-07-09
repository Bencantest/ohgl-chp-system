import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

function readAllFiles(dir, predicate, acc = []) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory() && entry.name !== '.git') readAllFiles(path, predicate, acc);
    else if (entry.isFile() && predicate(path)) acc.push(path);
  }
  return acc;
}

test('frontend configuration does not include Supabase service-role key material', () => {
  const files = ['config.js', 'config.example.js', 'src/services/supabaseClient.js'];
  for (const file of files) {
    const text = readFileSync(file, 'utf8');
    assert.doesNotMatch(text, /"role"\s*:\s*"service_role"|SERVICE_ROLE_KEY|SUPABASE_SERVICE_ROLE/i, `${file} appears to contain service role key material`);
  }
});

test('gitignore excludes local env and deployment-specific config variants', () => {
  const text = readFileSync('.gitignore', 'utf8');
  for (const pattern of ['.env', '.env.*', '!.env.example', 'config.local.js', 'config.production.js', 'config.staging.js']) {
    assert.ok(text.split(/\r?\n/).includes(pattern), `${pattern} missing`);
  }
});

test('repository docs acknowledge public anon key and prohibit service role keys in frontend', () => {
  const docs = readAllFiles('docs', path => path.endsWith('.md'));
  const combined = docs.map(file => readFileSync(file, 'utf8')).join('\n');
  assert.match(combined, /service-role keys? never appear|never place service-role keys|service-role keys in frontend/i);
});
