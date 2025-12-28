# 🔧 Connect PostgreSQL to Fix Data Loss

## 🚨 Problem

Your app is currently using SQLite, which means:
- ❌ ALL seller data is LOST every time Render restarts
- ❌ ALL tickets are LOST
- ❌ ALL registration requests are LOST

Render restarts happen automatically for various reasons (deployments, maintenance, scaling).

---

## ✅ Solution: Connect PostgreSQL

Follow these steps to permanently fix data loss:

---

### Step 1: Find Your PostgreSQL Connection String

1. **Go to Render Dashboard:**  
   https://dashboard.render.com

2. **Click on your PostgreSQL database** (NOT the web service)

3. **Scroll down to "Connections"**

4. **Copy the INTERNAL connection string**  
   It looks like:
   ```
   postgresql://raffleapp_user:PASSWORD123@dpg-xxxxxx-a/raffleapp
   ```
   
   ⚠️ **IMPORTANT:** Use **INTERNAL** URL, not External!

---

### Step 2: Add DATABASE_URL to Web Service

1. **Go back to Render Dashboard**

2. **Click on your WEB SERVICE** (raffleapp)

3. **Click "Environment" tab** (left sidebar)

4. **Click "Add Environment Variable"** button

5. **Add the variable:**
   ```
   Key:   DATABASE_URL
   Value: [paste the internal connection string from Step 1]
   ```

6. **Click "Save Changes"**

7. **Wait for automatic redeploy** (2-3 minutes)

---

### Step 3: Verify It's Working

1. **Open in browser:**  
   ```
   https://raffleapp-e4ev.onrender.com/api/database-status
   ```

2. **Check the response:**
   ```json
   {
     "database": {
       "configured": {
         "usingPostgres": true  ← Should be true
       },
       "persistence": {
         "dataWillSurviveRestart": true  ← Should be true
       }
     }
   }
   ```

3. **✅ If both are `true`** → Success! Data is now persistent!

4. **❌ If still `false`** → See troubleshooting below

---

## 🧪 Test Data Persistence

1. **Login as admin**
2. **Create a test seller**
3. **Go to Render → Manual Deploy → "Clear build cache & deploy"**
4. **Wait for restart**
5. **Login again**
6. **✅ Verify the seller still exists**

If the seller is still there, data persistence is working! 🎉

---

## 🆘 Troubleshooting

### "Still shows SQLite"

**Possible causes:**
- Used External URL instead of Internal URL
- DATABASE_URL has typo or extra spaces
- Service didn't redeploy after adding variable

**Fix:**
1. Double-check you copied INTERNAL URL
2. Remove DATABASE_URL and re-add it
3. Manually trigger redeploy: Render → Manual Deploy

---

### "PostgreSQL connection failed"

**Possible causes:**
- Database and web service in different regions
- Database not fully provisioned
- Wrong credentials

**Fix:**
1. Check both database and service are in same region
2. Wait 2-3 minutes after database creation
3. Try copying connection string again

---

### "actionRequired still shows issues"

**After connecting PostgreSQL, you'll still see:**
```json
{
  "priority": "HIGH",
  "issue": "Sessions not persistent"
}
```

**This is normal!** This refers to PR #69 which fixes session storage.

**Two separate issues:**
1. ✅ Database persistence (fixed by connecting PostgreSQL)
2. ⏳ Session persistence (fixed by PR #69)

---

## 📊 Before vs After

| Feature | Before (SQLite) | After (PostgreSQL) |
|---------|----------------|-------------------|
| Seller data | ❌ Lost on restart | ✅ Permanent |
| Ticket data | ❌ Lost on restart | ✅ Permanent |
| Registration requests | ❌ Lost on restart | ✅ Permanent |
| Login sessions | ❌ Lost on restart | ⏳ Will be fixed by PR #69 |

---

## 🎯 Summary

**To fix data loss:**
1. Copy INTERNAL PostgreSQL URL from database
2. Add DATABASE_URL to web service environment variables
3. Save and wait for redeploy
4. Verify at `/api/database-status`

**Need help?** Check `/api/database-status` for detailed diagnostic info!
