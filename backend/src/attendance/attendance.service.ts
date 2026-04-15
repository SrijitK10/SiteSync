import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThanOrEqual, Between } from 'typeorm';
import { Attendance } from './entities/attendance.entity';

@Injectable()
export class AttendanceService {
  constructor(
    @InjectRepository(Attendance)
    private attendanceRepository: Repository<Attendance>,
  ) {}

  async createBulk(createDto: { siteAddress: string, projectId: string, records: any[] }, recorderId: string): Promise<void> {
    const formattedRecords = createDto.records.map(r => ({
      contractor_name: r.contractor_name,
      labourers_count: r.labourers_count ?? 0,
      mistris_count: r.mistris_count ?? 0,
      work_description: r.work_description ?? null,
      site_address: createDto.siteAddress,
      project: { id: createDto.projectId } as any,
      recorder: { id: recorderId } as any,
    }));
    
    await this.attendanceRepository.insert(formattedRecords);
  }

  async findAllByProject(projectId: string, range?: string, startDate?: string, endDate?: string): Promise<Attendance[]> {
    const whereClause: any = { project: { id: projectId } };
    
    if (range) {
      if (range === 'custom' && startDate && endDate) {
        whereClause.date = Between(startDate, endDate);
      } else {
        const now = new Date();
        const ms = now.getTime();
        if (range === 'daily') {
          whereClause.date = MoreThanOrEqual(new Date(ms - 24 * 60 * 60 * 1000).toISOString().split('T')[0]);
        } else if (range === 'weekly') {
          whereClause.date = MoreThanOrEqual(new Date(ms - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]);
        } else if (range === 'monthly') {
          whereClause.date = MoreThanOrEqual(new Date(ms - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]);
        }
      }
    }

    return this.attendanceRepository.find({
      where: whereClause,
      relations: ['recorder'],
      order: { date: 'DESC' },
    });
  }

  async remove(id: string): Promise<void> {
    const result = await this.attendanceRepository.delete(id);
    if (result.affected === 0) throw new NotFoundException('Attendance record not found');
  }
}
