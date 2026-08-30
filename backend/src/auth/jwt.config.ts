import { ConfigService } from '@nestjs/config';

const DEVELOPMENT_JWT_SECRET = 'fallback_secret';

export function getJwtSecret(configService: ConfigService): string {
  const secret = configService.get<string>('JWT_SECRET');
  if (secret && secret.trim().length > 0) {
    return secret;
  }

  console.warn(
    'JWT_SECRET is not set. Falling back to a development-only secret.',
  );
  return DEVELOPMENT_JWT_SECRET;
}
