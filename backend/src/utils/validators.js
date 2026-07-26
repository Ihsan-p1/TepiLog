// Reusable input validators for auth-related endpoints.

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Validate an email address.
 * @returns {string|null} error message, or null if valid
 */
const validateEmail = (email) => {
  if (typeof email !== 'string' || !EMAIL_REGEX.test(email)) {
    return 'Format email tidak valid';
  }
  return null;
};

/**
 * Validate password strength.
 * Policy: minimal 8 karakter, mengandung minimal 1 huruf dan 1 angka.
 * @returns {string|null} error message, or null if valid
 */
const validatePassword = (password) => {
  if (typeof password !== 'string' || password.length < 8) {
    return 'Password minimal 8 karakter';
  }
  if (!/[A-Za-z]/.test(password) || !/[0-9]/.test(password)) {
    return 'Password harus mengandung minimal 1 huruf dan 1 angka';
  }
  return null;
};

module.exports = { validateEmail, validatePassword };
