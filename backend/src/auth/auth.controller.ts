import { Controller, Post, Body, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { OtpService } from './otp.service';
import { JwtService } from '@nestjs/jwt';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
    private readonly otpService: OtpService,
    private readonly jwtService: JwtService,
  ) {}

  // ── Firebase Phone Auth (Android) ─────────────────────────────

  @Post('firebase-login')
  async firebaseLogin(@Body() body: { idToken: string; name?: string }) {
    if (!body.idToken) {
      throw new BadRequestException('Firebase ID token is required');
    }

    const decoded = await this.authService.verifyFirebaseToken(body.idToken);
    const phone = decoded.phone_number || undefined;
    const email = decoded.email || undefined;

    if (!phone && !email) {
      throw new UnauthorizedException('No phone or email found in Firebase token');
    }

    return this.authService.loginOrRegister({ phone, email }, decoded.uid, body.name);
  }

  // ── Custom Email OTP (iOS) ────────────────────────────────────

  @Post('send-otp')
  async sendOtp(@Body() body: { email: string }) {
    if (!body.email || !body.email.includes('@')) {
      throw new BadRequestException('Valid email is required');
    }

    try {
      await this.otpService.sendOTP(body.email);
      return { message: 'OTP sent successfully', email: body.email };
    } catch (error) {
      throw new BadRequestException('Failed to send OTP email. Check SMTP configuration.');
    }
  }

  @Post('verify-otp')
  async verifyOtp(@Body() body: { email: string; code: string; name?: string }) {
    if (!body.email || !body.code) {
      throw new BadRequestException('Email and OTP code are required');
    }

    const valid = this.otpService.verifyOTP(body.email, body.code);
    if (!valid) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    // OTP verified — find or create user, issue JWT
    let user = await this.usersService.findByEmail(body.email);

    if (!user) {
      user = await this.usersService.create({
        email: body.email,
        name: body.name || body.email.split('@')[0],
        role: 'viewer',
      });
    }

    const payload = {
      phone: user.phone,
      email: user.email,
      sub: user.id,
      role: user.role,
    };

    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        name: user.name,
        role: user.role,
      },
    };
  }

  // ── Initial Setup ─────────────────────────────────────────────

  @Post('setup')
  async setup(@Body() body: { phone?: string; email?: string; name?: string }) {
    const users = await this.usersService.findAll();
    if (users.length > 0) {
      throw new BadRequestException('Setup rejected. User database is not empty.');
    }

    if (!body.phone && !body.email) {
      throw new BadRequestException('Phone or email required for setup.');
    }

    const adminUser = await this.usersService.create({
      phone: body.phone || undefined,
      email: body.email || undefined,
      name: body.name || 'Super Admin',
      role: 'super_admin',
    });

    return { message: 'Master setup complete', phone: adminUser.phone, email: adminUser.email };
  }
}
