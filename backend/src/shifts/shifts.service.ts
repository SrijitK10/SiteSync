import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { randomUUID } from 'crypto';

import { ShiftDocument, Shift } from './entities/shift.entity';
import { UserDocument, User } from '../users/entities/user.entity';
import { ProjectDocument, Project } from '../projects/entities/project.entity';
import { buildIdFilter, buildIdsFilter, toCleanObject, toCleanObjects } from '../common/mongo-id.util';

@Injectable()
export class ShiftsService {
  constructor(
    @InjectModel(Shift.name)
    private shiftsRepository: Model<ShiftDocument>,
    @InjectModel(User.name)
    private usersRepository: Model<UserDocument>,
    @InjectModel(Project.name)
    private projectsRepository: Model<ProjectDocument>,
  ) {}

  private async populateShifts(shifts: any[]): Promise<any[]> {
    if (!shifts || !shifts.length) return [];

    const userIds = new Set<string>();
    const projectIds = new Set<string>();

    for (const s of shifts) {
      if (s.user_id) userIds.add(s.user_id);
      if (s.project_id) projectIds.add(s.project_id);
    }

    const [users, projects] = await Promise.all([
      userIds.size > 0
        ? this.usersRepository.find(buildIdsFilter(Array.from(userIds))).select('id name phone email role').lean().exec()
        : [],
      projectIds.size > 0
        ? this.projectsRepository.find(buildIdsFilter(Array.from(projectIds))).select('id name location').lean().exec()
        : [],
    ]);

    const userMap = new Map<string, any>();
    for (const u of users) {
      const cleanU = toCleanObject(u);
      userMap.set(cleanU.id, cleanU);
      if (u._id) userMap.set(u._id.toString(), cleanU);
    }

    const projectMap = new Map<string, any>();
    for (const p of projects) {
      const cleanP = toCleanObject(p);
      projectMap.set(cleanP.id, cleanP);
      if (p._id) projectMap.set(p._id.toString(), cleanP);
    }

    return shifts.map(s => {
      const cleanS = toCleanObject<any>(s);
      cleanS.user = userMap.get(s.user_id) || (s.user_id ? { id: s.user_id, name: 'Unknown User' } : null);
      cleanS.project = projectMap.get(s.project_id) || (s.project_id ? { id: s.project_id, name: '' } : null);
      return cleanS;
    });
  }

  async create(createShiftDto: any): Promise<Shift> {
    const shift = new this.shiftsRepository({
      id: randomUUID(),
      user_id: createShiftDto.userId || createShiftDto.user?.id,
      project_id: createShiftDto.projectId || createShiftDto.project?.id,
      start_time: createShiftDto.start_time || createShiftDto.startTime || new Date(),
      end_time: createShiftDto.end_time || createShiftDto.endTime || null,
      notes: createShiftDto.notes || null,
    });
    const saved = await shift.save();
    const [populated] = await this.populateShifts([saved]);
    return populated;
  }

  async findAllByUser(userId: string): Promise<Shift[]> {
    const userFilter = buildIdFilter(userId);
    const userIdConditions: any[] = [{ user_id: userId }];
    if (userFilter.$or && userFilter.$or[1]?._id) {
      userIdConditions.push({ user_id: userFilter.$or[1]._id.toString() });
    }

    const shifts = await this.shiftsRepository
      .find({ $or: userIdConditions })
      .sort({ start_time: 1 })
      .lean()
      .exec();

    return this.populateShifts(shifts);
  }

  async findAllByProject(projectId: string): Promise<Shift[]> {
    const shifts = await this.shiftsRepository
      .find({ project_id: projectId })
      .sort({ start_time: 1 })
      .lean()
      .exec();

    return this.populateShifts(shifts);
  }

  async findOne(id: string): Promise<Shift> {
    const shift = await this.shiftsRepository.findOne(buildIdFilter(id)).lean().exec();
    if (!shift) throw new NotFoundException('Shift not found');
    const [populated] = await this.populateShifts([shift]);
    return populated;
  }

  async update(id: string, updateShiftDto: any): Promise<Shift> {
    const updateFields: any = { ...updateShiftDto };
    if (updateShiftDto.userId) {
      updateFields.user_id = updateShiftDto.userId;
      delete updateFields.userId;
    }
    if (updateShiftDto.projectId) {
      updateFields.project_id = updateShiftDto.projectId;
      delete updateFields.projectId;
    }

    const updated = await this.shiftsRepository
      .findOneAndUpdate(
        buildIdFilter(id),
        { $set: updateFields },
        { returnDocument: 'after' },
      )
      .lean()
      .exec();

    if (!updated) throw new NotFoundException('Shift not found');
    const [populated] = await this.populateShifts([updated]);
    return populated;
  }

  async remove(id: string): Promise<void> {
    const result = await this.shiftsRepository.findOneAndDelete(buildIdFilter(id)).exec();
    if (!result) throw new NotFoundException('Shift not found');
  }
}
