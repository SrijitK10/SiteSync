import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { AttendanceDocument,  Attendance } from './entities/attendance.entity';

@Injectable()
export class AttendanceService {
  constructor(
    @InjectModel(Attendance.name)
    private attendanceRepository: Model<AttendanceDocument>,
  ) {}

  async createBulk(createDto: { siteAddress: string, projectId: string, records: any[] }, recorderId: string): Promise<void> {
    const formattedRecords = createDto.records.map(r => ({
      contractor_name: r.contractor_name,
      labourers_count: r.labourers_count ?? 0,
      mistris_count: r.mistris_count ?? 0,
      maati_kata_count: r.maati_kata_count ?? 0,
      santras_count: r.santras_count ?? 0,
      work_description: r.work_description ?? null,
      site_address: createDto.siteAddress,
      project: { id: createDto.projectId } as any,
      recorder: { id: recorderId } as any,
    }));
    
    await this.attendanceRepository.insertMany(formattedRecords);
  }

  async findAllByProject(projectId: string, range?: string, startDate?: string, endDate?: string, contractorName?: string): Promise<Attendance[]> {
    const whereClause: any = { project: { id: projectId } };
    
    if (contractorName) {
      whereClause.contractor_name = contractorName;
    }

    if (range && range !== 'all') {
      if (range === 'custom' && startDate && endDate) {
        whereClause.date = { $gte: startDate, $lte: endDate };
      } else {
        const now = new Date();
        const ms = now.getTime();
        if (range === 'daily') {
          whereClause.date = { $gte: new Date(ms - 24 * 60 * 60 * 1000 ).toISOString().split('T')[0] };
        } else if (range === 'weekly') {
          whereClause.date = { $gte: new Date(ms - 7 * 24 * 60 * 60 * 1000 ).toISOString().split('T')[0] };
        } else if (range === 'monthly') {
          whereClause.date = { $gte: new Date(ms - 30 * 24 * 60 * 60 * 1000 ).toISOString().split('T')[0] };
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
    const result = await this.attendanceRepository.findByIdAndDelete(id);
    if (!result) throw new NotFoundException('Attendance record not found');
  }
}
