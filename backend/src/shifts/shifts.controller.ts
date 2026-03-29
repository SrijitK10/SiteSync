import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request, Query } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ShiftsService } from './shifts.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('shifts')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class ShiftsController {
  constructor(private readonly shiftsService: ShiftsService) {}

  @Post()
  @Roles('admin', 'super_admin', 'site_manager')
  create(@Body() createShiftDto: any) {
    return this.shiftsService.create(createShiftDto);
  }

  // Workers fetching their own shifts
  @Get('my')
  findMyShifts(@Request() req: any) {
    return this.shiftsService.findAllByUser(req.user.userId);
  }

  // Managers fetching shifts for a project
  @Get()
  @Roles('admin', 'super_admin', 'site_manager')
  findAll(@Query('projectId') projectId: string) {
    if (projectId) {
      return this.shiftsService.findAllByProject(projectId);
    }
    return [];
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.shiftsService.findOne(id);
  }

  @Patch(':id')
  @Roles('admin', 'super_admin', 'site_manager')
  update(@Param('id') id: string, @Body() updateShiftDto: any) {
    return this.shiftsService.update(id, updateShiftDto);
  }

  @Delete(':id')
  @Roles('admin', 'super_admin', 'site_manager')
  remove(@Param('id') id: string) {
    return this.shiftsService.remove(id);
  }
}
