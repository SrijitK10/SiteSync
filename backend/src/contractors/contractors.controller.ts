import { Controller, Get, Post, Body, Param, Delete, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ContractorsService } from './contractors.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('contractors')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class ContractorsController {
  constructor(private readonly contractorsService: ContractorsService) {}

  @Get()
  @Roles('admin', 'super_admin', 'site_manager', 'viewer')
  findAll() {
    return this.contractorsService.findAll();
  }

  @Post()
  @Roles('admin', 'super_admin', 'site_manager')
  create(@Body() body: any) {
    return this.contractorsService.create(body.name);
  }

  @Delete(':id')
  @Roles('admin', 'super_admin', 'site_manager')
  remove(@Param('id') id: string) {
    return this.contractorsService.remove(id);
  }
}
