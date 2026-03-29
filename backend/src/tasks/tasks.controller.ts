import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TasksService } from './tasks.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('tasks')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Post()
  @Roles('admin', 'super_admin', 'site_manager')
  create(@Body() createTaskDto: any) {
    return this.tasksService.create(createTaskDto);
  }

  @Get()
  findAll(@Query('projectId') projectId: string) {
    if (!projectId) return [];
    return this.tasksService.findAllByProject(projectId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.tasksService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateTaskDto: any) {
    // Workers can update status, Managers can update anything
    return this.tasksService.update(id, updateTaskDto);
  }

  @Delete(':id')
  @Roles('admin', 'super_admin', 'site_manager')
  remove(@Param('id') id: string) {
    return this.tasksService.remove(id);
  }
}
