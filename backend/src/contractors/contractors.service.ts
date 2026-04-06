import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Contractor } from './entities/contractor.entity';

@Injectable()
export class ContractorsService {
  constructor(
    @InjectRepository(Contractor)
    private contractorsRepo: Repository<Contractor>,
  ) {}

  async create(name: string): Promise<Contractor> {
    const contractor = this.contractorsRepo.create({ name });
    return this.contractorsRepo.save(contractor);
  }

  async findAll(): Promise<Contractor[]> {
    return this.contractorsRepo.find({ order: { name: 'ASC' } });
  }

  async remove(id: string): Promise<void> {
    const result = await this.contractorsRepo.delete(id);
    if (result.affected === 0) throw new NotFoundException('Contractor not found');
  }
}
