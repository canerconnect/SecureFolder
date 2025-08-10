// Global Error Handler Middleware
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error for debugging
  console.error('Error:', {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    user: req.user?.uid || 'anonymous',
    timestamp: new Date().toISOString()
  });

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map(val => val.message);
    error = {
      message: 'Validierungsfehler',
      details: message,
      code: 'VALIDATION_ERROR'
    };
    return res.status(400).json(error);
  }

  // Mongoose duplicate key error
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    error = {
      message: `${field} existiert bereits.`,
      code: 'DUPLICATE_KEY',
      field: field
    };
    return res.status(400).json(error);
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error = {
      message: 'Ungültiger Token.',
      code: 'INVALID_TOKEN'
    };
    return res.status(401).json(error);
  }

  if (err.name === 'TokenExpiredError') {
    error = {
      message: 'Token ist abgelaufen.',
      code: 'TOKEN_EXPIRED'
    };
    return res.status(401).json(error);
  }

  // Firebase errors
  if (err.code === 'auth/user-not-found') {
    error = {
      message: 'Benutzer nicht gefunden.',
      code: 'USER_NOT_FOUND'
    };
    return res.status(404).json(error);
  }

  if (err.code === 'auth/wrong-password') {
    error = {
      message: 'Falsches Passwort.',
      code: 'WRONG_PASSWORD'
    };
    return res.status(401).json(error);
  }

  if (err.code === 'auth/email-already-in-use') {
    error = {
      message: 'E-Mail-Adresse wird bereits verwendet.',
      code: 'EMAIL_IN_USE'
    };
    return res.status(400).json(error);
  }

  // File upload errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    error = {
      message: 'Datei ist zu groß.',
      code: 'FILE_TOO_LARGE',
      maxSize: process.env.MAX_FILE_SIZE || '100MB'
    };
    return res.status(400).json(error);
  }

  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    error = {
      message: 'Unerwartete Datei.',
      code: 'UNEXPECTED_FILE'
    };
    return res.status(400).json(error);
  }

  // Encryption errors
  if (err.message && err.message.includes('Verschlüsselung')) {
    error = {
      message: 'Verschlüsselungsfehler.',
      code: 'ENCRYPTION_ERROR'
    };
    return res.status(500).json(error);
  }

  if (err.message && err.message.includes('Entschlüsselung')) {
    error = {
      message: 'Entschlüsselungsfehler.',
      code: 'DECRYPTION_ERROR'
    };
    return res.status(500).json(error);
  }

  // Default error
  res.status(error.statusCode || 500).json({
    message: error.message || 'Server-Fehler aufgetreten.',
    code: error.code || 'INTERNAL_ERROR',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

module.exports = { errorHandler };