import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { randomUUID } from 'crypto';
import { ContractorDocument, Contractor } from './entities/contractor.entity';
import { buildIdFilter, toCleanObject, toCleanObjects } from '../common/mongo-id.util';

@Injectable()
export class ContractorsService {
  constructor(
    @InjectModel(Contractor.name)
    private contractorsRepo: Model<ContractorDocument>,
  ) {}

  async create(name: string): Promise<Contractor> {
    const contractor = new this.contractorsRepo({
      id: randomUUID(),
      name,
    });
    const saved = await contractor.save();
    return toCleanObject<Contractor>(saved);
  }

  async findAll(): Promise<Contractor[]> {
    const contractors = await this.contractorsRepo.find().sort({ name: 1 }).lean().exec();
    return toCleanObjects<Contractor>(contractors);
  }

  async remove(id: string): Promise<void> {
    const result = await this.contractorsRepo.findOneAndDelete(buildIdFilter(id)).exec();
    if (!result) throw new NotFoundException('Contractor not found');
  }
}
