import { Injectable, Logger } from '@nestjs/common';
import { Resend } from 'resend';

interface OTPEntry {
  code: string;
  email: string;
  expiresAt: number;
}

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);
  private otpStore = new Map<string, OTPEntry>();
  private resend: Resend;

  constructor() {
    this.resend = new Resend(process.env.RESEND_API_KEY);
    this.logger.log(`Resend API key configured: ${!!process.env.RESEND_API_KEY}`);

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
    this.logger.log(`OTP generated for ${email}: ${code}`);

    try {
      this.logger.log('Sending email via Resend API...');

      const { data, error } = await this.resend.emails.send({
        from: 'SiteSync <onboarding@resend.dev>',
        to: [email],
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

      if (error) {
        this.logger.error(`Resend API error: ${JSON.stringify(error)}`);
        throw new Error(error.message);
      }

      this.logger.log(`Email sent successfully via Resend: ${data?.id}`);
    } catch (error) {
      this.logger.error(`Email send failed: ${error.message}`);
      throw error;
    }
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
