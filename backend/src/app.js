const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const errorHandler = require('./middleware/errorHandler');
const { generalLimiter, authLimiter } = require('./middleware/rateLimiters');

// Routes
const authRoutes = require('./routes/auth.routes');
const locationRoutes = require('./routes/location.routes');
const postRoutes = require('./routes/post.routes');
const profileRoutes = require('./routes/profile.routes');
const commentRoutes = require('./routes/comment.routes');
const savedRoutes = require('./routes/saved.routes');

const app = express();

// Diperlukan agar express-rate-limit membaca IP asli client di belakang
// reverse proxy (Nginx, Render, Railway, dll).
app.set('trust proxy', 1);

// Security headers
app.use(helmet());

// CORS — batasi origin lewat env (comma-separated). Default: izinkan semua
// (memudahkan dev). Di produksi, set CORS_ORIGIN ke domain frontend.
const allowedOrigins = (process.env.CORS_ORIGIN || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);
app.use(
  cors({
    origin: allowedOrigins.length > 0 ? allowedOrigins : true,
    credentials: true,
  })
);

// Body parsers (batasi ukuran payload)
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Rate limiter global
app.use('/api', generalLimiter);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API Routes — auth diberi limiter ketat untuk mencegah brute-force
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/locations', locationRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/users', profileRoutes);
app.use('/api/comments', commentRoutes);
app.use('/api/saved', savedRoutes);

// Error handler (harus di paling bawah)
app.use(errorHandler);

module.exports = app;
