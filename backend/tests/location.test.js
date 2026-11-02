const request = require('supertest');
const app = require('../src/app');
const prisma = require('../src/config/db');

// Same guard as auth.test.js: the DB suite runs only against TEST_DATABASE_URL.
const HAS_TEST_DB = Boolean(process.env.TEST_DATABASE_URL);
const describeDb = HAS_TEST_DB ? describe : describe.skip;

describeDb('GET /api/locations (integration)', () => {
  beforeEach(async () => {
    await prisma.location.deleteMany();
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.location.deleteMany();
    await prisma.user.deleteMany();
    await prisma.$disconnect();
  });

  it('returns the newest photo as cover and the capture date span', async () => {
    const user = await prisma.user.create({
      data: { email: 'peta@test.local', username: 'peta', password: 'x' },
    });
    const location = await prisma.location.create({
      data: { name: 'Gunung Prau', latitude: -7.1867, longitude: 109.9228, post_count: 2 },
    });
    const post = (url, takenAt) => ({
      user_id: user.id,
      location_id: location.id,
      media_url: url,
      media_type: 'photo',
      taken_at: new Date(takenAt),
    });
    await prisma.post.createMany({
      data: [
        post('https://img/old.jpg', '2019-08-17T22:00:00Z'),
        post('https://img/new.jpg', '2025-05-27T22:15:00Z'),
      ],
    });

    const res = await request(app)
      .get('/api/locations')
      .query({ lat: -7.1867, lng: 109.9228 });

    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].cover_url).toBe('https://img/new.jpg');
    expect(new Date(res.body[0].first_taken_at).toISOString()).toBe('2019-08-17T22:00:00.000Z');
    expect(new Date(res.body[0].last_taken_at).toISOString()).toBe('2025-05-27T22:15:00.000Z');
  });

  it('returns null cover for a place with no photos', async () => {
    await prisma.location.create({
      data: { name: 'Kosong', latitude: -7.1867, longitude: 109.9228 },
    });

    const res = await request(app)
      .get('/api/locations')
      .query({ lat: -7.1867, lng: 109.9228 });

    expect(res.status).toBe(200);
    expect(res.body[0].cover_url).toBeNull();
    expect(res.body[0].first_taken_at).toBeNull();
  });
});
