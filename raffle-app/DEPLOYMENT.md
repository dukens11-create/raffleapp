# Deployment Guide - Raffle App

This guide covers deploying the Raffle App to production environments.

## Table of Contents
- [Minimal Required Configuration](#minimal-required-configuration)
- [Prerequisites](#prerequisites)
- [Environment Configuration](#environment-configuration)
- [Database Setup](#database-setup)
- [Deployment Platforms](#deployment-platforms)
- [Security Checklist](#security-checklist)
- [Post-Deployment](#post-deployment)

## Minimal Required Configuration

To get the app running quickly, you only need to set **one critical variable**:

### On Render.com:

1. Go to your service → Environment tab
2. Add this variable:

```bash
DATABASE_URL=<your-postgresql-internal-url>
```

**That's it!** The server will:
- ✅ Auto-generate a SESSION_SECRET (you should set a persistent one later)
- ✅ Start successfully and be accessible
- ⚠️  Display warnings for optional configurations

### Optional but Recommended:

For production use, also set:

```bash
SESSION_SECRET=<generate-with-crypto.randomBytes>
ADMIN_SETUP_TOKEN=<your-secure-token>
ALLOWED_ORIGINS=https://yourapp.com
EMAIL_USER=your-email@example.com
EMAIL_PASS=your-app-password
```

**Generate secure values:**
```bash
# Generate SESSION_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Generate ADMIN_SETUP_TOKEN
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Prerequisites

Before deploying, ensure you have:
- Node.js 18+ installed
- PostgreSQL database (required for production)
- Email service credentials (for notifications)
- SSL certificate (automatically handled by most platforms)

## Environment Configuration

### Required Environment Variables

Only **DATABASE_URL** is strictly required. Other variables have sensible defaults:

```bash
# REQUIRED - Server won't start without this
DATABASE_URL=postgresql://user:password@host:5432/database

# RECOMMENDED - Will be auto-generated if missing
SESSION_SECRET=your-random-secret-minimum-32-characters

# OPTIONAL - Server will work without these
ADMIN_SETUP_TOKEN=your-secure-admin-setup-token-keep-this-secret
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
EMAIL_USER=your-email@example.com
EMAIL_PASS=your-email-app-password

# Server Configuration (optional)
NODE_ENV=production
PORT=3000

# Rate Limiting (optional - defaults provided)
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
AUTH_RATE_LIMIT_MAX=5

# Debug Mode (disable in production)
DEBUG_MODE=false
```

### Generating Secure Secrets

```bash
# Generate SESSION_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Generate ADMIN_SETUP_TOKEN
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

## Database Setup

### PostgreSQL (Required for Production)

1. **Create Database:**
   ```sql
   CREATE DATABASE raffleapp;
   CREATE USER raffleuser WITH ENCRYPTED PASSWORD 'your-secure-password';
   GRANT ALL PRIVILEGES ON DATABASE raffleapp TO raffleuser;
   ```

2. **Get Connection String:**
   ```
   postgresql://raffleuser:your-secure-password@localhost:5432/raffleapp
   ```

3. **Set Environment Variable:**
   ```bash
   export DATABASE_URL="postgresql://..."
   ```

### Database Migration

The app automatically runs migrations on startup:
- Creates all required tables
- Runs migration scripts from `migrations/` folder
- No manual migration required

## Deployment Platforms

### Render.com (Recommended)

1. **Create PostgreSQL Database:**
   - Go to Render Dashboard
   - Click "New +" → "PostgreSQL"
   - Note the **Internal Database URL** (starts with `postgresql://`)

2. **Create Web Service:**
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Configure:
     - **Name:** raffleapp
     - **Environment:** Node
     - **Build Command:** `cd raffle-app && npm install`
     - **Start Command:** `cd raffle-app && npm start`
     - **Instance Type:** Standard or higher (Starter not recommended for production)

3. **Add Environment Variables:**
   - Go to Environment tab
   - Add all required variables from `.env.example`
   - Use **Internal Database URL** for `DATABASE_URL`
   - **IMPORTANT:** Set `ADMIN_SETUP_TOKEN` to a secure random value

4. **Deploy:**
   - Click "Create Web Service"
   - Wait for deployment to complete
   - Check logs for any errors

### Heroku

1. **Create App:**
   ```bash
   heroku create your-raffle-app
   ```

2. **Add PostgreSQL:**
   ```bash
   heroku addons:create heroku-postgresql:standard-0
   ```

3. **Set Environment Variables:**
   ```bash
   heroku config:set SESSION_SECRET=your-secret
   heroku config:set ADMIN_SETUP_TOKEN=your-token
   heroku config:set NODE_ENV=production
   # ... add all other variables
   ```

4. **Deploy:**
   ```bash
   git push heroku main
   ```

### Docker

1. **Build Image:**
   ```bash
   docker build -t raffleapp .
   ```

2. **Run Container:**
   ```bash
   docker run -d \
     -p 3000:3000 \
     -e DATABASE_URL="postgresql://..." \
     -e SESSION_SECRET="your-secret" \
     -e ADMIN_SETUP_TOKEN="your-token" \
     --name raffleapp \
     raffleapp
   ```

### VPS (Ubuntu/Debian)

1. **Install Dependencies:**
   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Install Node.js
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt install -y nodejs
   
   # Install PostgreSQL
   sudo apt install -y postgresql postgresql-contrib
   
   # Install PM2 (process manager)
   sudo npm install -g pm2
   ```

2. **Setup PostgreSQL:**
   ```bash
   sudo -u postgres psql
   CREATE DATABASE raffleapp;
   CREATE USER raffleuser WITH ENCRYPTED PASSWORD 'your-password';
   GRANT ALL PRIVILEGES ON DATABASE raffleapp TO raffleuser;
   \q
   ```

3. **Deploy Application:**
   ```bash
   # Clone repository
   git clone https://github.com/your-username/raffleapp.git
   cd raffleapp/raffle-app
   
   # Install dependencies
   npm install
   
   # Create .env file
   nano .env
   # Paste your environment variables
   
   # Start with PM2
   pm2 start server.js --name raffleapp
   pm2 startup
   pm2 save
   ```

4. **Setup Nginx (Reverse Proxy):**
   ```bash
   sudo apt install -y nginx
   sudo nano /etc/nginx/sites-available/raffleapp
   ```
   
   Add configuration:
   ```nginx
   server {
       listen 80;
       server_name yourdomain.com;
       
       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```
   
   Enable site:
   ```bash
   sudo ln -s /etc/nginx/sites-available/raffleapp /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

5. **Setup SSL with Let's Encrypt:**
   ```bash
   sudo apt install -y certbot python3-certbot-nginx
   sudo certbot --nginx -d yourdomain.com
   ```

## Security Checklist

Before going live, verify:

- [ ] `SESSION_SECRET` is set to a strong random value (NOT default)
- [ ] `ADMIN_SETUP_TOKEN` is set and kept secret
- [ ] `DATABASE_URL` points to PostgreSQL (NOT SQLite)
- [ ] `NODE_ENV=production`
- [ ] `DEBUG_MODE=false` or not set
- [ ] HTTPS/SSL is enabled
- [ ] `ALLOWED_ORIGINS` is configured for your domain
- [ ] Email credentials are configured (or feature disabled)
- [ ] Database backups are configured
- [ ] All default passwords changed after first admin login
- [ ] Rate limiting is enabled (check logs)
- [ ] CORS is properly configured

## Post-Deployment

### 1. Initialize Admin Account

**SECURE THIS ENDPOINT!** Only run once during initial setup.

```bash
curl -X POST https://your-domain.com/api/setup-admin \
  -H "Content-Type: application/json" \
  -d '{"token": "your-ADMIN_SETUP_TOKEN-value"}'
```

This creates admin account:
- **Phone:** 1234567890
- **Password:** admin123

**CRITICAL:** Login immediately and change these credentials!

### 2. Health Check

Verify deployment:
```bash
curl https://your-domain.com/health
```

Should return:
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

### 3. Change Default Credentials

1. Login with default credentials (phone: 1234567890)
2. Go to admin dashboard
3. Change phone number and password immediately
4. Test login with new credentials

### 4. Monitor Logs

**Render:**
- Dashboard → Your Service → Logs

**Heroku:**
```bash
heroku logs --tail
```

**PM2:**
```bash
pm2 logs raffleapp
```

### 5. Database Backups

**Render:** Automatic daily backups included

**Manual Backup:**
```bash
pg_dump -h host -U user -d database > backup.sql
```

**Restore:**
```bash
psql -h host -U user -d database < backup.sql
```

## Troubleshooting

### Issue: "Data will be lost on restart"

**Cause:** No `DATABASE_URL` configured
**Fix:** Add PostgreSQL connection string to environment variables

### Issue: "Session expired" after every restart

**Cause:** Using in-memory session store (SQLite)
**Fix:** Configure PostgreSQL with `DATABASE_URL`

### Issue: Admin setup fails with 403

**Cause:** Missing or invalid `ADMIN_SETUP_TOKEN`
**Fix:** Ensure token in request matches environment variable

### Issue: CORS errors in browser

**Cause:** `ALLOWED_ORIGINS` not configured
**Fix:** Add your domain to `ALLOWED_ORIGINS` environment variable

### Issue: Rate limit errors

**Cause:** Too many requests from same IP
**Fix:** Clear login attempts or adjust rate limits in environment variables

## Maintenance

### Update Application

```bash
# Pull latest code
git pull origin main

# Install dependencies
npm install

# Restart application
pm2 restart raffleapp  # PM2
# or
heroku restart  # Heroku
# or just redeploy on Render
```

### Monitor Performance

```bash
# PM2
pm2 monit

# Check memory/CPU
pm2 status
```

### View Logs

```bash
# PM2
pm2 logs raffleapp --lines 100

# Heroku
heroku logs --tail

# Render
Check dashboard logs
```

## Support

For issues or questions:
- Check server logs first
- Visit `/health` endpoint for diagnostics
- Visit `/api/database-status` for database diagnostics
- Review environment variables
- Check database connectivity

## Additional Resources

- [Database Migration Guide](MIGRATION.md)
- [Database Documentation](DATABASE.md)
- [Ticket Printing Guide](TICKET_PRINTING.md)
- [Migration Checklist](MIGRATION_CHECKLIST.md)
