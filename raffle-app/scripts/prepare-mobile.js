/**
 * Prepare static web files for mobile build
 * Copies public directory to www for Capacitor
 */

const fs = require('fs');
const path = require('path');

const publicDir = path.join(__dirname, '..', 'public');
const wwwDir = path.join(__dirname, '..', 'www');

// Create www directory if it doesn't exist
if (!fs.existsSync(wwwDir)) {
  fs.mkdirSync(wwwDir, { recursive: true });
}

// Copy all files from public to www
function copyDirectory(src, dest) {
  const entries = fs.readdirSync(src, { withFileTypes: true });
  
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    
    if (entry.isDirectory()) {
      fs.mkdirSync(destPath, { recursive: true });
      copyDirectory(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

console.log('📦 Preparing mobile build...');
copyDirectory(publicDir, wwwDir);
console.log('✅ Files copied to www directory');

// Update index.html for mobile (if login.html is the entry point, we'll update it)
const loginPath = path.join(wwwDir, 'login.html');
if (fs.existsSync(loginPath)) {
  let loginContent = fs.readFileSync(loginPath, 'utf8');
  
  // Add Capacitor script if not already present
  if (!loginContent.includes('capacitor.js')) {
    loginContent = loginContent.replace(
      '</head>',
      '  <script type="module" src="capacitor.js"></script>\n</head>'
    );
  }
  
  fs.writeFileSync(loginPath, loginContent);
  console.log('✅ Updated login.html for Capacitor');
}

// Also create an index.html that redirects to login.html for mobile apps
const indexPath = path.join(wwwDir, 'index.html');
if (!fs.existsSync(indexPath)) {
  const indexContent = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Grate Genyen</title>
    <script type="module" src="capacitor.js"></script>
    <script>
        window.location.href = 'login.html';
    </script>
</head>
<body>
    <p>Loading...</p>
</body>
</html>`;
  fs.writeFileSync(indexPath, indexContent);
  console.log('✅ Created index.html for mobile entry point');
}

console.log('🎉 Mobile build preparation complete!');
