const rateLimit = require('express-rate-limit');

const WINDOW_MS = 15 * 60 * 1000; // 15 menit

// Global limiter — melindungi seluruh API dari abuse / flooding.
const createGeneralLimiter = (
  max = Number(process.env.GENERAL_RATE_LIMIT_MAX) || 300
) =>
  rateLimit({
    windowMs: WINDOW_MS,
    max,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Terlalu banyak request, coba lagi nanti' },
  });

// Limiter ketat khusus endpoint auth — mencegah brute-force login/register.
const createAuthLimiter = (
  max = Number(process.env.AUTH_RATE_LIMIT_MAX) || 10
) =>
  rateLimit({
    windowMs: WINDOW_MS,
    max,
    standardHeaders: true,
    legacyHeaders: false,
    // Jangan hitung request yang sukses agar user sah tidak terkunci.
    skipSuccessfulRequests: true,
    message: { error: 'Terlalu banyak percobaan, coba lagi dalam beberapa menit' },
  });

module.exports = {
  generalLimiter: createGeneralLimiter(),
  authLimiter: createAuthLimiter(),
  createGeneralLimiter,
  createAuthLimiter,
};
