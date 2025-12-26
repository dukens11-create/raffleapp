const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Initialize database
const db = new sqlite3.Database('./raffle.db', (err) => {
  if (err) {
    console.error('Error opening database:', err);
  } else {
    console.log('Connected to SQLite database');
    initializeDatabase();
  }
});

function initializeDatabase() {
  db.serialize(() => {
    // Users table
    db.run(`CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      phone TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT DEFAULT 'user',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Tickets table
    db.run(`CREATE TABLE IF NOT EXISTS tickets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      ticket_number TEXT UNIQUE NOT NULL,
      purchased_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )`);

    // Winners table
    db.run(`CREATE TABLE IF NOT EXISTS winners (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ticket_id INTEGER NOT NULL,
      drawn_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (ticket_id) REFERENCES tickets (id)
    )`);
  });
}

// POST endpoint to setup default admin user
app.post('/api/setup-admin', async (req, res) => {
  try {
    // Check if admin already exists
    db.get('SELECT * FROM users WHERE phone = ?', ['1234567890'], async (err, existingAdmin) => {
      if (err) {
        console.error('Error checking for existing admin:', err);
        return res.status(500).json({ error: 'Database error' });
      }

      if (existingAdmin) {
        return res.status(400).json({ error: 'Admin user already exists' });
      }

      // Hash the password
      const hashedPassword = await bcrypt.hash('admin123', 10);

      // Create the admin user
      db.run(
        'INSERT INTO users (phone, password, role) VALUES (?, ?, ?)',
        ['1234567890', hashedPassword, 'admin'],
        function(err) {
          if (err) {
            console.error('Error creating admin user:', err);
            return res.status(500).json({ error: 'Failed to create admin user' });
          }

          res.json({ 
            success: true, 
            message: 'Admin user created successfully',
            admin: {
              id: this.lastID,
              phone: '1234567890',
              role: 'admin'
            }
          });
        }
      );
    });
  } catch (error) {
    console.error('Error in setup-admin:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Middleware to verify JWT token
const requireAuth = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// Middleware to check admin role
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

// Register endpoint
app.post('/api/register', async (req, res) => {
  const { phone, password } = req.body;

  if (!phone || !password) {
    return res.status(400).json({ error: 'Phone and password are required' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    
    db.run(
      'INSERT INTO users (phone, password) VALUES (?, ?)',
      [phone, hashedPassword],
      function(err) {
        if (err) {
          if (err.message.includes('UNIQUE constraint failed')) {
            return res.status(400).json({ error: 'Phone number already registered' });
          }
          return res.status(500).json({ error: 'Error creating user' });
        }

        const token = jwt.sign(
          { id: this.lastID, phone, role: 'user' },
          JWT_SECRET,
          { expiresIn: '24h' }
        );

        res.json({ token, user: { id: this.lastID, phone, role: 'user' } });
      }
    );
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Login endpoint
app.post('/api/login', async (req, res) => {
  const { phone, password } = req.body;

  if (!phone || !password) {
    return res.status(400).json({ error: 'Phone and password are required' });
  }

  db.get('SELECT * FROM users WHERE phone = ?', [phone], async (err, user) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    try {
      const match = await bcrypt.compare(password, user.password);
      
      if (!match) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const token = jwt.sign(
        { id: user.id, phone: user.phone, role: user.role },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      res.json({ token, user: { id: user.id, phone: user.phone, role: user.role } });
    } catch (error) {
      res.status(500).json({ error: 'Server error' });
    }
  });
});

// Purchase tickets
app.post('/api/tickets/purchase', requireAuth, (req, res) => {
  const { quantity } = req.body;
  const userId = req.user.id;

  if (!quantity || quantity < 1 || quantity > 10) {
    return res.status(400).json({ error: 'Quantity must be between 1 and 10' });
  }

  const tickets = [];
  const generateTicketNumber = () => {
    return 'TKT' + Math.random().toString(36).substr(2, 9).toUpperCase();
  };

  db.serialize(() => {
    const stmt = db.prepare('INSERT INTO tickets (user_id, ticket_number) VALUES (?, ?)');
    
    for (let i = 0; i < quantity; i++) {
      const ticketNumber = generateTicketNumber();
      stmt.run(userId, ticketNumber, function(err) {
        if (err) {
          console.error('Error inserting ticket:', err);
        } else {
          tickets.push({ id: this.lastID, ticketNumber });
        }
      });
    }

    stmt.finalize((err) => {
      if (err) {
        return res.status(500).json({ error: 'Error purchasing tickets' });
      }
      res.json({ tickets });
    });
  });
});

// Get user's tickets
app.get('/api/tickets/my-tickets', requireAuth, (req, res) => {
  const userId = req.user.id;

  db.all(
    'SELECT * FROM tickets WHERE user_id = ? ORDER BY purchased_at DESC',
    [userId],
    (err, tickets) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      res.json({ tickets });
    }
  );
});

// Draw winner (admin only)
app.post('/api/admin/draw-winner', requireAuth, requireAdmin, (req, res) => {
  db.get(
    `SELECT t.* FROM tickets t
     LEFT JOIN winners w ON t.id = w.ticket_id
     WHERE w.id IS NULL
     ORDER BY RANDOM()
     LIMIT 1`,
    (err, ticket) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }

      if (!ticket) {
        return res.status(404).json({ error: 'No available tickets for drawing' });
      }

      db.run(
        'INSERT INTO winners (ticket_id) VALUES (?)',
        [ticket.id],
        function(err) {
          if (err) {
            return res.status(500).json({ error: 'Error recording winner' });
          }

          db.get(
            `SELECT w.*, t.ticket_number, u.phone 
             FROM winners w
             JOIN tickets t ON w.ticket_id = t.id
             JOIN users u ON t.user_id = u.id
             WHERE w.id = ?`,
            [this.lastID],
            (err, winner) => {
              if (err) {
                return res.status(500).json({ error: 'Error fetching winner details' });
              }
              res.json({ winner });
            }
          );
        }
      );
    }
  );
});

// Get all winners
app.get('/api/winners', (req, res) => {
  db.all(
    `SELECT w.*, t.ticket_number, u.phone 
     FROM winners w
     JOIN tickets t ON w.ticket_id = t.id
     JOIN users u ON t.user_id = u.id
     ORDER BY w.drawn_at DESC`,
    (err, winners) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      res.json({ winners });
    }
  );
});

// Get statistics (admin only)
app.get('/api/admin/stats', requireAuth, requireAdmin, (req, res) => {
  db.get(
    `SELECT 
      (SELECT COUNT(*) FROM users) as total_users,
      (SELECT COUNT(*) FROM tickets) as total_tickets,
      (SELECT COUNT(*) FROM winners) as total_winners
    `,
    (err, stats) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      res.json(stats);
    }
  );
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
