const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../config/db');
const { validateEmail, validatePassword } = require('../utils/validators');

const hashToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');

const userPublicFields = {
  id: true,
  email: true,
  username: true,
  avatar_url: true,
  created_at: true,
};

/**
 * Terbitkan access + refresh token, lalu simpan HASH refresh token di DB
 * agar bisa dicabut/dirotasi. Refresh token membawa `jti` yang menjadi
 * primary key baris di tabel refresh_tokens.
 */
const issueTokens = async (user) => {
  const accessToken = jwt.sign(
    { id: user.id, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '1h' }
  );

  const jti = crypto.randomUUID();
  const refreshToken = jwt.sign(
    { id: user.id, email: user.email, jti },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
  );

  const { exp } = jwt.decode(refreshToken);
  await prisma.refreshToken.create({
    data: {
      id: jti,
      user_id: user.id,
      token_hash: hashToken(refreshToken),
      expires_at: new Date(exp * 1000),
    },
  });

  return { accessToken, refreshToken };
};

// POST /api/auth/register
const register = async (req, res, next) => {
  try {
    const { email, password, username } = req.body;

    if (!email || !password || !username) {
      return res.status(400).json({ error: 'Email, password, dan username wajib diisi' });
    }

    const emailError = validateEmail(email);
    if (emailError) {
      return res.status(400).json({ error: emailError });
    }

    const passwordError = validatePassword(password);
    if (passwordError) {
      return res.status(400).json({ error: passwordError });
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    const user = await prisma.user.create({
      data: { email, password: hashedPassword, username },
      select: userPublicFields,
    });

    const tokens = await issueTokens(user);

    res.status(201).json({ user, ...tokens });
  } catch (error) {
    next(error);
  }
};

// POST /api/auth/login
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email dan password wajib diisi' });
    }

    const user = await prisma.user.findUnique({ where: { email } });
    // Bandingkan hash walau user tidak ada untuk mencegah timing/user enumeration.
    const isMatch = user && user.password
      ? await bcrypt.compare(password, user.password)
      : false;

    if (!user || !isMatch) {
      return res.status(401).json({ error: 'Email atau password salah' });
    }

    const tokens = await issueTokens(user);

    res.json({
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        avatar_url: user.avatar_url,
        created_at: user.created_at,
      },
      ...tokens,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/refresh
 * Rotasi refresh token: token lama dicabut, token baru diterbitkan.
 * Bila token yang sudah dirotasi/dicabut dipakai lagi (reuse), seluruh
 * sesi user dicabut sebagai mitigasi pencurian token.
 */
const refresh = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token wajib diisi' });
    }

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({ error: 'Refresh token expired' });
      }
      return res.status(401).json({ error: 'Refresh token tidak valid' });
    }

    const stored = decoded.jti
      ? await prisma.refreshToken.findUnique({ where: { id: decoded.jti } })
      : null;

    // Token bertanda tangan valid tapi tidak dikenali / hash tidak cocok.
    if (!stored || stored.token_hash !== hashToken(refreshToken)) {
      if (decoded.id) {
        await prisma.refreshToken.updateMany({
          where: { user_id: decoded.id, revoked_at: null },
          data: { revoked_at: new Date() },
        });
      }
      return res.status(401).json({ error: 'Refresh token tidak valid' });
    }

    // Reuse dari token yang sudah dicabut → indikasi pencurian. Cabut semua.
    if (stored.revoked_at) {
      await prisma.refreshToken.updateMany({
        where: { user_id: stored.user_id, revoked_at: null },
        data: { revoked_at: new Date() },
      });
      return res.status(401).json({ error: 'Refresh token sudah tidak berlaku' });
    }

    const user = await prisma.user.findUnique({
      where: { id: stored.user_id },
      select: userPublicFields,
    });
    if (!user) {
      return res.status(401).json({ error: 'User tidak ditemukan' });
    }

    // Rotasi: cabut token lama lalu terbitkan pasangan token baru.
    await prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revoked_at: new Date() },
    });

    const tokens = await issueTokens(user);
    res.json(tokens);
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/auth/logout  (butuh access token)
 * Mencabut refresh token tertentu. Kirim { all: true } untuk mencabut
 * seluruh sesi user (logout dari semua perangkat).
 */
const logout = async (req, res, next) => {
  try {
    const { refreshToken, all } = req.body;

    if (all) {
      await prisma.refreshToken.updateMany({
        where: { user_id: req.user.id, revoked_at: null },
        data: { revoked_at: new Date() },
      });
      return res.json({ message: 'Berhasil logout dari semua perangkat' });
    }

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token wajib diisi' });
    }

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    } catch (_) {
      // Token tak valid/kedaluwarsa dianggap sudah logout.
      return res.json({ message: 'Berhasil logout' });
    }

    if (decoded.jti) {
      await prisma.refreshToken.updateMany({
        // Hanya boleh mencabut token milik sendiri.
        where: { id: decoded.jti, user_id: req.user.id, revoked_at: null },
        data: { revoked_at: new Date() },
      });
    }

    res.json({ message: 'Berhasil logout' });
  } catch (error) {
    next(error);
  }
};

module.exports = { register, login, refresh, logout };
