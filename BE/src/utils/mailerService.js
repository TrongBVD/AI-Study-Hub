const axios = require("axios");

/**
 * Parses sender details into Brevo format { name, email }.
 */
function parseSender(fromValue) {
  const fallbackEmail =
    process.env.BREVO_SENDER_EMAIL ||
    process.env.EMAIL_FROM ||
    process.env.EMAIL_USER ||
    "no-reply@aistudyhub.com";
  const defaultName = process.env.BREVO_SENDER_NAME || "AI StudyHub";

  if (!fromValue) {
    return { name: defaultName, email: fallbackEmail.trim() };
  }

  const str = String(fromValue).trim();
  const match = str.match(/^(?:"?([^"]*)"?\s)?<?([^>]+)>?$/);
  if (match) {
    const name = (match[1] || "").trim() || defaultName;
    const email = (match[2] || "").trim() || fallbackEmail;
    return { name, email };
  }

  return { name: defaultName, email: str };
}

/**
 * Parses recipient details into Brevo format [{ email, name }].
 */
function parseRecipients(toValue) {
  if (!toValue) return [];
  if (Array.isArray(toValue)) {
    return toValue
      .map((item) => {
        if (typeof item === "string") return { email: item.trim() };
        if (item && item.email) return { email: item.email.trim(), name: item.name };
        return null;
      })
      .filter(Boolean);
  }
  if (typeof toValue === "string") {
    return toValue
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean)
      .map((email) => ({ email }));
  }
  if (typeof toValue === "object" && toValue.email) {
    return [{ email: toValue.email.trim(), name: toValue.name }];
  }
  return [];
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/**
 * Sends transactional email via Brevo REST API (HTTPS port 443).
 * Guaranteed to bypass cloud egress SMTP blocks (Render, Vercel, AWS).
 *
 * @param {Object} options
 * @param {string|Array} options.to - Recipient email(s)
 * @param {string} options.subject - Subject line
 * @param {string} [options.text] - Plain text content
 * @param {string} [options.html] - HTML content
 * @param {string} [options.from] - Custom sender header
 */
async function sendMail({ to, subject, text, html, from }) {
  const apiKey = process.env.BREVO_API_KEY;
  if (!apiKey || apiKey === "your_brevo_api_key_here") {
    throw new Error(
      "Brevo configuration error: Missing or unconfigured BREVO_API_KEY. Please set BREVO_API_KEY in your environment variables."
    );
  }

  const sender = parseSender(from);
  const recipients = parseRecipients(to);

  if (!recipients.length) {
    throw new Error("Brevo send error: No valid recipient email specified.");
  }

  const payload = {
    sender,
    to: recipients,
    subject: subject || "AI StudyHub Notification",
  };

  if (html) {
    payload.htmlContent = html;
  }
  if (text) {
    payload.textContent = text;
    if (!payload.htmlContent) {
      payload.htmlContent = `<p style="white-space: pre-line;">${escapeHtml(text)}</p>`;
    }
  }

  try {
    const response = await axios.post(
      "https://api.brevo.com/v3/smtp/email",
      payload,
      {
        headers: {
          accept: "application/json",
          "api-key": apiKey.trim(),
          "content-type": "application/json",
        },
        timeout: 15000,
      }
    );

    return {
      messageId: response.data?.messageId || "brevo-sent",
      response: response.data,
    };
  } catch (err) {
    const errorDetails =
      err.response?.data?.message ||
      err.response?.data?.code ||
      err.message;
    console.error("🔴 Brevo API Error:", errorDetails);
    throw new Error(`Brevo send error: ${errorDetails}`);
  }
}

/**
 * Interface compatible with Nodemailer transporter for zero-breakage across controllers.
 */
function createMailTransporter() {
  return {
    sendMail: (options) => sendMail(options),
  };
}

/**
 * Default sender address for outgoing system emails.
 */
function getMailSender() {
  const sender = parseSender();
  return `${sender.name} <${sender.email}>`;
}

module.exports = {
  createMailTransporter,
  sendMail,
  getMailSender,
};
