import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { randomUUID } from 'crypto';
import { FlatDocument, Flat } from './entities/flat.entity';
import { buildIdFilter, toCleanObject, toCleanObjects } from '../common/mongo-id.util';

@Injectable()
export class FlatsService {
  constructor(
    @InjectModel(Flat.name)
    private flatsRepo: Model<FlatDocument>,
  ) {}

  async findAllByProject(projectId: string): Promise<Flat[]> {
    const flats = await this.flatsRepo
      .find({ project_id: projectId })
      .sort({ flat_number: 1 })
      .lean()
      .exec();
    return toCleanObjects<Flat>(flats);
  }

  async create(projectId: string, flatNumber: string): Promise<Flat> {
    const trimmed = (flatNumber || '').trim();
    if (!trimmed) throw new ConflictException('Flat number is required');

    const existing = await this.flatsRepo.findOne({
      project_id: projectId,
      flat_number: trimmed,
    }).lean().exec();

    if (existing) throw new ConflictException('Flat already exists in this project');

    const flat = new this.flatsRepo({
      id: randomUUID(),
      flat_number: trimmed,
      project_id: projectId,
      is_completed: false,
    });
    const saved = await flat.save();
    return toCleanObject<Flat>(saved);
  }

  async toggleCompleted(id: string, isCompleted: boolean): Promise<Flat> {
    const flat = await this.flatsRepo
      .findOneAndUpdate(
        buildIdFilter(id),
        { $set: { is_completed: isCompleted } },
        { returnDocument: 'after' },
      )
      .lean()
      .exec();

    if (!flat) throw new NotFoundException('Flat not found');
    return toCleanObject<Flat>(flat);
  }

  async remove(id: string): Promise<void> {
    const result = await this.flatsRepo.findOneAndDelete(buildIdFilter(id)).exec();
    if (!result) throw new NotFoundException('Flat not found');
  }
}
