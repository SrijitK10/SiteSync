import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async create(userData: Partial<User>): Promise<User> {
    const existing = await this.usersRepository.findOne({ where: { email: userData.email } });
    if (existing) {
      throw new ConflictException('Email already exists');
    }

    if (userData.password_hash) {
      const salt = await bcrypt.genSalt(10);
      userData.password_hash = await bcrypt.hash(userData.password_hash, salt);
    }

    const newUser = this.usersRepository.create(userData);
    return this.usersRepository.save(newUser);
  }

  async findAll(): Promise<User[]> {
    // Purposefully omitting password_hash visually
    return this.usersRepository.find({ select: ['id', 'name', 'email', 'role', 'created_at'] });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id }, select: ['id', 'name', 'email', 'role', 'created_at'] });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async findByEmailForAuth(email: string): Promise<User | null> {
    // This strictly pulls the password_hash needed for auth validators
    return this.usersRepository.findOne({ where: { email } });
  }

  async update(id: string, updateData: Partial<User>): Promise<User> {
    const user = await this.findOne(id);
    if (updateData.password_hash) {
      const salt = await bcrypt.genSalt(10);
      updateData.password_hash = await bcrypt.hash(updateData.password_hash, salt);
    }
    Object.assign(user, updateData);
    return this.usersRepository.save(user);
  }

  async remove(id: string): Promise<void> {
    const result = await this.usersRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('User not found');
    }
  }
}
