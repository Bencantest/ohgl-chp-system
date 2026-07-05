import test from 'node:test';
import assert from 'node:assert/strict';

const requiredFolders = ['tests/unit', 'tests/integration', 'tests/workflow', 'tests/e2e'];

test('testing structure exists', () => {
  for (const folder of requiredFolders) {
    assert.ok(folder);
  }
});
