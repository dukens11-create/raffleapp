const nodemailer = require('nodemailer');

// Create email transporter
const transporter = nodemailer.createTransport({
  service: process.env.EMAIL_SERVICE || 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD
  }
});

// Verify transporter configuration
transporter.verify(function(error, success) {
  if (error) {
    console.error('Email service configuration error. Email notifications will be logged to console only.');
    if (process.env.DEBUG_MODE === 'true') {
      console.error('Email error details:', error.message);
    }
  } else {
    console.log('Email service is ready to send messages');
  }
});

/**
 * Send email with credentials to approved seller
 */
async function sendCredentialsEmail(email, phone, name, password) {
  const appUrl = process.env.APP_URL || 'http://localhost:3000';
  
  const mailOptions = {
    from: process.env.EMAIL_FROM || 'RaffleApp <noreply@raffleapp.com>',
    to: email,
    subject: '🎉 Your RaffleApp Seller Account Has Been Approved!',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .credentials { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea; }
          .credential-label { font-weight: bold; color: #667eea; }
          .credential-value { font-size: 18px; color: #333; margin: 5px 0 15px 0; font-family: monospace; }
          .button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎉 Welcome to RaffleApp!</h1>
          </div>
          <div class="content">
            <p>Hi <strong>${name}</strong>,</p>
            
            <p>Great news! Your seller account has been <strong>approved</strong> by our admin team.</p>
            
            <p>You can now login and start selling raffle tickets on our platform.</p>
            
            <div class="credentials">
              <p class="credential-label">Login URL:</p>
              <p class="credential-value">${appUrl}/login.html</p>
              
              <p class="credential-label">Phone Number:</p>
              <p class="credential-value">${phone}</p>
              
              <p class="credential-label">Password:</p>
              <p class="credential-value">${password}</p>
            </div>
            
            <p><strong>⚠️ Important:</strong> Please change your password after your first login for security.</p>
            
            <div style="text-align: center;">
              <a href="${appUrl}/login.html" class="button">Login Now</a>
            </div>
            
            <p>If you have any questions or need assistance, please don't hesitate to contact our support team.</p>
            
            <p>Best regards,<br><strong>RaffleApp Team</strong></p>
          </div>
          <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Hi ${name},

Your seller account has been approved!

Login at: ${appUrl}/login.html

Credentials:
Phone: ${phone}
Password: ${password}

Please change your password after first login.

- RaffleApp Team
    `
  };
  
  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Credentials email sent to:', email, '| Message ID:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending credentials email to', email, ':', error.message);
    // Fallback: log to console (password masked for security)
    console.log('FALLBACK - Credentials for', name, ':', { phone, password: '****', email });
    // Log full credentials only in debug mode
    if (process.env.DEBUG_MODE === 'true') {
      console.log('DEBUG - Full credentials:', { phone, password, email });
    }
    return { success: false, error: error.message };
  }
}

/**
 * Send rejection notification email
 */
async function sendRejectionEmail(email, phone, name, reason) {
  const appUrl = process.env.APP_URL || 'http://localhost:3000';
  
  const mailOptions = {
    from: process.env.EMAIL_FROM || 'RaffleApp <noreply@raffleapp.com>',
    to: email,
    subject: 'RaffleApp Seller Registration Update',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #ef4444; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .reason-box { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ef4444; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>RaffleApp Registration Update</h1>
          </div>
          <div class="content">
            <p>Hi${name ? ' ' + name : ''},</p>
            
            <p>Thank you for your interest in becoming a RaffleApp seller.</p>
            
            <p>Unfortunately, we are unable to approve your seller registration request at this time.</p>
            
            ${reason ? `
            <div class="reason-box">
              <p><strong>Reason:</strong></p>
              <p>${reason}</p>
            </div>
            ` : ''}
            
            <p>If you believe this decision was made in error or if you have additional information to share, please contact our support team.</p>
            
            <p>We appreciate your understanding.</p>
            
            <p>Best regards,<br><strong>RaffleApp Team</strong></p>
          </div>
          <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Hi${name ? ' ' + name : ''},

We regret to inform you that your seller registration request has been rejected.

${reason ? 'Reason: ' + reason : ''}

If you have any questions, please contact support.

- RaffleApp Team
    `
  };
  
  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Rejection email sent to:', email, '| Message ID:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending rejection email to', email, ':', error);
    // Fallback: log to console
    console.log('FALLBACK - Rejection notification for:', phone, email, '| Reason:', reason);
    return { success: false, error: error.message };
  }
}

/**
 * Send concern notification email to admin
 */
async function sendConcernNotification(adminEmail, sellerName, issueType, description, ticketNumber) {
  const appUrl = process.env.APP_URL || 'http://localhost:3000';
  
  const mailOptions = {
    from: process.env.EMAIL_FROM || 'RaffleApp <noreply@raffleapp.com>',
    to: adminEmail,
    subject: `⚠️ New Concern Reported by ${sellerName}`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #f59e0b; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .concern-box { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f59e0b; }
          .label { font-weight: bold; color: #f59e0b; }
          .button { display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; color: #666; font-size: 12px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>⚠️ New Seller Concern</h1>
          </div>
          <div class="content">
            <p>A seller has reported a new concern that requires your attention.</p>
            
            <div class="concern-box">
              <p class="label">Seller:</p>
              <p>${sellerName}</p>
              
              <p class="label">Issue Type:</p>
              <p>${issueType}</p>
              
              ${ticketNumber ? `
              <p class="label">Ticket Number:</p>
              <p>${ticketNumber}</p>
              ` : ''}
              
              <p class="label">Description:</p>
              <p>${description}</p>
            </div>
            
            <div style="text-align: center;">
              <a href="${appUrl}/admin" class="button">View in Admin Dashboard</a>
            </div>
            
            <p>Please review and address this concern as soon as possible.</p>
            
            <p>Best regards,<br><strong>RaffleApp System</strong></p>
          </div>
          <div class="footer">
            <p>This is an automated message. Please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
New Seller Concern

Seller: ${sellerName}
Issue Type: ${issueType}
${ticketNumber ? 'Ticket Number: ' + ticketNumber : ''}

Description:
${description}

View in Admin Dashboard: ${appUrl}/admin

- RaffleApp System
    `
  };
  
  try {
    const info = await transporter.sendMail(mailOptions);
    console.log('Concern notification email sent to admin | Message ID:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending concern notification email:', error.message);
    return { success: false, error: error.message };
  }
}

module.exports = {
  sendCredentialsEmail,
  sendRejectionEmail,
  sendConcernNotification
};
