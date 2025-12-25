// Global error handler for uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
});
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
console.log('Starting server.js...');
// ---------- ADMIN AUTH MIDDLEWARE ----------
console.log('Loaded modules and initialized Express.');
console.log('Setting up middleware and static files...');
console.log('Setting up database...');
console.log('Database setup complete.');
console.log('About to start server...');
// Two-factor authentication middleware for admin
function requireAdmin(req, res, next) {
  if (req.session && req.session.user && req.session.user.role === 'admin') {
    // If 2FA enabled, require verification
    if (req.session.user.twofa_enabled && !req.session.user.twofa_verified) {
      return res.status(401).json({ error: '2FA required', twofa: true });
    }
    return next();
  }
  res.status(403).send('Forbidden: Admins only');
}
const bwipjs = require('bwip-js');

const express = require("express");
require('dotenv').config();
// Payment gateway (Stripe)
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY || 'sk_test_yourkey');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');

// ...existing code...
const sqlite3 = require("sqlite3").verbose();
// ...existing code...
// ...existing code...
// ...existing code...
const multer = require('multer');
const fs = require('fs');
const nodemailer = require('nodemailer');
const bcrypt = require('bcrypt');

const app = express();
// CAPTCHA endpoint for login page (must be after app is defined)
app.get('/captcha', (req, res) => {
  const a = Math.floor(Math.random() * 10) + 1;
  const b = Math.floor(Math.random() * 10) + 1;
  req.session.captchaAnswer = a + b;
  res.json({ question: `What is ${a} + ${b}?` });
});

// Email config (replace with real credentials)
const mailTransport = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com',
    pass: 'your-app-password'
  }
});

function sendEmail(to, subject, text) {
  mailTransport.sendMail({
    from: 'your-email@gmail.com',
    to,
    subject,
    text
  }, (err, info) => {
    if (err) console.error('Email error:', err);
    else console.log('Email sent:', info.response);
  });
}
const xlsx = require('xlsx');
const PDFDocument = require('pdfkit');
const upload = multer({ dest: 'uploads/' });
const https = require('https');
const http = require('http');
// fs is already required above
// Security hardening
app.use(helmet());

// API rate limiting (100 requests per 15 min per IP)
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many requests, please try again later.'
});
app.use('/api/', apiLimiter);
const session = require('express-session');
const SQLiteStore = require('connect-sqlite3')(session);
app.use(session({
  secret: process.env.SESSION_SECRET || 'raffle_secret_key',
  resave: false,
  saveUninitialized: false,
  store: new SQLiteStore({ db: 'sessions.sqlite', dir: './' }),
  cookie: {
    secure: false, // set true if using HTTPS
    httpOnly: true,
    maxAge: 60 * 60 * 1000 // 1 hour session expiration
  }
}));
app.use(express.static('public'));
const PORT = process.env.PORT || 5000;
// SSL certificate paths (update to your actual certificate locations)
const SSL_KEY_PATH = '/etc/letsencrypt/live/yourdomain.com/privkey.pem';
const SSL_CERT_PATH = '/etc/letsencrypt/live/yourdomain.com/fullchain.pem';
let useHttps = false;
try {
  if (fs.existsSync(SSL_KEY_PATH) && fs.existsSync(SSL_CERT_PATH)) {
    useHttps = true;
  }
} catch (e) {}

// ---------- DATABASE ----------
const db = new sqlite3.Database("./raffle.db", (err) => {
  if (err) {
    console.error('Failed to open raffle.db:', err);
    process.exit(1);
  }
});
// ---------- AUDIT LOG TABLE ----------
db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action TEXT,
    details TEXT,
    user TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )`, (err) => {
    if (err) console.error('DB Error (audit_logs):', err);
  });
});

function logAudit(action, details, user) {
  db.run(
    'INSERT INTO audit_logs (action, details, user) VALUES (?, ?, ?)',
    [action, details, user || 'system']
  );
}

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    role TEXT,
    name TEXT,
    phone TEXT,
    password TEXT,
    email TEXT,
    twofa_enabled INTEGER DEFAULT 0,
    twofa_secret TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    permissions TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS tickets (
    number TEXT PRIMARY KEY,
    status TEXT,
    sold_by TEXT,
    sold_at TEXT,
    category TEXT
  )`);

  // Migration: add category column if not exists
  db.get("PRAGMA table_info(tickets)", (err, info) => {
    db.all("PRAGMA table_info(tickets)", (err, columns) => {
      if (!columns.some(col => col.name === 'category')) {
        db.run("ALTER TABLE tickets ADD COLUMN category TEXT");
      }
    });
  });

  // Create default admin
  db.get("SELECT * FROM users WHERE role='admin'", (err, row) => {
    if (!row) {
      db.run(
        "INSERT INTO users (role,name,phone,password) VALUES (?,?,?,?)",
        ["admin", "Admin", "0000000000", "admin123"]
      );
      console.log("✅ Admin created → phone: 0000000000 | password: admin123");
    }
  });
});

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// ---------- ADMIN ENDPOINTS ----------
// Remove user endpoint
app.post('/remove-user', requireAdmin, (req, res) => {
  const { phone } = req.body;
  if (!phone) return res.status(400).json({ error: 'Missing phone' });
  db.run('DELETE FROM users WHERE phone = ?', [phone], (err) => {
    if (err) return res.status(500).json({ error: 'Failed to remove user' });
    res.json({ success: true });
  });
});
// ---------- SELL TICKET ENDPOINT ----------
// Online ticket purchase endpoint
app.post('/buy-ticket-online', async (req, res) => {
  const { number, category, buyerName, email } = req.body;
  if (!number || !category || !buyerName || !email) return res.status(400).json({ error: 'Missing fields' });
  try {
    // Create Stripe Checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'usd',
          product_data: { name: `Raffle Ticket ${number}` },
          unit_amount: 500,
        },
        quantity: 1,
      }],
      mode: 'payment',
      success_url: req.headers.origin + '/success?number=' + number,
      cancel_url: req.headers.origin + '/cancel',
      customer_email: email
    });
    res.json({ url: session.url });
  } catch (err) {
    res.status(500).json({ error: 'Payment error' });
  }
});
// Seller sales history endpoint
app.get('/seller-sales', (req, res) => {
  const seller = req.query.seller;
  if (!seller) return res.json([]);
  db.all('SELECT number, sold_at FROM tickets WHERE sold_by = ? ORDER BY sold_at DESC', [seller], (err, rows) => {
    if (err) return res.status(500).json([]);
    res.json(rows || []);
  });
});
app.post('/sell', (req, res) => {
  const { ticketNumber, buyerName, sellerName } = req.body;
  if (!ticketNumber || !sellerName) {
    return res.status(400).json({ error: 'Missing ticket number or seller name' });
  }
  db.get('SELECT * FROM tickets WHERE number = ?', [ticketNumber], (err, ticket) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
    if (ticket.status === 'sold') return res.status(400).json({ error: 'Ticket already sold' });
    db.run('UPDATE tickets SET status = ?, sold_by = ?, sold_at = datetime("now") WHERE number = ?',
      ['sold', sellerName, ticketNumber],
      (err) => {
        if (err) return res.status(500).json({ error: 'Failed to update ticket' });
        res.json({ success: true, msg: `Ticket ${ticketNumber} sold to ${buyerName}` });
      }
    );
  });
});
// ---------- TICKET REFUND/CANCELLATION ENDPOINTS ----------
// Request refund (seller or admin)
app.post('/refund-ticket', (req, res) => {
  const { ticketNumber, reason } = req.body;
  if (!ticketNumber) return res.status(400).json({ error: 'Ticket number required' });
  db.get('SELECT * FROM tickets WHERE number = ?', [ticketNumber], (err, ticket) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
    if (ticket.status !== 'sold') return res.status(400).json({ error: 'Only sold tickets can be refunded' });
    db.run('UPDATE tickets SET status = ? WHERE number = ?', ['refunded', ticketNumber], (err2) => {
      if (err2) return res.status(500).json({ error: 'Failed to refund ticket' });
      logAudit('refund_ticket', `Ticket: ${ticketNumber}, Reason: ${reason || ''}`, req.session && req.session.user ? req.session.user.name : null);
      res.json({ success: true, msg: `Ticket ${ticketNumber} refunded` });
    });
  });
});

// Cancel ticket (admin only)
app.post('/cancel-ticket', requireAdmin, (req, res) => {
  const { ticketNumber, reason } = req.body;
  if (!ticketNumber) return res.status(400).json({ error: 'Ticket number required' });
  db.get('SELECT * FROM tickets WHERE number = ?', [ticketNumber], (err, ticket) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (!ticket) return res.status(404).json({ error: 'Ticket not found' });
    if (ticket.status === 'cancelled') return res.status(400).json({ error: 'Ticket already cancelled' });
    db.run('UPDATE tickets SET status = ? WHERE number = ?', ['cancelled', ticketNumber], (err2) => {
      if (err2) return res.status(500).json({ error: 'Failed to cancel ticket' });
      logAudit('cancel_ticket', `Ticket: ${ticketNumber}, Reason: ${reason || ''}`, req.session && req.session.user ? req.session.user.name : null);
      res.json({ success: true, msg: `Ticket ${ticketNumber} cancelled` });
    });
  });
});
// Barcode generation endpoint
app.get('/barcode/:text', (req, res) => {
  try {
    bwipjs.toBuffer({
      bcid:        'code128',       // Barcode type
      text:        req.params.text, // Text to encode
      scale:       3,               // 3x scaling factor
      height:      10,              // Bar height, in millimeters
      includetext: true,            // Show human-readable text
      textxalign:  'center',        // Always good to set this
    }, function (err, png) {
      if (err) {
        res.status(400).send('Error generating barcode');
      } else {
        res.type('image/png');
        res.send(png);
      }
    });
  } catch (e) {
    res.status(500).send('Barcode error');
  }
});
app.get('/users', (req, res) => {
  db.all("SELECT name, role, phone FROM users", (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(rows || []);
  });
});

// ---------- REGISTRATION PAGE ----------
app.get("/register", (req, res) => {
  // Generate random math question
  const a = Math.floor(Math.random() * 10) + 1;
  const b = Math.floor(Math.random() * 10) + 1;
  const captchaAnswer = a + b;
  req.session.captchaAnswer = captchaAnswer;
  res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Register - Raffle App</title>
  <link href="https://fonts.googleapis.com/css?family=Roboto:400,700&display=swap" rel="stylesheet">
  <link rel="icon" type="image/png" href="logo.png">
  <style>
    body {
      font-family: 'Roboto', Arial, sans-serif;
      background: linear-gradient(135deg, #0a174e 0%, #133b88 100%);
      color: #b3cfff;
      margin: 0;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
    }
    .register-card {
      background: #133b88;
      border-radius: 20px;
      box-shadow: 0 8px 32px rgba(10,23,78,0.15);
      padding: 2.5em 2em;
      border: 2px solid #0a174e;
      max-width: 350px;
      width: 100%;
      margin: 32px auto;
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    h2 {
      color: #b3cfff;
      text-shadow: 2px 2px 8px #09103a;
      margin-bottom: 1em;
      font-size: 2em;
    }
    input {
      padding: 12px;
      border-radius: 8px;
      border: 1.5px solid #1976d2;
      background: #102a5c;
      color: #b3cfff;
      font-size: 1.05em;
      margin-bottom: 10px;
      width: 100%;
      transition: border-color 0.2s, box-shadow 0.2s;
      box-shadow: 0 1px 4px rgba(25,118,210,0.10);
    }
    input:focus {
      border-color: #42a5f5;
      box-shadow: 0 2px 8px rgba(66,165,245,0.15);
      outline: none;
    }
    button {
      background: linear-gradient(90deg, #1976d2 0%, #133b88 100%);
      color: #fff;
      font-weight: bold;
      cursor: pointer;
      border: none;
      border-radius: 8px;
      padding: 12px 24px;
      font-size: 1.08em;
      box-shadow: 0 2px 8px rgba(25,118,210,0.15);
      transition: background 0.2s, box-shadow 0.2s;
      margin-bottom: 10px;
      width: 100%;
    }
    button:hover {
      background: linear-gradient(90deg, #133b88 0%, #1976d2 100%);
      box-shadow: 0 4px 16px rgba(25,118,210,0.25);
    }
    .msg-success {
      background: linear-gradient(90deg, #43e97b 0%, #38f9d7 100%);
      color: #0a174e;
      padding: 14px 22px;
      border-radius: 10px;
      font-weight: bold;
      box-shadow: 0 2px 8px rgba(67,233,123,0.15);
      margin-bottom: 16px;
      text-align: center;
      font-size: 1.08em;
      border: 1.5px solid #38f9d7;
    }
    .msg-error {
      background: linear-gradient(90deg, #ff5858 0%, #f09819 100%);
      color: #fff;
      padding: 14px 22px;
      border-radius: 10px;
      font-weight: bold;
      box-shadow: 0 2px 8px rgba(255,88,88,0.15);
      margin-bottom: 16px;
      text-align: center;
      font-size: 1.08em;
      border: 1.5px solid #f09819;
    }
    @media (max-width: 600px) {
      body {
        padding: 12px !important;
      }
      .register-card {
        padding: 1.2em 0.5em;
        border-radius: 0 !important;
        max-width: 98vw !important;
      }
      h2 {
        font-size: 1.32em !important;
      }
      button, input {
        font-size: 1.12em !important;
        padding: 14px !important;
        min-width: 44px;
        min-height: 44px;
      }
    }
  </style>
</head>
<body>
  <div class="register-card">
    <img src="logo.png" alt="Logo" style="display:block;margin:0 auto 18px auto;max-width:120px;">
    <h2>Register</h2>
    <input id="name" placeholder="Name" aria-label="Name"/>
    <input id="phone" placeholder="Phone" aria-label="Phone"/>
    <input id="password" type="password" placeholder="Password" aria-label="Password"/>
    <label for="captcha">What is ${a} + ${b}?</label>
    <input id="captcha" type="text" placeholder="Enter answer" aria-label="CAPTCHA"/>
    <button onclick="register()">Register</button>
    <p id="msg"></p>
  </div>
  <script>
  function register(){
    fetch('/register',{
      method:'POST',
      headers:{'Content-Type':'application/json'},
      body:JSON.stringify({
        name:name.value,
        phone:phone.value,
        password:password.value,
        captcha:captcha.value
      })
    }).then(r=>r.json()).then(d=>{
      msg.innerText = d.error || d.msg || '';
      if(d.success) setTimeout(()=>location.href='/', 1000);
    })
  }
  </script>
</body>
</html>
  `);
});

// ---------- REGISTRATION API ----------
app.post("/register", (req, res) => {
  const { name, phone, password, captcha } = req.body;
  if (!captcha || Number(captcha) !== req.session.captchaAnswer) {
    return res.json({ error: "Invalid CAPTCHA answer" });
  }
  if (!name || !phone || !password) return res.json({ error: "All fields required" });
  // Password strength: min 8 chars, 1 number, 1 letter
  if (!/^.*(?=.{8,})(?=.*\d)(?=.*[a-zA-Z]).*$/.test(password)) {
    return res.json({ error: "Password must be at least 8 characters, include a number and a letter." });
  }
  db.get("SELECT * FROM users WHERE phone=?", [phone], async (err, user) => {
    if (user) return res.json({ error: "Phone already registered" });
    try {
      const hash = await bcrypt.hash(password, 10);
      db.run(
        "INSERT INTO users (role,name,phone,password) VALUES (?,?,?,?)",
        ["seller", name, phone, hash],
        (err) => {
          if (err) return res.json({ error: "Registration failed" });
          res.json({ success: true, msg: "Registered! Redirecting to login..." });
        }
      );
    } catch (e) {
      res.json({ error: "Registration failed" });
    }
  });
});

// ---------- UI ----------
app.get("/", (req, res) => {
  // Generate random math question
  const a = Math.floor(Math.random() * 10) + 1;
  const b = Math.floor(Math.random() * 10) + 1;
  const captchaAnswer = a + b;
  req.session.captchaAnswer = captchaAnswer;
  res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Raffle App Login</title>
  <link href="https://fonts.googleapis.com/css?family=Roboto:400,700&display=swap" rel="stylesheet">
  <link rel="icon" type="image/png" href="logo.png">
  <style>
    body {
      font-family: 'Roboto', Arial, sans-serif;
      background: linear-gradient(135deg, #0a174e 0%, #133b88 100%);
      color: #b3cfff;
      margin: 0;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
    }
    .login-card {
      background: #133b88;
      border-radius: 20px;
      box-shadow: 0 8px 32px rgba(10,23,78,0.15);
      padding: 2.5em 2em;
      border: 2px solid #0a174e;
      max-width: 350px;
      width: 100%;
      margin: 32px auto;
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    h2 {
      color: #b3cfff;
      text-shadow: 2px 2px 8px #09103a;
      margin-bottom: 1em;
      font-size: 2em;
    }
    h3 {
      color: #fff;
      margin-bottom: 1em;
      font-size: 1.3em;
    }
    input {
      padding: 12px;
      border-radius: 8px;
      border: 1.5px solid #1976d2;
      background: #102a5c;
      color: #b3cfff;
      font-size: 1.05em;
      margin-bottom: 10px;
      width: 100%;
      transition: border-color 0.2s, box-shadow 0.2s;
      box-shadow: 0 1px 4px rgba(25,118,210,0.10);
    }
    input:focus {
      border-color: #42a5f5;
      box-shadow: 0 2px 8px rgba(66,165,245,0.15);
      outline: none;
    }
    button {
      background: linear-gradient(90deg, #1976d2 0%, #133b88 100%);
      color: #fff;
      font-weight: bold;
      cursor: pointer;
      border: none;
      border-radius: 8px;
      padding: 12px 24px;
      font-size: 1.08em;
      box-shadow: 0 2px 8px rgba(25,118,210,0.15);
      transition: background 0.2s, box-shadow 0.2s;
      margin-bottom: 10px;
      width: 100%;
    }
    button:hover {
      background: linear-gradient(90deg, #133b88 0%, #1976d2 100%);
      box-shadow: 0 4px 16px rgba(25,118,210,0.25);
    }
    .msg-success {
      background: linear-gradient(90deg, #43e97b 0%, #38f9d7 100%);
      color: #0a174e;
      padding: 14px 22px;
      border-radius: 10px;
      font-weight: bold;
      box-shadow: 0 2px 8px rgba(67,233,123,0.15);
      margin-bottom: 16px;
      text-align: center;
      font-size: 1.08em;
      border: 1.5px solid #38f9d7;
    }
    .msg-error {
      background: linear-gradient(90deg, #ff5858 0%, #f09819 100%);
      color: #fff;
      padding: 14px 22px;
      border-radius: 10px;
      font-weight: bold;
      box-shadow: 0 2px 8px rgba(255,88,88,0.15);
      margin-bottom: 16px;
      text-align: center;
      font-size: 1.08em;
      border: 1.5px solid #f09819;
    }
    @media (max-width: 600px) {
      body {
        padding: 12px !important;
      }
      .login-card {
        padding: 1.2em 0.5em;
        border-radius: 0 !important;
        max-width: 98vw !important;
      }
      h2 {
        font-size: 1.32em !important;
      }
      button, input {
        font-size: 1.12em !important;
        padding: 14px !important;
        min-width: 44px;
        min-height: 44px;
      }
    }
  </style>
</head>
<body>
  <div class="login-card">
    <img src="logo.png" alt="Logo" style="display:block;margin:0 auto 18px auto;max-width:120px;">
    <h2>🎟️ Raffle Ticket System</h2>
    <h3>Login</h3>
    <input id="phone" placeholder="Phone" aria-label="Phone"/>
    <input id="password" type="password" placeholder="Password" aria-label="Password"/>
    <label for="captcha">What is ${a} + ${b}?</label>
    <input id="captcha" type="text" placeholder="Enter answer" aria-label="CAPTCHA"/>
    <button onclick="login()">Login</button>
    <p id="msg"></p>
    <button onclick="toggleScanner()" id="scanBtn">Scan Barcode</button>
    <div id="reader" style="display:none"></div>
    <p style="margin-top:10px">Don't have an account? <a href="/register">Register here</a></p>
  </div>
  <script src="https://unpkg.com/html5-qrcode@2.3.8/minified/html5-qrcode.min.js"></script>
  <script>
function login(){
  fetch('/login',{
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body:JSON.stringify({
      phone:phone.value,
      password:password.value,
      captcha:captcha.value
    })
  }).then(r=>r.json()).then(d=>{
    if(d.role==='admin') location.href='/admin';
    if(d.role==='seller') location.href='/seller?name='+d.name;
    msg.innerText=d.error||''
  })
}

let scannerVisible = false;
let html5Qr;
function toggleScanner() {
  const reader = document.getElementById('reader');
  if (!scannerVisible) {
    reader.style.display = '';
    if (!html5Qr) {
      html5Qr = new Html5Qrcode('reader');
    }
    html5Qr.start(
      { facingMode: 'environment' },
      { fps: 10, qrbox: 250 },
      (decodedText) => {
        phone.value = decodedText;
        html5Qr.stop();
        reader.style.display = 'none';
        scannerVisible = false;
      },
      (err) => {}
    );
    scannerVisible = true;
    scanBtn.innerText = 'Close Scanner';
  } else {
    html5Qr && html5Qr.stop();
    reader.style.display = 'none';
    scannerVisible = false;
    scanBtn.innerText = 'Scan Barcode';
  }
}
</script>
</body>
</html>
  `);
});

// ---------- LOGIN ----------
app.post("/login", (req, res) => {
  const { phone, password } = req.body;
  db.get("SELECT * FROM users WHERE phone=?", [phone], async (err, user) => {
    if (!user) return res.json({ error: "Invalid login" });
    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.json({ error: "Invalid login" });
    // 2FA check for admin
    if (user.role === 'admin' && user.twofa_enabled) {
      // Generate code and send email
      const code = Math.floor(100000 + Math.random() * 900000).toString();
      req.session.user = { name: user.name, role: user.role, phone: user.phone, twofa_enabled: true, twofa_verified: false, twofa_code: code };
      db.get('SELECT email FROM users WHERE phone=?', [phone], (err2, u) => {
        if (u && u.email) {
          sendEmail(u.email, 'Your 2FA Code', `Your admin login code: ${code}`);
        }
      });
      return res.json({ twofa: true, msg: '2FA code sent to admin email.' });
    }
    req.session.user = { name: user.name, role: user.role, phone: user.phone, twofa_enabled: !!user.twofa_enabled, twofa_verified: !user.twofa_enabled };
    if (user.role === 'admin') {
      res.json({ redirect: '/admin', name: user.name, role: user.role });
    } else {
      res.json({ redirect: `/seller?name=${encodeURIComponent(user.name)}`, name: user.name, role: user.role });
    }
  });
});

// 2FA verify endpoint
app.post('/verify-2fa', (req, res) => {
  const { code } = req.body;
  if (!req.session.user || !req.session.user.twofa_enabled) return res.status(400).json({ error: '2FA not required' });
  if (req.session.user.twofa_code === code) {
    req.session.user.twofa_verified = true;
    return res.json({ success: true, redirect: '/admin' });
  }
  res.status(401).json({ error: 'Invalid 2FA code' });
});

// Enable 2FA for admin (must have email)
app.post('/enable-2fa', requireAdmin, (req, res) => {
  const { phone } = req.session.user;
  db.run('UPDATE users SET twofa_enabled=1 WHERE phone=?', [phone], (err) => {
    if (err) return res.status(500).json({ error: 'Failed to enable 2FA' });
    req.session.user.twofa_enabled = true;
    res.json({ success: true });
  });
});

// Disable 2FA for admin
app.post('/disable-2fa', requireAdmin, (req, res) => {
  const { phone } = req.session.user;
  db.run('UPDATE users SET twofa_enabled=0 WHERE phone=?', [phone], (err) => {
    if (err) return res.status(500).json({ error: 'Failed to disable 2FA' });
    req.session.user.twofa_enabled = false;
    res.json({ success: true });
  });
});

// Create ticket with category
app.post("/create-ticket", (req, res) => {
  const { number, category } = req.body;
  if (!number || !category) return res.status(400).json({ error: 'Number and category required' });
  db.run(
    "INSERT OR IGNORE INTO tickets (number,status,category) VALUES (?,?,?)",
    [number, "available", category],
    (err) => {
      if (err) return res.status(500).json({ error: 'Failed to create ticket' });
      res.sendStatus(200);
    }
  );
});
app.get("/admin", requireAdmin, (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Admin Dashboard - Raffle App</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      min-height: 100vh;
      background: linear-gradient(135deg, #0a174e 0%, #133b88 100%);
      color: #b3cfff;
    }
    h2, h3 {
      color: #b3cfff;
      text-shadow: 2px 2px 8px #09103a;
    }
    .section {
      margin: 2em auto;
      max-width: 900px;
      background: #133b88;
      border-radius: 16px;
      box-shadow: 0 4px 24px rgba(10,23,78,0.5);
      padding: 2em;
      border: 2px solid #0a174e;
    }
    input, button {
      padding: 10px;
      margin: 5px 0;
      width: 100%;
      background: #102a5c;
      color: #b3cfff;
      border: 1px solid #1a237e;
      border-radius: 4px;
    }
    button {
      background: #1a237e;
      color: #b3cfff;
      font-weight: bold;
      cursor: pointer;
      transition: background 0.2s;
    }
    button:hover {
      background: #0a174e;
    }
    .card {
      background: #102a5c;
      border-radius: 8px;
      padding: 1em;
      margin-bottom: 1em;
      box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    }
    table {
      border-collapse: collapse;
      width: 100%;
      margin-top: 1em;
      background: #0a174e;
      color: #b3cfff;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
      border-radius: 8px;
      overflow: hidden;
    }
    th, td {
      border: 1px solid #133b88;
      padding: 14px 10px;
      text-align: left;
    }
    th {
      background: #133b88;
      color: #b3cfff;
      font-weight: bold;
      letter-spacing: 1px;
    }
    tr:nth-child(even) {
      background: #102a5c;
    }
    .barcode-img {
      height: 40px;
      background: #fff;
      padding: 4px;
      border-radius: 4px;
    }
  </style>
</head>
<body>
  <div class="section">
    <h2>👑 Admin Dashboard</h2>
    <div class="card">
      <h3>Create Seller</h3>
      <input id="name" placeholder="Name"/>
      <input id="phone" placeholder="Phone"/>
      <input id="pass" placeholder="Password"/>
      <button onclick="createSeller()">Create</button>
      <h3>All Users</h3>
      <table id="users-table">
        <thead><tr><th>Name</th><th>Role</th><th>Phone</th></tr></thead>
        <tbody></tbody>
      </table>
    </div>
    <div class="card">
      <h3>Create Ticket</h3>
      <input id="ticket" placeholder="Ticket Number"/>
      <button onclick="createTicket()">Create Ticket</button>
    </div>
    <div class="card">
      <h3>Bulk Import Tickets (Excel)</h3>
      <form id="importForm" enctype="multipart/form-data" method="POST" action="/import-tickets">
        <input type="file" name="excel" accept=".xlsx,.xls" />
        <button type="submit">Import</button>
      </form>
      <p id="importMsg"></p>
    </div>
    <div class="card">
      <h3>All Tickets</h3>
      <table id="tickets-table">
        <thead><tr><th>Number</th><th>Status</th><th>Barcode</th></tr></thead>
        <tbody></tbody>
      </table>
    </div>
    <div class="card">
      <h3>Seller Sales Report</h3>
      <table id="sales-table">
        <thead><tr><th>Seller</th><th>Tickets Sold</th></tr></thead>
        <tbody></tbody>
      </table>
    </div>
    <div class="card">
      <h3>Sales Chart</h3>
      <canvas id="salesChart" width="400" height="150"></canvas>
    </div>
  </div>
  <script>
    function createSeller(){
      fetch('/create-seller',{method:'POST',headers:{'Content-Type':'application/json'},
      body:JSON.stringify({name:name.value,phone:phone.value,password:pass.value})})
      .then(()=>alert('Seller created'))
      .then(()=>loadUsers());
    }
    function createTicket(){
      fetch('/create-ticket',{method:'POST',headers:{'Content-Type':'application/json'},
      body:JSON.stringify({number:ticket.value})})
      .then(()=>loadTickets());
    }
    document.getElementById('importForm').onsubmit = function(e) {
      e.preventDefault();
      var formData = new FormData(importForm);
      fetch('/import-tickets', {
        method: 'POST',
        body: formData
      }).then(r=>r.json()).then(d=>{
        importMsg.innerText = d.msg || d.error || '';
        loadTickets();
      });
    }
    function loadTickets(){
      fetch('/tickets').then(r=>r.json()).then(d=>{
// ...existing code...
    }
    function removeUser(phone) {
      if (!confirm('Are you sure you want to remove this user?')) return;
      fetch('/remove-user', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone })
      }).then(r=>r.json()).then(d=>{
        if (d.success) {
          alert('User removed');
          loadUsers();
        } else {
          alert(d.error || 'Failed to remove user');
        }
      });
    }
    loadTickets();
    loadSales();
    loadUsers();
  </script>
</body>
</html>
  `);
});

// ---------- SELLER ----------
function requireSeller(req, res, next) {
  if (req.session.user && req.session.user.role === 'seller') return next();
  res.redirect('/');
}
app.get("/seller", requireSeller, (req, res) => {
  const name = req.query.name;
  res.send(`
<!DOCTYPE html>
<html>
<head>
<title>Seller Dashboard - Raffle App</title>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<style>
body{font-family:Arial;padding:20px;background:#1565c0;color:#fff}
input,button{padding:10px;margin:5px;width:100%;background:#1976d2;color:#fff;border:none;border-radius:4px}
.card{border:1px solid #1976d2;padding:15px;border-radius:8px;margin-bottom:20px;background:#1e88e5;color:#fff}
</style>
</head>
<body>
<h2>Seller: ${name}</h2>
<div class="card">
  <input id="ticket" placeholder="Ticket Number"/>
  <button onclick="sell()">Sell Ticket</button>
  <p id="msg"></p>
</div>
<script>
function sell(){
 fetch('/sell',{
  method:'POST',
  headers:{'Content-Type':'application/json'},
  body:JSON.stringify({number:ticket.value,seller:'${name}'})
 }).then(r=>r.json()).then(d=>{
   msg.innerText=d.msg||d.error
 })
}
</script>
</body>
</html>
  `);
});

// ---------- API ----------
// Create new role
app.post('/create-role', requireAdmin, (req, res) => {
  const { name, permissions } = req.body;
  if (!name) return res.status(400).json({ error: 'Role name required' });
  db.run('INSERT INTO roles (name, permissions) VALUES (?, ?)', [name, JSON.stringify(permissions || [])], (err) => {
    if (err) return res.status(500).json({ error: 'Failed to create role' });
    res.json({ success: true });
  });
});

// List all roles
app.get('/roles', requireAdmin, (req, res) => {
  db.all('SELECT * FROM roles', (err, rows) => {
    if (err) return res.status(500).json({ error: 'Failed to fetch roles' });
    res.json(rows);
  });
});

// Assign role to user
app.post('/assign-role', requireAdmin, (req, res) => {
  const { phone, role } = req.body;
  if (!phone || !role) return res.status(400).json({ error: 'Phone and role required' });
  db.run('UPDATE users SET role=? WHERE phone=?', [role, phone], (err) => {
    if (err) return res.status(500).json({ error: 'Failed to assign role' });
    res.json({ success: true });
  });
});
// Logout endpoint
app.get('/logout', (req, res) => {
  req.session.destroy(() => {
    res.redirect('/');
  });
});
// Backup database (download)

// Manual backup endpoint (download)
app.get('/backup-db', requireAdmin, (req, res) => {
  const dbPath = './raffle.db';
  res.download(dbPath, 'raffle-backup.db');
});

// Automated scheduled backup (daily)
const cron = require('node-cron');
const path = require('path');
const BACKUP_DIR = path.join(__dirname, '../backups');
if (!fs.existsSync(BACKUP_DIR)) fs.mkdirSync(BACKUP_DIR);
cron.schedule('0 2 * * *', () => {
  const src = path.join(__dirname, '../raffle.db');
  const dest = path.join(BACKUP_DIR, `raffle-backup-${new Date().toISOString().slice(0,10)}.db`);
  fs.copyFile(src, dest, (err) => {
    if (err) console.error('Scheduled backup failed:', err);
    else console.log('✅ Scheduled backup created:', dest);
  });
});

// List backups endpoint
app.get('/list-backups', requireAdmin, (req, res) => {
  fs.readdir(BACKUP_DIR, (err, files) => {
    if (err) return res.status(500).json({ error: 'Failed to list backups' });
    res.json(files.filter(f => f.endsWith('.db')));
  });
});

// Download specific backup
app.get('/download-backup/:file', requireAdmin, (req, res) => {
  const file = req.params.file;
  const filePath = path.join(BACKUP_DIR, file);
  if (!fs.existsSync(filePath)) return res.status(404).send('Backup not found');
  res.download(filePath);
});

// Restore database (upload)
const restoreUpload = multer({ dest: 'uploads/' });
app.post('/restore-db', requireAdmin, restoreUpload.single('backup'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
  const backupPath = req.file.path;
  const dbPath = './raffle.db';
  fs.copyFile(backupPath, dbPath, (err) => {
    if (err) return res.status(500).json({ error: 'Restore failed' });
    res.json({ success: true, msg: 'Database restored. Please restart the server.' });
  });
});
// In-memory notifications (for demo; use DB for production)
let sellerNotifications = {};

// Send notification to seller
app.post('/notify-seller', requireAdmin, (req, res) => {
  const { seller, message } = req.body;
  if (!seller || !message) return res.status(400).json({ error: 'Seller and message required' });
  if (!sellerNotifications[seller]) sellerNotifications[seller] = [];
  sellerNotifications[seller].push({ message, time: new Date().toISOString() });
  res.json({ success: true });
});

// Get notifications for seller
app.get('/seller-notifications', (req, res) => {
  const seller = req.query.seller;
  res.json(sellerNotifications[seller] || []);
});

// Notify seller on ticket sale
function notifySellerSale(seller, ticketNumber) {
  if (!sellerNotifications[seller]) sellerNotifications[seller] = [];
  sellerNotifications[seller].push({ message: `Ticket ${ticketNumber} sold!`, time: new Date().toISOString() });
  // Find seller email
  db.get('SELECT * FROM users WHERE name=?', [seller], (err, user) => {
    if (user && user.email) {
      sendEmail(user.email, 'Ticket Sold', `Your ticket ${ticketNumber} was sold.`);
    }
  });
}

// Notify winner (example endpoint)
app.post('/notify-winner', requireAdmin, (req, res) => {
  const { winnerName, winnerEmail, ticketNumber } = req.body;
  if (!winnerEmail || !ticketNumber) return res.status(400).json({ error: 'Winner email and ticket required' });
  sendEmail(winnerEmail, 'Congratulations!', `You won with ticket ${ticketNumber}!`);
  res.json({ success: true });
});
// Bulk delete tickets
app.post('/bulk-delete-tickets', requireAdmin, (req, res) => {
  const { numbers } = req.body;
  if (!Array.isArray(numbers) || numbers.length === 0) return res.status(400).json({ error: 'No tickets selected' });
  const placeholders = numbers.map(() => '?').join(',');
  db.run(`DELETE FROM tickets WHERE number IN (${placeholders})`, numbers, function(err) {
    if (err) return res.status(500).json({ error: 'Failed to delete tickets' });
    logAudit('bulk_delete_tickets', `Deleted tickets: ${numbers.join(', ')}`, req.session.user.name);
    res.json({ success: true, msg: `${numbers.length} tickets deleted` });
  });
});

// Bulk delete users
app.post('/bulk-delete-users', requireAdmin, (req, res) => {
  const { phones } = req.body;
  if (!Array.isArray(phones) || phones.length === 0) return res.status(400).json({ error: 'No users selected' });
  const placeholders = phones.map(() => '?').join(',');
  db.run(`DELETE FROM users WHERE phone IN (${placeholders})`, phones, function(err) {
    if (err) return res.status(500).json({ error: 'Failed to delete users' });
    logAudit('bulk_delete_users', `Deleted users: ${phones.join(', ')}`, req.session.user.name);
    res.json({ success: true, msg: `${phones.length} users deleted` });
  });
});
app.post("/create-seller", (req, res) => {
  const { name, phone, password } = req.body;
  // Password strength: min 8 chars, 1 number, 1 letter
  if (!/^.*(?=.{8,})(?=.*\d)(?=.*[a-zA-Z]).*$/.test(password)) {
    return res.status(400).json({ error: "Password must be at least 8 characters, include a number and a letter." });
  }
  db.get("SELECT * FROM users WHERE phone=?", [phone], (err, user) => {
    if (user) return res.status(400).json({ error: "Phone already registered" });
    db.run(
      "INSERT INTO users (role,name,phone,password) VALUES (?,?,?,?)",
      ["seller", name, phone, password],
      (err2) => {
        if (err2) return res.status(500).json({ error: "Failed to create seller" });
        logAudit('create_seller', `Seller: ${name}, Phone: ${phone}`, req.session && req.session.user ? req.session.user.name : null);
        res.json({ success: true, msg: "Seller created successfully" });
      }
    );
  });
});

app.post("/create-ticket", (req, res) => {
  if (!req.body.number) return res.status(400).json({ error: "Ticket number required" });
  db.get("SELECT * FROM tickets WHERE number=?", [req.body.number], (err, ticket) => {
    if (ticket) return res.status(400).json({ error: "Ticket number already exists" });
    db.run(
      "INSERT OR IGNORE INTO tickets (number,status) VALUES (?,?)",
      [req.body.number, "available"],
      (err2) => {
        if (err2) return res.status(500).json({ error: "Failed to create ticket" });
        logAudit('create_ticket', `Ticket: ${req.body.number}`, req.session && req.session.user ? req.session.user.name : null);
        res.json({ success: true, msg: "Ticket created successfully" });
      }
    );
  });
});

app.get("/tickets", (req, res) => {
  db.all("SELECT * FROM tickets", (err, rows) => res.json(rows));
});

app.post("/sell", (req, res) => {
  const { number, seller } = req.body;
  db.get("SELECT * FROM tickets WHERE number=?", [number], (err, t) => {
    if (!t) return res.status(404).json({ error: "Ticket not found" });
    if (t.status === "sold") return res.status(400).json({ error: "Ticket already sold" });
    db.run(
      "UPDATE tickets SET status='sold', sold_by=?, sold_at=datetime('now') WHERE number=?",
      [seller, number],
      (err2) => {
        if (err2) return res.status(500).json({ error: "Failed to update ticket" });
        logAudit('sell_ticket', `Ticket: ${number}, Seller: ${seller}`, seller);
        notifySellerSale(seller, number);
        res.json({ success: true, msg: "Ticket sold successfully" });
      }
    );
  });
// ---------- AUDIT LOG API ----------
app.get('/audit-logs', (req, res) => {
  db.all('SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 100', (err, rows) => {
    if (err) return res.status(500).json({ error: 'Failed to fetch logs' });
    res.json(rows);
  });
});
});

// ---------- BULK IMPORT TICKETS ----------
app.post('/import-tickets', upload.single('excel'), (req, res) => {
  if (!req.file) return res.json({ error: 'No file uploaded' });
  try {
    const workbook = xlsx.readFile(req.file.path);
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const data = xlsx.utils.sheet_to_json(sheet);
    let count = 0;
    data.forEach(row => {
      if (row.number) {
        db.run(
          "INSERT OR IGNORE INTO tickets (number,status) VALUES (?,?)",
          [row.number, "available"]
        );
        count++;
      }
    });
    res.json({ msg: `Imported ${count} tickets.` });
  } catch (e) {
    res.json({ error: 'Import failed' });
  }
});

// ---------- SALES REPORT API ----------
// Sales by day (for chart)
app.get('/analytics/sales-by-day', requireAdmin, (req, res) => {
  db.all("SELECT date(sold_at) as day, COUNT(*) as count FROM tickets WHERE status='sold' GROUP BY day ORDER BY day DESC LIMIT 30", (err, rows) => {
    if (err) return res.status(500).json({ error: 'Failed to fetch sales data' });
    res.json(rows);
  });
});

// Tickets by category (for chart)
app.get('/analytics/tickets-by-category', requireAdmin, (req, res) => {
  db.all("SELECT category, COUNT(*) as count FROM tickets GROUP BY category", (err, rows) => {
    if (err) return res.status(500).json({ error: 'Failed to fetch ticket data' });
    res.json(rows);
  });
});
// Seller leaderboard (top sellers)
app.get('/seller-leaderboard', (req, res) => {
  db.all("SELECT sold_by, COUNT(*) as tickets_sold FROM tickets WHERE status='sold' AND sold_by IS NOT NULL GROUP BY sold_by ORDER BY tickets_sold DESC LIMIT 10", (err, rows) => {
    if (err) return res.status(500).json({ error: 'Failed to fetch leaderboard' });
    res.json(rows || []);
  });
});

// Seller performance stats
app.get('/seller-performance', (req, res) => {
  const seller = req.query.seller;
  if (!seller) return res.status(400).json({ error: 'Seller required' });
  db.get("SELECT COUNT(*) as sold FROM tickets WHERE sold_by=? AND status='sold'", [seller], (err, soldRow) => {
    db.get("SELECT COUNT(*) as refunded FROM tickets WHERE sold_by=? AND status='refunded'", [seller], (err2, refundRow) => {
      db.get("SELECT COUNT(*) as cancelled FROM tickets WHERE sold_by=? AND status='cancelled'", [seller], (err3, cancelRow) => {
        res.json({ sold: soldRow.sold, refunded: refundRow.refunded, cancelled: cancelRow.cancelled });
      });
    });
  });
});

// Existing sales report endpoint
app.get('/sales-report', (req, res) => {
  db.all("SELECT sold_by, COUNT(*) as count FROM tickets WHERE status='sold' AND sold_by IS NOT NULL GROUP BY sold_by", (err, rows) => {
    res.json(rows || []);
  });
});

// ---------- EXPORT REPORTS ----------
app.get('/export/tickets/csv', requireAdmin, (req, res) => {
  db.all('SELECT * FROM tickets', (err, rows) => {
    if (err) return res.status(500).send('Error exporting tickets');
    const ws = xlsx.utils.json_to_sheet(rows);
    const wb = xlsx.utils.book_new();
    xlsx.utils.book_append_sheet(wb, ws, 'Tickets');
    const buf = xlsx.write(wb, { type: 'buffer', bookType: 'csv' });
    res.setHeader('Content-Disposition', 'attachment; filename="tickets.csv"');
    res.type('text/csv');
    res.send(buf);
  });
});

app.get('/export/sales/csv', requireAdmin, (req, res) => {
  db.all('SELECT * FROM tickets WHERE status="sold"', (err, rows) => {
    if (err) return res.status(500).send('Error exporting sales');
    const ws = xlsx.utils.json_to_sheet(rows);
    const wb = xlsx.utils.book_new();
    xlsx.utils.book_append_sheet(wb, ws, 'Sales');
    const buf = xlsx.write(wb, { type: 'buffer', bookType: 'csv' });
    res.setHeader('Content-Disposition', 'attachment; filename="sales.csv"');
    res.type('text/csv');
    res.send(buf);
  });
});

app.get('/export/tickets/pdf', requireAdmin, (req, res) => {
  db.all('SELECT * FROM tickets', (err, rows) => {
    if (err) return res.status(500).send('Error exporting tickets');
    const doc = new PDFDocument();
    res.setHeader('Content-Disposition', 'attachment; filename="tickets.pdf"');
    res.type('application/pdf');
    doc.pipe(res);
    doc.fontSize(18).text('Tickets Report', { align: 'center' });
    doc.moveDown();
    rows.forEach(row => {
      doc.fontSize(12).text(`Number: ${row.number}, Status: ${row.status}, Category: ${row.category || ''}, Sold By: ${row.sold_by || ''}, Sold At: ${row.sold_at || ''}`);
    });
    doc.end();
  });
});

app.get('/export/sales/pdf', requireAdmin, (req, res) => {
  db.all('SELECT * FROM tickets WHERE status="sold"', (err, rows) => {
    if (err) return res.status(500).send('Error exporting sales');
    const doc = new PDFDocument();
    res.setHeader('Content-Disposition', 'attachment; filename="sales.pdf"');
    res.type('application/pdf');
    doc.pipe(res);
    doc.fontSize(18).text('Sales Report', { align: 'center' });
    doc.moveDown();
    rows.forEach(row => {
      doc.fontSize(12).text(`Number: ${row.number}, Category: ${row.category || ''}, Sold By: ${row.sold_by || ''}, Sold At: ${row.sold_at || ''}`);
    });
    doc.end();
  });
});

// ---------- START ----------
if (useHttps) {
  const options = {
    key: fs.readFileSync(SSL_KEY_PATH),
    cert: fs.readFileSync(SSL_CERT_PATH)
  };
  https.createServer(options, app).listen(443, () => {
    console.log('🚀 HTTPS server running on port 443');
  });
  // Optional: Redirect HTTP to HTTPS
  http.createServer((req, res) => {
    res.writeHead(301, { "Location": "https://" + req.headers.host + req.url });
    res.end();
  }).listen(PORT, () => {
    console.log(`HTTP redirect server running on port ${PORT}`);
  });
} else {
  app.listen(PORT, (err) => {
    if (err) {
      console.error('Server failed to start:', err);
      process.exit(1);
    }
    console.log(`🚀 Running on http://localhost:${PORT}`);
  });
}