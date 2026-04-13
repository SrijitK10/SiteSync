import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async create(userData: Partial<User>): Promise<User> {
    if (userData.phone) {
      userData.phone = userData.phone.replace(/[^\d+]/g, ''); // Normalize by keeping only digits and +

      const existing = await this.findByPhone(userData.phone);
      if (existing) {
        throw new ConflictException('Phone number already registered');
      }
    }
    if (userData.email) {
      const existing = await this.usersRepository.findOne({ where: { email: userData.email } });
      if (existing) {
        throw new ConflictException('Email already registered');
      }
    }

    const newUser = this.usersRepository.create(userData);
    return this.usersRepository.save(newUser);
  }

  async findAll(): Promise<User[]> {
    return this.usersRepository.find({ select: ['id', 'name', 'phone', 'email', 'role', 'created_at'] });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id }, select: ['id', 'name', 'phone', 'email', 'role', 'created_at'] });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async findByPhone(phone: string): Promise<User | null> {
    if (!phone) return null;

    // Exact match first
    const exactMatch = await this.usersRepository.findOne({ where: { phone } });
    if (exactMatch) return exactMatch;

    // Fuzzy match based on last 10 digits
    const cleanPhone = phone.replace(/\D/g, '');
    if (cleanPhone.length >= 10) {
      const last10 = cleanPhone.slice(-10);
      // Use REPLACE to strip common non-digit characters in DB for matching existing non-normalized rows
      const fuzzyMatch = await this.usersRepository.createQueryBuilder('user')
        .where("REPLACE(REPLACE(REPLACE(user.phone, ' ', ''), '-', ''), '+', '') LIKE :likePhone", { likePhone: `%${last10}` })
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
      select: ['id', 'name', 'phone', 'email', 'role', 'password_hash', 'firebase_uid'],
    });
  }

  async findByIdWithPassword(id: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { id },
      select: ['id', 'name', 'phone', 'email', 'role', 'password_hash', 'firebase_uid'],
    });
  }

  async findByFirebaseUid(uid: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { firebase_uid: uid } });
  }

  async update(id: string, updateData: Partial<User>): Promise<User> {
    const user = await this.findOne(id);
    Object.assign(user, updateData);
    return this.usersRepository.save(user);
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

  async findTokensByRoles(roles: string[], excludeUserId?: string): Promise<string[]> {
    const queryBuilder = this.usersRepository.createQueryBuilder('user')
      .where('user.role IN (:...roles)', { roles })
      .andWhere('user.fcm_token IS NOT NULL');

    if (excludeUserId) {
      queryBuilder.andWhere('user.id != :excludeUserId', { excludeUserId });
    }

    const users = await queryBuilder.select(['user.fcm_token']).getMany();
    return users.map(u => u.fcm_token);
  }
}
