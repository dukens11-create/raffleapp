# Email Notification Service

This directory contains the email service module that handles automated email notifications for seller registration approvals and rejections.

## Features

- 📧 Automated email notifications for seller approval with login credentials
- ❌ Automated email notifications for seller rejection with reason
- 🎨 Professional HTML email templates with responsive design
- 📝 Plain text email fallback for compatibility
- 🛡️ Secure password handling with masking in logs
- 🔄 Graceful fallback to console logging if email service is unavailable

## Configuration

### Environment Variables

Add these variables to your `.env` file:

```env
# Email Configuration
EMAIL_SERVICE=gmail
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-specific-password
EMAIL_FROM=RaffleApp <your-email@gmail.com>
APP_URL=https://your-app.onrender.com
```

### Gmail Setup (Recommended)

1. **Enable 2-Step Verification:**
   - Go to [Google Account Security](https://myaccount.google.com/security)
   - Enable 2-Step Verification

2. **Generate App Password:**
   - Go to [App Passwords](https://myaccount.google.com/apppasswords)
   - Select app: "Mail"
   - Select device: "Other (Custom name)"
   - Enter name: "RaffleApp"
   - Click Generate
   - Copy the 16-character password

3. **Add to Environment:**
   ```env
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASSWORD=your-16-char-app-password
   ```

### Other Email Services

The service supports any SMTP-compatible email provider. Examples:

**SendGrid:**
```env
EMAIL_SERVICE=SendGrid
EMAIL_USER=apikey
EMAIL_PASSWORD=your-sendgrid-api-key
```

**Outlook:**
```env
EMAIL_SERVICE=Outlook365
EMAIL_USER=your-email@outlook.com
EMAIL_PASSWORD=your-password
```

**Custom SMTP:**
For custom SMTP servers, modify `emailService.js` to use `host`, `port`, and `secure` options instead of `service`.

## Usage

### In Server Code

```javascript
const emailService = require('./services/emailService');

// Send approval email with credentials
const result = await emailService.sendCredentialsEmail(
  'seller@example.com',  // email
  '1234567890',          // phone
  'John Doe',            // name
  'Seller@abc123'        // password
);

if (result.success) {
  console.log('Email sent:', result.messageId);
} else {
  console.error('Email failed:', result.error);
}

// Send rejection email
const result = await emailService.sendRejectionEmail(
  'seller@example.com',  // email
  '1234567890',          // phone
  'John Doe',            // name
  'Incomplete documents' // reason
);
```

## Email Templates

### Approval Email

- **Subject:** 🎉 Your RaffleApp Seller Account Has Been Approved!
- **Contains:**
  - Welcome message
  - Login URL
  - Phone number
  - Password (masked in logs)
  - Security reminder to change password
  - Call-to-action button

### Rejection Email

- **Subject:** RaffleApp Seller Registration Update
- **Contains:**
  - Thank you message
  - Rejection notification
  - Reason (if provided)
  - Contact support information

## Security Features

1. **Password Masking:** Passwords are masked (****) in console logs for security
2. **Debug Mode:** Full credentials only logged when `DEBUG_MODE=true`
3. **Error Handling:** Email errors show minimal details in production
4. **Fallback Logging:** If email fails, notification is logged to console (with masked password)

## Troubleshooting

### Email Not Sending

1. **Check Configuration:**
   ```bash
   # Verify environment variables are set
   echo $EMAIL_USER
   echo $EMAIL_SERVICE
   ```

2. **Check Logs:**
   - Look for "Email service is ready" message on server start
   - Check for email configuration errors

3. **Test Connection:**
   - Transporter verification runs on module load
   - Check console for verification errors

### Gmail Issues

- **"Less secure app access":** Use App Password instead
- **"Invalid credentials":** Regenerate App Password
- **"Authentication failed":** Verify 2-Step Verification is enabled

### Firewall/Network Issues

- Ensure outbound SMTP port 465 or 587 is open
- Check if your hosting provider blocks SMTP
- Consider using API-based services (SendGrid, Mailgun) instead

## Testing

Test the email service without making code changes:

```bash
# Set environment variables
export EMAIL_USER=your-email@gmail.com
export EMAIL_PASSWORD=your-app-password

# Restart server
npm start

# Test by approving/rejecting a seller request
```

## Production Deployment (Render)

1. Go to Render Dashboard → Your Service → Environment
2. Add environment variables:
   - `EMAIL_SERVICE=gmail`
   - `EMAIL_USER=your-email@gmail.com`
   - `EMAIL_PASSWORD=your-app-password`
   - `EMAIL_FROM=RaffleApp <your-email@gmail.com>`
3. Save and redeploy

## Maintenance

### Updating Email Templates

Email templates are inline in `emailService.js`. To update:

1. Edit HTML/CSS in the `html` property
2. Update plain text in the `text` property
3. Test changes locally before deploying

### Monitoring

- Monitor email send success/failure in logs
- Check for "✅ Email sent successfully" or "❌ Failed to send email"
- Set up log aggregation for production monitoring

## Future Enhancements

- [ ] Separate email templates into files
- [ ] Queue system for bulk email sending
- [ ] Email delivery tracking and analytics
- [ ] SMS notifications (Twilio integration)
- [ ] Support for email attachments
- [ ] Multi-language email templates
- [ ] Email preview/testing endpoint
