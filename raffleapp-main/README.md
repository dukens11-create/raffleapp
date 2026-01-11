# Raffle App

A web-based raffle ticket management system for organizing and managing raffle draws with ticket sales tracking, seller management, and automated prize distribution.

## Features

- 🎫 Ticket sales management
- 👥 Multi-user support (Admin & Sellers)
- 🎰 Automated raffle draws
- 📊 Sales reporting and analytics
- 📱 Mobile-responsive design
- 🔐 Secure authentication

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
