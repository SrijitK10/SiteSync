import { Controller, Post, Body, UnauthorizedException, BadRequestException, Get } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import * as bcrypt from 'bcrypt';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
  ) {}

  @Post('login')
  async login(@Body() body: any) {
    const user = await this.authService.validateUser(body.email, body.password);
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }
    return this.authService.login(user);
  }

  @Post('setup')
  async setup(@Body() body: any) {
    // SECURITY: This endpoint explicitly only functions if the database is natively empty
    const users = await this.usersService.findAll();
    if (users.length > 0) {
      throw new BadRequestException('Setup rejected. Security constraint: User database is not empty.');
    }

    if (!body.email || !body.password) {
      throw new BadRequestException('Email and password required for setup.');
    } // No need to hash here, the UsersService automatically salts and hashes it

    const adminUser = await this.usersService.create({
      email: body.email,
      password_hash: body.password,
      name: body.name || 'Super Admin',
      role: 'super_admin',
    });

    return { message: 'Master setup complete', email: adminUser.email };
  }
}
