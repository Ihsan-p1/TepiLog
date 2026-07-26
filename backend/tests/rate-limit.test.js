const express = require('express');
const request = require('supertest');
const { createAuthLimiter } = require('../src/middleware/rateLimiters');

// Uji perilaku limiter secara terisolasi (tanpa DB) dengan limit rendah
// supaya deterministik dan cepat.
describe('authLimiter', () => {
  // skipSuccessfulRequests aktif, jadi endpoint sengaja mengembalikan 401
  // agar setiap percobaan benar-benar dihitung limiter.
  const buildApp = (max) => {
    const app = express();
    app.set('trust proxy', 1);
    app.use(createAuthLimiter(max));
    app.post('/login', (req, res) => res.status(401).json({ error: 'salah' }));
    return app;
  };

  it('memblokir dengan 429 setelah melewati batas percobaan gagal', async () => {
    const app = buildApp(2); // izinkan 2 percobaan gagal

    const r1 = await request(app).post('/login');
    const r2 = await request(app).post('/login');
    const r3 = await request(app).post('/login');

    expect(r1.status).toBe(401);
    expect(r2.status).toBe(401);
    expect(r3.status).toBe(429);
    expect(r3.body.error).toMatch(/terlalu banyak percobaan/i);
  });
});
