const express = require('express');
const bodyParser = require('body-parser');
const session = require('express-session');
const bcrypt = require('bcrypt');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Database setup
const db = new sqlite3.Database('./raffle.db', (err) => {
  if (err) {
    console.error('Error opening database:', err);
  } else {
    console.log('Connected to SQLite database');
    initializeDatabase();
  }
});

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(session({
  secret: process.env.SESSION_SECRET || 'raffle-secret-key-2024',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 }
}));

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Initialize database tables
function initializeDatabase() {
  db.serialize(() => {
    // Users table
    db.run(`CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Tickets table
    db.run(`CREATE TABLE IF NOT EXISTS tickets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ticket_number TEXT UNIQUE NOT NULL,
      buyer_name TEXT NOT NULL,
      buyer_phone TEXT NOT NULL,
      seller_name TEXT NOT NULL,
      seller_phone TEXT NOT NULL,
      amount REAL NOT NULL,
      status TEXT DEFAULT 'active',
      barcode TEXT,
      category TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);
    
    // Add barcode and category columns if they don't exist (migration)
    db.run(`ALTER TABLE tickets ADD COLUMN barcode TEXT`, (err) => {
      // Error code 1 is SQLITE_ERROR which includes "duplicate column name"
      // Silently ignore if column already exists
      if (err && err.errno !== 1) {
        console.error('Error adding barcode column:', err);
      }
    });
    
    db.run(`ALTER TABLE tickets ADD COLUMN category TEXT`, (err) => {
      // Error code 1 is SQLITE_ERROR which includes "duplicate column name"
      // Silently ignore if column already exists
      if (err && err.errno !== 1) {
        console.error('Error adding category column:', err);
      }
    });

    // Draws table
    db.run(`CREATE TABLE IF NOT EXISTS draws (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      draw_number INTEGER NOT NULL,
      ticket_number INTEGER NOT NULL,
      prize_name TEXT NOT NULL,
      winner_name TEXT NOT NULL,
      winner_phone TEXT NOT NULL,
      drawn_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Check if admin exists, if not create default admin
    db.get("SELECT * FROM users WHERE role = 'admin'", (err, row) => {
      if (!row) {
        bcrypt.hash('admin123', 10, (err, hash) => {
          if (err) {
            console.error('Error hashing password:', err);
            return;
          }
          db.run(
            "INSERT INTO users (name, phone, password, role) VALUES (?, ?, ?, ?)",
            ['Admin', '1234567890', hash, 'admin'],
            (err) => {
              if (err) {
                console.error('Error creating admin:', err);
              } else {
                console.log('Default admin created - Phone: 1234567890, Password: admin123');
              }
            }
          );
        });
      }
    });
  });
}

// Authentication middleware
function requireAuth(req, res, next) {
  if (req.session.user) {
    next();
  } else {
    res.redirect('/');
  }
}

function requireAdmin(req, res, next) {
  if (req.session.user && req.session.user.role === 'admin') {
    next();
  } else {
    res.status(403).send('Access denied');
  }
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
app.post('/login', (req, res) => {
  const { phone, password } = req.body;
  
  db.get("SELECT * FROM users WHERE phone = ?", [phone], (err, user) => {
    if (err) {
      return res.json({ error: 'Database error' });
    }
    
    if (!user) {
      return res.json({ error: 'Invalid phone number or password' });
    }
    
    bcrypt.compare(password, user.password, (err, result) => {
      if (err) {
        return res.json({ error: 'Authentication error' });
      }
      
      if (result) {
        req.session.user = {
          id: user.id,
          name: user.name,
          phone: user.phone,
          role: user.role
        };
        
        if (user.role === 'admin') {
          res.json({ redirect: '/admin', role: 'admin' });
        } else {
          res.json({ redirect: '/seller?name=' + encodeURIComponent(user.name), role: 'seller', name: user.name });
        }
      } else {
        res.json({ error: 'Invalid phone number or password' });
      }
    });
  });
});

// Logout
app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/');
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
app.get('/api/sellers', requireAuth, requireAdmin, (req, res) => {
  db.all("SELECT id, name, phone, created_at FROM users WHERE role = 'seller'", (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

// API: Add seller
app.post('/api/sellers', requireAuth, requireAdmin, (req, res) => {
  const { name, phone, password } = req.body;
  
  if (!name || !phone || !password) {
    return res.status(400).json({ error: 'All fields are required' });
  }
  
  bcrypt.hash(password, 10, (err, hash) => {
    if (err) {
      return res.status(500).json({ error: 'Error hashing password' });
    }
    
    db.run(
      "INSERT INTO users (name, phone, password, role) VALUES (?, ?, ?, 'seller')",
      [name, phone, hash],
      function(err) {
        if (err) {
          if (err.message.includes('UNIQUE constraint failed')) {
            return res.status(400).json({ error: 'Phone number already exists' });
          }
          return res.status(500).json({ error: 'Database error' });
        }
        res.json({ success: true, id: this.lastID });
      }
    );
  });
});

// API: Update seller
app.put('/api/sellers/:id', requireAuth, requireAdmin, (req, res) => {
  const { id } = req.params;
  const { name, phone, password } = req.body;
  
  if (!name || !phone) {
    return res.status(400).json({ error: 'Name and phone are required' });
  }
  
  if (password) {
    bcrypt.hash(password, 10, (err, hash) => {
      if (err) {
        return res.status(500).json({ error: 'Error hashing password' });
      }
      
      db.run(
        "UPDATE users SET name = ?, phone = ?, password = ? WHERE id = ? AND role = 'seller'",
        [name, phone, hash, id],
        function(err) {
          if (err) {
            if (err.message.includes('UNIQUE constraint failed')) {
              return res.status(400).json({ error: 'Phone number already exists' });
            }
            return res.status(500).json({ error: 'Database error' });
          }
          res.json({ success: true });
        }
      );
    });
  } else {
    db.run(
      "UPDATE users SET name = ?, phone = ? WHERE id = ? AND role = 'seller'",
      [name, phone, id],
      function(err) {
        if (err) {
          if (err.message.includes('UNIQUE constraint failed')) {
            return res.status(400).json({ error: 'Phone number already exists' });
          }
          return res.status(500).json({ error: 'Database error' });
        }
        res.json({ success: true });
      }
    );
  }
});

// API: Delete seller
app.delete('/api/sellers/:id', requireAuth, requireAdmin, (req, res) => {
  const { id } = req.params;
  
  db.run("DELETE FROM users WHERE id = ? AND role = 'seller'", [id], function(err) {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json({ success: true });
  });
});

// API: Get all tickets
app.get('/api/tickets', requireAuth, (req, res) => {
  let query = "SELECT * FROM tickets ORDER BY ticket_number";
  let params = [];
  
  if (req.session.user.role === 'seller') {
    query = "SELECT * FROM tickets WHERE seller_phone = ? ORDER BY ticket_number";
    params = [req.session.user.phone];
  }
  
  db.all(query, params, (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

// API: Add ticket
app.post('/api/tickets', requireAuth, (req, res) => {
  const { ticket_number, buyer_name, buyer_phone, amount } = req.body;
  
  if (!ticket_number || !buyer_name || !buyer_phone || !amount) {
    return res.status(400).json({ error: 'All fields are required' });
  }
  
  const seller_name = req.session.user.name;
  const seller_phone = req.session.user.phone;
  
  db.run(
    "INSERT INTO tickets (ticket_number, buyer_name, buyer_phone, seller_name, seller_phone, amount) VALUES (?, ?, ?, ?, ?, ?)",
    [ticket_number, buyer_name, buyer_phone, seller_name, seller_phone, amount],
    function(err) {
      if (err) {
        if (err.message.includes('UNIQUE constraint failed')) {
          return res.status(400).json({ error: 'Ticket number already exists' });
        }
        return res.status(500).json({ error: 'Database error' });
      }
      res.json({ success: true, id: this.lastID });
    }
  );
});

// API: Update ticket
app.put('/api/tickets/:id', requireAuth, (req, res) => {
  const { id } = req.params;
  const { buyer_name, buyer_phone, amount } = req.body;
  
  if (!buyer_name || !buyer_phone || !amount) {
    return res.status(400).json({ error: 'All fields are required' });
  }
  
  let query, params;
  
  if (req.session.user.role === 'admin') {
    query = "UPDATE tickets SET buyer_name = ?, buyer_phone = ?, amount = ? WHERE id = ?";
    params = [buyer_name, buyer_phone, amount, id];
  } else {
    query = "UPDATE tickets SET buyer_name = ?, buyer_phone = ?, amount = ? WHERE id = ? AND seller_phone = ?";
    params = [buyer_name, buyer_phone, amount, id, req.session.user.phone];
  }
  
  db.run(query, params, function(err) {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    if (this.changes === 0) {
      return res.status(403).json({ error: 'Not authorized to update this ticket' });
    }
    res.json({ success: true });
  });
});

// API: Delete ticket
app.delete('/api/tickets/:id', requireAuth, (req, res) => {
  const { id } = req.params;
  
  let query, params;
  
  if (req.session.user.role === 'admin') {
    query = "DELETE FROM tickets WHERE id = ?";
    params = [id];
  } else {
    query = "DELETE FROM tickets WHERE id = ? AND seller_phone = ?";
    params = [id, req.session.user.phone];
  }
  
  db.run(query, params, function(err) {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    if (this.changes === 0) {
      return res.status(403).json({ error: 'Not authorized to delete this ticket' });
    }
    res.json({ success: true });
  });
});

// API: Get ticket statistics
app.get('/api/stats', requireAuth, (req, res) => {
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
  
  db.get(ticketQuery, params, (err, ticketRow) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    
    db.get(revenueQuery, params, (err, revenueRow) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      
      res.json({
        totalTickets: ticketRow.total || 0,
        totalRevenue: revenueRow.total || 0
      });
    });
  });
});

// API: Get all draws
app.get('/api/draws', requireAuth, requireAdmin, (req, res) => {
  db.all("SELECT * FROM draws ORDER BY drawn_at DESC", (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

// API: Conduct draw
app.post('/api/draw', requireAuth, requireAdmin, (req, res) => {
  const { prize_name } = req.body;
  
  if (!prize_name) {
    return res.status(400).json({ error: 'Prize name is required' });
  }
  
  // Get all active tickets
  db.all("SELECT * FROM tickets WHERE status = 'active'", (err, tickets) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    
    if (tickets.length === 0) {
      return res.status(400).json({ error: 'No active tickets available' });
    }
    
    // Random selection
    const winner = tickets[Math.floor(Math.random() * tickets.length)];
    
    // Get next draw number
    db.get("SELECT MAX(draw_number) as max_draw FROM draws", (err, row) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      
      const draw_number = (row.max_draw || 0) + 1;
      
      // Insert draw result
      db.run(
        "INSERT INTO draws (draw_number, ticket_number, prize_name, winner_name, winner_phone) VALUES (?, ?, ?, ?, ?)",
        [draw_number, winner.ticket_number, prize_name, winner.buyer_name, winner.buyer_phone],
        function(err) {
          if (err) {
            return res.status(500).json({ error: 'Database error' });
          }
          
          // Mark ticket as won
          db.run(
            "UPDATE tickets SET status = 'won' WHERE id = ?",
            [winner.id],
            (err) => {
              if (err) {
                return res.status(500).json({ error: 'Error updating ticket status' });
              }
              
              res.json({
                success: true,
                draw: {
                  draw_number,
                  ticket_number: winner.ticket_number,
                  prize_name,
                  winner_name: winner.buyer_name,
                  winner_phone: winner.buyer_phone
                }
              });
            }
          );
        }
      );
    });
  });
});

// API: Get available tickets for draw
app.get('/api/available-tickets', requireAuth, requireAdmin, (req, res) => {
  db.all("SELECT ticket_number FROM tickets WHERE status = 'active' ORDER BY ticket_number", (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows.map(row => row.ticket_number));
  });
});

// API: Get seller statistics
app.get('/api/seller-stats', requireAuth, requireAdmin, (req, res) => {
  db.all(`
    SELECT 
      seller_name,
      seller_phone,
      COUNT(*) as ticket_count,
      SUM(amount) as total_revenue
    FROM tickets
    GROUP BY seller_phone
    ORDER BY total_revenue DESC
  `, (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

// API: Bulk import ticket
app.post('/api/tickets/bulk', requireAuth, requireAdmin, async (req, res) => {
  try {
    const { ticketNumber, buyerName, buyerPhone, amount, category, seller, status, barcode } = req.body;
    
    // Validate required fields (allow amount to be 0)
    if (!ticketNumber || !buyerName || !buyerPhone || amount === undefined || amount === null) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // Validate amount is a number
    if (typeof amount !== 'number' || isNaN(amount) || amount < 0) {
      return res.status(400).json({ error: 'Amount must be a non-negative number' });
    }
    
    // Check if ticket number already exists
    db.get('SELECT id FROM tickets WHERE ticket_number = ?', [ticketNumber], (err, existing) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      
      if (existing) {
        return res.status(400).json({ error: 'Ticket number already exists' });
      }
      
      // Insert ticket with barcode
      db.run(`
        INSERT INTO tickets (ticket_number, buyer_name, buyer_phone, seller_name, seller_phone, amount, category, status, barcode, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
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
      ], function(err) {
        if (err) {
          console.error('Bulk import error:', err);
          return res.status(500).json({ error: err.message });
        }
        
        res.json({ 
          success: true, 
          ticketId: this.lastID,
          ticketNumber 
        });
      });
    });
  } catch (error) {
    console.error('Bulk import error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Legacy endpoints (for backward compatibility with frontend)
app.get('/tickets', requireAuth, (req, res) => {
  let query = "SELECT ticket_number as number, category, status, barcode FROM tickets ORDER BY ticket_number";
  let params = [];
  
  if (req.session.user.role === 'seller') {
    query = "SELECT ticket_number as number, category, status, barcode FROM tickets WHERE seller_phone = ? ORDER BY ticket_number";
    params = [req.session.user.phone];
  }
  
  db.all(query, params, (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

app.get('/users', requireAuth, requireAdmin, (req, res) => {
  db.all("SELECT name, phone, role FROM users ORDER BY name", (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

app.get('/audit-logs', requireAuth, requireAdmin, (req, res) => {
  // Return empty array for now - audit logs table doesn't exist yet
  res.json([]);
});

app.get('/sales-report', requireAuth, requireAdmin, (req, res) => {
  db.all(`
    SELECT seller_name as sold_by, COUNT(*) as count
    FROM tickets
    GROUP BY seller_name
    ORDER BY count DESC
  `, (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

app.get('/seller-leaderboard', requireAuth, requireAdmin, (req, res) => {
  db.all(`
    SELECT seller_name as sold_by, COUNT(*) as tickets_sold
    FROM tickets
    GROUP BY seller_name
    ORDER BY tickets_sold DESC
  `, (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

app.get('/list-backups', requireAuth, requireAdmin, (req, res) => {
  // Return empty array for now - backup functionality not implemented
  res.json([]);
});

app.get('/analytics/sales-by-day', requireAuth, requireAdmin, (req, res) => {
  db.all(`
    SELECT DATE(created_at) as day, COUNT(*) as count
    FROM tickets
    WHERE created_at >= DATE('now', '-30 days')
    GROUP BY DATE(created_at)
    ORDER BY day
  `, (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

app.get('/analytics/tickets-by-category', requireAuth, requireAdmin, (req, res) => {
  db.all(`
    SELECT category, COUNT(*) as count
    FROM tickets
    WHERE category IS NOT NULL
    GROUP BY category
    ORDER BY count DESC
  `, (err, rows) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Access the application at http://localhost:${PORT}`);
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
