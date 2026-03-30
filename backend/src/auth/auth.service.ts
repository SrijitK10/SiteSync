import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as admin from 'firebase-admin';

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
    // Try to find existing user by Firebase UID first, then phone/email
    let user = await this.usersService.findByFirebaseUid(firebaseUid);

    if (!user && identifier.phone) {
      user = await this.usersService.findByPhone(identifier.phone);
    }
    if (!user && identifier.email) {
      user = await this.usersService.findByEmail(identifier.email);
    }

    if (!user) {
      // Auto-register new users as 'viewer'
      user = await this.usersService.create({
        phone: identifier.phone || undefined,
        email: identifier.email || undefined,
        firebase_uid: firebaseUid,
        name: name || identifier.phone || identifier.email || 'User',
        role: 'viewer',
      });
    } else if (!user.firebase_uid) {
      // Link Firebase UID if user was pre-created by admin
      await this.usersService.update(user.id, { firebase_uid: firebaseUid } as any);
    }

    // Issue app JWT with role from PostgreSQL
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
