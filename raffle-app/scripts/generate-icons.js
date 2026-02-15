/**
 * Generate app icons for Android and iOS
 * Requires: sharp (already in dependencies)
 */

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const sourceIcon = path.join(__dirname, '..', 'public', 'logo.png');
const androidRes = path.join(__dirname, '..', 'android', 'app', 'src', 'main', 'res');

// Check if source icon exists
if (!fs.existsSync(sourceIcon)) {
  console.error('❌ Source icon not found:', sourceIcon);
  console.log('Please ensure logo.png exists in the public directory');
  process.exit(1);
}

// Android icon sizes
const androidSizes = [
  { folder: 'mipmap-mdpi', size: 48 },
  { folder: 'mipmap-hdpi', size: 72 },
  { folder: 'mipmap-xhdpi', size: 96 },
  { folder: 'mipmap-xxhdpi', size: 144 },
  { folder: 'mipmap-xxxhdpi', size: 192 }
];

// Check if Android directory exists
if (!fs.existsSync(androidRes)) {
  console.log('⚠️  Android directory not found. Run "npm run cap:add:android" first.');
  console.log('Icon generation will be skipped for now.');
  process.exit(0);
}

console.log('🎨 Generating app icons...');

// Generate Android icons
let successCount = 0;
androidSizes.forEach(({ folder, size }) => {
  const dir = path.join(androidRes, folder);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  
  sharp(sourceIcon)
    .resize(size, size)
    .toFile(path.join(dir, 'ic_launcher.png'), (err) => {
      if (err) {
        console.error(`❌ Error generating ${folder}:`, err.message);
      } else {
        console.log(`✅ Generated ${folder}/ic_launcher.png`);
        successCount++;
        
        if (successCount === androidSizes.length) {
          console.log('🎉 Icon generation complete!');
          console.log('For iOS, use Xcode to add icons to Assets.xcassets');
        }
      }
    });
});
