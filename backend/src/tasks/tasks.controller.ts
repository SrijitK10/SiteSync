import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query, UseInterceptors, Request } from '@nestjs/common';
import { CacheInterceptor } from '@nestjs/cache-manager';
import { AuthGuard } from '@nestjs/passport';
import { TasksService } from './tasks.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('tasks')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Post()
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  create(@Request() req: any, @Body() createTaskDto: any) {
    return this.tasksService.create(createTaskDto, req.user?.id);
  }

  @Get()
  @UseInterceptors(CacheInterceptor)
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  findAll(
    @Query('projectId') projectId: string,
    @Query('range') range?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('flatId') flatId?: string,
  ) {
    if (!projectId) return [];
    return this.tasksService.findAllByProject(projectId, range, startDate, endDate, flatId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.tasksService.findOne(id);
  }

  @Patch(':id')
  update(@Request() req: any, @Param('id') id: string, @Body() updateTaskDto: any) {
    // Workers can update status, Managers can update anything
    return this.tasksService.update(id, updateTaskDto, req.user?.id);
  }

  @Delete(':id')
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  remove(@Param('id') id: string) {
    return this.tasksService.remove(id);
  }
}
