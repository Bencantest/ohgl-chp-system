import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const vercel = JSON.parse(readFileSync('vercel.json', 'utf8'));
const globalHeaders = vercel.headers.find(entry => entry.source === '/(.*)').headers;
const headerMap = new Map(globalHeaders.map(header => [header.key.toLowerCase(), header.value]));

test('deployment security headers are configured', () => {
  for (const header of [
    'strict-transport-security',
    'x-content-type-options',
    'x-frame-options',
    'referrer-policy',
    'permissions-policy',
    'content-security-policy',
    'cross-origin-opener-policy',
    'x-dns-prefetch-control',
  ]) {
    assert.ok(headerMap.has(header), `${header} missing`);
  }
});

test('CSP restricts core sources and Supabase connections', () => {
  const csp = headerMap.get('content-security-policy');
  assert.match(csp, /default-src 'self'/);
  assert.match(csp, /connect-src 'self' https:\/\/\*\.supabase\.co wss:\/\/\*\.supabase\.co/);
  assert.match(csp, /frame-ancestors 'none'/);
  assert.match(csp, /base-uri 'self'/);
  assert.match(csp, /form-action 'self'/);
});
