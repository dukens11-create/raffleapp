const express = require('express');
const session = require('express-session');
const bodyParser = require('body-parser');
const path = require('path');
const bcrypt = require('bcrypt');
const sqlite3 = require('sqlite3').verbose();
const app = express();
const PORT = 3000;

// Database setup
const db = new sqlite3.Database('./raffle.db', (err) => {
    if (err) {
        console.error('Error opening database:', err);
    } else {
        console.log('Connected to SQLite database');
        initializeDatabase();
    }
});

// Initialize database tables
function initializeDatabase() {
    db.serialize(() => {
        // Users table
        db.run(`CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'user',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )`);

        // Raffles table
        db.run(`CREATE TABLE IF NOT EXISTS raffles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            max_entries INTEGER NOT NULL,
            current_entries INTEGER DEFAULT 0,
            status TEXT DEFAULT 'active',
            created_by INTEGER,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            drawn_at DATETIME,
            FOREIGN KEY (created_by) REFERENCES users(id)
        )`);

        // Entries table
        db.run(`CREATE TABLE IF NOT EXISTS entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            raffle_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            entry_time DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (raffle_id) REFERENCES raffles(id),
            FOREIGN KEY (user_id) REFERENCES users(id),
            UNIQUE(raffle_id, user_id)
        )`);

        // Winners table
        db.run(`CREATE TABLE IF NOT EXISTS winners (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            raffle_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            won_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (raffle_id) REFERENCES raffles(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
        )`);

        // Create default admin user if not exists
        const defaultAdminPassword = bcrypt.hashSync('admin123', 10);
        db.run(`INSERT OR IGNORE INTO users (username, password, role) VALUES (?, ?, ?)`,
            ['admin', defaultAdminPassword, 'admin'],
            (err) => {
                if (err) {
                    console.error('Error creating default admin:', err);
                } else {
                    console.log('Default admin user initialized');
                }
            }
        );
    });
}

// Middleware
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(session({
    secret: 'raffle-secret-key-change-in-production',
    resave: false,
    saveUninitialized: false,
    cookie: { secure: false } // Set to true if using HTTPS
}));

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Authentication middleware
function requireAuth(req, res, next) {
    if (req.session.userId) {
        next();
    } else {
        res.redirect('/login.html');
    }
}

function requireAdmin(req, res, next) {
    if (req.session.userId && req.session.role === 'admin') {
        next();
    } else {
        res.status(403).json({ error: 'Admin access required' });
    }
}

// Routes

// Login endpoint
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;

    db.get('SELECT * FROM users WHERE username = ?', [username], (err, user) => {
        if (err) {
            return res.status(500).json({ error: 'Database error' });
        }

        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        bcrypt.compare(password, user.password, (err, result) => {
            if (err) {
                return res.status(500).json({ error: 'Authentication error' });
            }

            if (result) {
                req.session.userId = user.id;
                req.session.username = user.username;
                req.session.role = user.role;

                const redirectUrl = user.role === 'admin' ? '/admin.html' : '/user.html';
                res.json({ 
                    success: true, 
                    redirect: redirectUrl,
                    role: user.role 
                });
            } else {
                res.status(401).json({ error: 'Invalid credentials' });
            }
        });
    });
});

// Register endpoint
app.post('/api/register', (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ error: 'Username and password required' });
    }

    if (password.length < 6) {
        return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    bcrypt.hash(password, 10, (err, hashedPassword) => {
        if (err) {
            return res.status(500).json({ error: 'Error creating account' });
        }

        db.run('INSERT INTO users (username, password, role) VALUES (?, ?, ?)',
            [username, hashedPassword, 'user'],
            function(err) {
                if (err) {
                    if (err.message.includes('UNIQUE')) {
                        return res.status(400).json({ error: 'Username already exists' });
                    }
                    return res.status(500).json({ error: 'Error creating account' });
                }

                req.session.userId = this.lastID;
                req.session.username = username;
                req.session.role = 'user';

                res.json({ 
                    success: true, 
                    redirect: '/user.html',
                    role: 'user'
                });
            }
        );
    });
});

// Logout endpoint
app.post('/api/logout', (req, res) => {
    req.session.destroy((err) => {
        if (err) {
            return res.status(500).json({ error: 'Error logging out' });
        }
        res.json({ success: true });
    });
});

// Get current user info
app.get('/api/user', requireAuth, (req, res) => {
    res.json({
        id: req.session.userId,
        username: req.session.username,
        role: req.session.role
    });
});

// Admin endpoints

// Get all raffles (admin)
app.get('/api/admin/raffles', requireAdmin, (req, res) => {
    db.all(`SELECT r.*, u.username as creator_name,
            (SELECT COUNT(*) FROM entries WHERE raffle_id = r.id) as entry_count
            FROM raffles r
            LEFT JOIN users u ON r.created_by = u.id
            ORDER BY r.created_at DESC`, [], (err, raffles) => {
        if (err) {
            return res.status(500).json({ error: 'Database error' });
        }
        res.json(raffles);
    });
});

// Create raffle (admin)
app.post('/api/admin/raffles', requireAdmin, (req, res) => {
    const { name, description, max_entries } = req.body;

    if (!name || !max_entries) {
        return res.status(400).json({ error: 'Name and max entries required' });
    }

    db.run(`INSERT INTO raffles (name, description, max_entries, created_by) VALUES (?, ?, ?, ?)`,
        [name, description, max_entries, req.session.userId],
        function(err) {
            if (err) {
                return res.status(500).json({ error: 'Error creating raffle' });
            }
            res.json({ success: true, raffleId: this.lastID });
        }
    );
});

// Draw winner (admin)
app.post('/api/admin/raffles/:id/draw', requireAdmin, (req, res) => {
    const raffleId = req.params.id;

    // Check if raffle exists and is active
    db.get('SELECT * FROM raffles WHERE id = ? AND status = ?', [raffleId, 'active'], (err, raffle) => {
        if (err) {
            return res.status(500).json({ error: 'Database error' });
        }

        if (!raffle) {
            return res.status(404).json({ error: 'Active raffle not found' });
        }

        // Get all entries for this raffle
        db.all('SELECT * FROM entries WHERE raffle_id = ?', [raffleId], (err, entries) => {
            if (err) {
                return res.status(500).json({ error: 'Database error' });
            }

            if (entries.length === 0) {
                return res.status(400).json({ error: 'No entries in this raffle' });
            }

            // Randomly select a winner
            const winnerEntry = entries[Math.floor(Math.random() * entries.length)];

            // Update raffle status and add winner
            db.serialize(() => {
                db.run('UPDATE raffles SET status = ?, drawn_at = CURRENT_TIMESTAMP WHERE id = ?',
                    ['completed', raffleId]);

                db.run('INSERT INTO winners (raffle_id, user_id) VALUES (?, ?)',
                    [raffleId, winnerEntry.user_id]);

                // Get winner details
                db.get('SELECT username FROM users WHERE id = ?', [winnerEntry.user_id], (err, user) => {
                    if (err) {
                        return res.status(500).json({ error: 'Database error' });
                    }
                    res.json({ 
                        success: true, 
                        winner: {
                            userId: winnerEntry.user_id,
                            username: user.username
                        }
                    });
                });
            });
        });
    });
});

// Get raffle entries (admin)
app.get('/api/admin/raffles/:id/entries', requireAdmin, (req, res) => {
    const raffleId = req.params.id;

    db.all(`SELECT e.*, u.username 
            FROM entries e
            JOIN users u ON e.user_id = u.id
            WHERE e.raffle_id = ?
            ORDER BY e.entry_time DESC`, [raffleId], (err, entries) => {
        if (err) {
            return res.status(500).json({ error: 'Database error' });
        }
        res.json(entries);
    });
});

// User endpoints

// Get active raffles (user)
app.get('/api/raffles', requireAuth, (req, res) => {
    db.all(`SELECT r.*, 
            (SELECT COUNT(*) FROM entries WHERE raffle_id = r.id) as entry_count,
            EXISTS(SELECT 1 FROM entries WHERE raffle_id = r.id AND user_id = ?) as user_entered
            FROM raffles r
            WHERE r.status = 'active'
            ORDER BY r.created_at DESC`, [req.session.userId], (err, raffles) => {
        if (err) {
            return res.status(500).json({ error: 'Database error' });
        }
        res.json(raffles);
    });
});

// Enter raffle (user)
app.post('/api/raffles/:id/enter', requireAuth, (req, res) => {
    const raffleId = req.params.id;
    const userId = req.session.userId;

    // Check if raffle exists and is active
    db.get('SELECT * FROM raffles WHERE id = ? AND status = ?', [raffleId, 'active'], (err, raffle) => {
        if (err) {
            return res.status(500).json({ error: 'Database error' });
        }

        if (!raffle) {
            return res.status(404).json({ error: 'Active raffle not found' });
        }

        // Check if raffle is full
        db.get('SELECT COUNT(*) as count FROM entries WHERE raffle_id = ?', [raffleId], (err, result) => {
            if (err) {
                return res.status(500).json({ error: 'Database error' });
            }

            if (result.count >= raffle.max_entries) {
                return res.status(400).json({ error: 'Raffle is full' });
            }

            // Try to enter
            db.run('INSERT INTO entries (raffle_id, user_id) VALUES (?, ?)',
                [raffleId, userId],
                function(err) {
                    if (err) {
                        if (err.message.includes('UNIQUE')) {
                            return res.status(400).json({ error: 'Already entered this raffle' });
                        }
                        return res.status(500).json({ error: 'Error entering raffle' });
                    }

                    // Update current entries count
                    db.run('UPDATE raffles SET current_entries = current_entries + 1 WHERE id = ?',
                        [raffleId]);

                    res.json({ success: true });
                }
            );
        });
    });
});

// Get user's entries
app.get('/api/user/entries', requireAuth, (req, res) => {
    db.all(`SELECT e.*, r.name as raffle_name, r.status, r.drawn_at,
            (SELECT u.username FROM winners w JOIN users u ON w.user_id = u.id 
             WHERE w.raffle_id = r.id LIMIT 1) as winner_username,
            EXISTS(SELECT 1 FROM winners WHERE raffle_id = r.id AND user_id = ?) as is_winner
            FROM entries e
            JOIN raffles r ON e.raffle_id = r.id
            WHERE e.user_id = ?
            ORDER BY e.entry_time DESC`, [req.session.userId, req.session.userId], (err, entries) => {
        if (err) {
            return res.status(500).json({ error: 'Database error' });
        }
        res.json(entries);
    });
});

// Get user's wins
app.get('/api/user/wins', requireAuth, (req, res) => {
    db.all(`SELECT w.*, r.name as raffle_name, r.description
            FROM winners w
            JOIN raffles r ON w.raffle_id = r.id
            WHERE w.user_id = ?
            ORDER BY w.won_at DESC`, [req.session.userId], (err, wins) => {
        if (err) {
            return res.status(500).json({ error: 'Database error' });
        }
        res.json(wins);
    });
});

// Serve HTML pages
app.get('/admin.html', requireAuth, (req, res) => {
    if (req.session.role !== 'admin') {
        return res.redirect('/user.html');
    }
    res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

app.get('/user.html', requireAuth, (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'user.html'));
});

// Redirect root to login
app.get('/', (req, res) => {
    if (req.session.userId) {
        const redirect = req.session.role === 'admin' ? '/admin.html' : '/user.html';
        res.redirect(redirect);
    } else {
        res.redirect('/login.html');
    }
});

// Start server
app.listen(PORT, () => {
    console.log(`Raffle app server running on http://localhost:${PORT}`);
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