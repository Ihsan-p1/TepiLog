const errorHandler = (err, req, res, next) => {
  console.error('Error:', err.message);
  console.error('Stack:', err.stack);

  if (err.name === 'ValidationError') {
    return res.status(400).json({ error: err.message });
  }

  if (err.code === 'P2002') {
    // Prisma unique constraint violation
    const field = err.meta?.target?.[0] || 'field';
    return res.status(409).json({ error: `${field} sudah digunakan` });
  }

  if (err.code === 'P2025') {
    // Prisma record not found
    return res.status(404).json({ error: 'Data tidak ditemukan' });
  }

  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
  });
};

module.exports = errorHandler;
