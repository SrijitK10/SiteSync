import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { FlatDocument,  Flat } from './entities/flat.entity';

@Injectable()
export class FlatsService {
  constructor(
    @InjectModel(Flat.name)
    private flatsRepo: Model<FlatDocument>,
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

    const flat = new this.flatsRepo({
      flat_number: trimmed,
      project: { id: projectId } as any,
    });
    return new this.flatsRepo(flat).save() as any;
  }

  async toggleCompleted(id: string, isCompleted: boolean): Promise<Flat> {
    const flat = await this.flatsRepo.findOne({ where: { id } });
    if (!flat) throw new NotFoundException('Flat not found');
    flat.is_completed = isCompleted;
    return new this.flatsRepo(flat).save() as any;
  }

  async remove(id: string): Promise<void> {
    const result = await this.flatsRepo.findByIdAndDelete(id);
    if (!result) throw new NotFoundException('Flat not found');
  }
}
