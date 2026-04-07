import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { FlatsService } from './flats.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('flats')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class FlatsController {
  constructor(private readonly flatsService: FlatsService) {}

  @Get()
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  findAll(@Query('projectId') projectId: string) {
    if (!projectId) return [];
    return this.flatsService.findAllByProject(projectId);
  }

  @Post()
  @Roles('admin', 'super_admin', 'site_manager')
  create(@Body() body: { projectId: string; flat_number: string }) {
    return this.flatsService.create(body.projectId, body.flat_number);
  }

  @Patch(':id')
  @Roles('admin', 'super_admin', 'site_manager')
  update(@Param('id') id: string, @Body() body: { is_completed: boolean }) {
    return this.flatsService.toggleCompleted(id, body.is_completed);
  }

  @Delete(':id')
  @Roles('admin', 'super_admin', 'site_manager')
  remove(@Param('id') id: string) {
    return this.flatsService.remove(id);
  }
}
