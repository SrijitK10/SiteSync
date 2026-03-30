import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

interface OTPEntry {
  code: string;
  email: string;
  expiresAt: number;
}

@Injectable()
export class OtpService {
  private otpStore = new Map<string, OTPEntry>();
  private transporter: nodemailer.Transporter;

  constructor() {
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.SMTP_EMAIL,
        pass: process.env.SMTP_PASSWORD, // Gmail App Password (16-char)
      },
    });

    // Clean expired OTPs every 5 minutes
    setInterval(() => this.cleanExpired(), 5 * 60 * 1000);
  }

  generateOTP(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async sendOTP(email: string): Promise<void> {
    const code = this.generateOTP();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 min expiry

    this.otpStore.set(email, { code, email, expiresAt });

    await this.transporter.sendMail({
      from: `"SiteSync" <${process.env.SMTP_EMAIL}>`,
      to: email,
      subject: 'SiteSync - Your Login Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 400px; margin: 0 auto; padding: 24px;">
          <h2 style="color: #1B3A4B; text-align: center;">SiteSync</h2>
          <p style="color: #333; text-align: center;">Your verification code is:</p>
          <div style="background: #F0F4F8; border-radius: 12px; padding: 20px; text-align: center; margin: 20px 0;">
            <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1B3A4B;">${code}</span>
          </div>
          <p style="color: #666; text-align: center; font-size: 13px;">
            This code expires in 5 minutes.<br/>
            If you didn't request this, ignore this email.
          </p>
        </div>
      `,
    });
  }

  verifyOTP(email: string, code: string): boolean {
    const entry = this.otpStore.get(email);
    if (!entry) return false;
    if (Date.now() > entry.expiresAt) {
      this.otpStore.delete(email);
      return false;
    }
    if (entry.code !== code) return false;

    this.otpStore.delete(email);
    return true;
  }

  private cleanExpired() {
    const now = Date.now();
    for (const [key, entry] of this.otpStore.entries()) {
      if (now > entry.expiresAt) {
        this.otpStore.delete(key);
      }
    }
  }
}
