import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThanOrEqual, Between, In } from 'typeorm';
import { Task } from './entities/task.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { TranslationService } from '../translation/translation.service';

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(Task)
    private tasksRepository: Repository<Task>,
    private readonly notificationsService: NotificationsService,
    private readonly translationService: TranslationService,
  ) {}

  private async translateTaskAndSave(task: Task, title?: string, description?: string) {
    const targetLangs = ['en', 'hi', 'bn'];
    task.title_translations = task.title_translations || {};
    task.description_translations = task.description_translations || {};

    try {
      if (title) {
        const titleTranslations = await this.translationService.translateText(title, targetLangs);
        task.title_translations = { ...task.title_translations, ...titleTranslations };
      }
      if (description) {
        const descTranslations = await this.translationService.translateText(description, targetLangs);
        task.description_translations = { ...task.description_translations, ...descTranslations };
      }
      await this.tasksRepository.save(task);
    } catch (e) {
      console.error('Background translation failed', e);
    }
  }

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
    if (userId) {
      task.createdBy = { id: userId } as any;
    }
    const savedTask = await this.tasksRepository.save(task);

    // Asynchronously update translations
    this.translateTaskAndSave(savedTask, createTaskDto.title, createTaskDto.description);

    // Fire and forget notification
    if (userId) { // userId of the creator
      this.notificationsService.sendNotification(
        'New Task Created',
        `${savedTask.title || 'A new task'} has been assigned.`,
        ['super_admin', 'admin', 'site_manager', 'viewer'],
        userId,
        { route: `/projects/${savedTask.project.id}` },
        savedTask.project.id
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
      relations: ['assignee', 'flat', 'createdBy'],
      order: { created_at: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Task> {
    const task = await this.tasksRepository.findOne({
      where: { id },
      relations: ['assignee', 'project', 'flat', 'createdBy'],
    });
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

    if (updateTaskDto.title !== undefined || updateTaskDto.description !== undefined) {
      this.translateTaskAndSave(savedTask, updateTaskDto.title, updateTaskDto.description);
    }

    if (updateTaskDto.status === 'completed' && userId) {
      const taskTitle = savedTask.title || 'A task';
      let message = `${taskTitle} has been marked as completed.`;
      
      if (savedTask.project && savedTask.flat) {
        message = `${taskTitle} has been completed for flat ${savedTask.flat.flat_number} in project ${savedTask.project.name}.`;
      } else if (savedTask.project) {
        message = `${taskTitle} has been completed in project ${savedTask.project.name}.`;
      }

      this.notificationsService.sendNotification(
        'Task Completed',
        message,
        ['super_admin', 'admin', 'site_manager', 'viewer'],
        userId,
        { route: `/projects/${savedTask.project?.id || updateTaskDto?.projectId || ''}` },
        savedTask.project?.id || updateTaskDto?.projectId
      );
    }

    return savedTask;
  }

  async copyTasks(taskIds: string[], targetFlatId: string, projectId: string, userId?: string): Promise<Task[]> {
    const sourceTasks = await this.tasksRepository.find({
      where: {
        id: In(taskIds),
        project: { id: projectId },
      },
    });

    if (!sourceTasks.length) throw new NotFoundException('No source tasks found');

    const newTasks: Task[] = [];
    for (const source of sourceTasks) {
      const task = this.tasksRepository.create({
        title: source.title,
        // Only copy the task itself. Notes stay blank on imported tasks.
        description: null as any,
        title_translations: source.title_translations || {},
        description_translations: {},
        status: 'todo' as any,
        project: { id: projectId } as any,
        flat: { id: targetFlatId } as any,
        createdBy: userId ? ({ id: userId } as any) : null,
      });
      newTasks.push(task);
    }

    return this.tasksRepository.save(newTasks);
  }

  async remove(id: string): Promise<void> {
    const result = await this.tasksRepository.delete(id);
    if (result.affected === 0) throw new NotFoundException();
  }
}
