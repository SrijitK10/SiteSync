import { Controller, Post, Body, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
  ) {}

  @Post('firebase-login')
  async firebaseLogin(@Body() body: { idToken: string }) {
    if (!body.idToken) {
      throw new BadRequestException('Firebase ID token is required');
    }

    // Verify the Firebase ID token
    const decoded = await this.authService.verifyFirebaseToken(body.idToken);
    const phone = decoded.phone_number;

    if (!phone) {
      throw new UnauthorizedException('Phone number not found in Firebase token');
    }

    // Login or auto-register the user
    return this.authService.loginOrRegister(phone, decoded.uid);
  }

  @Post('setup')
  async setup(@Body() body: { phone: string; name?: string }) {
    // SECURITY: Only works if the database is empty
    const users = await this.usersService.findAll();
    if (users.length > 0) {
      throw new BadRequestException('Setup rejected. User database is not empty.');
    }

    if (!body.phone) {
      throw new BadRequestException('Phone number required for setup.');
    }

    const adminUser = await this.usersService.create({
      phone: body.phone,
      name: body.name || 'Super Admin',
      role: 'super_admin',
    });

    return { message: 'Master setup complete', phone: adminUser.phone };
  }
}
