# Render Deployment Guide for Raffle App

## Overview
This guide provides step-by-step instructions for deploying the Raffle App on Render.com.

## Prerequisites
- GitHub account with access to the raffleapp repository
- Render.com account (free tier is sufficient for testing)

## Quick Start (Emergency Deployment)

The app is configured to start even without a database connection, allowing you to verify the deployment first, then add services incrementally.

### Step 1: Deploy Web Service

1. **Fork/Clone Repository** (if not already done)
   - Ensure you have access to `dukens11-create/raffleapp`

2. **Connect to Render**
   - Go to [Render Dashboard](https://dashboard.render.com/)
   - Click "New +" → "Web Service"
   - Connect your GitHub account
   - Select `dukens11-create/raffleapp` repository

3. **Configure Web Service**
   ```
   Name:              raffle-app
   Region:            Oregon (or closest to your users)
   Branch:            main
   Root Directory:    raffle-app
   Runtime:           Node
   Build Command:     npm install
   Start Command:     node server.js
   Plan:              Free
   ```

4. **Environment Variables (Minimal Start)**
   
   Add only these initially:
   ```
   NODE_ENV=production
   ```
   
   The server will auto-generate other required variables and start successfully.

5. **Deploy**
   - Click "Create Web Service"
   - Wait for deployment (3-5 minutes)
   - Check logs for: "🚀 SERVER STARTED SUCCESSFULLY"

6. **Verify Deployment**
   - Visit: `https://your-app.onrender.com/health`
   - Should return: `{"status":"degraded",...}` (degraded because no database yet)
   - This confirms the server is running!

### Step 2: Add PostgreSQL Database (Recommended)

1. **Create PostgreSQL Database**
   - In Render Dashboard: "New +" → "PostgreSQL"
   - Name: `raffle-db`
   - Database: `raffle`
   - User: `raffle`
   - Region: Same as web service (Oregon)
   - Plan: Free

2. **Get Internal Connection URL**
   - Go to database → "Info"
   - Copy "Internal Database URL" (starts with `postgresql://`)
   - Important: Use INTERNAL URL (not External) for same-region services

3. **Add DATABASE_URL to Web Service**
   - Go to web service → "Environment"
   - Add variable:
     ```
     DATABASE_URL=<paste-internal-url-here>
     ```
   - Click "Save Changes"
   - Service will auto-redeploy

4. **Verify Database Connection**
   - Check logs: "✅ PostgreSQL connected successfully"
   - Visit: `/health` - should show `"status":"ok"`

### Step 3: Add Required Environment Variables

Add these one by one in "Environment" section:

#### Session Security (Required for Production)
```bash
# Generate a secure random string (run locally):
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Add to Render:
SESSION_SECRET=<paste-generated-value>
```

#### Application URL
```
APP_URL=https://your-app.onrender.com
# Or custom domain:
APP_URL=https://www.enejipamticket.com
```

#### Email Configuration (Optional but Recommended)
```
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
```

For Gmail:
1. Enable 2-factor authentication
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use app password (not your regular password)

#### Payment Integration (Optional)
```
# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...

# MonCash
MONCASH_CLIENT_ID=your-client-id
MONCASH_CLIENT_SECRET=your-client-secret
```

#### SMS Notifications (Optional)
```
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=your-twilio-number
```

#### CORS Configuration (if using separate frontend)
```
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://www.enejipamticket.com
```

## Custom Domain Setup

### Step 1: Add Domain in Render
1. Go to web service → "Settings"
2. Scroll to "Custom Domain"
3. Click "Add Custom Domain"
4. Enter: `www.enejipamticket.com`

### Step 2: Configure DNS
Add these records in your domain registrar (e.g., GoDaddy, Namecheap):

```
Type    Name    Value                           TTL
CNAME   www     your-app.onrender.com           3600
```

For root domain (`enejipamticket.com`):
```
Type    Name    Value                           TTL
A       @       <IP from Render instructions>   3600
```

Or use CNAME flattening if your DNS provider supports it.

### Step 3: Wait for SSL Certificate
- Render automatically provisions SSL/TLS certificates
- This takes 1-5 minutes after DNS propagates
- Visit `https://www.enejipamticket.com/health` to verify

## Troubleshooting

### Server Not Starting / ERR_FAILED

**Symptoms**: 
- Website shows ERR_FAILED
- No logs in Render dashboard
- Health checks failing

**Solution**:
1. Check "Logs" tab in Render dashboard
2. Look for startup errors
3. Verify environment variables are set correctly
4. Check if build command succeeded

**Common Causes**:
- Wrong root directory (should be `raffle-app`)
- Missing `NODE_ENV` variable
- Build failures (check npm install logs)

### Database Connection Errors

**Symptoms**:
- "PostgreSQL connection FAILED" in logs
- Health check shows `"database": {"connected": false}`

**Solutions**:
1. Verify DATABASE_URL is set (Environment tab)
2. Use INTERNAL database URL (not External)
3. Ensure database and web service in same region
4. Check database is running (Database dashboard → Status)

**Verify Connection**:
```bash
# In Render Shell (web service → "Shell" tab):
echo $DATABASE_URL
# Should output: postgresql://...
```

### Port Already in Use (Local Testing)

**Symptoms**:
- "EADDRINUSE" error locally

**Solution**:
```bash
# Find process on port 10000:
lsof -ti:10000 | xargs kill -9

# Or use different port:
PORT=3001 npm start
```

### Memory Issues

**Symptoms**:
- App crashes with "out of memory" errors
- R10 errors in logs

**Solutions**:
1. Upgrade to paid plan (more memory)
2. Check for memory leaks in code
3. Add memory limits in start command:
   ```
   node --max-old-space-size=512 server.js
   ```

### Session Issues

**Symptoms**:
- Users logged out after restart
- Session data lost

**Solutions**:
1. Ensure DATABASE_URL is set (sessions stored in database)
2. Set SESSION_SECRET to persistent value
3. Check session configuration in logs

### SSL/HTTPS Issues

**Symptoms**:
- Mixed content warnings
- Redirect loops
- "Not secure" warnings

**Solutions**:
1. Ensure `app.set('trust proxy', 1)` is in server.js ✅
2. Use `https://` in APP_URL
3. Wait for SSL certificate provisioning (5 minutes)
4. Clear browser cache and cookies

### No Logs Showing

**Solutions**:
1. Check if build succeeded (Build tab)
2. Verify server actually started
3. Look at "Events" tab for deployment status
4. Try manual deploy: "Manual Deploy" → "Deploy latest commit"

## Monitoring and Maintenance

### Health Checks
- Primary: `https://your-app.onrender.com/health`
- API: `https://your-app.onrender.com/api/health`
- Database: `https://your-app.onrender.com/api/database-status`

### View Logs
```bash
# In Render Dashboard:
Web Service → Logs (live tail)

# Download logs:
Web Service → Logs → "Download"
```

### Database Backups
1. Database → "Backups" tab
2. Enable daily backups (free on paid plans)
3. Manual backup: "Create Backup" button

### Auto-Deploy
- Enabled by default in `render.yaml`
- Every push to `main` triggers deployment
- Disable: Settings → "Auto-Deploy" → OFF

## Performance Optimization

### Free Tier Considerations
- Free services "spin down" after 15 minutes of inactivity
- First request after spin-down takes 30-60 seconds
- Subsequent requests are fast

### Stay Active Script (Optional)
```bash
# Ping every 10 minutes to keep service active:
# Add to external cron service (cron-job.org)
curl https://your-app.onrender.com/health
```

### Upgrade to Paid Plan
Benefits:
- No spin-down (always active)
- More memory and CPU
- Better performance
- Faster deploys
- Email support

Cost: $7/month (Starter plan)

## Security Checklist

- [ ] Set strong SESSION_SECRET (32+ characters)
- [ ] Use INTERNAL database URL (not External)
- [ ] Enable SSL/HTTPS (automatic with custom domain)
- [ ] Set ALLOWED_ORIGINS for CORS
- [ ] Use environment variables for all secrets
- [ ] Enable database backups
- [ ] Set NODE_ENV=production
- [ ] Review logs regularly
- [ ] Keep dependencies updated

## Emergency Rollback

If deployment fails:

1. **Rollback in Render**:
   - Web Service → "Manual Deploy"
   - Select previous successful deploy
   - Click "Deploy"

2. **Via Git**:
   ```bash
   git revert HEAD
   git push origin main
   # Render auto-deploys the revert
   ```

## Support and Resources

### Render Documentation
- https://render.com/docs
- https://render.com/docs/deploy-node-express-app
- https://render.com/docs/databases

### Application Support
- GitHub Issues: https://github.com/dukens11-create/raffleapp/issues
- Health Check: `/health` endpoint
- Database Status: `/api/database-status` endpoint

### Common Commands

```bash
# Local testing
npm install
npm start

# Environment variables (local)
cp .env.example .env
# Edit .env with your values

# Check deployment
npm run check-deployment

# Generate secrets
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Success Checklist

After deployment, verify:
- [ ] Service is "Live" in Render dashboard
- [ ] Logs show "🚀 SERVER STARTED SUCCESSFULLY"
- [ ] `/health` returns `{"status":"ok"}`
- [ ] Database connected (if configured)
- [ ] Custom domain works (if configured)
- [ ] SSL certificate active (https://)
- [ ] Admin panel accessible
- [ ] Environment variables set correctly
- [ ] Auto-deploy enabled
- [ ] Backups configured (if using paid plan)

## Next Steps

1. **Setup Admin Account**:
   - Visit: `/admin` (first-time setup)
   - Create admin credentials

2. **Configure Raffle Settings**:
   - Admin panel → Settings
   - Set raffle details, prizes, dates

3. **Add Sellers**:
   - Admin panel → Sellers
   - Add seller accounts

4. **Test Full Flow**:
   - Purchase ticket
   - Verify email notifications
   - Check payment processing
   - Test admin reports

5. **Monitor Performance**:
   - Check logs daily
   - Review `/health` endpoint
   - Monitor database size
   - Track memory usage

---

**Last Updated**: 2026-02-15

**Questions?** Create an issue on GitHub or check the `/health` endpoint for system status.
