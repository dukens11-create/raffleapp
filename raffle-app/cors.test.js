/**
 * Unit tests for CORS origin validation logic.
 *
 * Run with: node cors.test.js
 */
'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');

// ---------------------------------------------------------------------------
// Replicate the origin-check logic from server.js so we can unit-test it
// without booting the whole Express app.
// ---------------------------------------------------------------------------
function buildAllowedOrigins(envValue) {
  return envValue
    ? envValue.split(',').map(o => o.trim())
    : [
        'https://www.grategenyen.com',
        'https://grategenyen.com',
        'https://raffleapp-e4ev.onrender.com',
        'https://www.enejipamticket.com',
        'https://enejipamticket.com',
      ];
}

function isOriginAllowed(origin, allowedOrigins) {
  // No origin header (mobile apps, Postman, curl, etc.)
  if (!origin) return true;

  if (allowedOrigins.includes(origin)) return true;

  // Allow any *.onrender.com subdomain (HTTPS only)
  if (origin.startsWith('https://') && origin.endsWith('.onrender.com')) return true;

  return false;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

const defaultOrigins = buildAllowedOrigins(undefined);

test('allows https://www.enejipamticket.com (hardcoded default)', () => {
  assert.equal(isOriginAllowed('https://www.enejipamticket.com', defaultOrigins), true);
});

test('allows https://enejipamticket.com (hardcoded default)', () => {
  assert.equal(isOriginAllowed('https://enejipamticket.com', defaultOrigins), true);
});

test('allows existing origins - www.grategenyen.com', () => {
  assert.equal(isOriginAllowed('https://www.grategenyen.com', defaultOrigins), true);
});

test('allows existing origins - grategenyen.com', () => {
  assert.equal(isOriginAllowed('https://grategenyen.com', defaultOrigins), true);
});

test('allows existing origins - raffleapp-e4ev.onrender.com', () => {
  assert.equal(isOriginAllowed('https://raffleapp-e4ev.onrender.com', defaultOrigins), true);
});

test('allows any *.onrender.com subdomain (HTTPS)', () => {
  assert.equal(isOriginAllowed('https://my-app-xyz.onrender.com', defaultOrigins), true);
});

test('allows requests with no origin (mobile / Postman)', () => {
  assert.equal(isOriginAllowed(undefined, defaultOrigins), true);
  assert.equal(isOriginAllowed(null, defaultOrigins), true);
});

test('rejects unknown origins', () => {
  assert.equal(isOriginAllowed('https://evil.example.com', defaultOrigins), false);
});

test('rejects http (non-HTTPS) onrender.com requests', () => {
  assert.equal(isOriginAllowed('http://my-app.onrender.com', defaultOrigins), false);
});

test('respects ALLOWED_ORIGINS env var when set', () => {
  const envOrigins = buildAllowedOrigins('https://custom.example.com,https://another.example.com');
  assert.equal(isOriginAllowed('https://custom.example.com', envOrigins), true);
  assert.equal(isOriginAllowed('https://another.example.com', envOrigins), true);
  // Hardcoded defaults are NOT present when env var overrides
  assert.equal(isOriginAllowed('https://www.grategenyen.com', envOrigins), false);
});
