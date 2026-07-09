#!/usr/bin/env node
import { existsSync, readFileSync, statSync } from 'node:fs';

const requiredFiles = [
  'index.html',
  'config.example.js',
  'vercel.json',
  'src/main.js',
  'src/services/supabaseClient.js',
  'src/services/authService.js',
  'src/pages/settings.js',
];

let failed = false;
for (const file of requiredFiles) {
  if (!existsSync(file)) {
    console.error(`Missing deploy artifact: ${file}`);
    failed = true;
    continue;
  }
  if (statSync(file).size === 0) {
    console.error(`Empty deploy artifact: ${file}`);
    failed = true;
  }
}

const index = existsSync('index.html') ? readFileSync('index.html', 'utf8') : '';
for (const expected of ['src/main.js', 'config.js']) {
  if (!index.includes(expected)) {
    console.error(`index.html does not reference expected deployment asset: ${expected}`);
    failed = true;
  }
}

const configText = ['config.example.js', 'config.js']
  .filter(file => existsSync(file))
  .map(file => readFileSync(file, 'utf8'))
  .join('\n');
for (const expected of ['OHGL_SUPABASE_URL', 'OHGL_SUPABASE_ANON_KEY']) {
  if (!configText.includes(expected)) {
    console.error(`Config files do not reference expected environment key: ${expected}`);
    failed = true;
  }
}

const vercel = existsSync('vercel.json') ? readFileSync('vercel.json', 'utf8') : '';
for (const expected of ['Strict-Transport-Security', 'Content-Security-Policy', '@vercel/static']) {
  if (!vercel.includes(expected)) {
    console.error(`vercel.json missing expected deployment setting: ${expected}`);
    failed = true;
  }
}

if (failed) process.exit(1);
console.log('Static deployment artifact verification passed.');