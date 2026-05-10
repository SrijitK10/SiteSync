import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Response } from 'express';
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

  @Get('all')
  @Roles('admin', 'super_admin', 'site_manager')
  findAllGlobal(
    @Query('range') range?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    return this.tasksService.findAllGlobal(range, startDate, endDate);
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

  @Post(':taskId/attachments/upload')
  @Roles('admin', 'super_admin', 'site_manager')
  @UseInterceptors(FileInterceptor('file'))
  uploadAttachment(
    @Request() req: any,
    @Param('taskId') taskId: string,
    @UploadedFile() file: any,
    @Body('displayName') displayName?: string,
  ) {
    return this.tasksService.addUploadedAttachment(
      taskId,
      file,
      displayName,
      req.user?.id,
    );
  }

  @Get(':taskId/attachments')
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  getAttachments(@Param('taskId') taskId: string) {
    return this.tasksService.getAttachments(taskId);
  }

  @Get('attachments/:attachmentId/file')
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  async getAttachmentFile(
    @Param('attachmentId') attachmentId: string,
    @Res() res: Response,
  ) {
    const attachment = await this.tasksService.getAttachmentFile(attachmentId);
    const fileName = attachment.original_name || attachment.display_name || 'file';

    res.setHeader(
      'Content-Disposition',
      `inline; filename*=UTF-8''${encodeURIComponent(fileName)}`,
    );
    res.setHeader(
      'Content-Type',
      attachment.mime_type || 'application/octet-stream',
    );
    if (attachment.file_size) {
      res.setHeader('Content-Length', String(attachment.file_size));
    }

    return res.send(attachment.file_data);
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
