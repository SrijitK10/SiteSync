import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as admin from 'firebase-admin';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {
    // Initialize Firebase Admin SDK if not already initialized
    if (!admin.apps.length) {
      const serviceAccount = JSON.parse(
        process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '{}',
      );
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
  }

  async verifyFirebaseToken(idToken: string): Promise<admin.auth.DecodedIdToken> {
    try {
      return await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      throw new UnauthorizedException('Invalid or expired Firebase token');
    }
  }

  async loginOrRegister(identifier: { phone?: string; email?: string }, firebaseUid: string, name?: string) {
    // Normalize phone before any lookups or comparisons
    const normalizedPhone = identifier.phone
      ? this.usersService.normalizePhone(identifier.phone)
      : undefined;

    // Try to find existing user by Firebase UID first, then phone/email
    let user = await this.usersService.findByFirebaseUid(firebaseUid);

    if (!user && normalizedPhone) {
      user = await this.usersService.findByPhone(normalizedPhone);
    }
    if (!user && identifier.email) {
      user = await this.usersService.findByEmail(identifier.email);
    }

    if (!user) {
      // Auto-register new users as 'viewer'
      try {
        user = await this.usersService.create({
          phone: normalizedPhone || undefined,
          email: identifier.email || undefined,
          firebase_uid: firebaseUid,
          name: name || normalizedPhone || identifier.email || 'User',
          role: 'viewer',
        });
      } catch (error) {
        // Race condition: another request created the user between our lookup and insert.
        // Find the existing user instead of failing.
        if (error instanceof ConflictException) {
          if (normalizedPhone) {
            user = await this.usersService.findByPhone(normalizedPhone);
          }
          if (!user && identifier.email) {
            user = await this.usersService.findByEmail(identifier.email);
          }
          if (!user) throw error;
        } else {
          throw error;
        }
      }
    } else {
      const updates: Record<string, string> = {};

      if (user.firebase_uid !== firebaseUid) {
        updates.firebase_uid = firebaseUid;
      }
      if (normalizedPhone && user.phone !== normalizedPhone) {
        updates.phone = normalizedPhone;
      }
      if (identifier.email && !user.email) {
        updates.email = identifier.email;
      }
      if ((!user.name || user.name.trim().length === 0) && name) {
        updates.name = name;
      }

      if (Object.keys(updates).length > 0) {
        user = await this.usersService.update(user.id, updates as any);
      }
    }

    return this.issueToken(user);
  }

  // ── Email + Password Auth (iOS) ──────────────────────────────

  async register(email: string, password: string, name: string) {
    const existing = await this.usersService.findByEmail(email);

    if (existing) {
      // Check if already has a password set (true duplicate)
      const withPw = await this.usersService.findByEmailWithPassword(email);
      if (withPw?.password_hash) {
        throw new ConflictException('Email already registered');
      }
      // Pre-created user without password — let them claim the account
      const hash = await bcrypt.hash(password, 10);
      await this.usersService.update(existing.id, { password_hash: hash, name } as any);
      const updated = await this.usersService.findOne(existing.id);
      return this.issueToken(updated);
    }

    const hash = await bcrypt.hash(password, 10);
    const user = await this.usersService.create({
      email,
      password_hash: hash,
      name,
      role: 'viewer',
    });
    return this.issueToken(user);
  }

  async loginWithPassword(email: string, password: string) {
    const user = await this.usersService.findByEmailWithPassword(email);
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }
    if (!user.password_hash) {
      throw new UnauthorizedException('No password set for this account. Please register first.');
    }
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      throw new UnauthorizedException('Invalid email or password');
    }
    return this.issueToken(user);
  }

  async changePassword(userId: string, oldPassword: string, newPassword: string) {
    const user = await this.usersService.findByIdWithPassword(userId);
    if (!user || !user.password_hash) {
      throw new UnauthorizedException('No password set for this account');
    }
    const valid = await bcrypt.compare(oldPassword, user.password_hash);
    if (!valid) {
      throw new UnauthorizedException('Current password is incorrect');
    }
    const hash = await bcrypt.hash(newPassword, 10);
    await this.usersService.update(userId, { password_hash: hash } as any);
    return { message: 'Password changed successfully' };
  }

  async resetPassword(firebaseIdToken: string, newPassword: string) {
    const decoded = await this.verifyFirebaseToken(firebaseIdToken);
    const phone = decoded.phone_number;
    if (!phone) {
      throw new UnauthorizedException('Firebase token must contain a phone number');
    }
    const user = await this.usersService.findByPhone(phone);
    if (!user) {
      throw new UnauthorizedException('No account found with this phone number');
    }
    const hash = await bcrypt.hash(newPassword, 10);
    await this.usersService.update(user.id, { password_hash: hash } as any);
    return { message: 'Password reset successfully' };
  }

  // ── Helpers ───────────────────────────────────────────────────

  private issueToken(user: any) {
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
}
