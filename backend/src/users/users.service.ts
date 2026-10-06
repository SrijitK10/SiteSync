import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from './entities/user.entity';

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

    const newUser = new this.userModel(userData);
    try {
      const savedUser = await newUser.save();
      // Map _id to id for backwards compatibility
      const result = savedUser.toObject();
      result.id = result._id.toString();
      return result;
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        throw this.uniqueViolationConflict(error);
      }
      throw error;
    }
  }

  async findAll(): Promise<User[]> {
    const users = await this.userModel.find().select('name phone email role created_at').exec();
    return users.map(u => {
      const obj = u.toObject();
      obj.id = obj._id.toString();
      return obj;
    });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userModel.findById(id).select('name phone email role created_at').exec();
    if (!user) throw new NotFoundException('User not found');
    const obj = user.toObject();
    obj.id = obj._id.toString();
    return obj;
  }

  async findByPhone(phone: string): Promise<User | null> {
    if (!phone) return null;

    const normalizedPhone = this.normalizePhone(phone);
    if (!normalizedPhone) return null;

    // Exact match first
    const exactMatch = await this.userModel.findOne({ phone: normalizedPhone }).exec();
    if (exactMatch) {
      const obj = exactMatch.toObject();
      obj.id = obj._id.toString();
      return obj;
    }

    // Fuzzy match based on last 10 digits
    const cleanPhone = normalizedPhone.replace(/\D/g, '');
    if (cleanPhone.length >= 10) {
      const last10 = cleanPhone.slice(-10);
      const fuzzyMatch = await this.userModel.findOne({ phone: { $regex: new RegExp(last10 + '$') } }).exec();
      if (fuzzyMatch) {
        const obj = fuzzyMatch.toObject();
        obj.id = obj._id.toString();
        return obj;
      }
    }

    return null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const user = await this.userModel.findOne({ email }).exec();
    if (!user) return null;
    const obj = user.toObject();
    obj.id = obj._id.toString();
    return obj;
  }

  async findByEmailWithPassword(email: string): Promise<User | null> {
    const user = await this.userModel.findOne({ email }).select('+password_hash').exec();
    if (!user) return null;
    const obj = user.toObject();
    obj.id = obj._id.toString();
    return obj;
  }

  async findByIdWithPassword(id: string): Promise<User | null> {
    const user = await this.userModel.findById(id).select('+password_hash').exec();
    if (!user) return null;
    const obj = user.toObject();
    obj.id = obj._id.toString();
    return obj;
  }

  async findByFirebaseUid(uid: string): Promise<User | null> {
    const user = await this.userModel.findOne({ firebase_uid: uid }).exec();
    if (!user) return null;
    const obj = user.toObject();
    obj.id = obj._id.toString();
    return obj;
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
      const updatedUser = await this.userModel.findByIdAndUpdate(id, updateData, { new: true }).exec();
      if (!updatedUser) throw new NotFoundException('User not found');
      const obj = updatedUser.toObject();
      obj.id = obj._id.toString();
      return obj;
    } catch (error) {
      if (this.isUniqueViolation(error)) {
        throw this.uniqueViolationConflict(error);
      }
      throw error;
    }
  }

  async updateFcmToken(id: string, fcm_token: string): Promise<User> {
    const user = await this.userModel.findByIdAndUpdate(id, { fcm_token }, { new: true }).exec();
    if (!user) throw new NotFoundException('User not found');
    const obj = user.toObject();
    obj.id = obj._id.toString();
    return obj;
  }

  async remove(id: string): Promise<void> {
    const result = await this.userModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException('User not found');
    }
  }

  async findTokensByRoles(
    roles: string[],
    excludeUserId?: string,
    projectId?: string,
  ): Promise<string[]> {
    // For Mongoose, we build the query filter
    const query: any = {
      role: { $in: roles },
      fcm_token: { $ne: null },
    };

    if (excludeUserId) {
      query._id = { $ne: excludeUserId };
    }
    
    // Note: ProjectMember check requires complex aggregation or a separate query
    // To maintain compatibility without injecting ProjectMemberModel here,
    // we fetch tokens for matching roles directly. If projectId is provided,
    // you might need a secondary check or to aggregate in another service.
    
    const users = await this.userModel.find(query).select('fcm_token').exec();
    return users.map(u => u.fcm_token);
  }
}
