require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const path = require('path');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('MongoDB connected'))
.catch(err => console.error('MongoDB connection error:', err));

// User Schema
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  resetToken: String,
  resetTokenExpiry: Date,
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

// Raffle Schema
const raffleSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: String,
  entries: [{
    name: String,
    email: String,
    entryDate: { type: Date, default: Date.now }
  }],
  winner: {
    name: String,
    email: String,
    selectedDate: Date
  },
  isActive: { type: Boolean, default: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdAt: { type: Date, default: Date.now }
});

const Raffle = mongoose.model('Raffle', raffleSchema);

// Auth Middleware
const authMiddleware = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'No authentication token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid authentication token' });
  }
};

// Routes

// Register
app.post('/api/register', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = new User({
      email,
      password: hashedPassword
    });

    await user.save();

    // Create token
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '7d'
    });

    res.status(201).json({ token, email: user.email });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Error creating user' });
  }
});

// Login
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Check password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Create token
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '7d'
    });

    res.json({ token, email: user.email });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Error logging in' });
  }
});

// Get current user
app.get('/api/user', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('-password');
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Error fetching user' });
  }
});

// Create raffle
app.post('/api/raffles', authMiddleware, async (req, res) => {
  try {
    const { title, description } = req.body;

    const raffle = new Raffle({
      title,
      description,
      createdBy: req.userId
    });

    await raffle.save();
    res.status(201).json(raffle);
  } catch (error) {
    console.error('Error creating raffle:', error);
    res.status(500).json({ error: 'Error creating raffle' });
  }
});

// Get all raffles for user
app.get('/api/raffles', authMiddleware, async (req, res) => {
  try {
    const raffles = await Raffle.find({ createdBy: req.userId }).sort({ createdAt: -1 });
    res.json(raffles);
  } catch (error) {
    console.error('Error fetching raffles:', error);
    res.status(500).json({ error: 'Error fetching raffles' });
  }
});

// Get single raffle
app.get('/api/raffles/:id', authMiddleware, async (req, res) => {
  try {
    const raffle = await Raffle.findOne({
      _id: req.params.id,
      createdBy: req.userId
    });

    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }

    res.json(raffle);
  } catch (error) {
    console.error('Error fetching raffle:', error);
    res.status(500).json({ error: 'Error fetching raffle' });
  }
});

// Update raffle
app.put('/api/raffles/:id', authMiddleware, async (req, res) => {
  try {
    const { title, description, isActive } = req.body;

    const raffle = await Raffle.findOneAndUpdate(
      { _id: req.params.id, createdBy: req.userId },
      { title, description, isActive },
      { new: true }
    );

    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }

    res.json(raffle);
  } catch (error) {
    console.error('Error updating raffle:', error);
    res.status(500).json({ error: 'Error updating raffle' });
  }
});

// Delete raffle
app.delete('/api/raffles/:id', authMiddleware, async (req, res) => {
  try {
    const raffle = await Raffle.findOneAndDelete({
      _id: req.params.id,
      createdBy: req.userId
    });

    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }

    res.json({ message: 'Raffle deleted successfully' });
  } catch (error) {
    console.error('Error deleting raffle:', error);
    res.status(500).json({ error: 'Error deleting raffle' });
  }
});

// Add entry to raffle
app.post('/api/raffles/:id/entries', authMiddleware, async (req, res) => {
  try {
    const { name, email } = req.body;

    const raffle = await Raffle.findOne({
      _id: req.params.id,
      createdBy: req.userId
    });

    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }

    if (!raffle.isActive) {
      return res.status(400).json({ error: 'Raffle is not active' });
    }

    // Check if email already entered
    const existingEntry = raffle.entries.find(entry => entry.email === email);
    if (existingEntry) {
      return res.status(400).json({ error: 'Email already entered in this raffle' });
    }

    raffle.entries.push({ name, email });
    await raffle.save();

    res.status(201).json(raffle);
  } catch (error) {
    console.error('Error adding entry:', error);
    res.status(500).json({ error: 'Error adding entry' });
  }
});

// Remove entry from raffle
app.delete('/api/raffles/:id/entries/:entryId', authMiddleware, async (req, res) => {
  try {
    const raffle = await Raffle.findOne({
      _id: req.params.id,
      createdBy: req.userId
    });

    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }

    raffle.entries = raffle.entries.filter(
      entry => entry._id.toString() !== req.params.entryId
    );

    await raffle.save();
    res.json(raffle);
  } catch (error) {
    console.error('Error removing entry:', error);
    res.status(500).json({ error: 'Error removing entry' });
  }
});

// Select winner
app.post('/api/raffles/:id/select-winner', authMiddleware, async (req, res) => {
  try {
    const raffle = await Raffle.findOne({
      _id: req.params.id,
      createdBy: req.userId
    });

    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }

    if (raffle.entries.length === 0) {
      return res.status(400).json({ error: 'No entries in raffle' });
    }

    // Select random winner
    const randomIndex = Math.floor(Math.random() * raffle.entries.length);
    const winner = raffle.entries[randomIndex];

    raffle.winner = {
      name: winner.name,
      email: winner.email,
      selectedDate: new Date()
    };

    raffle.isActive = false;
    await raffle.save();

    res.json(raffle);
  } catch (error) {
    console.error('Error selecting winner:', error);
    res.status(500).json({ error: 'Error selecting winner' });
  }
});

// Public raffle entry (no auth required)
app.post('/api/public/raffles/:id/enter', async (req, res) => {
  try {
    const { name, email } = req.body;

    const raffle = await Raffle.findById(req.params.id);

    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }

    if (!raffle.isActive) {
      return res.status(400).json({ error: 'Raffle is not active' });
    }

    // Check if email already entered
    const existingEntry = raffle.entries.find(entry => entry.email === email);
    if (existingEntry) {
      return res.status(400).json({ error: 'You have already entered this raffle' });
    }

    raffle.entries.push({ name, email });
    await raffle.save();

    res.status(201).json({ message: 'Entry added successfully' });
  } catch (error) {
    console.error('Error adding public entry:', error);
    res.status(500).json({ error: 'Error adding entry' });
  }
});

// Get public raffle info (no auth required)
app.get('/api/public/raffles/:id', async (req, res) => {
  try {
    const raffle = await Raffle.findById(req.params.id)
      .select('title description isActive entries.length winner');

    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }

    // Return limited info for public view
    const publicInfo = {
      title: raffle.title,
      description: raffle.description,
      isActive: raffle.isActive,
      entryCount: raffle.entries.length,
      hasWinner: !!raffle.winner,
      winner: raffle.winner ? {
        name: raffle.winner.name,
        selectedDate: raffle.winner.selectedDate
      } : null
    };

    res.json(publicInfo);
  } catch (error) {
    console.error('Error fetching public raffle:', error);
    res.status(500).json({ error: 'Error fetching raffle' });
  }
});

// Bulk import entries
app.post('/api/raffles/:id/import', authMiddleware, async (req, res) => {
  try {
    const { entries } = req.body;

    const raffle = await Raffle.findOne({
      _id: req.params.id,
      createdBy: req.userId
    });

    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }

    if (!raffle.isActive) {
      return res.status(400).json({ error: 'Raffle is not active' });
    }

    // Validate and add entries
    const existingEmails = new Set(raffle.entries.map(e => e.email));
    const newEntries = [];
    const duplicates = [];

    entries.forEach(entry => {
      if (existingEmails.has(entry.email)) {
        duplicates.push(entry.email);
      } else {
        newEntries.push(entry);
        existingEmails.add(entry.email);
      }
    });

    raffle.entries.push(...newEntries);
    await raffle.save();

    res.json({
      message: 'Import completed',
      added: newEntries.length,
      duplicates: duplicates.length,
      duplicateEmails: duplicates
    });
  } catch (error) {
    console.error('Error importing entries:', error);
    res.status(500).json({ error: 'Error importing entries' });
  }
});

// Export entries
app.get('/api/raffles/:id/export', authMiddleware, async (req, res) => {
  try {
    const raffle = await Raffle.findOne({
      _id: req.params.id,
      createdBy: req.userId
    });

    if (!raffle) {
      return res.status(404).json({ error: 'Raffle not found' });
    }

    // Format as CSV
    const csv = [
      'Name,Email,Entry Date',
      ...raffle.entries.map(entry => 
        `"${entry.name}","${entry.email}","${entry.entryDate}"`
      )
    ].join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="raffle-${raffle._id}-entries.csv"`);
    res.send(csv);
  } catch (error) {
    console.error('Error exporting entries:', error);
    res.status(500).json({ error: 'Error exporting entries' });
  }
});

// Serve static files in production
if (process.env.NODE_ENV === 'production') {
  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
  });
}

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});