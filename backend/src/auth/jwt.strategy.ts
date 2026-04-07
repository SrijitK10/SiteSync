import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    configService: ConfigService,
    private usersService: UsersService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET') || 'fallback_secret',
    });
  }

  // Fetch the live user on every request so role/permission checks always
  // reflect the current database state — never the role baked into the JWT
  // at login time. This prevents two failure modes:
  //   1. A promoted user stuck with their old role until they log out/in
  //   2. A demoted user retaining privileges via their still-valid JWT
  async validate(payload: any) {
    if (!payload?.sub) {
      throw new UnauthorizedException('Invalid token payload');
    }

    const user = await this.usersService.findOne(payload.sub).catch(() => null);
    if (!user) {
      throw new UnauthorizedException('User no longer exists');
    }

    // Populate every key variant callers in the codebase rely on, so
    // req.user.id / req.user.userId / req.user.sub all resolve correctly.
    return {
      id: user.id,
      userId: user.id,
      sub: user.id,
      phone: user.phone,
      email: user.email,
      name: user.name,
      role: user.role,
    };
  }
}
