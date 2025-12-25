const express = require('express');
const bodyParser = require-parser');
const session = require('express-session');
const bcrypt = require('bcrypt');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(session({
  secret: 'raffle-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false }
}));

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// In-memory database (replace with a real database in production)
let users = [];
let tickets = [];
let draws = [];

// Helper functions
function generateTicketNumber() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function isAuthenticated(req, res, next) {
  if (req.session.userId) {
    return next();
  }
  res.redirect('/login.html');
}

function isAdmin(req, res, next) {
  if (req.session.role === 'admin') {
    return next();
  }
  res.status(403).send('Access denied');
}

function isSeller(req, res, next) {
  if (req.session.role === 'seller') {
    return next();
  }
  res.status(403).send('Access denied');
}

// Routes
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.post('/register', async (req, res) => {
  const { phone, password, name, role } = req.body;
  
  if (users.find(u => u.phone === phone)) {
    return res.json({ error: 'Phone number already registered' });
  }

  const hashedPassword = await bcrypt.hash(password, 10);
  const user = {
    id: users.length + 1,
    phone,
    password: hashedPassword,
    name,
    role: role || 'seller'
  };
  
  users.push(user);
  res.json({ success: true, message: 'Registration successful' });
});

app.post('/login', async (req, res) => {
  const { phone, password } = req.body;
  const user = users.find(u => u.phone === phone);

  if (!user) {
    return res.json({ error: 'Invalid credentials' });
  }

  const validPassword = await bcrypt.compare(password, user.password);
  if (!validPassword) {
    return res.json({ error: 'Invalid credentials' });
  }

  req.session.userId = user.id;
  req.session.role = user.role;
  req.session.name = user.name;

  res.json({ 
    success: true, 
    role: user.role,
    name: user.name,
    redirect: user.role === 'admin' ? '/admin' : `/seller?name=${encodeURIComponent(user.name)}`
  });
});

app.post('/logout', (req, res) => {
  req.session.destroy();
  res.json({ success: true });
});

app.post('/sell-ticket', isAuthenticated, isSeller, (req, res) => {
  const { customerName, customerPhone, amount } = req.body;
  
  const ticket = {
    id: tickets.length + 1,
    ticketNumber: generateTicketNumber(),
    customerName,
    customerPhone,
    amount: parseFloat(amount),
    sellerId: req.session.userId,
    sellerName: req.session.name,
    date: new Date(),
    status: 'active'
  };

  tickets.push(ticket);
  res.json({ success: true, ticket });
});

app.get('/my-tickets', isAuthenticated, isSeller, (req, res) => {
  const myTickets = tickets.filter(t => t.sellerId === req.session.userId);
  res.json(myTickets);
});

app.get('/all-tickets', isAuthenticated, isAdmin, (req, res) => {
  res.json(tickets);
});

app.post('/draw', isAuthenticated, isAdmin, (req, res) => {
  const activeTickets = tickets.filter(t => t.status === 'active');
  
  if (activeTickets.length === 0) {
    return res.json({ error: 'No active tickets available' });
  }

  const winningTicket = activeTickets[Math.floor(Math.random() * activeTickets.length)];
  winningTicket.status = 'won';

  const draw = {
    id: draws.length + 1,
    date: new Date(),
    winningTicket: winningTicket.ticketNumber,
    winner: winningTicket.customerName,
    amount: winningTicket.amount
  };

  draws.push(draw);
  res.json({ success: true, draw });
});

app.get('/draws', isAuthenticated, (req, res) => {
  res.json(draws);
});

app.get('/stats', isAuthenticated, isAdmin, (req, res) => {
  const totalTickets = tickets.length;
  const totalAmount = tickets.reduce((sum, t) => sum + t.amount, 0);
  const activeTickets = tickets.filter(t => t.status === 'active').length;
  
  res.json({
    totalTickets,
    totalAmount,
    activeTickets,
    totalDraws: draws.length
  });
});

// Create default admin user
async function createDefaultAdmin() {
  const adminExists = users.find(u => u.role === 'admin');
  if (!adminExists) {
    const hashedPassword = await bcrypt.hash('admin123', 10);
    users.push({
      id: 1,
      phone: '1234567890',
      password: hashedPassword,
      name: 'Admin',
      role: 'admin'
    });
    console.log('Default admin created - Phone: 1234567890, Password: admin123');
  }
}

app.listen(PORT, () => {
  createDefaultAdmin();
  console.log(`Server running on port ${PORT}`);
});
