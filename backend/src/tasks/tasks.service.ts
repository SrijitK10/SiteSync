import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { randomUUID } from 'crypto';

import { TaskDocument, Task, TaskStatus } from './entities/task.entity';
import { TaskAttachmentDocument, TaskAttachment } from './entities/task-attachment.entity';
import { ProjectDocument, Project } from '../projects/entities/project.entity';
import { FlatDocument, Flat } from '../flats/entities/flat.entity';
import { UserDocument, User } from '../users/entities/user.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { TranslationService } from '../translation/translation.service';
import { buildIdFilter, buildIdsFilter, toCleanObject, toCleanObjects } from '../common/mongo-id.util';

@Injectable()
export class TasksService {
  constructor(
    @InjectModel(Task.name)
    private tasksRepository: Model<TaskDocument>,
    @InjectModel(TaskAttachment.name)
    private attachmentsRepository: Model<TaskAttachmentDocument>,
    @InjectModel(Project.name)
    private projectsRepository: Model<ProjectDocument>,
    @InjectModel(Flat.name)
    private flatsRepository: Model<FlatDocument>,
    @InjectModel(User.name)
    private usersRepository: Model<UserDocument>,
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

  private async translateTaskAndSave(taskId: string, title?: string, description?: string) {
    const targetLangs = ['en', 'hi', 'bn'];
    try {
      const updates: any = {};
      if (title) {
        updates.title_translations = await this.translationService.translateText(title, targetLangs);
      }
      if (description) {
        updates.description_translations = await this.translationService.translateText(description, targetLangs);
      }
      if (Object.keys(updates).length > 0) {
        await this.tasksRepository.findOneAndUpdate(
          buildIdFilter(taskId),
          { $set: updates },
        ).exec();
      }
    } catch (e) {
      console.error('Background translation failed', e);
    }
  }

  private async populateTasks(tasks: any[]): Promise<any[]> {
    if (!tasks || !tasks.length) return [];

    const projectIds = new Set<string>();
    const flatIds = new Set<string>();
    const userIds = new Set<string>();

    for (const t of tasks) {
      if (t.project_id) projectIds.add(t.project_id);
      if (t.flat_id) flatIds.add(t.flat_id);
      if (t.assigned_to) userIds.add(t.assigned_to);
      if (t.created_by) userIds.add(t.created_by);
      if (t.completed_by) userIds.add(t.completed_by);
    }

    const [projects, flats, users] = await Promise.all([
      projectIds.size > 0
        ? this.projectsRepository.find(buildIdsFilter(Array.from(projectIds))).select('id name location').lean().exec()
        : [],
      flatIds.size > 0
        ? this.flatsRepository.find(buildIdsFilter(Array.from(flatIds))).select('id flat_number is_completed').lean().exec()
        : [],
      userIds.size > 0
        ? this.usersRepository.find(buildIdsFilter(Array.from(userIds))).select('id name phone role').lean().exec()
        : [],
    ]);

    const projectMap = new Map<string, any>();
    for (const p of projects) {
      const cleanP = toCleanObject(p);
      projectMap.set(cleanP.id, cleanP);
      if (p._id) projectMap.set(p._id.toString(), cleanP);
    }

    const flatMap = new Map<string, any>();
    for (const f of flats) {
      const cleanF = toCleanObject(f);
      flatMap.set(cleanF.id, cleanF);
      if (f._id) flatMap.set(f._id.toString(), cleanF);
    }

    const userMap = new Map<string, any>();
    for (const u of users) {
      const cleanU = toCleanObject(u);
      userMap.set(cleanU.id, cleanU);
      if (u._id) userMap.set(u._id.toString(), cleanU);
    }

    return tasks.map(t => {
      const cleanT = toCleanObject<any>(t);
      cleanT.project = projectMap.get(t.project_id) || (t.project_id ? { id: t.project_id, name: '' } : null);
      cleanT.flat = flatMap.get(t.flat_id) || (t.flat_id ? { id: t.flat_id, flat_number: '' } : null);
      cleanT.assignee = userMap.get(t.assigned_to) || null;
      cleanT.createdBy = userMap.get(t.created_by) || null;
      cleanT.completedBy = userMap.get(t.completed_by) || null;
      return cleanT;
    });
  }

  async create(createTaskDto: any, userId?: string): Promise<Task> {
    const taskId = randomUUID();
    const projectId = createTaskDto.projectId || createTaskDto.project?.id;
    const flatId = createTaskDto.flatId || createTaskDto.flat?.id || null;
    const assignedTo = createTaskDto.userId || createTaskDto.assignedTo || createTaskDto.assignee?.id || null;

    const task = new this.tasksRepository({
      id: taskId,
      title: createTaskDto.title,
      description: createTaskDto.description || null,
      status: createTaskDto.status || TaskStatus.TODO,
      due_date: createTaskDto.dueDate || createTaskDto.due_date || null,
      project_id: projectId,
      flat_id: flatId,
      assigned_to: assignedTo,
      created_by: userId || null,
      completed_by: null,
      completed_at: null,
      title_translations: {},
      description_translations: {},
    });

    const savedTask = await task.save();
    const result = toCleanObject<Task>(savedTask);

    // Asynchronously update translations
    this.translateTaskAndSave(taskId, createTaskDto.title, createTaskDto.description);

    // Fire and forget notification
    if (userId) {
      this.notificationsService.sendNotification(
        'New Task Created',
        `${result.title || 'A new task'} has been assigned.`,
        ['super_admin', 'admin', 'site_manager', 'viewer'],
        userId,
        { route: `/projects/${projectId || ''}` },
        projectId,
      );
    }

    return (await this.populateTasks([result]))[0];
  }

  async findAllByProject(projectId: string, range?: string, startDate?: string, endDate?: string, flatId?: string): Promise<Task[]> {
    const filter: any = { project_id: projectId };

    if (flatId) {
      filter.flat_id = flatId;
    }

    if (range && range !== 'all') {
      if (range === 'custom' && startDate && endDate) {
        filter.created_at = { $gte: new Date(startDate), $lte: new Date(endDate) };
      } else {
        const now = new Date();
        const ms = now.getTime();
        if (range === 'daily') {
          filter.created_at = { $gte: new Date(ms - 24 * 60 * 60 * 1000) };
        } else if (range === 'weekly') {
          filter.created_at = { $gte: new Date(ms - 7 * 24 * 60 * 60 * 1000) };
        } else if (range === 'monthly') {
          filter.created_at = { $gte: new Date(ms - 30 * 24 * 60 * 60 * 1000) };
        }
      }
    }

    const tasks = await this.tasksRepository.find(filter).sort({ created_at: -1 }).lean().exec();
    return this.populateTasks(tasks);
  }

  async findAllGlobal(range?: string, startDate?: string, endDate?: string): Promise<Task[]> {
    const filter: any = {};

    if (range && range !== 'all') {
      if (range === 'custom' && startDate && endDate) {
        filter.created_at = { $gte: new Date(startDate), $lte: new Date(endDate) };
      } else {
        const now = new Date();
        const ms = now.getTime();
        if (range === 'daily') {
          filter.created_at = { $gte: new Date(ms - 24 * 60 * 60 * 1000) };
        } else if (range === 'weekly') {
          filter.created_at = { $gte: new Date(ms - 7 * 24 * 60 * 60 * 1000) };
        } else if (range === 'monthly') {
          filter.created_at = { $gte: new Date(ms - 30 * 24 * 60 * 60 * 1000) };
        }
      }
    }

    const tasks = await this.tasksRepository.find(filter).sort({ created_at: -1 }).lean().exec();
    return this.populateTasks(tasks);
  }

  async findOne(id: string): Promise<Task> {
    const task = await this.tasksRepository.findOne(buildIdFilter(id)).lean().exec();
    if (!task) throw new NotFoundException('Task not found');
    const [populated] = await this.populateTasks([task]);
    return populated;
  }

  async update(id: string, updateTaskDto: any, userId?: string): Promise<Task> {
    const updateFields: any = { ...updateTaskDto };

    if (updateTaskDto.projectId) {
      updateFields.project_id = updateTaskDto.projectId;
      delete updateFields.projectId;
    }
    if (updateTaskDto.flatId !== undefined) {
      updateFields.flat_id = updateTaskDto.flatId;
      delete updateFields.flatId;
    }
    if (updateTaskDto.userId !== undefined) {
      updateFields.assigned_to = updateTaskDto.userId;
      delete updateFields.userId;
    }

    // Natively intercept completion bounds locking the Time securely
    if (updateTaskDto.status === 'completed') {
      updateFields.completed_at = new Date();
      if (userId) {
        updateFields.completed_by = userId;
      }
    } else if (updateTaskDto.status === 'todo' || updateTaskDto.status === 'in_progress') {
      updateFields.completed_at = null;
      updateFields.completed_by = null;
    }

    const updatedTask = await this.tasksRepository
      .findOneAndUpdate(
        buildIdFilter(id),
        { $set: updateFields },
        { returnDocument: 'after' },
      )
      .lean()
      .exec();

    if (!updatedTask) throw new NotFoundException('Task not found');

    if (updateTaskDto.title !== undefined || updateTaskDto.description !== undefined) {
      this.translateTaskAndSave(id, updateTaskDto.title, updateTaskDto.description);
    }

    const [populated] = await this.populateTasks([updatedTask]);

    if (updateTaskDto.status === 'completed' && userId) {
      const taskTitle = populated.title || 'A task';
      let message = `${taskTitle} has been marked as completed.`;

      if (populated.project && populated.flat) {
        message = `${taskTitle} has been completed for flat ${populated.flat.flat_number} in project ${populated.project.name}.`;
      } else if (populated.project) {
        message = `${taskTitle} has been completed in project ${populated.project.name}.`;
      }

      this.notificationsService.sendNotification(
        'Task Completed',
        message,
        ['super_admin', 'admin', 'site_manager', 'viewer'],
        userId,
        { route: `/projects/${populated.project_id || ''}` },
        populated.project_id,
      );
    }

    return populated;
  }

  async copyTasks(taskIds: string[], targetFlatId: string, projectId: string, userId?: string): Promise<Task[]> {
    const sourceTasks = await this.tasksRepository
      .find({
        ...buildIdsFilter(taskIds),
        project_id: projectId,
      })
      .lean()
      .exec();

    if (!sourceTasks.length) throw new NotFoundException('No source tasks found');

    const newTasks: any[] = [];
    for (const source of sourceTasks) {
      newTasks.push({
        id: randomUUID(),
        title: source.title,
        description: null,
        title_translations: source.title_translations || {},
        description_translations: {},
        status: TaskStatus.TODO,
        project_id: projectId,
        flat_id: targetFlatId,
        assigned_to: null,
        created_by: userId || null,
        completed_by: null,
        completed_at: null,
      });
    }

    const savedTasks = await this.tasksRepository.insertMany(newTasks);
    return this.populateTasks(savedTasks);
  }

  async remove(id: string): Promise<void> {
    const result = await this.tasksRepository.findOneAndDelete(buildIdFilter(id)).exec();
    if (!result) throw new NotFoundException('Task not found');
  }

  // ── Task Attachments ──

  async addAttachment(taskId: string, data: any, userId?: string): Promise<TaskAttachment> {
    const task = await this.tasksRepository.findOne(buildIdFilter(taskId)).lean().exec();
    if (!task) throw new NotFoundException('Task not found');

    const attachmentId = randomUUID();
    const attachment = new this.attachmentsRepository({
      id: attachmentId,
      url: data.url,
      storage_provider: data.storageProvider || 'external',
      display_name: data.displayName || data.originalName,
      original_name: data.originalName,
      file_type: data.fileType || 'document',
      mime_type: data.mimeType || null,
      file_size: data.fileSize || null,
      file_data: null,
      task_id: taskId,
      uploaded_by: userId || null,
    });

    const saved = await attachment.save();
    return toCleanObject<TaskAttachment>(saved);
  }

  async addUploadedAttachment(
    taskId: string,
    file: any,
    displayName?: string,
    userId?: string,
  ): Promise<TaskAttachment> {
    const task = await this.tasksRepository.findOne(buildIdFilter(taskId)).lean().exec();
    if (!task) throw new NotFoundException('Task not found');
    if (!file?.buffer?.length) {
      throw new NotFoundException('Attachment file is missing');
    }

    const attachmentId = randomUUID();
    const attachment = new this.attachmentsRepository({
      id: attachmentId,
      url: '',
      storage_provider: 'database',
      display_name: displayName?.trim() || file.originalname,
      original_name: file.originalname,
      file_type: this.classifyAttachmentType(file.originalname, file.mimetype),
      mime_type: file.mimetype || null,
      file_size: file.size || null,
      file_data: file.buffer,
      task_id: taskId,
      uploaded_by: userId || null,
    });

    const saved = await attachment.save();
    const updated = await this.attachmentsRepository
      .findOneAndUpdate(
        buildIdFilter(attachmentId),
        { $set: { url: `/tasks/attachments/${saved.id}/file` } },
        { returnDocument: 'after' },
      )
      .lean()
      .exec();

    return toCleanObject<TaskAttachment>(updated || saved);
  }

  async getAttachments(taskId: string): Promise<TaskAttachment[]> {
    const attachments = await this.attachmentsRepository
      .find({ task_id: taskId })
      .sort({ created_at: -1 })
      .lean()
      .exec();

    if (!attachments.length) return [];

    const userIds = attachments.map(a => a.uploaded_by).filter(Boolean);
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

    return attachments.map(a => {
      const cleanA = toCleanObject<any>(a);
      cleanA.uploadedBy = userMap.get(a.uploaded_by) || null;
      return cleanA;
    });
  }

  async renameAttachment(attachmentId: string, displayName: string): Promise<TaskAttachment> {
    const updated = await this.attachmentsRepository
      .findOneAndUpdate(
        buildIdFilter(attachmentId),
        { $set: { display_name: displayName } },
        { returnDocument: 'after' },
      )
      .lean()
      .exec();

    if (!updated) throw new NotFoundException('Attachment not found');
    return toCleanObject<TaskAttachment>(updated);
  }

  async getAttachmentFile(attachmentId: string): Promise<TaskAttachment> {
    const attachment = await this.attachmentsRepository
      .findOne(buildIdFilter(attachmentId))
      .select('+file_data')
      .lean()
      .exec();

    if (!attachment) {
      throw new NotFoundException('Attachment not found');
    }

    if (attachment.storage_provider !== 'database' || !attachment.file_data) {
      throw new NotFoundException('Attachment file not stored on server');
    }

    return toCleanObject<TaskAttachment>(attachment);
  }

  async removeAttachment(attachmentId: string): Promise<void> {
    const result = await this.attachmentsRepository
      .findOneAndDelete(buildIdFilter(attachmentId))
      .exec();
    if (!result) throw new NotFoundException('Attachment not found');
  }
}
