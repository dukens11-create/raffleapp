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
const pgSession = require('connect-pg-simple')(session);
const emailService = require('./services/emailService');
const multer = require('multer');
const sharp = require('sharp');

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

/**
 * Run database migrations
 */
async function runMigrations() {
  console.log('🔄 Running database migrations...');
  
  // Only run migrations for PostgreSQL
  if (!db.USE_POSTGRES) {
    console.log('⚠️  Skipping migrations - SQLite database detected');
    return;
  }
  
  const migrationFile = path.join(__dirname, 'migrations', 'add_raffle_id_to_tickets.sql');
  
  if (fs.existsSync(migrationFile)) {
    const sql = fs.readFileSync(migrationFile, 'utf8');
    try {
      await db.run(sql);
      console.log('✅ Migrations completed successfully');
    } catch (error) {
      console.error('❌ Migration failed:', error.message);
      // Don't crash the server, just log the error
      // The migration is idempotent, so it's safe to continue
    }
  } else {
    console.log('⚠️  No migration file found at:', migrationFile);
  }
}

// Initialize database schema, run migrations, and validate setup
db.initializeSchema()
  .then(() => runMigrations())
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

// Session store configuration
let sessionStore;

if (process.env.DATABASE_URL) {
  // Production: Use PostgreSQL session store
  sessionStore = new pgSession({
    conString: process.env.DATABASE_URL,
    tableName: 'session', // Table name for sessions
    createTableIfMissing: true, // Auto-create session table
    pruneSessionInterval: 60 * 15, // Clean up expired sessions every 15 minutes
  });
  console.log('✅ Using PostgreSQL session store');
} else {
  // Development: Use memory store (with warning)
  console.warn('⚠️  WARNING: Using MemoryStore for sessions (development only)');
  console.warn('   Sessions will be lost on server restart');
  console.warn('   Add DATABASE_URL for persistent sessions');
  sessionStore = undefined; // Express will use default MemoryStore
}

// Session configuration with enhanced security
app.use(session({
  store: sessionStore,
  secret: process.env.SESSION_SECRET || 'raffle-secret-key-2024',
  resave: false,
  saveUninitialized: false,
  name: 'sessionId', // Rename session cookie to prevent fingerprinting
  cookie: { 
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production', // Only use secure cookies in production
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
    environment: process.env.NODE_ENV || 'development',
    criticalIssues: []
  };

  try {
    // Test database connection
    await db.get('SELECT 1 as test');
    health.database.connected = true;
    health.database.persistent = process.env.DATABASE_URL ? true : false;
    
    // CRITICAL: Check for SQLite in production
    if (!process.env.DATABASE_URL) {
      health.status = 'degraded';
      health.criticalIssues.push({
        severity: 'CRITICAL',
        issue: 'Using SQLite - Data will be LOST on restart',
        action: 'Set DATABASE_URL environment variable to PostgreSQL connection string',
        documentation: '/api/database-status for detailed steps'
      });
      
      health.warnings = [
        '🚨 CRITICAL: Using SQLite in production',
        '🚨 ALL DATA (sellers, tickets, users) WILL BE LOST on restart',
        '🔧 ACTION REQUIRED: Connect PostgreSQL database',
        '📚 Visit /api/database-status for fix instructions'
      ];
    }
    
    res.json(health);
  } catch (error) {
    health.status = 'error';
    health.database.error = error.message;
    res.status(503).json(health);
  }
});

// Detailed database diagnostic endpoint
app.get('/api/database-status', async (req, res) => {
  const status = {
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    database: {
      configured: {
        hasDatabaseUrl: !!process.env.DATABASE_URL,
        databaseUrlPreview: process.env.DATABASE_URL 
          ? process.env.DATABASE_URL.substring(0, 20) + '...' 
          : 'NOT SET',
        usingPostgres: !!process.env.DATABASE_URL,
        usingSqlite: !process.env.DATABASE_URL
      },
      connection: {
        connected: false,
        error: null
      },
      persistence: {
        isPersistent: !!process.env.DATABASE_URL,
        dataWillSurviveRestart: !!process.env.DATABASE_URL,
        warning: !process.env.DATABASE_URL 
          ? '⚠️ CRITICAL: Using SQLite - ALL DATA WILL BE LOST ON RESTART' 
          : null
      }
    },
    sessions: {
      store: process.env.DATABASE_URL ? 'PostgreSQL' : 'MemoryStore',
      persistent: false, // Will be true after PR #69 is merged
      warning: 'Sessions stored in memory - users will be logged out on restart (Fix in PR #69)'
    },
    actionRequired: []
  };

  // Test database connection
  try {
    await db.get('SELECT 1 as test');
    status.database.connection.connected = true;
  } catch (error) {
    status.database.connection.connected = false;
    status.database.connection.error = error.message;
  }

  // Determine action required
  if (!process.env.DATABASE_URL) {
    status.actionRequired.push({
      priority: 'CRITICAL',
      issue: 'No PostgreSQL connection',
      impact: 'ALL user data (sellers, tickets, requests) is being LOST on every restart',
      solution: 'Add DATABASE_URL environment variable with PostgreSQL connection string',
      steps: [
        '1. Go to Render Dashboard → Your PostgreSQL database',
        '2. Copy the INTERNAL connection string',
        '3. Go to Web Service → Environment tab',
        '4. Add: Key=DATABASE_URL, Value=[internal connection string]',
        '5. Save changes (will trigger automatic redeploy)'
      ]
    });
  }

  if (!status.sessions.persistent) {
    status.actionRequired.push({
      priority: 'HIGH',
      issue: 'Sessions not persistent',
      impact: 'Users are logged out on every restart',
      solution: 'Merge PR #69 to use PostgreSQL session store',
      steps: [
        '1. Review PR #69: Fix session loss when Render restarts',
        '2. Merge the pull request',
        '3. Wait for automatic deployment'
      ]
    });
  }

  const httpCode = status.actionRequired.length > 0 ? 503 : 200;
  res.status(httpCode).json(status);
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

// ============================================================================
// RAFFLE TICKET SYSTEM API ENDPOINTS
// ============================================================================

const ticketService = require('./services/ticketService');
const printService = require('./services/printService');
const importExportService = require('./services/importExportService');
// Note: multer is already imported at the top of the file

// Configure multer for file uploads
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// Admin Raffle Endpoints

// GET /api/admin/raffles - List all raffles
app.get('/api/admin/raffles', requireAuth, requireAdmin, async (req, res) => {
  try {
    const raffles = await db.all('SELECT * FROM raffles ORDER BY created_at DESC');
    res.json(raffles);
  } catch (error) {
    console.error('Error fetching raffles:', error);
    res.status(500).json({ error: 'Failed to fetch raffles' });
  }
});

// POST /api/admin/raffles - Create a new raffle
app.post('/api/admin/raffles', requireAuth, requireAdmin, async (req, res) => {
  try {
    const { name, description, start_date, draw_date, total_tickets } = req.body;
    
    const result = await db.run(
      `INSERT INTO raffles (name, description, start_date, draw_date, total_tickets, status)
       VALUES (?, ?, ?, ?, ?, 'draft')`,
      [name, description, start_date, draw_date, total_tickets || 1500000]
    );
    
    const raffle = await db.get('SELECT * FROM raffles WHERE id = ?', [result.lastID]);
    res.json(raffle);
  } catch (error) {
    console.error('Error creating raffle:', error);
    res.status(500).json({ error: 'Failed to create raffle' });
  }
});

// GET /api/admin/raffles/:id/stats - Get raffle statistics
app.get('/api/admin/raffles/:id/stats', requireAuth, requireAdmin, async (req, res) => {
  try {
    const raffleId = req.params.id;
    
    // Get raffle info
    const raffle = await db.get('SELECT * FROM raffles WHERE id = ?', [raffleId]);
    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }
    
    // Get category statistics
    const categories = await db.all(`
      SELECT 
        tc.id,
        tc.category_code,
        tc.category_name,
        tc.price,
        tc.total_tickets,
        tc.color,
        COUNT(t.id) as tickets_created,
        COUNT(CASE WHEN t.status = 'SOLD' THEN 1 END) as tickets_sold,
        COUNT(CASE WHEN t.status = 'AVAILABLE' THEN 1 END) as tickets_available,
        COUNT(CASE WHEN t.printed = ${db.USE_POSTGRES ? 'TRUE' : '1'} THEN 1 END) as tickets_printed,
        SUM(CASE WHEN t.status = 'SOLD' THEN t.price ELSE 0 END) as revenue
      FROM ticket_categories tc
      LEFT JOIN tickets t ON tc.id = t.category_id AND t.raffle_id = ?
      WHERE tc.raffle_id = ?
      GROUP BY tc.id, tc.category_code, tc.category_name, tc.price, tc.total_tickets, tc.color
      ORDER BY tc.category_code
    `, [raffleId, raffleId]);
    
    // Calculate totals
    const totals = {
      total_tickets: 0,
      tickets_created: 0,
      tickets_sold: 0,
      tickets_available: 0,
      tickets_printed: 0,
      total_revenue: 0,
      potential_revenue: 0
    };
    
    categories.forEach(cat => {
      totals.total_tickets += cat.total_tickets;
      totals.tickets_created += cat.tickets_created || 0;
      totals.tickets_sold += cat.tickets_sold || 0;
      totals.tickets_available += cat.tickets_available || 0;
      totals.tickets_printed += cat.tickets_printed || 0;
      totals.total_revenue += parseFloat(cat.revenue || 0);
      totals.potential_revenue += cat.total_tickets * cat.price;
    });
    
    res.json({
      raffle,
      categories,
      totals
    });
  } catch (error) {
    console.error('Error fetching raffle stats:', error);
    res.status(500).json({ error: 'Failed to fetch raffle statistics' });
  }
});

// Ticket Management Endpoints

// POST /api/admin/tickets/import - Import tickets from Excel/CSV
app.post('/api/admin/tickets/import', requireAuth, requireAdmin, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }
    
    const raffleId = req.body.raffle_id || 1;
    const fileType = req.file.mimetype;
    
    // Parse file
    const data = importExportService.parseImportFile(req.file.buffer, fileType);
    
    // Validate data
    const validation = importExportService.validateImportData(data);
    
    if (validation.errors.length > 0) {
      return res.status(400).json({
        error: 'Validation failed',
        errors: validation.errors,
        valid: validation.valid.length,
        invalid: validation.invalid.length
      });
    }
    
    // Import valid tickets
    const results = await importExportService.importTickets(validation.valid, raffleId);
    
    res.json({
      success: true,
      results
    });
  } catch (error) {
    console.error('Error importing tickets:', error);
    res.status(500).json({ error: 'Failed to import tickets: ' + error.message });
  }
});

// GET /api/admin/tickets/count - Get ticket count for diagnostics
app.get('/api/admin/tickets/count', requireAuth, requireAdmin, async (req, res) => {
  try {
    const raffleId = req.query.raffle_id || 1;
    const count = await db.get(
      'SELECT COUNT(*) as total FROM tickets WHERE raffle_id = ?',
      [raffleId]
    );
    res.json({ 
      raffle_id: raffleId,
      total_tickets: count.total,
      message: count.total === 0 ? 'No tickets found - generate tickets first' : 'Tickets available'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/admin/tickets/export - Export tickets to Excel
app.get('/api/admin/tickets/export', requireAuth, requireAdmin, async (req, res) => {
  try {
    console.log('📥 Export request received:', req.query);
    
    const filters = {
      raffle_id: req.query.raffle_id || 1,
      category: req.query.category,
      status: req.query.status,
      printed: req.query.printed === 'true' ? true : req.query.printed === 'false' ? false : undefined
    };
    
    console.log('📊 Fetching tickets with filters:', filters);
    
    const buffer = await importExportService.exportTickets(filters);
    
    if (!buffer || buffer.length === 0) {
      console.warn('⚠️ No tickets found or empty buffer returned');
      return res.status(404).json({ 
        error: 'No tickets found to export',
        filters: filters
      });
    }
    
    console.log(`✅ Export successful: ${buffer.length} bytes`);
    
    const filename = `raffle-tickets-export-${new Date().toISOString().split('T')[0]}.xlsx`;
    
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.setHeader('Content-Length', buffer.length);
    res.send(buffer);
    
  } catch (error) {
    console.error('❌ Error exporting tickets:', error);
    console.error('Stack:', error.stack);
    res.status(500).json({ 
      error: 'Failed to export tickets',
      message: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// GET /api/admin/tickets/template - Download import template
app.get('/api/admin/tickets/template', requireAuth, requireAdmin, (req, res) => {
  try {
    const buffer = importExportService.generateTemplate();
    
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename=ticket-import-template.xlsx');
    res.send(buffer);
  } catch (error) {
    console.error('Error generating template:', error);
    res.status(500).json({ error: 'Failed to generate template' });
  }
});

// Print Endpoints

// POST /api/admin/tickets/print - Generate print job
app.post('/api/admin/tickets/print', requireAuth, requireAdmin, async (req, res) => {
  try {
    const {
      raffle_id,
      category,
      start_ticket,
      end_ticket,
      paper_type
    } = req.body;
    
    // Validate input
    if (!category || !start_ticket || !end_ticket) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }
    
    if (!['AVERY_16145', 'PRINTWORKS'].includes(paper_type)) {
      return res.status(400).json({ error: 'Invalid paper type' });
    }
    
    // Get tickets in range
    const tickets = await ticketService.getTicketsByRange(start_ticket, end_ticket);
    
    if (tickets.length === 0) {
      return res.status(404).json({ error: 'No tickets found in range' });
    }
    
    // Create print job
    const printJobId = await printService.createPrintJob({
      admin_id: req.session.user.id,
      raffle_id: raffle_id || 1,
      category,
      ticket_range_start: start_ticket,
      ticket_range_end: end_ticket,
      total_tickets: tickets.length,
      paper_type
    });
    
    // Generate PDF asynchronously
    setTimeout(async () => {
      try {
        const doc = await printService.generatePrintPDF(tickets, paper_type, printJobId);
        // PDF is generated but not streamed to response
        // In production, you'd save this to a file or cloud storage
        doc.end();
      } catch (error) {
        console.error('Error generating print PDF:', error);
        await printService.updatePrintJobStatus(printJobId, 'failed', 0);
      }
    }, 100);
    
    res.json({
      success: true,
      printJobId,
      totalTickets: tickets.length,
      message: 'Print job started'
    });
  } catch (error) {
    console.error('Error creating print job:', error);
    res.status(500).json({ error: 'Failed to create print job: ' + error.message });
  }
});

// POST /api/admin/tickets/print/generate - Generate and download PDF immediately
app.post('/api/admin/tickets/print/generate', requireAuth, requireAdmin, async (req, res) => {
  try {
    const {
      raffle_id,
      category,
      start_ticket,
      end_ticket,
      paper_type,
      use_custom_template,
      template_id
    } = req.body;
    
    // Validate input
    if (!category || !start_ticket || !end_ticket) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }
    
    if (!['AVERY_16145', 'PRINTWORKS'].includes(paper_type)) {
      return res.status(400).json({ error: 'Invalid paper type' });
    }
    
    // Get tickets in range
    let tickets = await ticketService.getTicketsByRange(start_ticket, end_ticket);
    
    // If no tickets exist, create them
    if (tickets.length === 0) {
      // Parse ticket range
      const startParts = start_ticket.split('-');
      const endParts = end_ticket.split('-');
      
      if (startParts[0] !== endParts[0]) {
        return res.status(400).json({ error: 'Ticket range must be within the same category' });
      }
      
      const categoryCode = startParts[0];
      const startNum = parseInt(startParts[1]);
      const endNum = parseInt(endParts[1]);
      
      // Get category info
      const categoryInfo = await db.get(
        'SELECT id, price FROM ticket_categories WHERE raffle_id = ? AND category_code = ?',
        [raffle_id || 1, categoryCode]
      );
      
      if (!categoryInfo) {
        return res.status(404).json({ error: 'Category not found' });
      }
      
      // Create tickets
      await ticketService.createTicketsForRange({
        raffle_id: raffle_id || 1,
        category_id: categoryInfo.id,
        category: categoryCode,
        price: categoryInfo.price,
        startNum,
        endNum
      });
      
      // Fetch newly created tickets
      tickets = await ticketService.getTicketsByRange(start_ticket, end_ticket);
    }
    
    // Create print job
    const printJobId = await printService.createPrintJob({
      admin_id: req.session.user.id,
      raffle_id: raffle_id || 1,
      category,
      ticket_range_start: start_ticket,
      ticket_range_end: end_ticket,
      total_tickets: tickets.length,
      paper_type
    });
    
    let doc;
    
    // Check if using custom template
    if (use_custom_template && template_id) {
      const customTemplate = await db.get('SELECT * FROM ticket_templates WHERE id = ?', [template_id]);
      
      if (!customTemplate) {
        return res.status(404).json({ error: 'Custom template not found' });
      }
      
      // Generate PDF with custom template
      doc = await printService.generateCustomTemplatePDF(tickets, customTemplate, paper_type, printJobId);
    } else {
      // Generate PDF with default template
      doc = await printService.generatePrintPDF(tickets, paper_type, printJobId);
    }
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=tickets-${category}-${start_ticket}-to-${end_ticket}.pdf`);
    
    doc.pipe(res);
    doc.end();
    
  } catch (error) {
    console.error('Error generating print PDF:', error);
    res.status(500).json({ error: 'Failed to generate PDF: ' + error.message });
  }
});

// GET /api/admin/print-jobs - List print jobs
app.get('/api/admin/print-jobs', requireAuth, requireAdmin, async (req, res) => {
  try {
    const filters = {
      raffle_id: req.query.raffle_id,
      status: req.query.status,
      limit: req.query.limit ? parseInt(req.query.limit) : 50
    };
    
    const jobs = await printService.getPrintJobs(filters);
    res.json(jobs);
  } catch (error) {
    console.error('Error fetching print jobs:', error);
    res.status(500).json({ error: 'Failed to fetch print jobs' });
  }
});

// GET /api/admin/print-jobs/:id - Get print job details
app.get('/api/admin/print-jobs/:id', requireAuth, requireAdmin, async (req, res) => {
  try {
    const job = await printService.getPrintJob(req.params.id);
    
    if (!job) {
      return res.status(404).json({ error: 'Print job not found' });
    }
    
    res.json(job);
  } catch (error) {
    console.error('Error fetching print job:', error);
    res.status(500).json({ error: 'Failed to fetch print job' });
  }
});

// GET /api/admin/tickets/print-batch - Get tickets for printing
app.get('/api/admin/tickets/print-batch', requireAuth, requireAdmin, async (req, res) => {
  try {
    const { category, start, end } = req.query;
    
    if (!category || !start || !end) {
      return res.status(400).json({ error: 'Missing required parameters: category, start, end' });
    }
    
    // Build ticket range
    const startTicket = `${category}-${String(start).padStart(9, '0')}`;
    const endTicket = `${category}-${String(end).padStart(9, '0')}`;
    
    // Get tickets in range
    const tickets = await ticketService.getTicketsByRange(startTicket, endTicket);
    
    // Generate QR codes for preview
    const ticketsWithQR = await Promise.all(tickets.map(async (ticket) => {
      const qrCode = await qrcodeService.generateQRCodeDataURL(
        qrcodeService.generateVerificationURL(ticket.ticket_number),
        { size: 150 }
      );
      
      return {
        id: ticket.id,
        barcode: ticket.barcode || ticket.ticket_number,
        category: ticket.category,
        price: ticket.price,
        qr_code: qrCode,
        status: ticket.status,
        ticket_number: ticket.ticket_number
      };
    }));
    
    // Calculate sheets needed (10 tickets per sheet for Avery 16145)
    const sheets = Math.ceil(ticketsWithQR.length / 10);
    
    res.json({
      tickets: ticketsWithQR,
      sheets: sheets,
      total_tickets: ticketsWithQR.length
    });
  } catch (error) {
    console.error('Error fetching tickets for printing:', error);
    res.status(500).json({ error: 'Failed to fetch tickets: ' + error.message });
  }
});

// POST /api/admin/tickets/mark-printed - Mark tickets as printed
app.post('/api/admin/tickets/mark-printed', requireAuth, requireAdmin, async (req, res) => {
  try {
    const { ticket_ids } = req.body;
    
    if (!ticket_ids || !Array.isArray(ticket_ids)) {
      return res.status(400).json({ error: 'ticket_ids must be an array' });
    }
    
    let marked = 0;
    for (const ticketId of ticket_ids) {
      try {
        await db.run(
          `UPDATE tickets 
           SET printed = ${db.USE_POSTGRES ? 'TRUE' : '1'}, 
               printed_at = ${db.getCurrentTimestamp()},
               print_count = print_count + 1
           WHERE id = ?`,
          [ticketId]
        );
        marked++;
      } catch (error) {
        console.error(`Error marking ticket ${ticketId} as printed:`, error);
      }
    }
    
    res.json({
      success: true,
      marked: marked
    });
  } catch (error) {
    console.error('Error marking tickets as printed:', error);
    res.status(500).json({ error: 'Failed to mark tickets as printed: ' + error.message });
  }
});

// ============================================================================
// BULK TICKET GENERATION ENDPOINTS
// ============================================================================

// Track generation progress globally
let generationProgress = {
  total: 1500000,
  completed: 0,
  abc: 0,
  efg: 0,
  jkl: 0,
  xyz: 0,
  inProgress: false,
  error: null
};

// POST /api/admin/tickets/generate-all - Generate all 1.5M tickets with barcodes and QR codes
app.post('/api/admin/tickets/generate-all', requireAuth, requireAdmin, async (req, res) => {
  console.log('📥 POST /api/admin/tickets/generate-all received');
  
  if (generationProgress.inProgress) {
    console.log('⚠️ Generation already in progress, rejecting request');
    return res.status(400).json({ 
      error: 'Generation already in progress',
      progress: generationProgress
    });
  }
  
  try {
    console.log('✅ Starting ticket generation process...');
    
    // Reset progress
    generationProgress.inProgress = true;
    generationProgress.completed = 0;
    generationProgress.abc = 0;
    generationProgress.efg = 0;
    generationProgress.jkl = 0;
    generationProgress.xyz = 0;
    generationProgress.error = null;
    
    console.log('📊 Progress reset:', generationProgress);
    
    res.json({ 
      success: true,
      message: 'Generation started', 
      total: 1500000 
    });
    
    console.log('🚀 Launching background generation task...');
    
    // Run generation in background with error handling
    setImmediate(() => {
      generateAllTicketsBackground().catch(error => {
        console.error('❌ CRITICAL: Background generation crashed:', error);
        console.error('❌ Stack trace:', error.stack);
        generationProgress.inProgress = false;
        generationProgress.error = error.message;
      });
    });
    
  } catch (error) {
    console.error('❌ Error starting generation:', error);
    console.error('❌ Stack trace:', error.stack);
    generationProgress.inProgress = false;
    generationProgress.error = error.message;
    
    return res.status(500).json({ 
      error: 'Failed to start generation', 
      details: error.message 
    });
  }
});

// GET /api/admin/tickets/generation-progress - Get current generation progress
app.get('/api/admin/tickets/generation-progress', requireAuth, requireAdmin, (req, res) => {
  res.json(generationProgress);
});

// POST /api/admin/tickets/generate-test - Generate test batch (1,000 tickets)
app.post('/api/admin/tickets/generate-test', requireAuth, requireAdmin, async (req, res) => {
  console.log('🧪 TEST MODE: Generating 1,000 test tickets');
  
  try {
    const ticketService = require('./services/ticketService');
    
    // Use raffle ID 1
    const raffleId = 1;
    const TICKETS_PER_CATEGORY = 250;
    
    // Step 1: Check if raffle exists
    let raffle = await db.get('SELECT id FROM raffles WHERE id = ?', [raffleId]);
    if (!raffle) {
      return res.status(404).json({ 
        error: 'Raffle not found. Please run full generation first to create raffle and categories.' 
      });
    }
    console.log('✅ Raffle found:', raffle.id);
    
    // Step 2: Use all valid categories for testing (250 tickets per category = 1,000 total)
    const testCategories = [
      { code: 'ABC', price: 100 },
      { code: 'EFG', price: 50 },
      { code: 'JKL', price: 20 },
      { code: 'XYZ', price: 10 }
    ];
    
    let totalCreated = 0;
    
    // Generate tickets for each category
    for (const cat of testCategories) {
      // Get category record
      const category = await db.get(
        'SELECT id FROM ticket_categories WHERE raffle_id = ? AND category_code = ?',
        [raffleId, cat.code]
      );
      
      if (!category) {
        console.log(`⚠️ Category ${cat.code} not found, skipping...`);
        continue;
      }
      
      console.log(`🎫 Generating ${TICKETS_PER_CATEGORY} test tickets for ${cat.code}...`);
      
      // Get last ticket number for this category
      const lastTicket = await db.get(
        'SELECT ticket_number FROM tickets WHERE raffle_id = ? AND category_id = ? ORDER BY id DESC LIMIT 1',
        [raffleId, category.id]
      );
      
      let startNum = 1;
      if (lastTicket) {
        // Extract number from ticket like "ABC-000123" (6-digit format)
        const match = lastTicket.ticket_number.match(/-(\d+)$/);
        if (match) {
          startNum = parseInt(match[1], 10) + 1;
        }
      }
      
      // Generate tickets for this category
      const result = await ticketService.generateTickets({
        raffle_id: raffleId,
        category_id: category.id,
        category: cat.code,
        startNum: startNum,
        endNum: startNum + TICKETS_PER_CATEGORY - 1,
        price: cat.price,
        progressCallback: (progress) => {
          console.log(`  ${cat.code}: ${progress.created} / ${TICKETS_PER_CATEGORY} tickets`);
        }
      });
      
      totalCreated += result.created;
      console.log(`✅ ${cat.code}: Generated ${result.created} tickets`);
    }
    
    console.log('✅ TEST COMPLETE: Generated', totalCreated, 'total tickets');
    
    res.json({
      success: true,
      created: totalCreated,
      message: `Test generation completed successfully! Generated ${totalCreated} tickets across all categories.`
    });
    
  } catch (error) {
    console.error('❌ TEST FAILED:', error.message);
    console.error('❌ Stack:', error.stack);
    res.status(500).json({ 
      error: error.message,
      details: 'Check server logs for full error details'
    });
  }
});

/**
 * Background task to generate all tickets for all categories
 */
async function generateAllTicketsBackground() {
  const ticketService = require('./services/ticketService');
  
  try {
    console.log('');
    console.log('='.repeat(60));
    console.log('🚀 STARTING BULK TICKET GENERATION');
    console.log('='.repeat(60));
    console.log('');
    
    // Step 1: Check database connection
    console.log('📡 Step 1: Testing database connection...');
    try {
      await db.get('SELECT 1 as test');
      console.log('✅ Database connection OK');
    } catch (dbError) {
      console.error('❌ Database connection FAILED:', dbError.message);
      throw new Error(`Database not accessible: ${dbError.message}`);
    }
    
    // Step 2: Check if tables exist
    console.log('📊 Step 2: Checking if required tables exist...');
    try {
      const tables = await db.all(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('raffles', 'ticket_categories', 'tickets')"
      );
      console.log('✅ Found tables:', tables.map(t => t.name).join(', '));
      
      if (tables.length < 3) {
        console.log('⚠️ Missing tables, will attempt to create...');
      }
    } catch (tableError) {
      console.error('❌ Error checking tables:', tableError.message);
    }
    
    // Step 3: Check/create raffle
    console.log('🎫 Step 3: Checking for raffle record...');
    let raffle = await db.get('SELECT id FROM raffles WHERE id = 1');
    
    if (!raffle) {
      console.log('⚠️ No raffle found, creating default raffle...');
      try {
        await db.run(
          `INSERT INTO raffles (id, name, description, draw_date, status, created_at)
           VALUES (1, 'Main Raffle', 'Main raffle event', ${db.getCurrentTimestamp()}, 'active', ${db.getCurrentTimestamp()})`
        );
        raffle = { id: 1 };
        console.log('✅ Default raffle created with id: 1');
      } catch (raffleError) {
        console.error('❌ Failed to create raffle:', raffleError.message);
        throw new Error(`Cannot create raffle: ${raffleError.message}`);
      }
    } else {
      console.log('✅ Raffle exists with id:', raffle.id);
    }
    
    // Step 4: Define and create categories
    console.log('📝 Step 4: Setting up ticket categories...');
    const categories = [
      { code: 'ABC', price: 100, count: 375000 },
      { code: 'EFG', price: 50, count: 375000 },
      { code: 'JKL', price: 20, count: 375000 },
      { code: 'XYZ', price: 10, count: 375000 }
    ];
    
    console.log('✅ Categories defined:', categories.map(c => c.code).join(', '));
    
    // Step 5: Generate tickets for each category
    for (const category of categories) {
      console.log('');
      console.log('-'.repeat(60));
      console.log(`📝 Generating ${category.code} tickets...`);
      console.log(`   Price: $${category.price}, Count: ${category.count.toLocaleString()}`);
      console.log('-'.repeat(60));
      
      // Get or create category record
      let categoryRecord = await db.get(
        'SELECT id FROM ticket_categories WHERE raffle_id = ? AND category_code = ?',
        [raffle.id, category.code]
      );
      
      if (!categoryRecord) {
        console.log(`⚠️ Category ${category.code} not found in database, creating...`);
        try {
          const result = await db.run(
            `INSERT INTO ticket_categories (raffle_id, category_code, category_name, price, total_tickets, created_at)
             VALUES (?, ?, ?, ?, ?, ${db.getCurrentTimestamp()})`,
            [raffle.id, category.code, `${category.code} Category`, category.price, category.count]
          );
          categoryRecord = { id: result.lastID };
          console.log(`✅ Category ${category.code} created with id: ${categoryRecord.id}`);
        } catch (catError) {
          console.error(`❌ Failed to create category ${category.code}:`, catError.message);
          throw new Error(`Cannot create category: ${catError.message}`);
        }
      } else {
        console.log(`✅ Category ${category.code} exists with id: ${categoryRecord.id}`);
      }
      
      // Generate tickets with progress callback
      console.log(`🎫 Starting ticket generation for ${category.code}...`);
      try {
        await ticketService.generateTickets({
          raffle_id: raffle.id,
          category_id: categoryRecord.id,
          category: category.code,
          startNum: 1,
          endNum: category.count,
          price: category.price,
          progressCallback: (progress) => {
            // Update global progress
            generationProgress[category.code.toLowerCase()] = progress.created;
            generationProgress.completed = 
              generationProgress.abc + 
              generationProgress.efg + 
              generationProgress.jkl + 
              generationProgress.xyz;
            
            // Log every 10,000 tickets
            if (progress.created % 10000 === 0) {
              console.log(`   ${category.code}: ${progress.created.toLocaleString()} / ${category.count.toLocaleString()} (${progress.percent}%)`);
            }
          }
        });
        
        console.log(`✅ Completed ${category.code}: ${category.count.toLocaleString()} tickets`);
      } catch (genError) {
        console.error(`❌ Error generating ${category.code} tickets:`, genError.message);
        console.error('❌ Stack:', genError.stack);
        throw new Error(`Failed to generate ${category.code} tickets: ${genError.message}`);
      }
    }
    
    generationProgress.inProgress = false;
    console.log('');
    console.log('='.repeat(60));
    console.log('🎉 ALL 1.5M TICKETS GENERATED SUCCESSFULLY!');
    console.log('='.repeat(60));
    console.log('');
    
  } catch (error) {
    console.error('');
    console.error('='.repeat(60));
    console.error('❌ TICKET GENERATION FAILED');
    console.error('='.repeat(60));
    console.error('❌ Error message:', error.message);
    console.error('❌ Stack trace:', error.stack);
    console.error('='.repeat(60));
    console.error('');
    
    generationProgress.inProgress = false;
    generationProgress.error = error.message;
  }
}

// ============================================================================
// TEMPLATE MANAGEMENT ENDPOINTS
// ============================================================================

// Configure multer for template uploads
const templateStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, 'uploads', 'templates');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${Date.now()}-${file.originalname}`;
    cb(null, uniqueName);
  }
});

const templateUpload = multer({ 
  storage: templateStorage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|pdf/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    if (extname && mimetype) {
      cb(null, true);
    } else {
      cb(new Error('Only PNG, JPG, and PDF files allowed'));
    }
  }
});

// Image processing function
async function processTemplateImage(inputPath, width, height, fitMode) {
  const outputPath = inputPath.replace(/\.(jpg|jpeg|png|pdf)$/i, '-processed.png');
  
  let sharpInstance = sharp(inputPath);
  
  switch (fitMode) {
    case 'stretch':
      sharpInstance = sharpInstance.resize(width, height, { fit: 'fill' });
      break;
    case 'aspect':
      sharpInstance = sharpInstance.resize(width, height, { fit: 'contain', background: '#ffffff' });
      break;
    case 'crop':
      sharpInstance = sharpInstance.resize(width, height, { fit: 'cover' });
      break;
    default:
      sharpInstance = sharpInstance.resize(width, height, { fit: 'contain', background: '#ffffff' });
  }
  
  await sharpInstance.png().toFile(outputPath);
  
  return outputPath;
}

// POST /api/admin/templates/upload - Upload new custom template
app.post('/api/admin/templates/upload', requireAuth, requireAdmin, 
  templateUpload.fields([
    { name: 'frontImage', maxCount: 1 },
    { name: 'backImage', maxCount: 1 }
  ]), 
  async (req, res) => {
    try {
      const { templateName, fitMode } = req.body;
      
      if (!req.files || !req.files['frontImage'] || !req.files['backImage']) {
        return res.status(400).json({ error: 'Both front and back images are required' });
      }
      
      const frontImage = req.files['frontImage'][0];
      const backImage = req.files['backImage'][0];
      
      // Process images with Sharp (resize to exact dimensions)
      const targetWidth = 1650;  // 5.5" at 300 DPI
      const targetHeight = 525;  // 1.75" at 300 DPI
      
      const processedFrontPath = await processTemplateImage(
        frontImage.path, 
        targetWidth, 
        targetHeight, 
        fitMode || 'aspect'
      );
      const processedBackPath = await processTemplateImage(
        backImage.path, 
        targetWidth, 
        targetHeight, 
        fitMode || 'aspect'
      );
      
      // Delete original files
      fs.unlinkSync(frontImage.path);
      fs.unlinkSync(backImage.path);
      
      // Save to database
      const result = await db.run(
        `INSERT INTO ticket_templates (name, front_image_path, back_image_path, fit_mode) 
         VALUES (?, ?, ?, ?)`,
        [templateName, processedFrontPath, processedBackPath, fitMode || 'aspect']
      );
      
      res.json({
        success: true,
        templateId: result.lastID,
        message: 'Template uploaded successfully'
      });
    } catch (error) {
      console.error('Template upload error:', error);
      res.status(500).json({ error: error.message });
    }
  }
);

// GET /api/admin/templates - List all templates
app.get('/api/admin/templates', requireAuth, requireAdmin, async (req, res) => {
  try {
    const templates = await db.all('SELECT * FROM ticket_templates ORDER BY created_at DESC');
    res.json({ templates });
  } catch (error) {
    console.error('Error fetching templates:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /api/admin/templates/:id - Get specific template
app.get('/api/admin/templates/:id', requireAuth, requireAdmin, async (req, res) => {
  try {
    const template = await db.get('SELECT * FROM ticket_templates WHERE id = ?', [req.params.id]);
    if (!template) {
      return res.status(404).json({ error: 'Template not found' });
    }
    res.json({ template });
  } catch (error) {
    console.error('Error fetching template:', error);
    res.status(500).json({ error: error.message });
  }
});

// PUT /api/admin/templates/:id/activate - Set active template
app.put('/api/admin/templates/:id/activate', requireAuth, requireAdmin, async (req, res) => {
  try {
    // Deactivate all templates
    await db.run(`UPDATE ticket_templates SET is_active = ${db.USE_POSTGRES ? 'FALSE' : '0'}`);
    // Activate selected template
    await db.run(
      `UPDATE ticket_templates SET is_active = ${db.USE_POSTGRES ? 'TRUE' : '1'} WHERE id = ?`, 
      [req.params.id]
    );
    res.json({ success: true, message: 'Template activated' });
  } catch (error) {
    console.error('Error activating template:', error);
    res.status(500).json({ error: error.message });
  }
});

// DELETE /api/admin/templates/:id - Delete template
app.delete('/api/admin/templates/:id', requireAuth, requireAdmin, async (req, res) => {
  try {
    const template = await db.get('SELECT * FROM ticket_templates WHERE id = ?', [req.params.id]);
    if (template) {
      // Delete files if they exist
      try {
        if (fs.existsSync(template.front_image_path)) {
          fs.unlinkSync(template.front_image_path);
        }
        if (fs.existsSync(template.back_image_path)) {
          fs.unlinkSync(template.back_image_path);
        }
      } catch (fileError) {
        console.warn('Error deleting template files:', fileError);
      }
      
      // Delete from DB
      await db.run('DELETE FROM ticket_templates WHERE id = ?', [req.params.id]);
    }
    res.json({ success: true, message: 'Template deleted' });
  } catch (error) {
    console.error('Error deleting template:', error);
    res.status(500).json({ error: error.message });
  }
});

// Serve uploaded template images
app.use('/uploads/templates', requireAuth, requireAdmin, express.static(path.join(__dirname, 'uploads', 'templates')));

// ============================================================================
// REPORTS ENDPOINTS
// ============================================================================

// Reports Endpoints

// GET /api/admin/reports/revenue - Revenue report by category
app.get('/api/admin/reports/revenue', requireAuth, requireAdmin, async (req, res) => {
  try {
    const raffleId = req.query.raffle_id || 1;
    
    const revenue = await db.all(`
      SELECT 
        tc.category_code,
        tc.category_name,
        tc.price,
        COUNT(t.id) as tickets_sold,
        SUM(t.price) as total_revenue
      FROM ticket_categories tc
      LEFT JOIN tickets t ON tc.id = t.category_id AND t.status = 'SOLD'
      WHERE tc.raffle_id = ?
      GROUP BY tc.id, tc.category_code, tc.category_name, tc.price
      ORDER BY tc.category_code
    `, [raffleId]);
    
    res.json(revenue);
  } catch (error) {
    console.error('Error fetching revenue report:', error);
    res.status(500).json({ error: 'Failed to fetch revenue report' });
  }
});

// Public Endpoints

// GET /api/tickets/verify/:ticketNumber - Verify a ticket
app.get('/api/tickets/verify/:ticketNumber', async (req, res) => {
  try {
    const ticketNumber = req.params.ticketNumber;
    const ticket = await ticketService.getTicketByNumber(ticketNumber);
    
    if (!ticket) {
      return res.status(404).json({ 
        valid: false,
        error: 'Ticket not found' 
      });
    }
    
    res.json({
      valid: true,
      ticket: {
        ticket_number: ticket.ticket_number,
        category: ticket.category,
        price: ticket.price,
        status: ticket.status,
        printed: ticket.printed
      }
    });
  } catch (error) {
    console.error('Error verifying ticket:', error);
    res.status(500).json({ error: 'Failed to verify ticket' });
  }
});

// ============================================================================
// END RAFFLE TICKET SYSTEM API ENDPOINTS
// ============================================================================

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
