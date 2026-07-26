// Dijalankan Jest sebelum modul test di-import (lihat jest.config.js > setupFiles).
// Menyiapkan environment untuk test dan MELINDUNGI database dev agar tidak terhapus.

process.env.NODE_ENV = 'test';

// Secret dummy khusus test (boleh dioverride dari environment CI).
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-access-secret';
process.env.JWT_REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET || 'test-refresh-secret';
process.env.JWT_EXPIRES_IN = '1h';
process.env.JWT_REFRESH_EXPIRES_IN = '7d';

// Naikkan batas rate limit agar test fungsional tidak ikut terblok.
// (Rate limiter diuji terpisah dengan limit rendah di rate-limit.test.js.)
process.env.AUTH_RATE_LIMIT_MAX = '100000';
process.env.GENERAL_RATE_LIMIT_MAX = '100000';

// Pakai database khusus test bila disediakan. Ini mencegah test menghapus
// data pada database development. Tes yang menyentuh DB akan menolak jalan
// bila TEST_DATABASE_URL tidak diset (lihat guard di auth.test.js).
if (process.env.TEST_DATABASE_URL) {
  process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
}
