import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { randomUUID } from 'crypto';

import { AttendanceDocument, Attendance } from './entities/attendance.entity';
import { UserDocument, User } from '../users/entities/user.entity';
import { buildIdFilter, buildIdsFilter, toCleanObject, toCleanObjects } from '../common/mongo-id.util';

@Injectable()
export class AttendanceService {
  constructor(
    @InjectModel(Attendance.name)
    private attendanceRepository: Model<AttendanceDocument>,
    @InjectModel(User.name)
    private usersRepository: Model<UserDocument>,
  ) {}

  async createBulk(createDto: { siteAddress: string; projectId: string; records: any[] }, recorderId: string): Promise<void> {
    const formattedRecords = createDto.records.map(r => ({
      id: randomUUID(),
      contractor_name: r.contractor_name,
      labourers_count: r.labourers_count ?? 0,
      mistris_count: r.mistris_count ?? 0,
      maati_kata_count: r.maati_kata_count ?? 0,
      santras_count: r.santras_count ?? 0,
      work_description: r.work_description ?? null,
      site_address: createDto.siteAddress,
      project_id: createDto.projectId,
      recorded_by: recorderId,
      date: r.date ? new Date(r.date) : new Date(),
    }));

    await this.attendanceRepository.insertMany(formattedRecords);
  }

  async findAllByProject(
    projectId: string,
    range?: string,
    startDate?: string,
    endDate?: string,
    contractorName?: string,
  ): Promise<Attendance[]> {
    const filter: any = { project_id: projectId };

    if (contractorName) {
      filter.contractor_name = contractorName;
    }

    if (range && range !== 'all') {
      if (range === 'custom' && startDate && endDate) {
        filter.date = { $gte: new Date(startDate), $lte: new Date(endDate) };
      } else {
        const now = new Date();
        const ms = now.getTime();
        if (range === 'daily') {
          filter.date = { $gte: new Date(ms - 24 * 60 * 60 * 1000) };
        } else if (range === 'weekly') {
          filter.date = { $gte: new Date(ms - 7 * 24 * 60 * 60 * 1000) };
        } else if (range === 'monthly') {
          filter.date = { $gte: new Date(ms - 30 * 24 * 60 * 60 * 1000) };
        }
      }
    }

    const records = await this.attendanceRepository.find(filter).sort({ date: -1 }).lean().exec();

    if (!records.length) return [];

    const recorderIds = records.map(r => r.recorded_by).filter(Boolean);
    const users = await this.usersRepository
      .find(buildIdsFilter(recorderIds))
      .select('id name phone email')
      .lean()
      .exec();

    const userMap = new Map<string, any>();
    for (const u of users) {
      const cleanU = toCleanObject(u);
      userMap.set(cleanU.id, cleanU);
      if (u._id) userMap.set(u._id.toString(), cleanU);
    }

    return records.map(r => {
      const cleanR = toCleanObject<any>(r);
      cleanR.recorder = userMap.get(r.recorded_by) || null;
      return cleanR;
    });
  }

  async remove(id: string): Promise<void> {
    const result = await this.attendanceRepository.findOneAndDelete(buildIdFilter(id)).exec();
    if (!result) throw new NotFoundException('Attendance record not found');
  }
}
