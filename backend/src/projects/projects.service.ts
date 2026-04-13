import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Project } from './entities/project.entity';
import { ProjectMember } from './entities/project-member.entity';
import { ProjectImage } from './entities/project-image.entity';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ProjectsService {
  constructor(
    @InjectRepository(Project)
    private projectsRepository: Repository<Project>,
    @InjectRepository(ProjectMember)
    private membersRepository: Repository<ProjectMember>,
    @InjectRepository(ProjectImage)
    private imagesRepository: Repository<ProjectImage>,
    private readonly notificationsService: NotificationsService,
  ) {}

  async create(createProjectDto: any, userId: string): Promise<Project> {
    const project = this.projectsRepository.create();
    Object.assign(project, createProjectDto);
    project.createdBy = { id: userId } as any;
    const savedProject = await this.projectsRepository.save(project);
    
    // Fire and forget notification
    this.notificationsService.sendNotification(
      'New Project Added',
      `${savedProject.name || 'A new project'} has been added.`,
      ['super_admin', 'admin'],
      userId,
      { route: `/projects/${savedProject.id}` }
    );

    return savedProject;
  }

  // ── Project Listing (role-filtered) ─────────────────────────────
  async findAll(userId: string, role: string): Promise<Project[]> {
    // Admins see everything
    if (role === 'super_admin' || role === 'admin') {
      return this.projectsRepository.find({ order: { created_at: 'DESC' } });
    }

    // Non-admins only see projects they are assigned to
    const memberships = await this.membersRepository.find({
      where: { user: { id: userId } },
      relations: ['project'],
    });

    if (memberships.length === 0) return [];

    const projectIds = memberships.map(m => m.project.id);
    return this.projectsRepository.find({
      where: { id: In(projectIds) },
      order: { created_at: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Project> {
    const project = await this.projectsRepository.findOne({ where: { id } });
    if (!project) throw new NotFoundException('Project not found');
    return project;
  }

  async update(id: string, updateProjectDto: any): Promise<Project> {
    const project = await this.findOne(id);
    Object.assign(project, updateProjectDto);
    return this.projectsRepository.save(project);
  }

  async remove(id: string): Promise<void> {
    const result = await this.projectsRepository.delete(id);
    if (result.affected === 0) throw new NotFoundException();
  }

  // ── Project Member Management ───────────────────────────────────

  async addMember(projectId: string, userId: string, roleInProject: string = 'member') {
    // Check for existing assignment to avoid duplicate errors
    const existing = await this.membersRepository.findOne({
      where: { project: { id: projectId }, user: { id: userId } },
    });
    if (existing) {
      return existing; // Already assigned, no-op
    }

    const member = this.membersRepository.create({
      project: { id: projectId },
      user: { id: userId },
      role_in_project: roleInProject,
    });
    return this.membersRepository.save(member);
  }

  async removeMember(projectId: string, userId: string): Promise<void> {
    const result = await this.membersRepository.delete({
      project: { id: projectId },
      user: { id: userId },
    } as any);
    // Silently succeed even if nothing was deleted
  }

  async getMembers(projectId: string): Promise<ProjectMember[]> {
    return this.membersRepository.find({
      where: { project: { id: projectId } },
      relations: ['user'],
      order: { assigned_at: 'DESC' },
    });
  }

  /** Get all project IDs a specific user is assigned to. */
  async getProjectIdsForUser(userId: string): Promise<string[]> {
    const memberships = await this.membersRepository.find({
      where: { user: { id: userId } },
      relations: ['project'],
    });
    return memberships.map(m => m.project.id);
  }

  /** Assign a user to multiple projects at once (idempotent). */
  async setProjectsForUser(userId: string, projectIds: string[]): Promise<void> {
    // Get current assignments
    const current = await this.membersRepository.find({
      where: { user: { id: userId } },
      relations: ['project'],
    });
    const currentIds = new Set(current.map(m => m.project.id));
    const targetIds = new Set(projectIds);

    // Add new assignments
    for (const pid of targetIds) {
      if (!currentIds.has(pid)) {
        await this.addMember(pid, userId);
      }
    }

    // Remove revoked assignments
    for (const m of current) {
      if (!targetIds.has(m.project.id)) {
        await this.membersRepository.delete(m.id);
      }
    }
  }

  /** Assign ALL existing projects to a user (for migration). */
  async assignAllProjectsToUser(userId: string): Promise<number> {
    const allProjects = await this.projectsRepository.find({ select: ['id'] });
    let count = 0;
    for (const p of allProjects) {
      const existing = await this.membersRepository.findOne({
        where: { project: { id: p.id }, user: { id: userId } },
      });
      if (!existing) {
        await this.addMember(p.id, userId);
        count++;
      }
    }
    return count;
  }

  // ── Images ──────────────────────────────────────────────────────

  async addImage(projectId: string, userId: string, url: string, caption?: string) {
    const image = this.imagesRepository.create({
      url,
      caption,
      project: { id: projectId },
      uploadedBy: { id: userId },
    });
    const savedImage = await this.imagesRepository.save(image);

    this.notificationsService.sendNotification(
      'Progress Image Added',
      `A new image has been uploaded to the project.`,
      ['super_admin', 'admin', 'site_manager'],
      userId,
      { route: `/projects/${projectId}` },
      projectId
    );
    return savedImage;
  }

  async getImages(projectId: string): Promise<ProjectImage[]> {
    return this.imagesRepository.find({
      where: { project: { id: projectId } },
      relations: ['uploadedBy'],
      order: { date: 'DESC' },
    });
  }
}
