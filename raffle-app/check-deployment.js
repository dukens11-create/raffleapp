#!/usr/bin/env node

/**
 * Deployment Validation Script
 * 
 * This script validates the deployment configuration and checks:
 * - Required environment variables
 * - Database connectivity
 * - File permissions
 * - Critical API endpoints
 * 
 * Usage:
 *   node check-deployment.js [--url=https://your-domain.com]
 */

const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');

// Color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

// Parse command line arguments
const args = process.argv.slice(2);
let deploymentUrl = null;

args.forEach(arg => {
  if (arg.startsWith('--url=')) {
    deploymentUrl = arg.substring(6);
  }
});

// Load environment variables if .env exists
const envPath = path.join(__dirname, '.env');
if (fs.existsSync(envPath)) {
  require('dotenv').config({ path: envPath });
  console.log(`${colors.blue}ℹ${colors.reset} Loaded environment variables from .env\n`);
}

let checksPassed = 0;
let checksWarning = 0;
let checksFailed = 0;

/**
 * Print a check result
 */
function printCheck(status, message) {
  if (status === 'pass') {
    console.log(`${colors.green}✓${colors.reset} ${message}`);
    checksPassed++;
  } else if (status === 'warn') {
    console.log(`${colors.yellow}⚠${colors.reset} ${message}`);
    checksWarning++;
  } else {
    console.log(`${colors.red}✗${colors.reset} ${message}`);
    checksFailed++;
  }
}

/**
 * Print a section header
 */
function printSection(title) {
  console.log(`\n${colors.cyan}${title}${colors.reset}`);
  console.log('='.repeat(title.length));
}

/**
 * Check environment variables
 */
function checkEnvironmentVariables() {
  printSection('Environment Variables');

  // Critical variables
  const criticalVars = [
    { name: 'NODE_ENV', required: false, expected: 'production' },
    { name: 'PORT', required: false, default: '3000 or 10000' },
    { name: 'SESSION_SECRET', required: true, minLength: 32 },
  ];

  // Database
  if (process.env.DATABASE_URL) {
    printCheck('pass', 'DATABASE_URL is configured (PostgreSQL)');
    
    // Validate PostgreSQL URL format
    if (process.env.DATABASE_URL.startsWith('postgresql://') || 
        process.env.DATABASE_URL.startsWith('postgres://')) {
      printCheck('pass', 'DATABASE_URL has valid PostgreSQL format');
    } else {
      printCheck('warn', 'DATABASE_URL might have invalid format');
    }
  } else {
    if (process.env.NODE_ENV === 'production') {
      printCheck('fail', 'DATABASE_URL not set - Required for production (data will be lost!)');
    } else {
      printCheck('warn', 'DATABASE_URL not set - Using SQLite (development only)');
    }
  }

  // Session Secret
  if (process.env.SESSION_SECRET) {
    if (process.env.SESSION_SECRET.length >= 32) {
      printCheck('pass', `SESSION_SECRET configured (${process.env.SESSION_SECRET.length} chars)`);
    } else {
      printCheck('warn', `SESSION_SECRET is too short (${process.env.SESSION_SECRET.length} chars, should be >= 32)`);
    }
  } else {
    printCheck('fail', 'SESSION_SECRET not set - Will be auto-generated (sessions lost on restart)');
  }

  // Node Environment
  if (process.env.NODE_ENV) {
    if (process.env.NODE_ENV === 'production') {
      printCheck('pass', `NODE_ENV=${process.env.NODE_ENV}`);
    } else {
      printCheck('warn', `NODE_ENV=${process.env.NODE_ENV} (should be 'production' for deployment)`);
    }
  } else {
    printCheck('warn', 'NODE_ENV not set (server defaults to production in startup validation)');
  }

  // Port
  if (process.env.PORT) {
    printCheck('pass', `PORT=${process.env.PORT}`);
  } else {
    printCheck('warn', 'PORT not set (will default to 3000 or platform default)');
  }

  // CORS Configuration
  if (process.env.ALLOWED_ORIGINS) {
    printCheck('pass', `ALLOWED_ORIGINS configured`);
  } else {
    printCheck('warn', 'ALLOWED_ORIGINS not set (will use secure defaults)');
  }

  // Email configuration
  if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
    printCheck('pass', 'Email configuration present');
  } else {
    printCheck('warn', 'Email configuration missing (notifications will be disabled)');
  }

  // Admin setup token
  if (process.env.ADMIN_SETUP_TOKEN) {
    printCheck('pass', 'ADMIN_SETUP_TOKEN configured');
  } else {
    printCheck('warn', 'ADMIN_SETUP_TOKEN not set (/api/setup-admin will be disabled)');
  }

  // APP_URL
  if (process.env.APP_URL) {
    printCheck('pass', `APP_URL=${process.env.APP_URL}`);
  } else {
    printCheck('warn', 'APP_URL not set (will use default or platform URL)');
  }
}

/**
 * Check database connectivity
 */
async function checkDatabaseConnectivity() {
  printSection('Database Connectivity');

  try {
    const db = require('./db');
    
    // Test basic query
    const result = await db.get('SELECT 1 as test');
    if (result && result.test === 1) {
      printCheck('pass', 'Database connection successful');
    } else {
      printCheck('fail', 'Database query returned unexpected result');
    }

    // Check if tables exist
    const tablesQuery = process.env.DATABASE_URL
      ? `SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema = 'public'`
      : `SELECT COUNT(*) as count FROM sqlite_master WHERE type='table'`;
    
    const tables = await db.get(tablesQuery);
    if (tables && tables.count > 0) {
      printCheck('pass', `Database has ${tables.count} tables`);
    } else {
      printCheck('warn', 'Database has no tables (migrations may need to run)');
    }

    // Check for critical tables
    const criticalTables = ['sellers', 'tickets', 'sales'];
    for (const table of criticalTables) {
      try {
        const checkQuery = process.env.DATABASE_URL
          ? `SELECT COUNT(*) as count FROM ${table} LIMIT 1`
          : `SELECT COUNT(*) as count FROM ${table} LIMIT 1`;
        
        await db.get(checkQuery);
        printCheck('pass', `Table '${table}' exists`);
      } catch (error) {
        printCheck('warn', `Table '${table}' might not exist: ${error.message}`);
      }
    }

  } catch (error) {
    printCheck('fail', `Database connection failed: ${error.message}`);
  }
}

/**
 * Check file permissions
 */
function checkFilePermissions() {
  printSection('File Permissions');

  // Check if server.js is readable
  const serverPath = path.join(__dirname, 'server.js');
  try {
    fs.accessSync(serverPath, fs.constants.R_OK);
    printCheck('pass', 'server.js is readable');
  } catch (error) {
    printCheck('fail', `server.js is not readable: ${error.message}`);
  }

  // Check if db.js is readable
  const dbPath = path.join(__dirname, 'db.js');
  try {
    fs.accessSync(dbPath, fs.constants.R_OK);
    printCheck('pass', 'db.js is readable');
  } catch (error) {
    printCheck('fail', `db.js is not readable: ${error.message}`);
  }

  // Check if uploads directory exists and is writable
  const uploadsDir = process.env.UPLOAD_DIR || path.join(__dirname, 'uploads');
  try {
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
      printCheck('pass', 'uploads directory created');
    } else {
      fs.accessSync(uploadsDir, fs.constants.W_OK);
      printCheck('pass', 'uploads directory is writable');
    }
  } catch (error) {
    printCheck('warn', `uploads directory issue: ${error.message}`);
  }

  // Check if ticket_exports directory exists and is writable
  const exportsDir = path.join(__dirname, 'ticket_exports');
  try {
    if (!fs.existsSync(exportsDir)) {
      fs.mkdirSync(exportsDir, { recursive: true });
      printCheck('pass', 'ticket_exports directory created');
    } else {
      fs.accessSync(exportsDir, fs.constants.W_OK);
      printCheck('pass', 'ticket_exports directory is writable');
    }
  } catch (error) {
    printCheck('warn', `ticket_exports directory issue: ${error.message}`);
  }
}

/**
 * Test API endpoints
 */
async function testApiEndpoints(baseUrl) {
  printSection('API Endpoints');

  const endpoints = [
    { path: '/health', name: 'Health Check' },
    { path: '/api/health', name: 'API Health Check' },
    { path: '/api/database-status', name: 'Database Status' },
  ];

  for (const endpoint of endpoints) {
    const url = `${baseUrl}${endpoint.path}`;
    try {
      const response = await makeRequest(url);
      if (response.statusCode === 200) {
        printCheck('pass', `${endpoint.name} (${endpoint.path}) - Status ${response.statusCode}`);
      } else {
        printCheck('warn', `${endpoint.name} (${endpoint.path}) - Status ${response.statusCode}`);
      }
    } catch (error) {
      printCheck('fail', `${endpoint.name} (${endpoint.path}) - ${error.message}`);
    }
  }
}

/**
 * Make HTTP/HTTPS request
 */
function makeRequest(url) {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(url);
    const client = parsedUrl.protocol === 'https:' ? https : http;

    const req = client.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, data });
      });
    });

    // Set timeout after creating the request (preferred method)
    req.setTimeout(10000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.on('error', reject);
  });
}

/**
 * Main validation function
 */
async function runValidation() {
  console.log(`\n${colors.magenta}${'='.repeat(60)}${colors.reset}`);
  console.log(`${colors.magenta}  Raffle App Deployment Validation${colors.reset}`);
  console.log(`${colors.magenta}${'='.repeat(60)}${colors.reset}\n`);

  // Run all checks
  checkEnvironmentVariables();
  await checkDatabaseConnectivity();
  checkFilePermissions();

  // Test endpoints if URL provided
  if (deploymentUrl) {
    await testApiEndpoints(deploymentUrl);
  } else {
    printSection('API Endpoints');
    console.log(`${colors.blue}ℹ${colors.reset} Skipped (no URL provided)`);
    console.log(`  Run with --url=https://your-domain.com to test endpoints`);
  }

  // Print summary
  console.log(`\n${colors.magenta}${'='.repeat(60)}${colors.reset}`);
  console.log(`${colors.magenta}  Validation Summary${colors.reset}`);
  console.log(`${colors.magenta}${'='.repeat(60)}${colors.reset}\n`);

  console.log(`${colors.green}✓ Passed:${colors.reset} ${checksPassed}`);
  console.log(`${colors.yellow}⚠ Warnings:${colors.reset} ${checksWarning}`);
  console.log(`${colors.red}✗ Failed:${colors.reset} ${checksFailed}\n`);

  if (checksFailed > 0) {
    console.log(`${colors.red}❌ Deployment validation failed${colors.reset}`);
    console.log(`${colors.yellow}💡 Fix the failed checks before deploying${colors.reset}\n`);
    process.exit(1);
  } else if (checksWarning > 0) {
    console.log(`${colors.yellow}⚠️  Deployment validation passed with warnings${colors.reset}`);
    console.log(`${colors.yellow}💡 Review warnings for optimal configuration${colors.reset}\n`);
    process.exit(0);
  } else {
    console.log(`${colors.green}✅ Deployment validation passed${colors.reset}\n`);
    process.exit(0);
  }
}

// Run the validation
runValidation().catch(error => {
  console.error(`\n${colors.red}❌ Validation script error:${colors.reset}`, error);
  process.exit(1);
});
