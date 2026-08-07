const nodemailer = require('nodemailer');
const logger = require('./logger');

let transporter = null;

function getTransporter() {
  if (transporter) return transporter;
  
  const host = process.env.SMTP_HOST;
  const port = parseInt(process.env.SMTP_PORT) || 587;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!user || !pass) {
    logger.warn('SMTP credentials not configured in environment. Emails will be logged to console.');
    return null;
  }

  transporter = nodemailer.createTransport({
    host: host || 'smtp.gmail.com',
    port: port,
    secure: port === 465,
    auth: { user, pass },
  });
  
  return transporter;
}

/**
 * Send an email
 * @param {string} to  Recipient email
 * @param {string} subject  Email subject
 * @param {string} text  Plain text body
 * @param {string} html  HTML body
 */
async function sendEmail({ to, subject, text, html }) {
  const t = getTransporter();
  const from = process.env.SMTP_FROM || '"AgriLink Support" <no-reply@agrilink.in>';
  
  if (!t) {
    logger.info(`
=========================================
[EMAIL STUB]
To: ${to}
Subject: ${subject}
Body: ${text}
=========================================
`);
    return { status: 'STUBBED' };
  }

  try {
    const info = await t.sendMail({
      from,
      to,
      subject,
      text,
      html,
    });
    logger.info(`Email successfully sent: ${info.messageId}`);
    return { status: 'SENT', messageId: info.messageId };
  } catch (err) {
    logger.error(`Failed to send email to ${to}:`, err);
    return { status: 'FAILED', error: err.message };
  }
}

module.exports = { sendEmail };
