# Grate Genyen

A web-based raffle ticket management system for organizing and managing raffle draws with ticket sales tracking, seller management, and automated prize distribution.

## Features

- 🎫 Ticket sales management
- 👥 Multi-user support (Admin & Sellers)
- 🎰 Automated raffle draws
- 📊 Sales reporting and analytics
- 📱 Mobile-responsive design
- 🔐 Secure authentication

## 📱 Mobile Apps (Android & iOS)

This web application can be transformed into native mobile apps for Android and iOS using Capacitor!

### Quick Start for Mobile

```bash
cd raffle-app

# Install dependencies (includes Capacitor)
npm install

# Prepare web files for mobile
npm run build

# Initialize Capacitor (first time only)
npm run cap:init

# Add platforms
npm run cap:add:android    # For Android
npm run cap:add:ios        # For iOS (macOS only)

# Sync files
npm run cap:sync

# Open in native IDE
npm run cap:open:android   # Opens Android Studio
npm run cap:open:ios       # Opens Xcode
```

### What You Get

- ✅ **Android APK/AAB** - Ready for Google Play Store
- ✅ **iOS IPA** - Ready for Apple App Store  
- ✅ **Native Features** - Camera, push notifications, offline support
- ✅ **60fps Performance** - Smooth animations
- ✅ **Easy Updates** - Sync web changes to mobile

### Full Documentation

See [MOBILE_BUILD_GUIDE.md](raffle-app/MOBILE_BUILD_GUIDE.md) for complete instructions on:
- Android and iOS build steps
- App store submission guidelines
- Testing and troubleshooting
- Required tools and prerequisites

## Default Admin Credentials

When the application starts for the first time, a default admin account is automatically created:

- **Phone Number:** `1234567890`
- **Password:** `admin123`

⚠️ **Important:** Change the default admin password immediately after first login for security purposes.

## 🗄️ Database Status

### Current Setup Detection

The app automatically detects which database you're using:

- **Development (SQLite):** 📁 Data stored in local file
- **Production (PostgreSQL):** 🐘 Data stored in persistent database

### Migration Required?

If you see this in your Render logs:

```
⚠️  WARNING: Using SQLite database
   Data will be LOST on every restart
```

**Action Required:** Follow [MIGRATION.md](raffle-app/MIGRATION.md) to switch to PostgreSQL.

### Verify Your Setup

Check your database status:
```
GET https://your-app.onrender.com/health
```

Healthy PostgreSQL setup shows:
```json
{
  "status": "ok",
  "database": {
    "type": "PostgreSQL",
    "connected": true,
    "persistent": true
  }
}
```

## Prerequisites

- Node.js (v14 or higher)
- npm (Node Package Manager)
- SQLite3

## Local Development Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd raffleapp
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Configuration

Create a `.env` file in the root directory (optional, uses defaults if not provided):

```env
PORT=3000
NODE_ENV=development
SESSION_SECRET=your-secret-key-here
```

You can use the `.env.example` file as a template:

```bash
cp .env.example .env
```

### 4. Start the Application

```bash
npm start
```

The application will be available at `http://localhost:3000`

### 5. Login

Navigate to `http://localhost:3000` and login with the default admin credentials:
- Phone: `1234567890`
- Password: `admin123`

## Database

The application uses SQLite as its database. The database file (`raffle.db`) is automatically created when the application starts for the first time.

### Database Tables

- **users** - Stores user accounts (admin and sellers)
- **tickets** - Stores raffle ticket information
- **draws** - Stores raffle draw results

### Database Initialization

On first run, the application will:
1. Create all necessary database tables
2. Create a default admin user (phone: 1234567890, password: admin123)

## Deployment to Render

### Prerequisites

- A [Render](https://render.com) account
- Your code pushed to a Git repository (GitHub, GitLab, or Bitbucket)

### Deployment Steps

1. **Login to Render Dashboard**
   - Go to https://render.com and sign in

2. **Create a New Web Service**
   - Click "New +" and select "Web Service"
   - Connect your Git repository

3. **Configure the Service**
   - **Name:** `raffle-app` (or your preferred name)
   - **Environment:** `Node`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Plan:** Free (or your preferred plan)

4. **Set Environment Variables** (Optional but recommended)
   - Go to the "Environment" tab
   - Add the following variables:
     ```
     NODE_ENV=production
     SESSION_SECRET=<generate-a-strong-random-secret>
     PORT=10000
     ```

5. **Deploy**
   - Click "Create Web Service"
   - Render will automatically build and deploy your application
   - Wait for the deployment to complete

6. **Access Your Application**
   - Once deployed, Render will provide you with a URL (e.g., `https://raffle-app.onrender.com`)
   - Navigate to the URL and login with default credentials

### Important Notes for Render Deployment

#### ⚠️ Database Persistence Issue

Render's free tier uses an **ephemeral filesystem**, which means:
- The SQLite database (`raffle.db`) will be **deleted** on each deployment or service restart
- All data (users, tickets, draws) will be **lost** when the service restarts
- The default admin account will be recreated automatically

**Recommended Solutions for Production:**

1. **Use Render's PostgreSQL** (Recommended for production)
   - Add a PostgreSQL database from Render's dashboard
   - Modify the application to use PostgreSQL instead of SQLite
   - Data will persist across deployments

2. **Use an External Database Service**
   - Consider using services like:
     - [Supabase](https://supabase.com) (PostgreSQL)
     - [PlanetScale](https://planetscale.com) (MySQL)
     - [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) (MongoDB)

3. **For Testing/Demo Only**
   - If you're only testing or running a demo, the current SQLite setup is acceptable
   - Just be aware that data will reset on each deployment

### Render Configuration File

The repository includes a `render.yaml` file that defines the service configuration:

```yaml
services:
  - type: web
    name: raffle-app
    env: node
    rootDir: raffle-app
    buildCommand: npm install
    startCommand: node server.js
    plan: free
    autoDeploy: true
```

## Project Structure

```
raffleapp/
├── raffle-app/
│   ├── public/           # Static files (HTML, CSS, JS)
│   │   ├── login.html    # Login page
│   │   ├── admin.html    # Admin dashboard
│   │   └── seller.html   # Seller dashboard
│   ├── server.js         # Main application server
│   └── package.json      # Project dependencies
├── package.json          # Root package.json
├── .env.example          # Environment variables template
├── .gitignore           # Git ignore rules
├── render.yaml          # Render deployment configuration
└── README.md            # This file
```

## Admin Scripts

### Mark Tickets Available Online

The `markTicketsAvailable.js` script makes tickets available for purchase in the buyer portal. This script should be run after deploying the application to expose tickets for online sales.

#### Usage

```bash
# Navigate to the raffle-app directory
cd raffle-app

# Preview changes (dry-run mode)
npm run mark-available:dry-run

# Apply changes to make last 100,000 tickets per category available
npm run mark-available

# Or run directly with custom options
node scripts/markTicketsAvailable.js --limit=50000
```

#### What it does

For each ticket category in the database:
1. Selects the **last 100,000 tickets** (by `created_at` timestamp, newest first)
2. Updates those tickets to:
   - Set `available_online = true` (makes them visible in buyer portal)
   - Set `status = 'AVAILABLE'` (unless already sold)

#### Options

- `--dry-run` - Preview changes without applying them
- `--reset` - Mark all tickets as NOT available online (reverses the operation)
- `--limit=N` - Override the default 100,000 ticket limit per category

#### Examples

```bash
# Preview what would be updated
node scripts/markTicketsAvailable.js --dry-run

# Make 100,000 tickets per category available (default)
node scripts/markTicketsAvailable.js

# Make only 50,000 tickets per category available
node scripts/markTicketsAvailable.js --limit=50000

# Reset all tickets to not available online
node scripts/markTicketsAvailable.js --reset
```

#### Database Support

The script automatically detects and works with:
- **PostgreSQL** (when `DATABASE_URL` environment variable is set)
- **SQLite** (when `DATABASE_URL` is not set)

#### Notes

- The script preserves the status of sold tickets
- Progress is displayed for each category
- A summary table shows the results after completion
- Safe to run multiple times (idempotent operation)

## API Endpoints

### Authentication
- `POST /login` - User login
- `GET /logout` - User logout

### Admin Routes
- `GET /admin` - Admin dashboard
- `GET /api/tickets` - Get all tickets
- `GET /api/sellers` - Get all sellers
- `POST /api/draw` - Conduct a raffle draw
- Various other admin management endpoints

### Seller Routes
- `GET /seller` - Seller dashboard
- `POST /api/ticket` - Add a new ticket
- Various other seller-specific endpoints

## Security Considerations

1. **Change Default Credentials**: Always change the default admin password after first login
2. **Use Strong Session Secret**: Set a strong `SESSION_SECRET` in production
3. **HTTPS**: Always use HTTPS in production (Render provides this automatically)
4. **Database Security**: Consider using a proper database with authentication for production
5. **Input Validation**: The application includes basic input validation, but review before production use

## Troubleshooting

### "Cannot GET /register.html" Error
This error is fixed in the latest version. The register link has been removed from the login page.

### Login Not Working
- Verify you're using the correct default credentials (phone: 1234567890, password: admin123)
- Check that the database was initialized correctly (check console logs)
- Ensure the server is running and accessible

### Database Reset on Render
This is expected behavior with the current SQLite setup on Render's ephemeral filesystem. See "Database Persistence Issue" section above for solutions.

### Port Already in Use
If you get a "port already in use" error locally:
```bash
# Find and kill the process using port 3000
lsof -ti:3000 | xargs kill -9
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For issues, questions, or contributions, please open an issue in the repository.

---

**Note**: This application is designed for educational and demonstration purposes. For production use, implement additional security measures, data persistence solutions, and proper database management.
