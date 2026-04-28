import { Controller, Get, Post, Body, Param, Delete, UseGuards, Query, Request, UseInterceptors } from '@nestjs/common';
import { CacheInterceptor } from '@nestjs/cache-manager';
import { AuthGuard } from '@nestjs/passport';
import { AttendanceService } from './attendance.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('attendance')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  @Post('bulk')
  @Roles('admin', 'super_admin', 'site_manager')
  async createBulk(@Body() body: { siteAddress: string, projectId: string, records: any[] }, @Request() req: any) {
    await this.attendanceService.createBulk(body, req.user.userId);
    return { message: 'Attendance records created successfully' };
  }

  @Get()
  @Roles('admin', 'super_admin', 'site_manager')
  findAll(
    @Query('projectId') projectId: string, 
    @Query('range') range: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('contractorName') contractorName?: string,
  ) {
    if (!projectId) return [];
    return this.attendanceService.findAllByProject(projectId, range, startDate, endDate, contractorName);
  }

  @Delete(':id')
  @Roles('admin', 'super_admin')
  remove(@Param('id') id: string) {
    return this.attendanceService.remove(id);
  }
}
