import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
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

  async findAllByProject(projectId: string): Promise<Task[]> {
    return this.tasksRepository.find({
      where: { project: { id: projectId } },
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
