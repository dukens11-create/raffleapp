# Logo Instructions for Grate Genyen Raffle App

## ⚠️ About This Document

This document provides instructions for managing the logo files in the Grate Genyen Raffle App. The application currently contains a **placeholder logo** that demonstrates the proper design style (colorful raffle tickets with text). This placeholder uses "RaffleApp" branding and should be replaced with your official "Grate Genyen" branded logo when ready.

## Current Logo Status

The raffle application currently uses a **placeholder logo** at `raffle-app/public/logo.png`. This placeholder is a professional-quality raffle-themed design that demonstrates the proper style and format, but displays "RaffleApp" branding instead of the actual "Grate Genyen" branding.

**⚠️ Important:** The current placeholder should be replaced with your official "Grate Genyen" branded logo following the instructions in this document.

## Logo File Location

**Primary Logo File:** `raffle-app/public/logo.png`

This logo file is referenced throughout the application in the following files:
- `raffle-app/public/service-worker.js` - Cached for offline use
- `raffle-app/public/admin.html` - Header logo and favicon
- `raffle-app/public/seller.html` - Header logo (uses logo-transparent.png variant)
- `raffle-app/public/login.html` - Login page logo
- `raffle-app/public/register-seller.html` - Registration page logo
- `raffle-app/public/buyers.html` - Header logo and favicon
- `raffle-app/public/bulk-print.html` - Header logo and favicon
- `raffle-app/public/bulk-ticket-manager.html` - Favicon
- `raffle-app/public/manage-templates.html` - Header logo and favicon
- `raffle-app/public/upload-template.html` - Header logo and favicon
- `raffle-app/public/print-custom-tickets.html` - Favicon
- `raffle-app/public/print-tickets.html` - Header logo and favicon
- `raffle-app/public/raffle-print.html` - Header logo and favicon
- `raffle-app/public/raffle-dashboard.html` - Header logo and favicon
- `raffle-app/public/raffle-import.html` - Header logo and favicon
- `raffle-app/public/generate-tickets.html` - Favicon
- `raffle-app/public/payments-admin.html` - Header logo and favicon
- `raffle-app/public/custom-ticket-design.html` - Favicon
- `raffle-app/public/ticket-design-manager.html` - Header logo
- `raffle-app/public/verify-tickets.html` - Header logo

## Target "Grate Genyen" Logo Description

When you're ready to replace the placeholder, your actual "Grate Genyen" logo should feature the following elements for consistency with the application design:

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
2. Find line 1 and note the current version number
3. Increment the version number by one (examples below):
   - If current is `raffleapp-v1`, change to `raffleapp-v2`
   - If current is `raffleapp-v2`, change to `raffleapp-v3`
   - If current is `raffleapp-v5`, change to `raffleapp-v6`
   
   Example code change:
   ```javascript
   // Before:
   const CACHE_NAME = 'raffleapp-v1';
   
   // After:
   const CACHE_NAME = 'raffleapp-v2'; // Incremented to force cache refresh
   ```
4. Save the file
5. The service worker will automatically update on the next page load and cache the new logo

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
- [ ] `/print-custom-tickets.html` - Logo favicon
- [ ] `/raffle-print.html` - Logo in header
- [ ] `/raffle-dashboard.html` - Logo in header
- [ ] `/raffle-import.html` - Logo in header
- [ ] `/generate-tickets.html` - Logo favicon
- [ ] `/buyers.html` - Logo in header
- [ ] `/payments-admin.html` - Logo in header
- [ ] `/print-tickets.html` - Logo in header
- [ ] `/bulk-ticket-manager.html` - Logo favicon
- [ ] `/custom-ticket-design.html` - Logo favicon
- [ ] `/ticket-design-manager.html` - Logo in header
- [ ] `/verify-tickets.html` - Logo in header

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

The application also includes a transparent logo variant:
- **File:** `logo-transparent.png`
- **Location:** `raffle-app/public/logo-transparent.png`
- **Used in:** Seller dashboard header (`seller.html`)
- **Purpose:** Logo with transparent background for better integration with colored backgrounds

#### How to Update `logo-transparent.png`

If you want to update this variant as well:
1. Prepare your logo with a transparent background (PNG format)
2. Ensure the logo looks good on both light and dark backgrounds
3. Save as `logo-transparent.png` in the `raffle-app/public/` directory
4. Follow the same cache update steps as the main logo

**Note:** If you don't need a separate transparent variant, you can replace `logo-transparent.png` with the same file as `logo.png`.

### PWA Icons

For a complete branding experience, you may also want to update the Progressive Web App (PWA) icons that appear when the app is installed on mobile devices.

#### Icon Files to Update

All PWA icons are located in: `raffle-app/public/icons/`

The following icon files should be updated:
- `icon-72x72.png` - 72×72 pixels
- `icon-96x96.png` - 96×96 pixels
- `icon-128x128.png` - 128×128 pixels
- `icon-144x144.png` - 144×144 pixels
- `icon-152x152.png` - 152×152 pixels
- `icon-192x192.png` - 192×192 pixels (Android home screen)
- `icon-384x384.png` - 384×384 pixels
- `icon-512x512.png` - 512×512 pixels (Android splash screen)

#### How to Update PWA Icons

1. Start with your high-resolution logo (at least 512×512px)
2. Resize the logo to each required dimension
3. Save each as PNG with the exact filename listed above
4. Replace the existing files in `raffle-app/public/icons/`
5. Test installation on mobile devices to verify

**Tip:** You can use online tools like "PWA Asset Generator" or image editing software to create all sizes at once from your master logo file.

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

**Last Updated:** January 17, 2026  
**Application:** Grate Genyen Raffle App  
**Version:** 1.0
