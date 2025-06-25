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
