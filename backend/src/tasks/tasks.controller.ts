import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query, UseInterceptors, Request } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TasksService } from './tasks.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { TranslationInterceptor } from '../translation/translation.interceptor';

@Controller('tasks')
@UseGuards(AuthGuard('jwt'), RolesGuard)
@UseInterceptors(TranslationInterceptor)
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Post()
  @Roles('admin', 'super_admin', 'site_manager')
  create(@Request() req: any, @Body() createTaskDto: any) {
    return this.tasksService.create(createTaskDto, req.user?.id);
  }

  @Post('copy')
  @Roles('admin', 'super_admin', 'site_manager')
  copyTasks(@Request() req: any, @Body() body: { taskIds: string[]; targetFlatId: string; projectId: string }) {
    return this.tasksService.copyTasks(
      body.taskIds,
      body.targetFlatId,
      body.projectId,
      req.user?.id,
    );
  }

  @Get('counts')
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  async getCounts(@Query('projectIds') projectIds: string) {
    if (!projectIds) return {};
    const ids = projectIds.split(',').map(id => id.trim()).filter(Boolean);
    return this.tasksService.countByProjects(ids);
  }

  @Get()
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
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  }

  @Delete(':id')
  @Roles('admin', 'super_admin', 'site_manager')
  remove(@Param('id') id: string) {
    return this.tasksService.remove(id);
  }
}
