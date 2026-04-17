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
  findOne(@Param('id') id: string) {
    return this.tasksService.findOne(id);
  }

  @Patch(':id')
  @Roles('admin', 'super_admin', 'site_manager')
  update(@Request() req: any, @Param('id') id: string, @Body() updateTaskDto: any) {
    return this.tasksService.update(id, updateTaskDto, req.user?.id);
  }

  @Delete(':id')
  @Roles('admin', 'super_admin', 'site_manager')
  remove(@Param('id') id: string) {
    return this.tasksService.remove(id);
  }

  // ── Task Attachments ──

  @Post(':taskId/attachments')
  @Roles('admin', 'super_admin', 'site_manager')
  addAttachment(
    @Request() req: any,
    @Param('taskId') taskId: string,
    @Body() body: any,
  ) {
    return this.tasksService.addAttachment(taskId, body, req.user?.id);
  }

  @Get(':taskId/attachments')
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  getAttachments(@Param('taskId') taskId: string) {
    return this.tasksService.getAttachments(taskId);
  }

  @Patch('attachments/:attachmentId/rename')
  @Roles('admin', 'super_admin', 'site_manager')
  renameAttachment(
    @Param('attachmentId') attachmentId: string,
    @Body() body: { displayName: string },
  ) {
    return this.tasksService.renameAttachment(attachmentId, body.displayName);
  }

  @Delete('attachments/:attachmentId')
  @Roles('admin', 'super_admin', 'site_manager')
  removeAttachment(@Param('attachmentId') attachmentId: string) {
    return this.tasksService.removeAttachment(attachmentId);
  }
}
