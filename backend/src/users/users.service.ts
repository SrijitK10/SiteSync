import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { randomUUID } from 'crypto';
import { User, UserDocument } from './entities/user.entity';
import { buildIdFilter, toCleanObject, toCleanObjects } from '../common/mongo-id.util';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name)
    private userModel: Model<UserDocument>,
  ) {}

  private isUniqueViolation(error: unknown): boolean {
    return (error as { code?: number })?.code === 11000;
  }

  private uniqueViolationConflict(error: unknown): ConflictException {
    const detail = String((error as { message?: string })?.message || '');
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
      const existing = await this.userModel.findOne({ email: userData.email });
      if (existing) {
        throw new ConflictException('Email already registered');
      }
    }

    const userToSave = {
      ...userData,
      id: userData.id || randomUUID(),
    };

    const newUser = new this.userModel(userToSave);
    try {
      const savedUser = await newUser.save();
      return toCleanObject<User>(savedUser);
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        throw this.uniqueViolationConflict(error);
      }
      throw error;
    }
  }

  async findAll(): Promise<User[]> {
    const users = await this.userModel
      .find()
      .select('id name phone email role created_at')
      .sort({ name: 1 })
      .lean()
      .exec();
    return toCleanObjects<User>(users);
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userModel
      .findOne(buildIdFilter(id))
      .select('id name phone email role created_at')
      .lean()
      .exec();
    if (!user) throw new NotFoundException('User not found');
    return toCleanObject<User>(user);
  }

  async findByPhone(phone: string): Promise<User | null> {
    if (!phone) return null;

    const normalizedPhone = this.normalizePhone(phone);
    if (!normalizedPhone) return null;

    // Exact match first
    const exactMatch = await this.userModel.findOne({ phone: normalizedPhone }).lean().exec();
    if (exactMatch) {
      return toCleanObject<User>(exactMatch);
    }

    // Fuzzy match based on last 10 digits
    const cleanPhone = normalizedPhone.replace(/\D/g, '');
    if (cleanPhone.length >= 10) {
      const last10 = cleanPhone.slice(-10);
      const fuzzyMatch = await this.userModel
        .findOne({ phone: { $regex: new RegExp(last10 + '$') } })
        .lean()
        .exec();
      if (fuzzyMatch) {
        return toCleanObject<User>(fuzzyMatch);
      }
    }

    return null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const user = await this.userModel.findOne({ email }).lean().exec();
    if (!user) return null;
    return toCleanObject<User>(user);
  }

  async findByEmailWithPassword(email: string): Promise<User | null> {
    const user = await this.userModel.findOne({ email }).select('+password_hash').lean().exec();
    if (!user) return null;
    return toCleanObject<User>(user);
  }

  async findByIdWithPassword(id: string): Promise<User | null> {
    const user = await this.userModel.findOne(buildIdFilter(id)).select('+password_hash').lean().exec();
    if (!user) return null;
    return toCleanObject<User>(user);
  }

  async findByFirebaseUid(uid: string): Promise<User | null> {
    const user = await this.userModel.findOne({ firebase_uid: uid }).lean().exec();
    if (!user) return null;
    return toCleanObject<User>(user);
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

    try {
      const updatedUser = await this.userModel
        .findOneAndUpdate(
          buildIdFilter(id),
          { $set: updateData },
          { returnDocument: 'after' },
        )
        .lean()
        .exec();
      if (!updatedUser) throw new NotFoundException('User not found');
      return toCleanObject<User>(updatedUser);
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        throw this.uniqueViolationConflict(error);
      }
      throw error;
    }
  }

  async updateFcmToken(id: string, fcm_token: string): Promise<User> {
    const user = await this.userModel
      .findOneAndUpdate(
        buildIdFilter(id),
        { $set: { fcm_token } },
        { returnDocument: 'after' },
      )
      .lean()
      .exec();
    if (!user) throw new NotFoundException('User not found');
    return toCleanObject<User>(user);
  }

  async remove(id: string): Promise<void> {
    const result = await this.userModel.findOneAndDelete(buildIdFilter(id)).exec();
    if (!result) {
      throw new NotFoundException('User not found');
    }
  }

  async findTokensByRoles(
    roles: string[],
    excludeUserId?: string,
    projectId?: string,
  ): Promise<string[]> {
    const query: any = {
      role: { $in: roles },
      fcm_token: { $ne: null },
    };

    if (excludeUserId) {
      query.id = { $ne: excludeUserId };
      if (Types.ObjectId.isValid(excludeUserId)) {
        query._id = { $ne: new Types.ObjectId(excludeUserId) };
      }
    }

    const users = await this.userModel.find(query).select('fcm_token').lean().exec();
    return users.map(u => u.fcm_token).filter(Boolean);
  }
}
