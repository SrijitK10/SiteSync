import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { randomUUID } from 'crypto';

import { ProjectDocument, Project } from './entities/project.entity';
import { ProjectMemberDocument, ProjectMember } from './entities/project-member.entity';
import { ProjectImageDocument, ProjectImage } from './entities/project-image.entity';
import { UserDocument, User } from '../users/entities/user.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { buildIdFilter, buildIdsFilter, toCleanObject, toCleanObjects } from '../common/mongo-id.util';

@Injectable()
export class ProjectsService {
  constructor(
    @InjectModel(Project.name)
    private projectsRepository: Model<ProjectDocument>,
    @InjectModel(ProjectMember.name)
    private membersRepository: Model<ProjectMemberDocument>,
    @InjectModel(ProjectImage.name)
    private imagesRepository: Model<ProjectImageDocument>,
    @InjectModel(User.name)
    private usersRepository: Model<UserDocument>,
    private readonly notificationsService: NotificationsService,
  ) {}

  async create(createProjectDto: any, userId: string): Promise<Project> {
    const projectId = randomUUID();
    const project = new this.projectsRepository({
      ...createProjectDto,
      id: projectId,
      created_by: userId,
    });
    const savedProject = await project.save();
    const result = toCleanObject<Project>(savedProject);

    // Fire and forget notification
    this.notificationsService.sendNotification(
      'New Project Added',
      `${result.name || 'A new project'} has been added.`,
      ['super_admin', 'admin'],
      userId,
      { route: `/projects/${result.id}` },
    );

    return result;
  }

  // ── Project Listing (role-filtered) ─────────────────────────────
  async findAll(userId: string, role: string): Promise<Project[]> {
    // Admins see everything
    if (role === 'super_admin' || role === 'admin') {
      const projects = await this.projectsRepository.find().sort({ created_at: -1 }).lean().exec();
      return toCleanObjects<Project>(projects);
    }

    // Non-admins only see projects they are assigned to
    const userFilter = buildIdFilter(userId);
    const userIdConditions: any[] = [{ user_id: userId }];
    if (userFilter.$or && userFilter.$or[1]?._id) {
      userIdConditions.push({ user_id: userFilter.$or[1]._id.toString() });
    }

    const memberships = await this.membersRepository
      .find({ $or: userIdConditions })
      .lean()
      .exec();

    if (!memberships || memberships.length === 0) return [];

    const projectIds = memberships.map(m => m.project_id).filter(Boolean);
    if (projectIds.length === 0) return [];

    const projects = await this.projectsRepository
      .find(buildIdsFilter(projectIds))
      .sort({ created_at: -1 })
      .lean()
      .exec();

    return toCleanObjects<Project>(projects);
  }

  async findOne(id: string): Promise<Project> {
    const project = await this.projectsRepository.findOne(buildIdFilter(id)).lean().exec();
    if (!project) throw new NotFoundException('Project not found');
    return toCleanObject<Project>(project);
  }

  async update(id: string, updateProjectDto: any): Promise<Project> {
    const project = await this.projectsRepository
      .findOneAndUpdate(
        buildIdFilter(id),
        { $set: updateProjectDto },
        { returnDocument: 'after' },
      )
      .lean()
      .exec();
    if (!project) throw new NotFoundException('Project not found');
    return toCleanObject<Project>(project);
  }

  async remove(id: string): Promise<void> {
    const result = await this.projectsRepository.findOneAndDelete(buildIdFilter(id)).exec();
    if (!result) throw new NotFoundException('Project not found');
  }

  // ── Project Member Management ───────────────────────────────────

  async addMember(projectId: string, userId: string, roleInProject: string = 'member') {
    // Check for existing assignment to avoid duplicate errors
    const existing = await this.membersRepository
      .findOne({ project_id: projectId, user_id: userId })
      .lean()
      .exec();
    if (existing) {
      return toCleanObject(existing);
    }

    const member = new this.membersRepository({
      id: randomUUID(),
      project_id: projectId,
      user_id: userId,
      role_in_project: roleInProject,
      assigned_at: new Date(),
    });
    const saved = await member.save();
    return toCleanObject(saved);
  }

  async removeMember(projectId: string, userId: string): Promise<void> {
    await this.membersRepository
      .findOneAndDelete({ project_id: projectId, user_id: userId })
      .exec();
  }

  async getMembers(projectId: string): Promise<ProjectMember[]> {
    const members = await this.membersRepository
      .find({ project_id: projectId })
      .sort({ assigned_at: -1 })
      .lean()
      .exec();

    if (!members.length) return [];

    const userIds = members.map(m => m.user_id).filter(Boolean);
    const users = await this.usersRepository
      .find(buildIdsFilter(userIds))
      .select('id name phone email role')
      .lean()
      .exec();

    const userMap = new Map<string, any>();
    for (const u of users) {
      const cleanU = toCleanObject(u);
      userMap.set(cleanU.id, cleanU);
      if (u._id) userMap.set(u._id.toString(), cleanU);
    }

    return members.map(m => {
      const cleanM = toCleanObject<any>(m);
      cleanM.user = userMap.get(m.user_id) || { id: m.user_id, name: 'Unknown User' };
      return cleanM;
    });
  }

  /** Get all project IDs a specific user is assigned to. */
  async getProjectIdsForUser(userId: string): Promise<string[]> {
    const userFilter = buildIdFilter(userId);
    const userIdConditions: any[] = [{ user_id: userId }];
    if (userFilter.$or && userFilter.$or[1]?._id) {
      userIdConditions.push({ user_id: userFilter.$or[1]._id.toString() });
    }

    const memberships = await this.membersRepository
      .find({ $or: userIdConditions })
      .lean()
      .exec();

    return memberships.map(m => m.project_id).filter(Boolean);
  }

  /** Assign a user to multiple projects at once (idempotent). */
  async setProjectsForUser(userId: string, projectIds: string[]): Promise<void> {
    const current = await this.membersRepository.find({ user_id: userId }).lean().exec();
    const currentIds = new Set(current.map(m => m.project_id));
    const targetIds = new Set(projectIds);

    // Add new assignments
    for (const pid of targetIds) {
      if (!currentIds.has(pid)) {
        await this.addMember(pid, userId);
      }
    }

    // Remove revoked assignments
    for (const m of current) {
      if (!targetIds.has(m.project_id)) {
        await this.membersRepository.findOneAndDelete(buildIdFilter(m.id || m._id?.toString())).exec();
      }
    }
  }

  /** Assign ALL existing projects to a user (for migration). */
  async assignAllProjectsToUser(userId: string): Promise<number> {
    const allProjects = await this.projectsRepository.find().select('id').lean().exec();
    let count = 0;
    for (const p of allProjects) {
      const pId = p.id || p._id?.toString();
      const existing = await this.membersRepository.findOne({ project_id: pId, user_id: userId }).exec();
      if (!existing) {
        await this.addMember(pId, userId);
        count++;
      }
    }
    return count;
  }

  // ── Images ──────────────────────────────────────────────────────

  async addImage(projectId: string, userId: string, url: string, caption?: string) {
    const image = new this.imagesRepository({
      id: randomUUID(),
      url,
      caption: caption || null,
      project_id: projectId,
      uploaded_by: userId,
      date: new Date(),
    });
    const savedImage = await image.save();
    const result = toCleanObject<ProjectImage>(savedImage);

    this.notificationsService.sendNotification(
      'Progress Image Added',
      `A new image has been uploaded to the project.`,
      ['super_admin', 'admin', 'site_manager'],
      userId,
      { route: `/projects/${projectId}` },
      projectId,
    );
    return result;
  }

  async getImages(projectId: string): Promise<ProjectImage[]> {
    const images = await this.imagesRepository
      .find({ project_id: projectId })
      .sort({ date: -1 })
      .lean()
      .exec();

    if (!images.length) return [];

    const userIds = images.map(img => img.uploaded_by).filter(Boolean);
    const users = await this.usersRepository
      .find(buildIdsFilter(userIds))
      .select('id name phone email')
      .lean()
      .exec();

    const userMap = new Map<string, any>();
    for (const u of users) {
      const cleanU = toCleanObject(u);
      userMap.set(cleanU.id, cleanU);
      if (u._id) userMap.set(u._id.toString(), cleanU);
    }

    return images.map(img => {
      const cleanImg = toCleanObject<any>(img);
      cleanImg.uploadedBy = userMap.get(img.uploaded_by) || null;
      return cleanImg;
    });
  }
}
