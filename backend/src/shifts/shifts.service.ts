import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ShiftDocument,  Shift } from './entities/shift.entity';

@Injectable()
export class ShiftsService {
  constructor(
    @InjectModel(Shift.name)
    private shiftsRepository: Model<ShiftDocument>,
  ) {}

  async create(createShiftDto: any): Promise<Shift> {
    const shift = new this.shiftsRepository();
    Object.assign(shift, createShiftDto);
    shift.user = { id: createShiftDto.userId } as any;
    shift.project = { id: createShiftDto.projectId } as any;
    return new this.shiftsRepository(shift).save() as any;
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
    return new this.shiftsRepository(shift).save() as any;
  }

  async remove(id: string): Promise<void> {
    const result = await this.shiftsRepository.findByIdAndDelete(id);
    if (!result) throw new NotFoundException();
  }
}
