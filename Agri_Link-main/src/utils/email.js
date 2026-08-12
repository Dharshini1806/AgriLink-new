const { Resend } = require('resend');
const nodemailer = require('nodemailer');
const logger = require('./logger');

// ─── Resend (HTTP API — works on Render free tier) ────────
let resendClient = null;

function getResendClient() {
  if (resendClient) return resendClient;
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) return null;
  resendClient = new Resend(apiKey);
  return resendClient;
}

// ─── Nodemailer SMTP (local dev only — blocked on Render free tier) ───
let smtpTransporter = null;

function getSmtpTransporter() {
  if (smtpTransporter) return smtpTransporter;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  if (!user || !pass) return null;

  smtpTransporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT) || 587,
    secure: parseInt(process.env.SMTP_PORT) === 465,
    auth: { user, pass },
  });
  return smtpTransporter;
}

/**
 * Send an email via Resend (primary) → SMTP (fallback) → console stub
 * @param {string} to  Recipient email
 * @param {string} subject  Email subject
 * @param {string} text  Plain text body
 * @param {string} html  HTML body
 */
async function sendEmail({ to, subject, text, html }) {
  const from = process.env.EMAIL_FROM || 'AgriLink Support <onboarding@resend.dev>';

  // ── 1. Try Resend (HTTP API — Render compatible) ──────────
  const resend = getResendClient();
  if (resend) {
    try {
      const { data, error } = await resend.emails.send({ from, to, subject, text, html });
      if (error) {
        logger.error(`Resend API error sending to ${to}:`, error);
        return { status: 'FAILED', error: error.message };
      }
      logger.info(`Email sent via Resend: ${data.id}`);
      return { status: 'SENT', messageId: data.id };
    } catch (err) {
      logger.error(`Resend exception sending to ${to}:`, err);
      return { status: 'FAILED', error: err.message };
    }
  }

  // ── 2. Fallback: SMTP (local dev) ────────────────────────
  const smtp = getSmtpTransporter();
  if (smtp) {
    try {
      const info = await smtp.sendMail({ from, to, subject, text, html });
      logger.info(`Email sent via SMTP: ${info.messageId}`);
      return { status: 'SENT', messageId: info.messageId };
    } catch (err) {
      logger.error(`SMTP failed sending to ${to}:`, err);
      return { status: 'FAILED', error: err.message };
    }
  }

  // ── 3. Stub: log to console ───────────────────────────────
  logger.warn('No email provider configured (RESEND_API_KEY or SMTP_USER). Stubbing email to console.');
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

module.exports = { sendEmail };
