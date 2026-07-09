import test from 'node:test';
import assert from 'node:assert/strict';
import { h, sanitizeText } from '../../src/utils/sanitize.js';

test('h escapes HTML-sensitive characters', () => {
  assert.equal(h(`<script>'"&</script>`), '&lt;script&gt;&#39;&quot;&amp;&lt;/script&gt;');
});

test('sanitizeText trims, removes control characters, and enforces max length', () => {
  assert.equal(sanitizeText('  A\u0000B\nC  ', 2), 'AB');
});

test('sanitizeText converts nullish values to empty string', () => {
  assert.equal(sanitizeText(null), '');
  assert.equal(sanitizeText(undefined), '');
});
