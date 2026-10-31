'use strict';

const USERS = [
  { id: '11111111-1111-1111-1111-111111111111', name: 'Ada', email: 'ada@example.com' },
  { id: '22222222-2222-2222-2222-222222222222', name: 'Grace', email: 'grace@example.com' },
  { id: '33333333-3333-3333-3333-333333333333', name: 'Linus', email: 'linus@example.com' },
];

function parsePagination(query = {}) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const size = Math.min(100, Math.max(1, parseInt(query.size, 10) || 20));
  return { page, size };
}

function listUsers(query = {}) {
  const { page, size } = parsePagination(query);
  const start = (page - 1) * size;
  const items = USERS.slice(start, start + size);
  return { items, page, size };
}

module.exports = { parsePagination, listUsers, USERS };
