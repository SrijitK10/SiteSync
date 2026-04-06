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
  findAll(@Request() req: any) {
    return this.projectsService.findAll(req.user.userId, req.user.role);
  }

  @Get(':id')
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

  @Post(':id/members')
  @Roles('admin', 'super_admin')
  addMember(@Param('id') id: string, @Body() body: any) {
    return this.projectsService.addMember(id, body.userId, body.roleInProject);
  }

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
