const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../src/app');
const prisma = require('../src/config/db');

// Guard: menolak jalan tanpa TEST_DATABASE_URL agar tidak menghapus data
// pada database development. Set TEST_DATABASE_URL ke database khusus test.
const HAS_TEST_DB = Boolean(process.env.TEST_DATABASE_URL);

let counter = 0;
const uniqueUser = () => {
  counter += 1;
  return {
    email: `user${counter}@test.local`,
    username: `user${counter}`,
    password: 'rahasia12',
  };
};

const registerUser = async (overrides = {}) => {
  const body = { ...uniqueUser(), ...overrides };
  const res = await request(app).post('/api/auth/register').send(body);
  return { res, body };
};

const describeDb = HAS_TEST_DB ? describe : describe.skip;

describeDb('Auth API (integration)', () => {
  beforeAll(() => {
    if (!HAS_TEST_DB) return;
    // eslint-disable-next-line no-console
    console.log('Menjalankan test DB terhadap:', process.env.DATABASE_URL);
  });

  beforeEach(async () => {
    // Cascade menghapus refresh_tokens, posts, comments milik user.
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.user.deleteMany();
    await prisma.$disconnect();
  });

  describe('POST /register', () => {
    it('menolak password lemah (< 8 karakter)', async () => {
      const { res } = await registerUser({ password: 'abc' });
      expect(res.status).toBe(400);
      expect(res.body.error).toMatch(/minimal 8 karakter/i);
    });

    it('menolak password tanpa angka', async () => {
      const { res } = await registerUser({ password: 'abcdefgh' });
      expect(res.status).toBe(400);
      expect(res.body.error).toMatch(/huruf dan.*angka/i);
    });

    it('menolak email tidak valid', async () => {
      const { res } = await registerUser({ email: 'bukan-email' });
      expect(res.status).toBe(400);
      expect(res.body.error).toMatch(/email tidak valid/i);
    });

    it('berhasil register dan tidak membocorkan password hash', async () => {
      const { res } = await registerUser();
      expect(res.status).toBe(201);
      expect(res.body.accessToken).toBeDefined();
      expect(res.body.refreshToken).toBeDefined();
      expect(res.body.user).toBeDefined();
      expect(res.body.user.password).toBeUndefined();
    });

    it('menolak email duplikat dengan 409', async () => {
      const { body } = await registerUser();
      const res = await request(app).post('/api/auth/register').send(body);
      expect(res.status).toBe(409);
    });
  });

  describe('POST /login', () => {
    it('menolak kredensial salah dengan 401', async () => {
      const { body } = await registerUser();
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: body.email, password: 'salahsemua9' });
      expect(res.status).toBe(401);
    });

    it('menolak email tidak dikenal dengan 401 (anti user-enumeration)', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'nobody@test.local', password: 'rahasia12' });
      expect(res.status).toBe(401);
      expect(res.body.error).toMatch(/email atau password salah/i);
    });

    it('berhasil login dengan kredensial benar', async () => {
      const { body } = await registerUser();
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: body.email, password: body.password });
      expect(res.status).toBe(200);
      expect(res.body.accessToken).toBeDefined();
      expect(res.body.refreshToken).toBeDefined();
    });
  });

  describe('POST /refresh (rotation + reuse detection)', () => {
    it('merotasi token: token baru diterbitkan, token lama dicabut', async () => {
      const { res: reg } = await registerUser();
      const oldRefresh = reg.body.refreshToken;

      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: oldRefresh });

      expect(res.status).toBe(200);
      expect(res.body.refreshToken).toBeDefined();
      expect(res.body.refreshToken).not.toBe(oldRefresh);

      // Baris token lama harus tertandai revoked di DB.
      const { jti } = jwt.decode(oldRefresh);
      const oldRow = await prisma.refreshToken.findUnique({ where: { id: jti } });
      expect(oldRow.revoked_at).not.toBeNull();
    });

    it('reuse token yang sudah dirotasi mencabut SEMUA sesi user', async () => {
      const { res: reg } = await registerUser();
      const oldRefresh = reg.body.refreshToken;

      // Rotasi sekali → dapat token baru.
      const rotated = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: oldRefresh });
      const newRefresh = rotated.body.refreshToken;

      // Pakai lagi token LAMA (reuse) → harus 401.
      const reuse = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: oldRefresh });
      expect(reuse.status).toBe(401);

      // Efek samping: token baru pun ikut dicabut (semua sesi mati).
      const afterReuse = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: newRefresh });
      expect(afterReuse.status).toBe(401);
    });
  });

  describe('POST /logout', () => {
    it('mencabut satu token; refresh setelahnya gagal 401', async () => {
      const { res: reg } = await registerUser();
      const { accessToken, refreshToken } = reg.body;

      const out = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ refreshToken });
      expect(out.status).toBe(200);

      const res = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken });
      expect(res.status).toBe(401);
    });

    it('logout all mencabut seluruh sesi user', async () => {
      const { body } = await registerUser();

      // Buat 2 sesi via login berulang.
      const s1 = await request(app)
        .post('/api/auth/login')
        .send({ email: body.email, password: body.password });
      const s2 = await request(app)
        .post('/api/auth/login')
        .send({ email: body.email, password: body.password });

      await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${s1.body.accessToken}`)
        .send({ all: true });

      // Kedua refresh token harus tidak berlaku lagi.
      const r1 = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: s1.body.refreshToken });
      const r2 = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: s2.body.refreshToken });
      expect(r1.status).toBe(401);
      expect(r2.status).toBe(401);
    });

    it('menolak logout tanpa access token (401)', async () => {
      const res = await request(app).post('/api/auth/logout').send({ all: true });
      expect(res.status).toBe(401);
    });
  });
});
