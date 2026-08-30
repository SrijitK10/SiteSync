import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  private isUniqueViolation(error: unknown): boolean {
    return (error as { code?: string })?.code === '23505';
  }

  private uniqueViolationConflict(error: unknown): ConflictException {
    const detail = String((error as { detail?: string })?.detail || '');
    if (detail.includes('phone')) {
      return new ConflictException('Phone number already registered');
    }
    if (detail.includes('email')) {
      return new ConflictException('Email already registered');
    }
    if (detail.includes('firebase_uid')) {
      return new ConflictException('Firebase account already linked');
    }
    return new ConflictException('User already exists');
  }

  normalizePhone(phone?: string | null): string | undefined {
    if (!phone) return undefined;
    const trimmed = phone.trim();
    if (!trimmed) return undefined;

    const digits = trimmed.replace(/\D/g, '');
    if (!digits) return undefined;

    if (trimmed.startsWith('+')) {
      return `+${digits}`;
    }

    if (digits.length === 10) {
      return `+91${digits}`;
    }

    if (digits.length === 12 && digits.startsWith('91')) {
      return `+${digits}`;
    }

    if (digits.startsWith('00') && digits.length > 2) {
      return `+${digits.slice(2)}`;
    }

    return `+${digits}`;
  }

  async create(userData: Partial<User>): Promise<User> {
    if (userData.phone) {
      userData.phone = this.normalizePhone(userData.phone);

      if (userData.phone) {
        const existing = await this.findByPhone(userData.phone);
        if (existing) {
          throw new ConflictException('Phone number already registered');
        }
      }
    }
    if (userData.email) {
      const existing = await this.usersRepository.findOne({
        where: { email: userData.email },
      });
      if (existing) {
        throw new ConflictException('Email already registered');
      }
    }

    const newUser = this.usersRepository.create(userData);
    try {
      return await this.usersRepository.save(newUser);
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        throw this.uniqueViolationConflict(error);
      }
      throw error;
    }
  }

  async findAll(): Promise<User[]> {
    return this.usersRepository.find({
      select: ['id', 'name', 'phone', 'email', 'role', 'created_at'],
    });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({
      where: { id },
      select: ['id', 'name', 'phone', 'email', 'role', 'created_at'],
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async findByPhone(phone: string): Promise<User | null> {
    if (!phone) return null;

    const normalizedPhone = this.normalizePhone(phone);
    if (!normalizedPhone) return null;

    // Exact match first
    const exactMatch = await this.usersRepository.findOne({
      where: { phone: normalizedPhone },
    });
    if (exactMatch) return exactMatch;

    // Fuzzy match based on last 10 digits
    const cleanPhone = normalizedPhone.replace(/\D/g, '');
    if (cleanPhone.length >= 10) {
      const last10 = cleanPhone.slice(-10);
      const fuzzyMatch = await this.usersRepository
        .createQueryBuilder('user')
        .where(
          "RIGHT(regexp_replace(COALESCE(user.phone, ''), '\\D', '', 'g'), 10) = :last10",
          { last10 },
        )
        .getOne();

      if (fuzzyMatch) return fuzzyMatch;
    }

    return null;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email } });
  }

  async findByEmailWithPassword(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { email },
      select: [
        'id',
        'name',
        'phone',
        'email',
        'role',
        'password_hash',
        'firebase_uid',
      ],
    });
  }

  async findByIdWithPassword(id: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { id },
      select: [
        'id',
        'name',
        'phone',
        'email',
        'role',
        'password_hash',
        'firebase_uid',
      ],
    });
  }

  async findByFirebaseUid(uid: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { firebase_uid: uid } });
  }

  async update(id: string, updateData: Partial<User>): Promise<User> {
    if (updateData.phone !== undefined) {
      updateData.phone = this.normalizePhone(updateData.phone);

      if (updateData.phone) {
        const existing = await this.findByPhone(updateData.phone);
        if (existing && existing.id !== id) {
          throw new ConflictException('Phone number already registered');
        }
      }
    }
    if (updateData.email !== undefined && updateData.email) {
      const existing = await this.findByEmail(updateData.email);
      if (existing && existing.id !== id) {
        throw new ConflictException('Email already registered');
      }
    }
    if (updateData.firebase_uid !== undefined && updateData.firebase_uid) {
      const existing = await this.findByFirebaseUid(updateData.firebase_uid);
      if (existing && existing.id !== id) {
        throw new ConflictException('Firebase account already linked');
      }
    }

    const user = await this.findOne(id);
    Object.assign(user, updateData);
    try {
      return await this.usersRepository.save(user);
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        throw this.uniqueViolationConflict(error);
      }
      throw error;
    }
  }

  async updateFcmToken(id: string, fcm_token: string): Promise<User> {
    const user = await this.findOne(id);
    user.fcm_token = fcm_token;
    return this.usersRepository.save(user);
  }

  async remove(id: string): Promise<void> {
    const result = await this.usersRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('User not found');
    }
  }

  async findTokensByRoles(
    roles: string[],
    excludeUserId?: string,
    projectId?: string,
  ): Promise<string[]> {
    const queryBuilder = this.usersRepository
      .createQueryBuilder('user')
      .where('user.role IN (:...roles)', { roles })
      .andWhere('user.fcm_token IS NOT NULL');

    if (excludeUserId) {
      queryBuilder.andWhere('user.id != :excludeUserId', { excludeUserId });
    }

    if (projectId) {
      queryBuilder
        .andWhere((qb) => {
          const subQuery = qb
            .subQuery()
            .select('pm.user_id')
            .from('project_members', 'pm')
            .where('pm.project_id = :projectId')
            .getQuery();
          return `(user.role IN ('super_admin', 'admin') OR user.id IN ${subQuery})`;
        })
        .setParameter('projectId', projectId);
    }

    const users = await queryBuilder.select(['user.fcm_token']).getMany();
    return users.map((u) => u.fcm_token);
  }
}
