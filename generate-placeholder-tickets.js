#!/usr/bin/env node

/**
 * Placeholder Ticket Design Generator
 * 
 * This script creates simple placeholder images for the ticket design system.
 * These placeholders should be replaced with professional designs following
 * the specifications in TICKET_DESIGN_GUIDE.md
 * 
 * Usage:
 *   node generate-placeholder-tickets.js
 * 
 * Requirements:
 *   npm install canvas
 */

const fs = require('fs');
const path = require('path');

// Ticket specifications
const tickets = [
  {
    category: 'BASIC',
    price: 50,
    prize: '5,000',
    code: 'XYZ-######',
    color: '#10b981',
    gradient: ['#10b981', '#059669']
  },
  {
    category: 'PREMIUM',
    price: 100,
    prize: '10,000',
    code: 'EFG-######',
    color: '#7c3aed',
    gradient: ['#7c3aed', '#6366f1']
  },
  {
    category: 'BRONZE',
    price: 250,
    prize: '25,000',
    code: 'JKL-######',
    color: '#ea580c',
    gradient: ['#ea580c', '#dc2626']
  },
  {
    category: 'SILVER',
    price: 500,
    prize: '150,000',
    code: 'ABC-######',
    color: '#cbd5e1',
    gradient: ['#cbd5e1', '#94a3b8']
  },
  {
    category: 'GOLD',
    price: 1000,
    prize: '500,000',
    code: 'GOLD-#####',
    color: '#fbbf24',
    gradient: ['#fbbf24', '#f59e0b']
  },
  {
    category: 'DIAMOND',
    price: 5000,
    prize: '2,000,000',
    code: 'DMD-#####',
    color: '#22d3ee',
    gradient: ['#22d3ee', '#06b6d4']
  }
];

console.log('🎨 Ticket Design Placeholder Generator');
console.log('=' .repeat(60));

// Check if canvas is available
let Canvas;
try {
  Canvas = require('canvas');
  console.log('✅ Canvas library found - generating image placeholders');
} catch (e) {
  console.log('⚠️  Canvas library not found');
  console.log('📝 Creating text placeholders instead');
  console.log('💡 To generate PNG images: npm install canvas');
  Canvas = null;
}

const outputDir = path.join(__dirname, 'raffle-app', 'public', 'ticket-designs');
const flutterDir = path.join(__dirname, 'flutter_app', 'assets', 'images', 'tickets');

// Ensure directories exist
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}
if (!fs.existsSync(flutterDir)) {
  fs.mkdirSync(flutterDir, { recursive: true });
}

// Generate placeholders
tickets.forEach(ticket => {
  const webFileName = `${ticket.category}-${ticket.price}-HTG.png`;
  const flutterFileName = `${ticket.category.toLowerCase()}_ticket.png`;
  
  const webPath = path.join(outputDir, webFileName);
  const flutterPath = path.join(flutterDir, flutterFileName);
  
  if (Canvas) {
    // Generate actual PNG with canvas
    generateImagePlaceholder(ticket, webPath);
    generateImagePlaceholder(ticket, flutterPath);
    console.log(`✅ Created: ${webFileName}`);
  } else {
    // Generate text placeholder
    generateTextPlaceholder(ticket, webPath);
    generateTextPlaceholder(ticket, flutterPath);
    console.log(`📝 Placeholder: ${webFileName}`);
  }
});

console.log('=' .repeat(60));
console.log('✨ Placeholder generation complete!');
console.log('');
console.log('📌 Next Steps:');
console.log('  1. Review TICKET_DESIGN_GUIDE.md for design specifications');
console.log('  2. Create professional designs using graphic design software');
console.log('  3. Replace placeholder files with final designs');
console.log('  4. Ensure all images are optimized (< 500KB, 1024x1024px)');
console.log('');

function generateTextPlaceholder(ticket, filePath) {
  const placeholder = `
PLACEHOLDER: ${ticket.category} Ticket Design
=============================================

This is a placeholder file. Replace with actual ticket design PNG.

Specifications:
- Category: ${ticket.category}
- Price: ${ticket.price} HTG
- Max Prize: ${ticket.prize} HTG
- Code Format: ${ticket.code}
- Color: ${ticket.color}
- Gradient: ${ticket.gradient.join(' → ')}

Required Dimensions: 1024x1024px
Required DPI: 300
Required Format: PNG
Max File Size: 500KB

See TICKET_DESIGN_GUIDE.md for complete specifications.
`;
  fs.writeFileSync(filePath + '.txt', placeholder);
}

function generateImagePlaceholder(ticket, filePath) {
  const { createCanvas } = Canvas;
  const canvas = createCanvas(1024, 1024);
  const ctx = canvas.getContext('2d');
  
  // Create gradient background
  const gradient = ctx.createLinearGradient(0, 0, 1024, 1024);
  gradient.addColorStop(0, ticket.gradient[0]);
  gradient.addColorStop(1, ticket.gradient[1]);
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, 1024, 1024);
  
  // Add sparkle effect (simple dots)
  ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
  for (let i = 0; i < 50; i++) {
    const x = Math.random() * 1024;
    const y = Math.random() * 1024;
    const radius = Math.random() * 4 + 2;
    ctx.beginPath();
    ctx.arc(x, y, radius, 0, Math.PI * 2);
    ctx.fill();
  }
  
  // Brown header banner (GRATE TOUT)
  ctx.fillStyle = '#8B4513';
  ctx.fillRect(50, 50, 300, 80);
  ctx.fillStyle = '#ffffff';
  ctx.font = 'bold 40px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('GRATE TOUT', 200, 105);
  
  // Brown price banner (right side)
  ctx.fillStyle = '#8B4513';
  ctx.fillRect(674, 50, 300, 80);
  ctx.fillStyle = '#ffffff';
  ctx.font = 'bold 36px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText(`${ticket.price} GOURDES`, 824, 105);
  
  // Main logo
  ctx.font = 'bold 80px sans-serif';
  ctx.textAlign = 'center';
  
  // GRATE (yellow)
  ctx.fillStyle = '#FFD700';
  ctx.strokeStyle = '#000000';
  ctx.lineWidth = 3;
  ctx.fillText('GRATE', 512, 250);
  ctx.strokeText('GRATE', 512, 250);
  
  // GENYEN (light blue)
  ctx.fillStyle = '#87CEEB';
  ctx.fillText('GENYEN', 512, 350);
  ctx.strokeText('GENYEN', 512, 350);
  
  // Category banner (metallic ribbon)
  ctx.fillStyle = ticket.color;
  ctx.fillRect(200, 450, 624, 100);
  ctx.fillStyle = '#ffffff';
  ctx.font = 'bold 60px sans-serif';
  ctx.fillText(ticket.category, 512, 520);
  
  // Scratch area (white box)
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(262, 600, 500, 100);
  ctx.fillStyle = '#333333';
  ctx.font = '36px monospace';
  ctx.fillText(ticket.code, 512, 665);
  
  // Prize banner (bottom)
  ctx.fillStyle = '#8B4513';
  ctx.fillRect(50, 850, 924, 100);
  ctx.fillStyle = '#ffffff';
  ctx.font = 'bold 32px sans-serif';
  ctx.fillText(`GRATE & GENYEN JISKA ${ticket.prize} GOURDES!`, 512, 915);
  
  // Save to file
  const buffer = canvas.toBuffer('image/png');
  fs.writeFileSync(filePath, buffer);
}
