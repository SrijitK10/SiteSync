import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
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
      ['super_admin', 'admin', 'site_manager'],
      userId,
      { route: `/project/${savedProject.id}` } // Adjusted path based on what deep linking might use
    );

    return savedProject;
  }

  async findAll(userId: string, role: string): Promise<Project[]> {
    return this.projectsRepository.find();
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

  async addMember(projectId: string, userId: string, roleInProject: string) {
    const member = this.membersRepository.create({
      project: { id: projectId },
      user: { id: userId },
      role_in_project: roleInProject,
    });
    return this.membersRepository.save(member);
  }

  async addImage(projectId: string, userId: string, url: string, caption?: string) {
    const image = this.imagesRepository.create({
      url,
      caption,
      project: { id: projectId },
      uploadedBy: { id: userId },
    });
    const savedImage = await this.imagesRepository.save(image);

    // Fire and forget notification
    this.notificationsService.sendNotification(
      'Progress Image Added',
      `A new image has been uploaded to the project.`,
      ['super_admin', 'admin', 'site_manager'],
      userId,
      { route: `/project/${projectId}` } // Adjusted path
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
