# Database Setup Guide

## Development (SQLite)

SQLite is used automatically when `DATABASE_URL` is not set.

```bash
cd raffle-app
npm install
npm start
```

Data is stored in the `raffle.db` file in the raffle-app directory.

**Advantages:**
- ✅ No setup required
- ✅ Perfect for local development
- ✅ Fast and simple

**Limitations:**
- ⚠️ Not suitable for production on Render (ephemeral storage)
- ⚠️ Single-user concurrent access

## Production (PostgreSQL on Render)

### Step 1: Create PostgreSQL Database

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click **"New"** → **"PostgreSQL"**
3. Configure the database:
   - **Name:** `raffleapp-db`
   - **Database:** `raffleapp_db` (auto-generated)
   - **User:** `raffleapp_db_user` (auto-generated)
   - **Region:** Choose same region as your web service
   - **Plan:** **Free** (0.1 GB storage, 90 days)
4. Click **"Create Database"**
5. Wait 1-2 minutes for provisioning

### Step 2: Get Connection String

1. Open your newly created PostgreSQL database
2. Scroll down to **"Connections"** section
3. Copy the **"Internal Database URL"**
   - It looks like: `postgresql://raffleapp_db_user:xxxxx@dpg-xxxxx.oregon-postgres.render.com/raffleapp_db`
   - ⚠️ Use the **Internal URL** (not External) for better performance and security

### Step 3: Add to Your Web Service

1. Go to your **Raffle App** web service in Render
2. Navigate to **"Environment"** tab
3. Click **"Add Environment Variable"**
4. Add the following:
   - **Key:** `DATABASE_URL`
   - **Value:** [Paste the Internal Database URL from Step 2]
5. Click **"Save Changes"**

### Step 4: Deploy and Verify

1. Render will automatically redeploy your service
2. Click **"Manual Deploy"** → **"Deploy latest commit"** (if not auto-deploying)
3. Wait ~2 minutes for deployment
4. Check the logs for:
   ```
   🐘 Using PostgreSQL database
   ✅ PostgreSQL connected successfully
   🔧 Initializing database schema...
   ✅ Database schema initialized
   ✅ Default admin account created - Phone: 1234567890, Password: admin123
   ```

### Step 5: Test Data Persistence

1. Login to your app at `https://your-app.onrender.com`
2. Create a test ticket or add a seller
3. Go back to Render Dashboard → Click **"Manual Deploy"** → **"Deploy latest commit"**
4. After redeploy, login again
5. ✅ **Success!** Your data should still be there!

## Database Schema

### Tables

#### `users`
Stores admin and seller accounts.
```sql
- id: Serial/Integer (Primary Key)
- name: Text (Required)
- phone: Text (Unique, Required)
- password: Text (Hashed, Required)
- role: Text (Required: 'admin' or 'seller')
- created_at: Timestamp
- email: Text
- registered_via: Text (Default: 'manual')
- approved_by: Text
- approved_date: Timestamp
```

#### `tickets`
Stores raffle ticket sales.
```sql
- id: Serial/Integer (Primary Key)
- ticket_number: Text (Unique, Required)
- buyer_name: Text (Required)
- buyer_phone: Text (Required)
- seller_name: Text (Required)
- seller_phone: Text (Required)
- amount: Numeric/Real (Required)
- status: Text (Default: 'active')
- barcode: Text
- category: Text
- created_at: Timestamp
```

#### `draws`
Stores raffle draw results.
```sql
- id: Serial/Integer (Primary Key)
- draw_number: Integer (Required)
- ticket_number: Integer (Required)
- prize_name: Text (Required)
- winner_name: Text (Required)
- winner_phone: Text (Required)
- drawn_at: Timestamp
```

#### `seller_requests`
Stores pending seller registration requests.
```sql
- id: Serial/Integer (Primary Key)
- full_name: Text (Required)
- phone: Text (Unique, Required)
- email: Text (Required)
- experience: Text
- status: Text (Default: 'pending')
- request_date: Timestamp
- reviewed_by: Text
- reviewed_date: Timestamp
- approval_notes: Text
```

## Switching Between Databases

### Development → Production

No code changes needed! The app automatically detects:
- **SQLite** when `DATABASE_URL` is not set
- **PostgreSQL** when `DATABASE_URL` is set

### Production → Development

To test locally with your production data (optional):
1. Get a database dump from Render
2. Import into local PostgreSQL
3. Set `DATABASE_URL` in your local `.env` file

## Troubleshooting

### ❌ "PostgreSQL connection error"

**Possible Causes:**
- Incorrect `DATABASE_URL`
- Database not fully provisioned yet
- Network/firewall issues

**Solutions:**
1. Verify `DATABASE_URL` is correct (check Render dashboard)
2. Wait 2-3 minutes after creating database
3. Ensure you're using the **Internal URL**, not External
4. Check database status in Render (should be "Available")

### ❌ "Database initialization error"

**Possible Causes:**
- PostgreSQL syntax incompatibility
- Permissions issue
- Connection timeout

**Solutions:**
1. Check logs for specific error message
2. Verify database user has CREATE TABLE permissions
3. Try redeploying the application

### ❌ Data not persisting / Still losing data

**Checklist:**
- [ ] Is `DATABASE_URL` environment variable set in Render?
- [ ] Did you redeploy after adding `DATABASE_URL`?
- [ ] Do logs show "🐘 Using PostgreSQL database"?
- [ ] Do logs show "✅ PostgreSQL connected successfully"?

**Common Mistake:**
Still using SQLite in production. Check logs:
- ❌ If you see "📁 Using SQLite database" → `DATABASE_URL` not set correctly
- ✅ Should see "🐘 Using PostgreSQL database"

### ⚠️ "relation already exists" error

This happens if you run migrations manually. Safe to ignore - the app handles this automatically.

## Data Migration

### Migrating Existing SQLite Data to PostgreSQL

If you have important data in SQLite that needs to be migrated:

#### Option 1: Manual Export/Import

1. **Export from SQLite:**
   ```bash
   sqlite3 raffle.db .dump > data.sql
   ```

2. **Clean up for PostgreSQL:**
   - Replace `INTEGER PRIMARY KEY AUTOINCREMENT` with `SERIAL PRIMARY KEY`
   - Replace `DATETIME` with `TIMESTAMP`
   - Replace `REAL` with `NUMERIC`

3. **Import to PostgreSQL:**
   ```bash
   psql $DATABASE_URL -f data.sql
   ```

#### Option 2: Application-Level Migration (Recommended for small datasets)

1. Export data to CSV/JSON from SQLite
2. Create import script
3. Import into PostgreSQL through the application API

**Note:** Most deployments won't have critical data yet, so starting fresh is acceptable.

## Performance Considerations

### SQLite (Development)
- ⚡ Very fast for local development
- 📦 Single file storage
- 🔒 Limited concurrent writes

### PostgreSQL (Production)
- 🚀 Better concurrent access
- 💪 More robust for production
- 🔄 Better for multiple connections
- 📊 Advanced query features
- 💾 Automatic backups (on paid plans)

## Backup and Restore

### SQLite Backup
```bash
# Backup
cp raffle.db raffle.db.backup

# Restore
cp raffle.db.backup raffle.db
```

### PostgreSQL Backup on Render

**Free Plan:**
- No automatic backups
- Manual backup using pg_dump

**Paid Plans ($7+/month):**
- Automatic daily backups
- Point-in-time recovery
- 7-day retention (Starter) or more

**Manual Backup:**
```bash
pg_dump $DATABASE_URL > backup.sql
```

**Restore:**
```bash
psql $DATABASE_URL < backup.sql
```

## Cost

### Development (SQLite)
- **FREE** ✅
- No additional cost

### Production (PostgreSQL on Render)
- **FREE Plan**: 0.1 GB storage, expires after 90 days
- **Starter Plan**: $7/month, 256 MB storage, backups, no expiration
- **Standard Plan**: $20/month, 2 GB storage, more features

For a raffle app with moderate usage, the **FREE plan** should be sufficient initially. Upgrade when:
- You exceed 0.1 GB storage (~100,000+ tickets)
- You need automatic backups
- You want permanent storage (>90 days)

## Support

For issues:
1. Check the logs in Render Dashboard
2. Verify environment variables
3. Review this troubleshooting guide
4. Open an issue in the repository

## Security Best Practices

✅ **Do:**
- Use the Internal Database URL for web service connections
- Keep DATABASE_URL secret (never commit to git)
- Use SSL in production (handled automatically by Render)
- Regularly update PostgreSQL minor versions

❌ **Don't:**
- Expose DATABASE_URL publicly
- Use the External URL from your web service (slower, less secure)
- Share database credentials
- Store sensitive data unencrypted

---

**🎉 Congratulations!** Your raffle app now has persistent data storage that survives deploys!
