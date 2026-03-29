import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Shift } from './entities/shift.entity';

@Injectable()
export class ShiftsService {
  constructor(
    @InjectRepository(Shift)
    private shiftsRepository: Repository<Shift>,
  ) {}

  async create(createShiftDto: any): Promise<Shift> {
    const shift = this.shiftsRepository.create();
    Object.assign(shift, createShiftDto);
    shift.user = { id: createShiftDto.userId } as any;
    shift.project = { id: createShiftDto.projectId } as any;
    return this.shiftsRepository.save(shift);
  }

  async findAllByUser(userId: string): Promise<Shift[]> {
    return this.shiftsRepository.find({
      where: { user: { id: userId } },
      relations: ['project'],
      order: { start_time: 'ASC' },
    });
  }

  async findAllByProject(projectId: string): Promise<Shift[]> {
    return this.shiftsRepository.find({
      where: { project: { id: projectId } },
      relations: ['user'],
      order: { start_time: 'ASC' },
    });
  }

  async findOne(id: string): Promise<Shift> {
    const shift = await this.shiftsRepository.findOne({ where: { id }, relations: ['user', 'project'] });
    if (!shift) throw new NotFoundException('Shift not found');
    return shift;
  }

  async update(id: string, updateShiftDto: any): Promise<Shift> {
    const shift = await this.findOne(id);
    Object.assign(shift, updateShiftDto);
    return this.shiftsRepository.save(shift);
  }

  async remove(id: string): Promise<void> {
    const result = await this.shiftsRepository.delete(id);
    if (result.affected === 0) throw new NotFoundException();
  }
}
