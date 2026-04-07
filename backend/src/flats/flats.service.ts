import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Flat } from './entities/flat.entity';

@Injectable()
export class FlatsService {
  constructor(
    @InjectRepository(Flat)
    private flatsRepo: Repository<Flat>,
  ) {}

  async findAllByProject(projectId: string): Promise<Flat[]> {
    return this.flatsRepo.find({
      where: { project: { id: projectId } },
      order: { flat_number: 'ASC' },
    });
  }

  async create(projectId: string, flatNumber: string): Promise<Flat> {
    const trimmed = (flatNumber || '').trim();
    if (!trimmed) throw new ConflictException('Flat number is required');

    const existing = await this.flatsRepo.findOne({
      where: { project: { id: projectId }, flat_number: trimmed },
    });
    if (existing) throw new ConflictException('Flat already exists in this project');

    const flat = this.flatsRepo.create({
      flat_number: trimmed,
      project: { id: projectId } as any,
    });
    return this.flatsRepo.save(flat);
  }

  async toggleCompleted(id: string, isCompleted: boolean): Promise<Flat> {
    const flat = await this.flatsRepo.findOne({ where: { id } });
    if (!flat) throw new NotFoundException('Flat not found');
    flat.is_completed = isCompleted;
    return this.flatsRepo.save(flat);
  }

  async remove(id: string): Promise<void> {
    const result = await this.flatsRepo.delete(id);
    if (result.affected === 0) throw new NotFoundException('Flat not found');
  }
}
