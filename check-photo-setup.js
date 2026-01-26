const sqlite3 = require('sqlite3').verbose();
const fs = require('fs');
const path = require('path');

console.log('=== Ticket Photo Setup Diagnostic ===\n');

// Check database
const dbPath = path.join(__dirname, 'raffle-app', 'raffle.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ Database connection error:', err.message);
    return;
  }
  
  console.log('✓ Database connected');
  
  // Check if column exists
  db.all("PRAGMA table_info(tickets)", (err, columns) => {
    if (err) {
      console.error('❌ Error checking table schema:', err);
      return;
    }
    
    const hasPhotoPath = columns.some(col => col.name === 'ticket_photo_path');
    const hasPhotoTime = columns.some(col => col.name === 'ticket_photo_uploaded_at');
    
    if (hasPhotoPath && hasPhotoTime) {
      console.log('✓ Database columns exist: ticket_photo_path, ticket_photo_uploaded_at');
    } else {
      console.error('❌ Missing database columns. Run migration: node raffle-app/migrations/add_ticket_photo_columns.js');
    }
    
    // Check for tickets with photos
    db.get("SELECT COUNT(*) as count FROM tickets WHERE ticket_photo_path IS NOT NULL", (err, row) => {
      if (err) {
        console.error('❌ Error counting photos:', err);
      } else {
        console.log(`✓ Tickets with photos in database: ${row.count}`);
      }
      
      db.close();
    });
  });
});

// Check upload directory
const uploadDir = path.join(__dirname, 'raffle-app', 'uploads', 'ticket-photos');
if (fs.existsSync(uploadDir)) {
  const files = fs.readdirSync(uploadDir);
  console.log(`✓ Upload directory exists: ${uploadDir}`);
  console.log(`✓ Photos in directory: ${files.length}`);
  
  if (files.length > 0) {
    console.log('  Sample files:', files.slice(0, 5).join(', '));
  }
} else {
  console.error(`❌ Upload directory missing: ${uploadDir}`);
  console.log('   Create it with: mkdir -p raffle-app/uploads/ticket-photos');
}

console.log('\n=== End Diagnostic ===');
