# Logo Instructions for Grate Genyen Raffle App

## Current Logo Status

The raffle application currently uses a placeholder logo at `raffle-app/public/logo.png`. This placeholder displays a colorful raffle-themed design with "RaffleApp" text that matches the application's color scheme.

## Logo File Location

**Primary Logo File:** `raffle-app/public/logo.png`

This logo file is referenced throughout the application in the following files:
- `raffle-app/public/service-worker.js` - Cached for offline use
- `raffle-app/public/seller.html` - Header logo
- `raffle-app/public/admin.html` - Header logo and favicon
- `raffle-app/public/bulk-print.html` - Header logo and favicon
- `raffle-app/public/manage-templates.html` - Header logo and favicon
- `raffle-app/public/register-seller.html` - Registration page logo
- `raffle-app/public/upload-template.html` - Header logo and favicon
- `raffle-app/public/print-custom-tickets.html` - Header logo and favicon
- `raffle-app/public/raffle-print.html` - Header logo and favicon
- `raffle-app/public/raffle-dashboard.html` - Header logo and favicon
- `raffle-app/public/generate-tickets.html` - Header logo and favicon
- `raffle-app/public/buyers.html` - Header logo and favicon
- `raffle-app/public/login.html` - Login page logo
- `raffle-app/public/payments-admin.html` - Header logo and favicon
- `raffle-app/public/print-tickets.html` - Header logo and favicon

## Actual "Grate Genyen" Logo Description

The actual logo that should be uploaded by the repository owner features:

### Visual Elements
- **Text:** "Grate Genyen" 
  - "Grate" in dark blue (#003366 or similar)
  - "Genyen" in orange (#FF8C42 or similar)
- **Graphic Elements:**
  - Colorful overlapping cards/tickets in vibrant colors:
    - Pink/Coral (#FF6B8A)
    - Blue (#4A90E2)
    - Yellow/Gold (#FFD700)
    - Green (#5CB85C)
    - Red/Tomato (#FF6347)
    - Orange (#FF8C42)
  - Central white star on the yellow card
  - Orange swoosh arrow element at the bottom
  - Decorative confetti-like elements (small circles and diamonds) scattered around

### Design Style
- Fun, vibrant, and playful
- Raffle/lottery themed
- Professional yet approachable
- Conveys excitement and winning

## Recommended Image Specifications

When replacing the placeholder with the actual "Grate Genyen" logo, use these specifications:

### Technical Requirements
- **Format:** PNG (Portable Network Graphics)
- **Background:** Transparent or white
- **Dimensions:** 
  - Minimum: 400px × 400px
  - Recommended: 800px × 800px to 1024px × 1024px
  - Maximum: 2048px × 2048px
- **Aspect Ratio:** Square (1:1) or close to square
- **File Size:** Keep under 500KB for optimal loading performance
- **Color Mode:** RGB
- **Resolution:** 72-150 DPI (for web use)

### Quality Guidelines
- High-resolution, sharp edges
- Clear, legible text
- Vibrant colors that match the brand
- Professional quality with no pixelation or artifacts
- Optimized for web use (compressed but maintaining quality)

## How to Replace the Placeholder Logo

Follow these steps to replace the placeholder with the actual "Grate Genyen" logo:

### Step 1: Prepare Your Logo File
1. Ensure your logo file meets the specifications above
2. Name the file `logo.png` (exact filename, all lowercase)
3. Verify the file size is reasonable (ideally under 500KB)

### Step 2: Replace the Logo File
1. Navigate to the `raffle-app/public/` directory
2. Back up the existing `logo.png` file (optional, for safety):
   ```bash
   mv logo.png logo-backup.png
   ```
3. Upload your new `logo.png` file to this directory
4. Verify the file permissions are correct:
   ```bash
   chmod 644 logo.png
   ```

### Step 3: Clear Browser Cache
After replacing the logo, users may need to clear their browser cache or perform a hard refresh to see the new logo:
- **Chrome/Edge:** Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
- **Firefox:** Ctrl+F5 (Windows/Linux) or Cmd+Shift+R (Mac)
- **Safari:** Cmd+Option+R (Mac)

### Step 4: Clear Service Worker Cache (Important!)
Since the logo is cached by the service worker, you need to update the cache version:

1. Open `raffle-app/public/service-worker.js`
2. Update the cache version number on line 1:
   ```javascript
   const CACHE_NAME = 'raffleapp-v2'; // Increment the version number
   ```
3. Save the file
4. The service worker will automatically update on the next page load

## How to Verify Logo Displays Correctly

After replacing the logo, verify it appears correctly across all pages:

### Manual Verification Checklist

Visit each of the following pages and confirm the logo displays properly:

- [ ] `/login.html` - Logo in login form
- [ ] `/admin.html` - Logo in header and as favicon
- [ ] `/seller.html` - Logo in header
- [ ] `/register-seller.html` - Logo on registration page
- [ ] `/bulk-print.html` - Logo in header
- [ ] `/manage-templates.html` - Logo in header
- [ ] `/upload-template.html` - Logo in header
- [ ] `/print-custom-tickets.html` - Logo in header
- [ ] `/raffle-print.html` - Logo in header
- [ ] `/raffle-dashboard.html` - Logo in header
- [ ] `/generate-tickets.html` - Logo in header
- [ ] `/buyers.html` - Logo in header
- [ ] `/payments-admin.html` - Logo in header
- [ ] `/print-tickets.html` - Logo in header

### Verification Points

For each page, check:
1. **Logo loads without errors** (check browser console for 404 errors)
2. **Logo displays at appropriate size** (not too large or too small)
3. **Logo maintains aspect ratio** (not stretched or squished)
4. **Logo is visible and clear** (sharp, not blurry)
5. **Logo colors match brand** (accurate color reproduction)
6. **Logo works on different screen sizes** (responsive design)
7. **Favicon displays correctly** in browser tab (where applicable)

### Automated Testing (Optional)

You can use browser developer tools to verify:

```javascript
// Check if logo loads successfully
const img = new Image();
img.src = '/logo.png';
img.onload = () => console.log('Logo loaded successfully!');
img.onerror = () => console.error('Logo failed to load!');
```

### Performance Check

Verify logo loading performance:
1. Open browser DevTools (F12)
2. Go to the Network tab
3. Refresh the page
4. Find `logo.png` in the network requests
5. Verify:
   - Status: 200 OK
   - Size: Reasonable (under 500KB recommended)
   - Load time: Fast (under 1 second)

## Troubleshooting

### Logo Not Displaying
- **Check file path:** Ensure logo.png is in `raffle-app/public/` directory
- **Check file name:** Must be exactly `logo.png` (lowercase)
- **Check file permissions:** Should be readable (644)
- **Clear cache:** Hard refresh browser and clear service worker cache
- **Check browser console:** Look for 404 or loading errors

### Logo Appears Blurry or Pixelated
- **Use higher resolution:** Upload a larger image file
- **Use PNG format:** Avoid JPEG which can introduce artifacts
- **Check original quality:** Ensure source image is high quality

### Logo Size Issues
- **Check CSS styling:** Logo size is controlled by CSS classes
- **Responsive design:** Logo should scale appropriately on mobile devices
- **Inspect element:** Use browser DevTools to check applied styles

### Colors Look Different
- **Color profile:** Use sRGB color profile
- **Browser rendering:** Different browsers may render colors slightly differently
- **Screen calibration:** Colors may appear different on different displays

## Additional Notes

### Multiple Logo Variants

The application also includes:
- `logo-transparent.png` - Used in some header sections (seller.html)

If you want to update this variant as well, follow the same process but save your logo with transparency.

### PWA Icons

For a complete branding experience, you may also want to update:
- `/icons/icon-*.png` files - Progressive Web App icons in various sizes
- These appear when the app is installed on mobile devices

### Favicon

The logo is also used as the favicon (browser tab icon) via:
```html
<link rel="icon" type="image/png" href="logo.png">
```

Ensure your logo looks good at small sizes (16×16, 32×32 pixels).

## Support

If you encounter any issues replacing the logo or have questions:
1. Check this documentation first
2. Review browser console for error messages
3. Verify all steps were completed correctly
4. Test on multiple browsers if issues persist

---

**Last Updated:** January 2026  
**Application:** Grate Genyen Raffle App  
**Version:** 1.0
