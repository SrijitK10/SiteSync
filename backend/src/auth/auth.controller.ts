import { Controller, Post, Body, UnauthorizedException, BadRequestException, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { AuthGuard } from '@nestjs/passport';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
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

  // ── Email + Password Auth (iOS) ───────────────────────────────

  @Post('register')
  async register(@Body() body: { email: string; password: string; name: string }) {
    if (!body.email || !body.email.includes('@')) {
      throw new BadRequestException('Valid email is required');
    }
    if (!body.password || body.password.length < 6) {
      throw new BadRequestException('Password must be at least 6 characters');
    }
    if (!body.name || body.name.trim().length < 2) {
      throw new BadRequestException('Name must be at least 2 characters');
    }

    return this.authService.register(
      body.email.trim().toLowerCase(),
      body.password,
      body.name.trim(),
    );
  }

  @Post('login')
  async login(@Body() body: { email: string; password: string }) {
    if (!body.email || !body.password) {
      throw new BadRequestException('Email and password are required');
    }

    return this.authService.loginWithPassword(
      body.email.trim().toLowerCase(),
      body.password,
    );
  }

  @Post('change-password')
  @UseGuards(AuthGuard('jwt'))
  async changePassword(@Request() req: any, @Body() body: { oldPassword: string; newPassword: string }) {
    if (!body.oldPassword || !body.newPassword) {
      throw new BadRequestException('Old password and new password are required');
    }
    if (body.newPassword.length < 6) {
      throw new BadRequestException('New password must be at least 6 characters');
    }

    return this.authService.changePassword(req.user.sub, body.oldPassword, body.newPassword);
  }

  @Post('reset-password')
  async resetPassword(@Body() body: { firebaseIdToken: string; newPassword: string }) {
    if (!body.firebaseIdToken || !body.newPassword) {
      throw new BadRequestException('Firebase ID token and new password are required');
    }
    if (body.newPassword.length < 6) {
      throw new BadRequestException('New password must be at least 6 characters');
    }

    return this.authService.resetPassword(body.firebaseIdToken, body.newPassword);
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
