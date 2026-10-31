'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { listUsers, parsePagination } = require('./users.js');

describe('users', () => {
  it('defaults page and size', () => {
    assert.deepEqual(parsePagination({}), { page: 1, size: 20 });
  });

  it('paginates user list', () => {
    const result = listUsers({ page: '1', size: '2' });
    assert.equal(result.items.length, 2);
    assert.equal(result.page, 1);
    assert.equal(result.size, 2);
    assert.equal(result.items[0].email, 'ada@example.com');
  });

  it('returns empty on out-of-range page', () => {
    const result = listUsers({ page: '99', size: '10' });
    assert.deepEqual(result.items, []);
  });
});
