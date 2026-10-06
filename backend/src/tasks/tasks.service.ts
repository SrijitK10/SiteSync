import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import { TaskDocument,  Task } from './entities/task.entity';
import { TaskAttachmentDocument,  TaskAttachment } from './entities/task-attachment.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { TranslationService } from '../translation/translation.service';

@Injectable()
export class TasksService {
  constructor(
    @InjectModel(Task.name)
    private tasksRepository: Model<TaskDocument>,
    @InjectModel(TaskAttachment.name)
    private attachmentsRepository: Model<TaskAttachmentDocument>,
    private readonly notificationsService: NotificationsService,
    private readonly translationService: TranslationService,
  ) {}

  private classifyAttachmentType(fileName: string, mimeType?: string | null): string {
    const lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'pdf';
    if (
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.heic') ||
      (mimeType?.startsWith('image/') ?? false)
    ) {
      return 'image';
    }

    return 'document';
  }

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
      await new this.tasksRepository(task).save() as any;
    } catch (e) {
      console.error('Background translation failed', e);
    }
  }

  async create(createTaskDto: any, userId?: string): Promise<Task> {
    const task = new this.tasksRepository();
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
    const savedTask = await new this.tasksRepository(task).save() as any;

    // Asynchronously update translations
    this.translateTaskAndSave(savedTask, createTaskDto.title, createTaskDto.description);

    // Fire and forget notification
    if (userId) {
      this.notificationsService.sendNotification(
        'New Task Created',
        `${savedTask.title || 'A new task'} has been assigned.`,
        ['super_admin', 'admin', 'site_manager', 'viewer'],
        userId,
        { route: `/projects/${savedTask.project?.id || createTaskDto?.projectId || ''}` },
        savedTask.project?.id || createTaskDto?.projectId,
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
        whereClause.created_at = { $gte: startDate, $lte: endDate };
      } else {
        const now = new Date();
        const ms = now.getTime();
        if (range === 'daily') {
          whereClause.created_at = { $gte: new Date(ms - 24 * 60 * 60 * 1000 ).toISOString().split('T')[0] };
        } else if (range === 'weekly') {
          whereClause.created_at = { $gte: new Date(ms - 7 * 24 * 60 * 60 * 1000 ).toISOString().split('T')[0] };
        } else if (range === 'monthly') {
          whereClause.created_at = { $gte: new Date(ms - 30 * 24 * 60 * 60 * 1000 ).toISOString().split('T')[0] };
        }
      }
    }

    return this.tasksRepository.find({
      where: whereClause,
      relations: ['assignee', 'flat', 'createdBy', 'completedBy'],
      order: { created_at: 'DESC' },
    });
  }

  async findAllGlobal(range?: string, startDate?: string, endDate?: string): Promise<Task[]> {
    const whereClause: any = {};

    if (range) {
      if (range === 'custom' && startDate && endDate) {
        whereClause.created_at = { $gte: startDate, $lte: endDate };
      } else {
        const now = new Date();
        const ms = now.getTime();
        if (range === 'daily') {
          whereClause.created_at = { $gte: new Date(ms - 24 * 60 * 60 * 1000 ).toISOString().split('T')[0] };
        } else if (range === 'weekly') {
          whereClause.created_at = { $gte: new Date(ms - 7 * 24 * 60 * 60 * 1000 ).toISOString().split('T')[0] };
        } else if (range === 'monthly') {
          whereClause.created_at = { $gte: new Date(ms - 30 * 24 * 60 * 60 * 1000 ).toISOString().split('T')[0] };
        }
      }
    }

    return this.tasksRepository.find({
      where: whereClause,
      relations: ['project', 'assignee', 'flat', 'createdBy', 'completedBy'],
      order: { created_at: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Task> {
    const task = await this.tasksRepository.findOne({
      where: { id },
      relations: ['assignee', 'project', 'flat', 'createdBy', 'completedBy'],
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
      if (userId) {
        task.completedBy = { id: userId } as any;
      }
    } else if (updateTaskDto.status === 'todo' || updateTaskDto.status === 'in_progress') {
      task.completed_at = null as any;
      task.completedBy = null as any;
    }

    if (updateTaskDto.userId) {
      task.assignee = { id: updateTaskDto.userId } as any;
    }
    const savedTask = await new this.tasksRepository(task).save() as any;

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
        id: { $in: taskIds },
        project: { id: projectId },
      },
    });

    if (!sourceTasks.length) throw new NotFoundException('No source tasks found');

    const newTasks: Task[] = [];
    for (const source of sourceTasks) {
      const task = new this.tasksRepository({
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

    return new this.tasksRepository(newTasks).save() as any;
  }

  async remove(id: string): Promise<void> {
    const result = await this.tasksRepository.findByIdAndDelete(id);
    if (!result) throw new NotFoundException();
  }

  // ── Task Attachments ──

  async addAttachment(taskId: string, data: any, userId?: string): Promise<TaskAttachment> {
    const task = await this.tasksRepository.findOne({ where: { id: taskId } });
    if (!task) throw new NotFoundException('Task not found');

    const attachment = new this.attachmentsRepository({
      url: data.url,
      storage_provider: data.storageProvider || 'external',
      display_name: data.displayName || data.originalName,
      original_name: data.originalName,
      file_type: data.fileType || 'document',
      mime_type: data.mimeType || null,
      file_size: data.fileSize || null,
      file_data: null,
      task: { id: taskId } as any,
      uploadedBy: userId ? ({ id: userId } as any) : null,
    });

    return new this.attachmentsRepository(attachment).save() as any;
  }

  async addUploadedAttachment(
    taskId: string,
    file: any,
    displayName?: string,
    userId?: string,
  ): Promise<TaskAttachment> {
    const task = await this.tasksRepository.findOne({ where: { id: taskId } });
    if (!task) throw new NotFoundException('Task not found');
    if (!file?.buffer?.length) {
      throw new NotFoundException('Attachment file is missing');
    }

    const attachment = new this.attachmentsRepository({
      url: '',
      storage_provider: 'database',
      display_name: displayName?.trim() || file.originalname,
      original_name: file.originalname,
      file_type: this.classifyAttachmentType(file.originalname, file.mimetype),
      mime_type: file.mimetype || null,
      file_size: file.size || null,
      file_data: file.buffer,
      task: { id: taskId } as any,
      uploadedBy: userId ? ({ id: userId } as any) : null,
    });

    const savedAttachment = await new this.attachmentsRepository(attachment).save() as any;
    savedAttachment.url = `/tasks/attachments/${savedAttachment.id}/file`;
    return new this.attachmentsRepository(savedAttachment).save() as any;
  }

  async getAttachments(taskId: string): Promise<TaskAttachment[]> {
    return this.attachmentsRepository.find({
      where: { task: { id: taskId } },
      relations: ['uploadedBy'],
      order: { created_at: 'DESC' },
    });
  }

  async renameAttachment(attachmentId: string, displayName: string): Promise<TaskAttachment> {
    const attachment = await this.attachmentsRepository.findOne({ where: { id: attachmentId } });
    if (!attachment) throw new NotFoundException('Attachment not found');
    attachment.display_name = displayName;
    return new this.attachmentsRepository(attachment).save() as any;
  }

  async getAttachmentFile(attachmentId: string): Promise<TaskAttachment> {
    const attachment = await this.attachmentsRepository.findById(attachmentId).select('+file_data').exec();

    if (!attachment) {
      throw new NotFoundException('Attachment not found');
    }

    if (attachment.storage_provider !== 'database' || !attachment.file_data) {
      throw new NotFoundException('Attachment file not stored on server');
    }

    return attachment;
  }

  async removeAttachment(attachmentId: string): Promise<void> {
    const result = await this.attachmentsRepository.findByIdAndDelete(attachmentId);
    if (!result) throw new NotFoundException('Attachment not found');
  }
}
