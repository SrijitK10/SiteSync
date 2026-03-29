import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThanOrEqual, Between } from 'typeorm';
import { Task } from './entities/task.entity';

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(Task)
    private tasksRepository: Repository<Task>,
  ) {}

  async create(createTaskDto: any): Promise<Task> {
    const task = this.tasksRepository.create();
    Object.assign(task, createTaskDto);
    task.project = { id: createTaskDto.projectId } as any;
    if (createTaskDto.userId) {
      task.assignee = { id: createTaskDto.userId } as any;
    }
    return this.tasksRepository.save(task);
  }

  async findAllByProject(projectId: string, range?: string, startDate?: string, endDate?: string): Promise<Task[]> {
    const whereClause: any = { project: { id: projectId } };

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
      relations: ['assignee'],
      order: { created_at: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Task> {
    const task = await this.tasksRepository.findOne({ where: { id }, relations: ['assignee', 'project'] });
    if (!task) throw new NotFoundException('Task not found');
    return task;
  }

  async update(id: string, updateTaskDto: any): Promise<Task> {
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
    return this.tasksRepository.save(task);
  }

  async remove(id: string): Promise<void> {
    const result = await this.tasksRepository.delete(id);
    if (result.affected === 0) throw new NotFoundException();
  }
}
