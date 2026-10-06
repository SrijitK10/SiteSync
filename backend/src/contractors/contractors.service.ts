import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ContractorDocument,  Contractor } from './entities/contractor.entity';

@Injectable()
export class ContractorsService {
  constructor(
    @InjectModel(Contractor.name)
    private contractorsRepo: Model<ContractorDocument>,
  ) {}

  async create(name: string): Promise<Contractor> {
    const contractor = new this.contractorsRepo({ name });
    return new this.contractorsRepo(contractor).save() as any;
  }

  async findAll(): Promise<Contractor[]> {
    return this.contractorsRepo.find({ order: { name: 'ASC' } });
  }

  async remove(id: string): Promise<void> {
    const result = await this.contractorsRepo.findByIdAndDelete(id);
    if (!result) throw new NotFoundException('Contractor not found');
  }
}
