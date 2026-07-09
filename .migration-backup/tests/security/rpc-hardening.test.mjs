import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const migrationFiles = readdirSync('supabase/migrations').filter(file => file.endsWith('.sql'));
const sql = migrationFiles.map(file => readFileSync(join('supabase/migrations', file), 'utf8')).join('\n');

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

test('SECURITY DEFINER functions set an explicit public search path', () => {
  const functionBlocks = sql.split(/CREATE OR REPLACE FUNCTION/i).slice(1);
  const offenders = [];
  for (const block of functionBlocks) {
    if (/SECURITY DEFINER/i.test(block) && !/SET\s+search_path\s*=\s*public/i.test(block)) {
      const signature = block.split('\n')[0].trim();
      const name = signature.split('(')[0].trim();
      const alterPattern = new RegExp(`ALTER FUNCTION\\s+public\\.${escapeRegExp(name)}\\s*\\([^)]*\\)\\s+SET\\s+search_path\\s*=\\s*public`, 'i');
      if (!alterPattern.test(sql)) offenders.push(signature);
    }
  }
  assert.deepEqual(offenders, []);
});

test('public execute is revoked before authenticated grants for sensitive RPC families', () => {
  for (const fn of ['approve_user_secure', 'reject_user_secure', 'get_available_referral_actions']) {
    assert.match(sql, new RegExp(`REVOKE EXECUTE ON FUNCTION ${fn}`), `${fn} revoke missing`);
    assert.match(sql, new RegExp(`GRANT EXECUTE ON FUNCTION ${fn}`), `${fn} grant missing`);
  }
});
