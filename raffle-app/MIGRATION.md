# 🔄 PostgreSQL Migration Guide

## Quick Start (5 Minutes)

Your app already supports PostgreSQL! Just follow these 3 steps:

### Step 1: Create PostgreSQL Database on Render

1. Go to https://dashboard.render.com
2. Click **"New +"** → **"PostgreSQL"**
3. Configure:
   ```
   Name: raffleapp-db
   Database: raffleapp
   User: raffleapp_user
   Region: [Same as your web service]
   Plan: Free
   ```
4. Click **"Create Database"**
5. Wait 1-2 minutes for provisioning
6. **Copy the "Internal Database URL"** (looks like):
   ```
   postgresql://raffleapp_user:PASSWORD@dpg-xxxxx/raffleapp
   ```

### Step 2: Add DATABASE_URL to Web Service

1. Go to your web service in Render dashboard
2. Click **"Environment"** tab
3. Click **"Add Environment Variable"**
4. Add:
   ```
   Key: DATABASE_URL
   Value: [paste Internal Database URL from Step 1]
   ```
5. Click **"Save Changes"**
6. Service will automatically redeploy

### Step 3: Verify Migration

Check your deployment logs for:

```
✅ SUCCESS MESSAGES:
🐘 Using PostgreSQL database
✅ PostgreSQL connected successfully
🔧 Initializing database schema...
✅ Database schema initialized successfully
👤 Default admin account created
```

❌ If you see errors, check:
- DATABASE_URL is correct
- Used INTERNAL URL (not External)
- Database and service in same region

## Login After Migration

Default admin credentials:
```
URL: https://your-app.onrender.com/login.html
Phone: 1234567890
Password: admin123
```

## Recreate Your Data

Since SQLite data is ephemeral, you'll need to:

1. **Admin Account:** ✅ Already created automatically
2. **Sellers:** Re-register at `/register-seller.html`
3. **Tickets:** Use bulk import feature in admin dashboard

## Verify Data Persistence

Test that data now persists:

1. Login as admin
2. Create a test seller
3. Go to Render → Manual Deploy → "Deploy latest commit"
4. Wait for restart
5. Login again
6. ✅ Verify seller still exists

## Troubleshooting

### "Still using SQLite"

**Logs show:**
```
📁 Using SQLite database (development)
```

**Fix:**
1. Verify DATABASE_URL exists in Environment tab
2. Check URL format is correct
3. Redeploy manually

### "PostgreSQL connection error"

**Logs show:**
```
❌ PostgreSQL connection FAILED
```

**Fix:**
1. Use **Internal** Database URL (not External)
2. Check database status in Render dashboard
3. Verify same region as web service

### "Admin account not found"

**Error when logging in:**
```
Invalid credentials
```

**Fix:**
1. Go to: `https://your-app.onrender.com/setup-admin.html`
2. Reset admin account
3. Use new credentials

## Benefits After Migration

| Feature | SQLite | PostgreSQL |
|---------|--------|------------|
| Data Persistence | ❌ Lost on restart | ✅ Permanent |
| Production Ready | ❌ No | ✅ Yes |
| Automatic Backups | ❌ No | ✅ 90 days |
| Multi-user Support | ⚠️ Limited | ✅ Full |

## Need Help?

Check the logs for detailed error messages and troubleshooting steps.

---

**Migration complete?** ✅ Your app is now production-ready! 🚀
