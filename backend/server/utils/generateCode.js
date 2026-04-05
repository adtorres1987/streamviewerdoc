'use strict';

const ALPHANUMERIC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/**
 * Generates a 6-digit numeric activation code.
 * Stored in DB as a string like "CODE:TIMESTAMP" to track expiry
 * without adding a new column to the schema.
 *
 * The format is:  "<6-digit-code>:<unix-ms-expiry>"
 * Example:        "483920:1712012345678"
 *
 * @returns {{ raw: string, stored: string }}
 *   raw    — the 6-digit code to send to the user
 *   stored — the composite value to write to users.activation_code
 */
function generateActivationCode() {
  const digits = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = Date.now() + 24 * 60 * 60 * 1000; // 24 hours from now
  return {
    raw: digits,
    stored: `${digits}:${expiresAt}`,
  };
}

/**
 * Parses a stored activation_code value and validates it.
 * @param {string | null} stored - The value from users.activation_code
 * @param {string} inputCode - The code the user submitted
 * @returns {{ valid: boolean, expired: boolean }}
 */
function validateActivationCode(stored, inputCode) {
  if (!stored) return { valid: false, expired: false };

  const [code, expiryMs] = stored.split(':');

  if (code !== inputCode) return { valid: false, expired: false };

  const expired = Date.now() > parseInt(expiryMs, 10);
  if (expired) return { valid: false, expired: true };

  return { valid: true, expired: false };
}

/**
 * Generates a 6-character alphanumeric room code (uppercase).
 * @returns {string}
 */
function generateRoomCode() {
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += ALPHANUMERIC.charAt(Math.floor(Math.random() * ALPHANUMERIC.length));
  }
  return code;
}

module.exports = { generateActivationCode, validateActivationCode, generateRoomCode };
