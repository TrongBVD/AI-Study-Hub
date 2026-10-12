const nodemailer = require("nodemailer");

/**
 * Creates and returns a Nodemailer transporter configured for Gmail SMTP.
 * Default port 465 with SSL direct encryption is optimized for serverless deployments
 * (Vercel, Render) with strict timeouts to prevent process hangs.
 */
function createMailTransporter() {
  const emailHost = process.env.EMAIL_HOST || "smtp.gmail.com";
  const emailPort = parseInt(process.env.EMAIL_PORT, 10) || 465;
  const isDirectSsl = emailPort === 465;

  return nodemailer.createTransport({
    host: emailHost,
    port: emailPort,
    secure: isDirectSsl, // true for 465 (SSL), false for 587 (STARTTLS)
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS, // 16-character Google App Password
    },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 10000,
  });
}

/**
 * Default sender address for outgoing system emails.
 */
function getMailSender() {
  return (
    process.env.EMAIL_FROM ||
    process.env.EMAIL_USER ||
    "AI StudyHub <no-reply@aistudyhub.com>"
  );
}

module.exports = {
  createMailTransporter,
  getMailSender,
};
