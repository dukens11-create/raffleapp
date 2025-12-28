const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const bcrypt = require('bcrypt');
const db = require('./db');
const path = require('path');
const fs = require('fs');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const { body, validationResult } = require('express-validator');
const cookieParser = require('cookie-parser');
const csrf = require('csurf');
const emailService = require('./services/emailService');

// Load environment variables
require('dotenv').config();

const app = express();

// Trust proxy - required for Render deployment
app.set('trust proxy', 1);

const PORT = process.env.PORT || 3000;
const DEBUG_MODE = process.env.DEBUG_MODE === 'true';

// Global error handlers for uncaught errors
process.on('uncaughtException', (error) => {
  console.error('UNCAUGHT EXCEPTION:', error);
  console.error('Stack:', error.stack);
  // In production, you might want to log to external service
  // For now, keep the process running but log the error
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('UNHANDLED REJECTION at:', promise);
  console.error('Reason:', reason);
  // Log the error but don't crash
});

// Validate database setup on startup
async function validateDatabaseSetup() {
  console.log('');
  console.log('═══════════════════════════════════════');
  console.log('🔍 DATABASE SETUP VALIDATION');
  console.log('═══════════════════════════════════════');
  
  const isProduction = process.env.NODE_ENV === 'production';
  const hasPostgres = process.env.DATABASE_URL ? true : false;
  
  if (isProduction && !hasPostgres) {
    console.log('');
    console.log('⚠️  CRITICAL WARNING:');
    console.log('   Running in PRODUCTION with SQLite');
    console.log('   Data will be LOST on every restart!');
    console.log('');
    console.log('🔧 TO FIX:');
    console.log('   1. Create PostgreSQL database on Render');
    console.log('   2. Add DATABASE_URL environment variable');
    console.log('   3. Redeploy service');
    console.log('');
    console.log('📚 Full Guide: See raffle-app/MIGRATION.md');
    console.log('');
    console.log('═══════════════════════════════════════');
    console.log('');
  } else if (hasPostgres) {
    console.log('✅ Production database configured correctly');
    console.log('═══════════════════════════════════════');
    console.log('');
  }
}

// Initialize database schema and validate setup
db.initializeSchema()
  .then(() => validateDatabaseSetup())
  .catch(err => {
    console.error('Failed to initialize database:', err);
    process.exit(1);
  });

// Security: Helmet for basic security headers (CSP handled by custom middleware below)
app.use(helmet({
  contentSecurityPolicy: false, // Disabled - using custom CSP middleware instead
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));

// Rate limiting - General API limiter
const apiLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // 100 requests per window
  message: 'Too many requests from this IP, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    console.warn(`Rate limit exceeded for IP: ${req.ip}`);
    res.status(429).json({
      error: 'Too many requests, please try again later',
      timestamp: new Date().toISOString()
    });
  }
});

// Rate limiting - Strict limiter for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.AUTH_RATE_LIMIT_MAX) || 5, // 5 attempts per window
  message: 'Too many login attempts, please try again later',
  skipSuccessfulRequests: true,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    console.warn(`Auth rate limit exceeded for IP: ${req.ip}`);
    res.status(429).json({
      error: 'Too many login attempts, please try again later',
      timestamp: new Date().toISOString()
    });
  }
});

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${new Date().toISOString()} ${req.method} ${req.path} ${res.statusCode} ${duration}ms - ${req.ip}`);
  });
  
  next();
});

// Request validation middleware - Bot detection and payload size check
function validateRequest(req, res, next) {
  // Skip validation for public endpoints
  if (req.path === '/api/setup-admin' || 
      req.path === '/api/clear-login-attempts' ||
      req.path.startsWith('/api/login-status/') ||
      req.path === '/health') {
    return next();
  }
  
  // Check for suspicious patterns
  const userAgent = req.headers['user-agent'] || '';
  
  // Block known bot signatures (but allow legitimate browsers)
  const suspiciousBotSignatures = ['scraper', 'crawler', 'spider', 'bot'];
  const legitimateAgents = ['mozilla', 'chrome', 'safari', 'firefox', 'edge'];
  
  const hasLegitimateAgent = legitimateAgents.some(sig => 
    userAgent.toLowerCase().includes(sig)
  );
  
  const hasSuspiciousBot = suspiciousBotSignatures.some(sig => 
    userAgent.toLowerCase().includes(sig)
  );
  
  if (hasSuspiciousBot && !hasLegitimateAgent) {
    console.warn(`Suspicious bot detected: ${userAgent} from IP: ${req.ip}`);
    return res.status(403).json({ 
      error: 'Forbidden',
      timestamp: new Date().toISOString()
    });
  }
  
  // Check for excessively large payloads
  if (req.body && JSON.stringify(req.body).length > 1000000) {
    console.warn(`Excessive payload size from IP: ${req.ip}`);
    return res.status(413).json({ 
      error: 'Payload too large',
      timestamp: new Date().toISOString()
    });
  }
  
  next();
}

// Brute force protection for login
const loginAttempts = new Map();

function checkBruteForce(identifier) {
  const attempts = loginAttempts.get(identifier) || { count: 0, firstAttempt: Date.now() };
  
  // Reset after 1 hour
  if (Date.now() - attempts.firstAttempt > 60 * 60 * 1000) {
    loginAttempts.delete(identifier);
    return false;
  }
  
  // Block after 5 failed attempts
  return attempts.count >= 5;
}

function recordFailedAttempt(identifier) {
  const attempts = loginAttempts.get(identifier) || { count: 0, firstAttempt: Date.now() };
  attempts.count++;
  loginAttempts.set(identifier, attempts);
}

function clearFailedAttempts(identifier) {
  loginAttempts.delete(identifier);
}

// Middleware
app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));
app.use(bodyParser.json({ limit: '10mb' }));
app.use(cookieParser());

// Session configuration with enhanced security
app.use(session({
  secret: process.env.SESSION_SECRET || 'raffle-secret-key-2024',
  resave: false,
  saveUninitialized: false,
  name: 'sessionId', // Rename session cookie to prevent fingerprinting
  cookie: { 
    httpOnly: true,
    secure: true, // Always use secure on Render (HTTPS)
    maxAge: 24 * 60 * 60 * 1000, // 24 hours
    sameSite: 'lax', // Changed from 'strict' for mobile compatibility
  },
  rolling: true, // Reset expiry on activity
}));

// Session timeout middleware
const SESSION_TIMEOUT = 30 * 60 * 1000; // 30 minutes

app.use((req, res, next) => {
  if (req.session.user) {
    const now = Date.now();
    const lastActivity = req.session.lastActivity || now;
    
    if (now - lastActivity > SESSION_TIMEOUT) {
      console.log(`Session expired for user: ${req.session.user.phone}`);
      req.session.destroy((err) => {
        if (err) console.error('Error destroying session:', err);
      });
      return res.status(401).json({ 
        error: 'Session expired. Please login again.',
        timestamp: new Date().toISOString()
      });
    }
    
    req.session.lastActivity = now;
  }
  next();
});

// Content Security Policy middleware for enhanced security
app.use((req, res, next) => {
  // Set Content Security Policy headers
  const cspDirectives = [
    // Default: only load resources from same origin
    "default-src 'self'",
    
    // Scripts: allow inline scripts (needed for HTML files) and CDNs
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://unpkg.com https://cdn.jsdelivr.net https://cdnjs.cloudflare.com",
    
    // Styles: allow inline styles and Google Fonts
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    
    // Fonts: allow Google Fonts
    "font-src 'self' https://fonts.gstatic.com",
    
    // Images: allow from same origin, data URIs, and any HTTPS source
    "img-src 'self' data: https: blob:",
    
    // Media: allow camera streams and blob URLs
    "media-src 'self' blob: mediastream:",
    
    // Connect: allow API calls and WebSocket connections
    "connect-src 'self' https://unpkg.com https://cdn.jsdelivr.net https://cdnjs.cloudflare.com",
    
    // Frame ancestors: prevent clickjacking
    "frame-ancestors 'self'",
    
    // Base URI: prevent base tag injection
    "base-uri 'self'",
    
    // Form actions: only allow form submissions to same origin
    "form-action 'self'",
    
    // Upgrade insecure requests (HTTP to HTTPS)
    "upgrade-insecure-requests"
  ];
  
  res.setHeader('Content-Security-Policy', cspDirectives.join('; '));
  
  // Additional security headers
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'SAMEORIGIN');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  res.setHeader('Permissions-Policy', 'camera=*, microphone=*, geolocation=()');
  
  next();
});

// ===== PUBLIC ENDPOINTS (NO RATE LIMITING) =====

// Admin Setup Endpoint - Must be BEFORE rate limiting
app.post('/api/setup-admin', async (req, res) => {
  console.log('=== SETUP ADMIN ENDPOINT CALLED ===');
  console.log('IP:', req.ip);
  console.log('User-Agent:', req.headers['user-agent']);
  
  try {
    console.log('Setup admin endpoint called');
    
    // Delete existing admin
    await db.run("DELETE FROM users WHERE role = 'admin'");
    
    // Create new admin
    const hashedPassword = await bcrypt.hash('admin123', 10);
    await db.run(
      "INSERT INTO users (name, phone, password, role) VALUES (?, ?, ?, ?)",
      ['Admin', '1234567890', hashedPassword, 'admin']
    );
    
    console.log('Admin account created/reset - Phone: 1234567890, Password: admin123');
    
    res.json({ 
      success: true, 
      message: 'Admin account created successfully',
      credentials: {
        phone: '1234567890',
        password: 'admin123'
      }
    });
    
  } catch (error) {
    console.error('=== SETUP ADMIN ERROR ===');
    console.error('Setup admin error:', error);
    res.status(500).json({ 
      error: 'Failed to setup admin account',
      details: error.message 
    });
  }
});

// Clear Login Attempts Endpoint - Public for recovery
app.post('/api/clear-login-attempts', async (req, res) => {
  console.log('=== CLEAR LOGIN ATTEMPTS ENDPOINT CALLED ===');
  console.log('IP:', req.ip);
  console.log('User-Agent:', req.headers['user-agent']);
  
  try {
    const { phone } = req.body;
    
    if (!phone) {
      return res.status(400).json({ error: 'Phone number required' });
    }
    
    clearFailedAttempts(phone);
    
    console.log('Login attempts cleared for:', phone);
    
    res.json({ 
      success: true, 
      message: 'Login attempts cleared for ' + phone 
    });
    
  } catch (error) {
    console.error('Clear attempts error:', error);
    res.status(500).json({ error: 'Failed to clear attempts' });
  }
});

// Login Status Diagnostic Endpoint - Public for diagnostics
app.get('/api/login-status/:phone', async (req, res) => {
  console.log('=== LOGIN STATUS ENDPOINT CALLED ===');
  console.log('IP:', req.ip);
  console.log('User-Agent:', req.headers['user-agent']);
  console.log('Phone:', req.params.phone);
  
  try {
    const { phone } = req.params;
    
    // Check if user exists
    const user = await db.get("SELECT id, name, role FROM users WHERE phone = ?", [phone]);
    
    // Check brute force status
    const attempts = loginAttempts.get(phone) || { count: 0, firstAttempt: Date.now() };
    const isBlocked = checkBruteForce(phone);
    const timeUntilReset = isBlocked 
      ? Math.max(0, 60 * 60 * 1000 - (Date.now() - attempts.firstAttempt))
      : 0;
    
    res.json({
      userExists: !!user,
      userName: user ? user.name : null,
      userRole: user ? user.role : null,
      failedAttempts: attempts.count,
      isBlocked: isBlocked,
      timeUntilResetMs: timeUntilReset,
      timeUntilResetMin: Math.ceil(timeUntilReset / 60000)
    });
    
  } catch (error) {
    console.error('Login status check error:', error);
    res.status(500).json({ error: 'Failed to check status' });
  }
});

// Health check endpoint - Public
// Health check endpoint with database validation
app.get('/health', async (req, res) => {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    database: {
      type: process.env.DATABASE_URL ? 'PostgreSQL' : 'SQLite',
      connected: false,
      persistent: false
    },
    environment: process.env.NODE_ENV || 'development'
  };

  try {
    // Test database connection
    await db.get('SELECT 1 as test');
    health.database.connected = true;
    health.database.persistent = process.env.DATABASE_URL ? true : false;
    
    // Warning for SQLite in production
    if (!process.env.DATABASE_URL && process.env.NODE_ENV === 'production') {
      health.warnings = [
        'Using SQLite in production - data will be lost on restart',
        'Add DATABASE_URL environment variable to switch to PostgreSQL',
        'See MIGRATION.md for setup instructions'
      ];
    }
    
    res.json(health);
  } catch (error) {
    health.status = 'error';
    health.database.error = error.message;
    res.status(503).json(health);
  }
});

// Session debug endpoint - check if session is working
app.get('/api/session-check', (req, res) => {
  res.json({
    hasSession: !!req.session,
    hasUser: !!req.session?.user,
    user: req.session?.user ? {
      id: req.session.user.id,
      name: req.session.user.name,
      role: req.session.user.role
    } : null,
    sessionID: req.sessionID,
    cookies: req.headers.cookie || 'no cookies',
    timestamp: new Date().toISOString()
  });
});

// ===== NOW APPLY RATE LIMITING =====

// Apply validation middleware to all routes
app.use(validateRequest);

// Apply rate limiting to API routes
app.use('/api/', apiLimiter);

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Authentication middleware
function requireAuth(req, res, next) {
  if (req.session.user) {
    console.log(`Auth check passed for: ${req.session.user.phone}`);
    next();
  } else {
    console.log(`Auth check failed - no session user. SessionID: ${req.sessionID}, Path: ${req.path}`);
    res.redirect('/');
  }
}

function requireAdmin(req, res, next) {
  if (req.session.user && req.session.user.role === 'admin') {
    console.log(`Admin check passed for: ${req.session.user.phone}`);
    next();
  } else {
    console.log(`Admin check failed. User: ${req.session.user?.phone || 'none'}, Role: ${req.session.user?.role || 'none'}`);
    res.status(403).send('Access denied');
  }
}

// Helper function to generate secure password
function generatePassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let password = 'Seller@';
  for (let i = 0; i < 6; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

// Helper function to send credentials
async function sendCredentials(email, phone, name, password) {
  // Send email with credentials
  const result = await emailService.sendCredentialsEmail(email, phone, name, password);
  
  if (result.success) {
    console.log(`✅ Credentials email sent successfully to ${email}`);
  } else {
    console.error(`❌ Failed to send email to ${email}, credentials logged to console`);
  }
  
  return result;
}

// Helper function to send rejection notification
async function sendRejectionNotification(email, phone, name, reason) {
  // Send rejection email
  const result = await emailService.sendRejectionEmail(email, phone, name, reason);
  
  if (result.success) {
    console.log(`✅ Rejection email sent successfully to ${email}`);
  } else {
    console.error(`❌ Failed to send email to ${email}, notification logged to console`);
  }
  
  return result;
}

// Routes

// Home page - login
app.get('/', (req, res) => {
  if (req.session.user) {
    if (req.session.user.role === 'admin') {
      res.redirect('/admin');
    } else {
      res.redirect('/seller?name=' + encodeURIComponent(req.session.user.name));
    }
  } else {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
  }
});

// Login
app.post('/login', authLimiter, async (req, res) => {
  try {
    const { phone, password } = req.body;
    
    // Validate inputs
    if (!phone || !password) {
      return res.status(400).json({ 
        error: 'Phone and password are required',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check brute force protection
    if (checkBruteForce(phone)) {
      console.warn(`Brute force detected for phone: ${phone}`);
      return res.status(429).json({ 
        error: 'Too many failed attempts. Please try again later.',
        timestamp: new Date().toISOString()
      });
    }
    
    // Debug logging
    if (DEBUG_MODE) {
      console.log('Login attempt:', {
        phone,
        bruteForceLocked: checkBruteForce(phone),
        attempts: loginAttempts.get(phone)
      });
    }
    
    const user = await db.get("SELECT * FROM users WHERE phone = ?", [phone]);
    
    if (!user) {
      recordFailedAttempt(phone);
      if (DEBUG_MODE) {
        console.log('User not found:', phone);
      }
      return res.status(401).json({ 
        error: 'Invalid phone number or password',
        timestamp: new Date().toISOString()
      });
    }
    
    // Debug logging
    if (DEBUG_MODE) {
      console.log('User found:', {
        phone: user.phone,
        role: user.role,
        hasPassword: !!user.password
      });
    }
    
    try {
      const result = await bcrypt.compare(password, user.password);
      
      if (result) {
        // Clear failed attempts on successful login
        clearFailedAttempts(phone);
        
        req.session.user = {
          id: user.id,
          name: user.name,
          phone: user.phone,
          role: user.role
        };
        
        req.session.lastActivity = Date.now();
        
        console.log(`Successful login: ${user.phone} (${user.role})`);
        
        // Explicitly save session before sending response
        req.session.save((err) => {
          if (err) {
            console.error('Session save error:', err);
            return res.status(500).json({ 
              error: 'Failed to create session',
              timestamp: new Date().toISOString()
            });
          }
          
          console.log('Session saved successfully for user:', user.phone);
          
          if (user.role === 'admin') {
            res.json({ redirect: '/admin', role: 'admin' });
          } else {
            res.json({ redirect: '/seller?name=' + encodeURIComponent(user.name), role: 'seller', name: user.name });
          }
        });
      } else {
        recordFailedAttempt(phone);
        res.status(401).json({ 
          error: 'Invalid phone number or password',
          timestamp: new Date().toISOString()
        });
      }
    } catch (bcryptError) {
      console.error('Bcrypt error:', bcryptError);
      recordFailedAttempt(phone);
      return res.status(500).json({ 
        error: 'Authentication error',
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ 
      error: 'An error occurred during login',
      timestamp: new Date().toISOString()
    });
  }
});

// Logout
app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/');
});

// Seller Registration APIs
// Submit registration request with validation
const validateSellerRegistration = [
  body('fullName').trim().isLength({ min: 2, max: 100 }).escape().withMessage('Full name must be between 2 and 100 characters'),
  body('phone').trim().matches(/^[0-9]{10,15}$/).withMessage('Phone must be 10-15 digits'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('experience').optional().trim().isLength({ max: 500 }).escape().withMessage('Experience must be less than 500 characters'),
];

app.post('/api/seller-registration', authLimiter, validateSellerRegistration, async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array(),
        timestamp: new Date().toISOString()
      });
    }
    
    const { fullName, phone, email, experience } = req.body;
    
    // Check if phone already exists in users
    const existingUser = await db.get('SELECT id FROM users WHERE phone = ?', [phone]);
    
    if (existingUser) {
      return res.status(400).json({ 
        error: 'Phone number already registered',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check if pending request exists
    const existingRequest = await db.get('SELECT id FROM seller_requests WHERE phone = ? AND status = \'pending\'', [phone]);
    
    if (existingRequest) {
      return res.status(400).json({ 
        error: 'Registration request already pending',
        timestamp: new Date().toISOString()
      });
    }
    
    // Insert registration request
    await db.run(`
      INSERT INTO seller_requests (full_name, phone, email, experience, status)
      VALUES (?, ?, ?, ?, 'pending')
    `, [fullName, phone, email, experience || '']);
    
    console.log(`New seller registration request from: ${fullName} (${phone})`);
    
    res.json({ 
      success: true, 
      message: 'Registration request submitted successfully. You will be notified once approved.',
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ 
      error: 'An error occurred during registration',
      timestamp: new Date().toISOString()
    });
  }
});

// Get all seller requests (admin only)
app.get('/api/seller-requests', requireAuth, requireAdmin, async (req, res) => {
  try {
    const requests = await db.all(`
      SELECT * FROM seller_requests 
      ORDER BY 
        CASE status 
          WHEN 'pending' THEN 1 
          WHEN 'approved' THEN 2 
          WHEN 'rejected' THEN 3 
        END,
        request_date DESC
    `);
    res.json(requests);
  } catch (error) {
    console.error('Error in get seller requests:', error);
    res.status(500).json({ 
      error: 'An error occurred',
      timestamp: new Date().toISOString()
    });
  }
});

// Approve seller request
app.post('/api/seller-requests/:id/approve', requireAuth, requireAdmin, async (req, res) => {
  try {
    const requestId = req.params.id;
    const adminPhone = req.session.user.phone;
    const { notes } = req.body;
    
    // Get request details
    const request = await db.get('SELECT * FROM seller_requests WHERE id = ?', [requestId]);
    
    if (!request) {
      return res.status(404).json({ 
        error: 'Request not found',
        timestamp: new Date().toISOString()
      });
    }
    
    if (request.status !== 'pending') {
      return res.status(400).json({ 
        error: 'Request already processed',
        timestamp: new Date().toISOString()
      });
    }
    
    // Generate random password
    const generatedPassword = generatePassword();
    const hashedPassword = await bcrypt.hash(generatedPassword, 10);
    
    // Create seller user account
    await db.run(`
      INSERT INTO users (phone, password, role, name, email, registered_via, approved_by, approved_date)
      VALUES (?, ?, 'seller', ?, ?, 'registration', ?, ${db.getCurrentTimestamp()})
    `, [request.phone, hashedPassword, request.full_name, request.email, adminPhone]);
    
    // Update request status
    await db.run(`
      UPDATE seller_requests 
      SET status = 'approved', 
          reviewed_by = ?, 
          reviewed_date = ${db.getCurrentTimestamp()},
          approval_notes = ?
      WHERE id = ?
    `, [adminPhone, notes || '', requestId]);
    
    // Send credentials
    await sendCredentials(request.email, request.phone, request.full_name, generatedPassword);
    
    console.log(`Seller request approved: ${request.full_name} (${request.phone})`);
    
    res.json({ 
      success: true, 
      message: 'Seller approved and credentials sent',
      credentials: {
        phone: request.phone,
        password: generatedPassword,
        email: request.email
      },
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Approval error:', error);
    res.status(500).json({ 
      error: 'An error occurred during approval',
      timestamp: new Date().toISOString()
    });
  }
});

// Reject seller request
app.post('/api/seller-requests/:id/reject', requireAuth, requireAdmin, async (req, res) => {
  try {
    const requestId = req.params.id;
    const adminPhone = req.session.user.phone;
    const { reason } = req.body;
    
    const request = await db.get('SELECT * FROM seller_requests WHERE id = ?', [requestId]);
    
    if (!request || request.status !== 'pending') {
      return res.status(400).json({ error: 'Invalid request' });
    }
    
    await db.run(`
      UPDATE seller_requests 
      SET status = 'rejected', 
          reviewed_by = ?, 
          reviewed_date = ${db.getCurrentTimestamp()},
          approval_notes = ?
      WHERE id = ?
    `, [adminPhone, reason || '', requestId]);
    
    // Send rejection notification
    await sendRejectionNotification(request.email, request.phone, request.full_name, reason);
    
    res.json({ success: true, message: 'Request rejected' });
    
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Admin dashboard
app.get('/admin', requireAuth, requireAdmin, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// Seller page
app.get('/seller', requireAuth, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'seller.html'));
});

// API: Get all sellers
app.get('/api/sellers', requireAuth, requireAdmin, async (req, res) => {
  try {
    const rows = await db.all("SELECT id, name, phone, created_at FROM users WHERE role = 'seller'");
    res.json(rows);
  } catch (error) {
    console.error('Error in get sellers:', error);
    res.status(500).json({ 
      error: 'An error occurred',
      timestamp: new Date().toISOString()
    });
  }
});

// API: Add seller with validation
const validateSeller = [
  body('name').trim().isLength({ min: 2, max: 100 }).escape().withMessage('Name must be between 2 and 100 characters'),
  body('phone').trim().matches(/^[0-9]{10,15}$/).withMessage('Phone must be 10-15 digits'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
];

app.post('/api/sellers', requireAuth, requireAdmin, validateSeller, async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array(),
        timestamp: new Date().toISOString()
      });
    }
    
    const { name, phone, password } = req.body;
    
    const hash = await bcrypt.hash(password, 10);
    
    try {
      const result = await db.run(
        "INSERT INTO users (name, phone, password, role) VALUES (?, ?, ?, 'seller')",
        [name, phone, hash]
      );
      
      console.log(`Seller created: ${name} (${phone}) by admin`);
      res.json({ success: true, id: result.lastID });
    } catch (err) {
      if (db.isUniqueConstraintError(err)) {
        return res.status(400).json({ 
          error: 'Phone number already exists',
          timestamp: new Date().toISOString()
        });
      }
      console.error('Error creating seller:', err);
      return res.status(500).json({ 
        error: 'Database error',
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('Error adding seller:', error);
    res.status(500).json({ 
      error: 'An error occurred while adding seller',
      timestamp: new Date().toISOString()
    });
  }
});

// API: Update seller
app.put('/api/sellers/:id', requireAuth, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, phone, password } = req.body;
    
    if (!name || !phone) {
      return res.status(400).json({ error: 'Name and phone are required' });
    }
    
    if (password) {
      const hash = await bcrypt.hash(password, 10);
      
      try {
        await db.run(
          "UPDATE users SET name = ?, phone = ?, password = ? WHERE id = ? AND role = 'seller'",
          [name, phone, hash, id]
        );
        res.json({ success: true });
      } catch (err) {
        if (db.isUniqueConstraintError(err)) {
          return res.status(400).json({ error: 'Phone number already exists' });
        }
        return res.status(500).json({ error: 'Database error' });
      }
    } else {
      try {
        await db.run(
          "UPDATE users SET name = ?, phone = ? WHERE id = ? AND role = 'seller'",
          [name, phone, id]
        );
        res.json({ success: true });
      } catch (err) {
        if (db.isUniqueConstraintError(err)) {
          return res.status(400).json({ error: 'Phone number already exists' });
        }
        return res.status(500).json({ error: 'Database error' });
      }
    }
  } catch (error) {
    console.error('Error updating seller:', error);
    res.status(500).json({ error: 'An error occurred' });
  }
});

// API: Delete seller
app.delete('/api/sellers/:id', requireAuth, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    
    await db.run("DELETE FROM users WHERE id = ? AND role = 'seller'", [id]);
    res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

// API: Get all tickets
app.get('/api/tickets', requireAuth, async (req, res) => {
  try {
    let query = "SELECT * FROM tickets ORDER BY ticket_number";
    let params = [];
    
    if (req.session.user.role === 'seller') {
      query = "SELECT * FROM tickets WHERE seller_phone = ? ORDER BY ticket_number";
      params = [req.session.user.phone];
    }
    
    const rows = await db.all(query, params);
    res.json(rows);
  } catch (error) {
    console.error('Error in get tickets:', error);
    res.status(500).json({ 
      error: 'An error occurred',
      timestamp: new Date().toISOString()
    });
  }
});

// API: Add ticket with validation
const validateTicket = [
  body('ticket_number').trim().notEmpty().withMessage('Ticket number is required'),
  body('buyer_name').trim().isLength({ min: 2, max: 100 }).escape().withMessage('Buyer name must be between 2 and 100 characters'),
  body('buyer_phone').trim().matches(/^[0-9]{10,15}$/).withMessage('Buyer phone must be 10-15 digits'),
  body('amount').isFloat({ min: 0 }).withMessage('Amount must be a positive number'),
];

app.post('/api/tickets', requireAuth, validateTicket, async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Validation failed', 
        details: errors.array(),
        timestamp: new Date().toISOString()
      });
    }
    
    const { ticket_number, buyer_name, buyer_phone, amount } = req.body;
    
    const seller_name = req.session.user.name;
    const seller_phone = req.session.user.phone;
    
    try {
      const result = await db.run(
        "INSERT INTO tickets (ticket_number, buyer_name, buyer_phone, seller_name, seller_phone, amount) VALUES (?, ?, ?, ?, ?, ?)",
        [ticket_number, buyer_name, buyer_phone, seller_name, seller_phone, amount]
      );
      
      console.log(`Ticket created: ${ticket_number} by ${seller_name}`);
      res.json({ success: true, id: result.lastID });
    } catch (err) {
      if (db.isUniqueConstraintError(err)) {
        return res.status(400).json({ 
          error: 'Ticket number already exists',
          timestamp: new Date().toISOString()
        });
      }
      console.error('Error creating ticket:', err);
      return res.status(500).json({ 
        error: 'Database error',
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.error('Error adding ticket:', error);
    res.status(500).json({ 
      error: 'An error occurred while adding ticket',
      timestamp: new Date().toISOString()
    });
  }
});

// API: Update ticket
app.put('/api/tickets/:id', requireAuth, async (req, res) => {
  const { id } = req.params;
  const { buyer_name, buyer_phone, amount } = req.body;
  
  if (!buyer_name || !buyer_phone || !amount) {
    return res.status(400).json({ error: 'All fields are required' });
  }
  
  try {
    let query, params;
    
    if (req.session.user.role === 'admin') {
      query = "UPDATE tickets SET buyer_name = ?, buyer_phone = ?, amount = ? WHERE id = ?";
      params = [buyer_name, buyer_phone, amount, id];
    } else {
      query = "UPDATE tickets SET buyer_name = ?, buyer_phone = ?, amount = ? WHERE id = ? AND seller_phone = ?";
      params = [buyer_name, buyer_phone, amount, id, req.session.user.phone];
    }
    
    const result = await db.run(query, params);
    if (result.changes === 0) {
      return res.status(403).json({ error: 'Not authorized to update this ticket' });
    }
    res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

// API: Delete ticket
app.delete('/api/tickets/:id', requireAuth, async (req, res) => {
  const { id } = req.params;
  
  try {
    let query, params;
    
    if (req.session.user.role === 'admin') {
      query = "DELETE FROM tickets WHERE id = ?";
      params = [id];
    } else {
      query = "DELETE FROM tickets WHERE id = ? AND seller_phone = ?";
      params = [id, req.session.user.phone];
    }
    
    const result = await db.run(query, params);
    if (result.changes === 0) {
      return res.status(403).json({ error: 'Not authorized to delete this ticket' });
    }
    res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

// API: Get ticket statistics
app.get('/api/stats', requireAuth, async (req, res) => {
  try {
    let ticketQuery, revenueQuery;
    let params = [];
    
    if (req.session.user.role === 'admin') {
      ticketQuery = "SELECT COUNT(*) as total FROM tickets";
      revenueQuery = "SELECT SUM(amount) as total FROM tickets";
    } else {
      ticketQuery = "SELECT COUNT(*) as total FROM tickets WHERE seller_phone = ?";
      revenueQuery = "SELECT SUM(amount) as total FROM tickets WHERE seller_phone = ?";
      params = [req.session.user.phone];
    }
    
    const ticketRow = await db.get(ticketQuery, params);
    const revenueRow = await db.get(revenueQuery, params);
    
    res.json({
      totalTickets: ticketRow.total || 0,
      totalRevenue: revenueRow.total || 0
    });
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

// API: Get all draws
app.get('/api/draws', requireAuth, requireAdmin, async (req, res) => {
  try {
    const rows = await db.all("SELECT * FROM draws ORDER BY drawn_at DESC");
    res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

// API: Conduct draw
app.post('/api/draw', requireAuth, requireAdmin, async (req, res) => {
  try {
    const { prize_name } = req.body;
    
    if (!prize_name) {
      return res.status(400).json({ 
        error: 'Prize name is required',
        timestamp: new Date().toISOString()
      });
    }
    
    // Get all active tickets
    const tickets = await db.all("SELECT * FROM tickets WHERE status = 'active'");
    
    if (tickets.length === 0) {
      return res.status(400).json({ 
        error: 'No active tickets available',
        timestamp: new Date().toISOString()
      });
    }
    
    // Random selection
    const winner = tickets[Math.floor(Math.random() * tickets.length)];
    
    // Get next draw number
    const row = await db.get("SELECT MAX(draw_number) as max_draw FROM draws");
    const draw_number = (row.max_draw || 0) + 1;
    
    // Insert draw result
    await db.run(
      "INSERT INTO draws (draw_number, ticket_number, prize_name, winner_name, winner_phone) VALUES (?, ?, ?, ?, ?)",
      [draw_number, winner.ticket_number, prize_name, winner.buyer_name, winner.buyer_phone]
    );
    
    // Mark ticket as won
    await db.run(
      "UPDATE tickets SET status = 'won' WHERE id = ?",
      [winner.id]
    );
    
    console.log(`Draw conducted: ${prize_name} - Winner: ${winner.buyer_name} (Ticket: ${winner.ticket_number})`);
    
    res.json({
      success: true,
      draw: {
        draw_number,
        ticket_number: winner.ticket_number,
        prize_name,
        winner_name: winner.buyer_name,
        winner_phone: winner.buyer_phone
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Draw error:', error);
    res.status(500).json({ 
      error: 'An error occurred during draw',
      timestamp: new Date().toISOString()
    });
  }
});

// API: Get available tickets for draw
app.get('/api/available-tickets', requireAuth, requireAdmin, async (req, res) => {
  try {
    const rows = await db.all("SELECT ticket_number FROM tickets WHERE status = 'active' ORDER BY ticket_number");
    res.json(rows.map(row => row.ticket_number));
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

// API: Get seller statistics
app.get('/api/seller-stats', requireAuth, requireAdmin, async (req, res) => {
  try {
    const rows = await db.all(`
      SELECT 
        seller_name,
        seller_phone,
        COUNT(*) as ticket_count,
        SUM(amount) as total_revenue
      FROM tickets
      GROUP BY seller_phone
      ORDER BY total_revenue DESC
    `);
    res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

// API: Bulk import ticket
app.post('/api/tickets/bulk', requireAuth, requireAdmin, async (req, res) => {
  try {
    const { ticketNumber, buyerName, buyerPhone, amount, category, seller, status, barcode } = req.body;
    
    // Validate required fields (allow amount to be 0)
    if (!ticketNumber || !buyerName || !buyerPhone || amount === undefined || amount === null) {
      return res.status(400).json({ 
        error: 'Missing required fields',
        timestamp: new Date().toISOString()
      });
    }
    
    // Validate amount is a number
    if (typeof amount !== 'number' || isNaN(amount) || amount < 0) {
      return res.status(400).json({ 
        error: 'Amount must be a non-negative number',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check if ticket number already exists
    const existing = await db.get('SELECT id FROM tickets WHERE ticket_number = ?', [ticketNumber]);
    
    if (existing) {
      return res.status(400).json({ 
        error: 'Ticket number already exists',
        timestamp: new Date().toISOString()
      });
    }
    
    // Insert ticket with barcode
    const result = await db.run(`
      INSERT INTO tickets (ticket_number, buyer_name, buyer_phone, seller_name, seller_phone, amount, category, status, barcode, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ${db.getCurrentTimestamp()})
    `, [
      ticketNumber, 
      buyerName, 
      buyerPhone, 
      seller || 'Admin', 
      req.session.user.phone, 
      amount, 
      category || 'Standard', 
      status || 'sold', 
      barcode
    ]);
    
    console.log(`Bulk ticket imported: ${ticketNumber}`);
    res.json({ 
      success: true, 
      id: result.lastID,
      ticketNumber: ticketNumber
    });
  } catch (error) {
    console.error('Bulk import error:', error);
    res.status(500).json({ 
      error: 'An error occurred during import',
      timestamp: new Date().toISOString()
    });
  }
});

// API: Scan ticket barcode (seller only)
app.post('/api/tickets/scan', requireAuth, async (req, res) => {
  try {
    const { barcode } = req.body;
    
    if (!barcode) {
      return res.status(400).json({ error: 'Barcode is required' });
    }
    
    // Find ticket by barcode
    const ticket = await db.get('SELECT * FROM tickets WHERE barcode = ? AND status = \'active\'', [barcode]);
    
    if (!ticket) {
      return res.status(404).json({ error: 'Ticket not found or already sold' });
    }
    
    // Mark as sold by this seller
    await db.run(
      "UPDATE tickets SET status = 'sold', seller_name = ?, seller_phone = ? WHERE id = ?",
      [req.session.user.name, req.session.user.phone, ticket.id]
    );
    
    console.log(`Ticket ${barcode} scanned and sold by ${req.session.user.name}`);
    
    res.json({ 
      success: true, 
      message: 'Ticket sold successfully',
      ticket: ticket.ticket_number
    });
  } catch (error) {
    console.error('Scan ticket error:', error);
    res.status(500).json({ error: 'Failed to process ticket' });
  }
});

// API: Submit seller concern
app.post('/api/seller-concerns', requireAuth, async (req, res) => {
  try {
    const { issue_type, ticket_number, description } = req.body;
    
    if (!issue_type || !description) {
      return res.status(400).json({ error: 'Issue type and description are required' });
    }
    
    const result = await db.run(`
      INSERT INTO seller_concerns (seller_id, seller_name, seller_phone, issue_type, ticket_number, description, status)
      VALUES (?, ?, ?, ?, ?, ?, 'pending')
    `, [
      req.session.user.id,
      req.session.user.name,
      req.session.user.phone,
      issue_type,
      ticket_number || null,
      description
    ]);
    
    console.log(`Concern reported by ${req.session.user.name}: ${issue_type}`);
    
    // Send email notification to admin
    const adminEmail = process.env.EMAIL_USER;
    if (adminEmail) {
      await emailService.sendConcernNotification(
        adminEmail,
        req.session.user.name,
        issue_type,
        description,
        ticket_number
      );
    }
    
    res.json({ 
      success: true, 
      message: 'Concern submitted successfully',
      id: result.lastID
    });
  } catch (error) {
    console.error('Submit concern error:', error);
    res.status(500).json({ error: 'Failed to submit concern' });
  }
});

// API: Get all concerns (admin only)
app.get('/api/seller-concerns', requireAuth, requireAdmin, async (req, res) => {
  try {
    const concerns = await db.all(`
      SELECT * FROM seller_concerns 
      ORDER BY 
        CASE status 
          WHEN 'pending' THEN 1 
          WHEN 'resolved' THEN 2 
        END,
        created_at DESC
    `);
    res.json(concerns);
  } catch (error) {
    console.error('Get concerns error:', error);
    res.status(500).json({ error: 'Failed to fetch concerns' });
  }
});

// API: Resolve concern (admin only)
app.put('/api/seller-concerns/:id/resolve', requireAuth, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { admin_notes } = req.body;
    
    await db.run(`
      UPDATE seller_concerns 
      SET status = 'resolved', 
          resolved_by = ?, 
          resolved_at = ${db.getCurrentTimestamp()},
          admin_notes = ?
      WHERE id = ?
    `, [req.session.user.phone, admin_notes || '', id]);
    
    res.json({ success: true, message: 'Concern resolved' });
  } catch (error) {
    console.error('Resolve concern error:', error);
    res.status(500).json({ error: 'Failed to resolve concern' });
  }
});

// Legacy endpoints (for backward compatibility with frontend)
app.get('/tickets', requireAuth, async (req, res) => {
  try {
    let query = "SELECT ticket_number as number, category, status, barcode FROM tickets ORDER BY ticket_number";
    let params = [];
    
    if (req.session.user.role === 'seller') {
      query = "SELECT ticket_number as number, category, status, barcode FROM tickets WHERE seller_phone = ? ORDER BY ticket_number";
      params = [req.session.user.phone];
    }
    
    const rows = await db.all(query, params);
    res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

app.get('/users', requireAuth, requireAdmin, async (req, res) => {
  try {
    const rows = await db.all("SELECT name, phone, role FROM users ORDER BY name");
    res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

app.get('/audit-logs', requireAuth, requireAdmin, (req, res) => {
  // Return empty array for now - audit logs table doesn't exist yet
  res.json([]);
});

app.get('/sales-report', requireAuth, requireAdmin, async (req, res) => {
  try {
    const rows = await db.all(`
      SELECT seller_name as sold_by, COUNT(*) as count
      FROM tickets
      GROUP BY seller_name
      ORDER BY count DESC
    `);
    res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

app.get('/seller-leaderboard', requireAuth, requireAdmin, async (req, res) => {
  try {
    const rows = await db.all(`
      SELECT seller_name as sold_by, COUNT(*) as tickets_sold
      FROM tickets
      GROUP BY seller_name
      ORDER BY tickets_sold DESC
    `);
    res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

app.get('/list-backups', requireAuth, requireAdmin, (req, res) => {
  // Return empty array for now - backup functionality not implemented
  res.json([]);
});

app.get('/analytics/sales-by-day', requireAuth, requireAdmin, async (req, res) => {
  try {
    const rows = await db.all(`
      SELECT DATE(created_at) as day, COUNT(*) as count
      FROM tickets
      WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY DATE(created_at)
      ORDER BY day
    `);
    res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

app.get('/analytics/tickets-by-category', requireAuth, requireAdmin, async (req, res) => {
  try {
    const rows = await db.all(`
      SELECT category, COUNT(*) as count
      FROM tickets
      WHERE category IS NOT NULL
      GROUP BY category
      ORDER BY count DESC
    `);
    res.json(rows);
  } catch (err) {
    return res.status(500).json({ error: 'Database error' });
  }
});

// 404 handler - must be after all other routes
app.use((req, res, next) => {
  // Check if this is an API request
  if (req.path.startsWith('/api/')) {
    res.status(404).json({ 
      error: 'Endpoint not found',
      timestamp: new Date().toISOString()
    });
  } else {
    // Serve custom 404 page for regular requests
    res.status(404).sendFile(path.join(__dirname, 'public', '404.html'));
  }
});

// Express error handler middleware - must be last
app.use((err, req, res, next) => {
  console.error('Express Error Handler:', err);
  console.error('Stack:', err.stack);
  
  // Don't leak error details in production
  const errorResponse = {
    error: process.env.NODE_ENV === 'production' 
      ? 'An error occurred' 
      : err.message,
    timestamp: new Date().toISOString()
  };
  
  // For API requests, return JSON
  if (req.path.startsWith('/api/')) {
    res.status(err.status || 500).json(errorResponse);
  } else {
    // For regular requests, serve custom 500 page
    res.status(err.status || 500).sendFile(path.join(__dirname, 'public', '500.html'));
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Access the application at http://localhost:${PORT}`);
  console.log(`Health check available at http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGINT', () => {
  db.close((err) => {
    if (err) {
      console.error('Error closing database:', err);
    } else {
      console.log('Database connection closed');
    }
    process.exit(0);
  });
});
