const assert = require('assert');
const { isValidId } = require('./index');


try {
  assert.ok(isValidId('0123456789abcdef0123456789abcdef'));
  assert.ok(!isValidId('nothex'));
  assert.ok(!isValidId('123'));
  console.log('All tests passed');
} catch (err) {
  console.error('Test failed');
  console.error(err);
  process.exit(1);
}

// Valid 32-character hex string
assert.strictEqual(
  isValidId('0123456789abcdef0123456789abcdef'),
  true,
  'Expected valid ID to return true'
);

// Invalid: too short
assert.strictEqual(
  isValidId('0123456789abcdef0123456789abcde'),
  false,
  'Expected short ID to return false'
);

// Invalid: contains non-hex characters
assert.strictEqual(
  isValidId('0123456789abcdef0123456789abcdeg'),
  false,
  'Expected non-hex ID to return false'
);

// Invalid: undefined value
assert.strictEqual(
  isValidId(undefined),
  false,
  'Expected undefined ID to return false'
);

console.log('All tests passed.');
