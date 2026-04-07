import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThanOrEqual, Between } from 'typeorm';
import { Task } from './entities/task.entity';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(Task)
    private tasksRepository: Repository<Task>,
    private readonly notificationsService: NotificationsService,
  ) {}

  async create(createTaskDto: any, userId?: string): Promise<Task> {
    const task = this.tasksRepository.create();
    Object.assign(task, createTaskDto);
    task.project = { id: createTaskDto.projectId } as any;
    if (createTaskDto.flatId) {
      task.flat = { id: createTaskDto.flatId } as any;
    }
    if (createTaskDto.userId) {
      task.assignee = { id: createTaskDto.userId } as any;
    }
    const savedTask = await this.tasksRepository.save(task);

    // Fire and forget notification
    if (userId) { // userId of the creator
      this.notificationsService.sendNotification(
        'New Task Created',
        `${savedTask.title || 'A new task'} has been assigned.`,
        ['super_admin', 'admin', 'site_manager', 'viewer'],
        userId,
        { route: `/project/${savedTask.project.id}` } // or `/task/${savedTask.id}`
      );
    }

    return savedTask;
  }

  async findAllByProject(projectId: string, range?: string, startDate?: string, endDate?: string, flatId?: string): Promise<Task[]> {
    const whereClause: any = { project: { id: projectId } };

    if (flatId) {
      whereClause.flat = { id: flatId };
    }

    if (range) {
      if (range === 'custom' && startDate && endDate) {
        whereClause.created_at = Between(startDate, endDate);
      } else {
        const now = new Date();
        const ms = now.getTime();
        if (range === 'daily') {
          whereClause.created_at = MoreThanOrEqual(new Date(ms - 24 * 60 * 60 * 1000).toISOString().split('T')[0]);
        } else if (range === 'weekly') {
          whereClause.created_at = MoreThanOrEqual(new Date(ms - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]);
        } else if (range === 'monthly') {
          whereClause.created_at = MoreThanOrEqual(new Date(ms - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]);
        }
      }
    }

    return this.tasksRepository.find({
      where: whereClause,
      relations: ['assignee', 'flat'],
      order: { created_at: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Task> {
    const task = await this.tasksRepository.findOne({ where: { id }, relations: ['assignee', 'project'] });
    if (!task) throw new NotFoundException('Task not found');
    return task;
  }

  async update(id: string, updateTaskDto: any, userId?: string): Promise<Task> {
    const task = await this.findOne(id);
    Object.assign(task, updateTaskDto);
    
    // Natively intercept completion bounds locking the Time securely
    if (updateTaskDto.status === 'completed') {
      task.completed_at = new Date().toISOString().split('T')[0] as any;
    } else if (updateTaskDto.status === 'todo' || updateTaskDto.status === 'in_progress') {
      task.completed_at = null as any;
    }

    if (updateTaskDto.userId) {
      task.assignee = { id: updateTaskDto.userId } as any;
    }
    const savedTask = await this.tasksRepository.save(task);

    if (updateTaskDto.status === 'completed' && userId) {
      this.notificationsService.sendNotification(
        'Task Completed',
        `${savedTask.title || 'A task'} has been marked as completed.`,
        ['super_admin', 'admin', 'site_manager', 'viewer'],
        userId,
        { route: `/project/${savedTask.project?.id || updateTaskDto?.projectId || ''}` } 
      );
    }

    return savedTask;
  }

  async remove(id: string): Promise<void> {
    const result = await this.tasksRepository.delete(id);
    if (result.affected === 0) throw new NotFoundException();
  }
}
