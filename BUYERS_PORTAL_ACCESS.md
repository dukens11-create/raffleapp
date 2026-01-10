# Buyers Portal Access Guide

## Overview
The Buyers Portal is a **public-facing** page that allows visitors to:
- View current raffle information and ticket categories
- Browse available tickets
- Purchase raffle tickets (with payment integration)
- Look up their purchased tickets
- Verify ticket authenticity

## Access Points

The buyers portal can be accessed through multiple URLs:

### Primary Routes
1. **`/buyers`** - Main buyers portal route
2. **`/buyers.html`** - Alternative route with .html extension

Both routes serve the same content and require **NO AUTHENTICATION**.

### Example URLs
- Local development: `http://localhost:10000/buyers`
- Production: `https://yourdomain.com/buyers`
- Direct HTML: `https://yourdomain.com/buyers.html`

## Technical Details

### Server Configuration

The buyers portal routes are configured in `server.js`:

```javascript
// Buyers Dashboard - Public page (no authentication required)
app.get('/buyers', publicPageLimiter, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'buyers.html'));
});

// Buyers Dashboard - Alternative route with .html extension
app.get('/buyers.html', publicPageLimiter, (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'buyers.html'));
});
```

### Security Features

1. **Public Access**: No authentication middleware applied
2. **Rate Limiting**: Applies `publicPageLimiter` to prevent abuse
   - 200 requests per 15 minutes (generous limit)
   - Prevents DOS attacks while allowing normal usage
3. **Static File Serving**: Properly configured via `express.static`

### API Endpoints Used

The buyers portal makes calls to these public API endpoints:

1. **`GET /api/public/raffle-info`**
   - Returns current raffle details, categories, and statistics
   - No authentication required

2. **`GET /api/departments`**
   - Returns list of Haiti departments for buyer location
   - No authentication required

3. **`GET /api/payments/methods`**
   - Returns available payment methods
   - No authentication required

4. **`GET /api/public/available-tickets`**
   - Returns paginated list of available tickets
   - Optional category filter
   - No authentication required

5. **`POST /api/public/my-tickets`**
   - Lookup tickets by email, phone, or buyer code
   - No authentication required

6. **`GET /api/public/verify-ticket/:ticketNumber`**
   - Verify ticket status by ticket number or barcode
   - No authentication required

### PWA Support

The buyers portal includes Progressive Web App features:

- **Manifest**: `/manifest.json`
- **Service Worker**: `/service-worker.js`
- **Icons**: `/icons/icon-*.png` (various sizes)
- **Offline Support**: Can be installed as a standalone app

## Testing

### Manual Testing

1. **Start the server:**
   ```bash
   cd raffle-app
   npm install
   npm start
   ```

2. **Access the portal:**
   ```bash
   # Test /buyers route
   curl http://localhost:10000/buyers
   
   # Test /buyers.html route
   curl http://localhost:10000/buyers.html
   
   # Test API endpoints
   curl http://localhost:10000/api/public/raffle-info
   curl http://localhost:10000/api/departments
   ```

3. **Verify response codes:**
   ```bash
   # All should return 200
   curl -I http://localhost:10000/buyers
   curl -I http://localhost:10000/buyers.html
   curl -I http://localhost:10000/manifest.json
   ```

### Automated Testing

```bash
#!/bin/bash
# Test buyers portal accessibility

echo "Testing buyers portal routes..."

# Test /buyers
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:10000/buyers)
if [ "$STATUS" = "200" ]; then
  echo "✅ /buyers route: OK"
else
  echo "❌ /buyers route: FAILED (HTTP $STATUS)"
fi

# Test /buyers.html
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:10000/buyers.html)
if [ "$STATUS" = "200" ]; then
  echo "✅ /buyers.html route: OK"
else
  echo "❌ /buyers.html route: FAILED (HTTP $STATUS)"
fi

# Test manifest.json
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:10000/manifest.json)
if [ "$STATUS" = "200" ]; then
  echo "✅ /manifest.json: OK"
else
  echo "❌ /manifest.json: FAILED (HTTP $STATUS)"
fi

# Test raffle info API
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:10000/api/public/raffle-info)
if [ "$STATUS" = "200" ]; then
  echo "✅ Raffle info API: OK"
else
  echo "❌ Raffle info API: FAILED (HTTP $STATUS)"
fi

echo ""
echo "All tests completed!"
```

## Troubleshooting

### Issue: 404 Not Found

**Symptoms**: Accessing `/buyers` or `/buyers.html` returns 404

**Solutions**:
1. Verify the server is running: `ps aux | grep node`
2. Check server logs for errors
3. Ensure `buyers.html` exists in `public/` directory
4. Verify static file middleware is configured before 404 handler

### Issue: 500 Internal Server Error

**Symptoms**: Server returns 500 error

**Solutions**:
1. Check server logs for specific error
2. Verify database is properly initialized
3. Ensure all dependencies are installed: `npm install`
4. Check environment variables are set correctly

### Issue: Blank Page or Resources Not Loading

**Symptoms**: Page loads but appears blank or broken

**Solutions**:
1. Check browser console for JavaScript errors
2. Verify all API endpoints are accessible
3. Check network tab for failed resource requests
4. Ensure CORS is properly configured for your domain

### Issue: Rate Limit Exceeded

**Symptoms**: Error message about too many requests

**Solutions**:
1. Wait 15 minutes for rate limit to reset
2. Adjust `publicPageLimiter` settings in server.js if needed:
   ```javascript
   const publicPageLimiter = rateLimit({
     windowMs: 15 * 60 * 1000,
     max: 200, // Increase this value
     // ...
   });
   ```

## Production Deployment

### Environment Variables

Ensure these are set for production:

```env
NODE_ENV=production
PORT=10000
DATABASE_URL=postgresql://user:pass@host:5432/db
SESSION_SECRET=<strong-random-secret>
APP_URL=https://yourdomain.com
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

### Verification Checklist

Before going live:

- [ ] Server starts without errors
- [ ] `/buyers` route returns 200 OK
- [ ] `/buyers.html` route returns 200 OK
- [ ] All API endpoints return expected data
- [ ] Manifest.json and icons are accessible
- [ ] No authentication required for buyers portal
- [ ] Rate limiting is properly configured
- [ ] CORS allows your domain
- [ ] HTTPS is enabled (recommended)
- [ ] Database is properly configured
- [ ] Payment methods are configured (if using payments)

## Security Considerations

1. **Rate Limiting**: Protects against abuse while allowing legitimate traffic
2. **Input Validation**: All user inputs are validated and sanitized
3. **No Authentication**: Public access is intentional - buyers don't need accounts
4. **HTTPS**: Always use HTTPS in production
5. **CSP Headers**: Content Security Policy headers protect against XSS
6. **CORS**: Configure ALLOWED_ORIGINS to restrict API access

## Features

### Current Features
- ✅ View raffle information
- ✅ Browse available tickets by category
- ✅ Lookup purchased tickets
- ✅ Verify ticket authenticity
- ✅ Multiple payment methods support
- ✅ Department selection (Haiti)
- ✅ PWA support (installable app)
- ✅ Responsive design (mobile-friendly)

### Payment Integration
The portal supports:
- MonCash (automated and manual)
- NatCash (automated and manual)
- Manual payment submission with admin approval

## Support

For issues or questions:
1. Check this documentation
2. Review server logs
3. Verify all endpoints return 200 OK
4. Check browser console for client-side errors
5. Review the problem statement and success criteria

## Related Files

- `raffle-app/server.js` - Server routing and API endpoints
- `raffle-app/public/buyers.html` - Buyers portal HTML/CSS/JS
- `raffle-app/public/manifest.json` - PWA manifest
- `raffle-app/public/service-worker.js` - PWA service worker
- `raffle-app/.env.example` - Environment configuration example
