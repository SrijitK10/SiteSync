import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request, UseInterceptors } from '@nestjs/common';
import { CacheInterceptor } from '@nestjs/cache-manager';
import { AuthGuard } from '@nestjs/passport';
import { ProjectsService } from './projects.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('projects')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  @Post()
  @Roles('admin', 'super_admin')
  create(@Body() createProjectDto: any, @Request() req: any) {
    return this.projectsService.create(createProjectDto, req.user.userId);
  }

  @Get()
  @UseInterceptors(CacheInterceptor)
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  findAll(@Request() req: any) {
    return this.projectsService.findAll(req.user.userId, req.user.role);
  }

  @Get(':id')
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  findOne(@Param('id') id: string) {
    return this.projectsService.findOne(id);
  }

  @Patch(':id')
  @Roles('admin', 'super_admin', 'site_manager')
  update(@Param('id') id: string, @Body() updateProjectDto: any) {
    return this.projectsService.update(id, updateProjectDto);
  }

  @Delete(':id')
  @Roles('super_admin', 'admin')
  remove(@Param('id') id: string) {
    return this.projectsService.remove(id);
  }

  // ── Member Management ──────────────────────────────────────────

  @Get(':id/members')
  @Roles('admin', 'super_admin')
  getMembers(@Param('id') id: string) {
    return this.projectsService.getMembers(id);
  }

  @Post(':id/members')
  @Roles('admin', 'super_admin')
  addMember(@Param('id') id: string, @Body() body: any) {
    return this.projectsService.addMember(id, body.userId, body.roleInProject || 'member');
  }

  @Delete(':id/members/:userId')
  @Roles('admin', 'super_admin')
  removeMember(@Param('id') id: string, @Param('userId') userId: string) {
    return this.projectsService.removeMember(id, userId);
  }

  // ── User-centric project assignment ────────────────────────────

  /** Get all project IDs a user is assigned to. */
  @Get('user/:userId/assignments')
  @Roles('admin', 'super_admin')
  getProjectIdsForUser(@Param('userId') userId: string) {
    return this.projectsService.getProjectIdsForUser(userId);
  }

  /** Bulk set project assignments for a user. */
  @Post('user/:userId/assignments')
  @Roles('admin', 'super_admin')
  setProjectsForUser(@Param('userId') userId: string, @Body() body: { projectIds: string[] }) {
    return this.projectsService.setProjectsForUser(userId, body.projectIds);
  }

  /** Assign ALL projects to a user (migration helper). */
  @Post('user/:userId/assign-all')
  @Roles('admin', 'super_admin')
  assignAllProjectsToUser(@Param('userId') userId: string) {
    return this.projectsService.assignAllProjectsToUser(userId);
  }

  // ── Images ─────────────────────────────────────────────────────

  @Post(':id/images')
  @Roles('super_admin', 'admin', 'site_manager')
  addImage(@Param('id') id: string, @Body() body: any, @Request() req: any) {
    return this.projectsService.addImage(id, req.user.userId, body.url, body.caption);
  }

  @Get(':id/images')
  @Roles('super_admin', 'admin', 'site_manager')
  getImages(@Param('id') id: string) {
    return this.projectsService.getImages(id);
  }
}
