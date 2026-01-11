# PostgreSQL Migration Checklist

Copy this checklist and check off each step:

## Pre-Migration
- [ ] I understand SQLite data will be lost (ephemeral storage)
- [ ] I have exported any important data (tickets, sellers)

## Render Setup
- [ ] Created PostgreSQL database on Render
- [ ] Copied INTERNAL Database URL
- [ ] Added DATABASE_URL environment variable to web service
- [ ] Clicked "Save Changes" (triggers automatic redeploy)

## Verification
- [ ] Checked logs show: "🐘 Using PostgreSQL database"
- [ ] Checked logs show: "✅ PostgreSQL connected successfully"
- [ ] Tested health endpoint: `GET /api/health` shows `"type": "PostgreSQL"`
- [ ] Admin login works (1234567890 / admin123)
- [ ] Can create test seller

## Post-Migration
- [ ] Re-registered all sellers
- [ ] Imported tickets (if applicable)
- [ ] Verified data persists after manual service restart
- [ ] Configured email notifications (optional)

## Troubleshooting Used
- [ ] No issues encountered ✅
- [ ] Fixed connection errors (used Internal URL)
- [ ] Reset admin account via /setup-admin.html
- [ ] Checked database region matches service region

---

**Migration Date:** _____________

**Status:** ✅ Complete | ⚠️ In Progress | ❌ Issues

**Notes:**
