import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from './users.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@Controller('users')
@UseGuards(AuthGuard('jwt'), RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  getProfile(@Request() req: any) {
    return req.user;
  }

  @Post()
  @Roles('admin', 'super_admin')
  create(@Body() createUserDto: any) {
    // Admin can pre-register users with phone + role (no password needed)
    return this.usersService.create(createUserDto);
  }

  @Get()
  @Roles('admin', 'super_admin')
  findAll() {
    return this.usersService.findAll();
  }

  @Get(':id')
  @Roles('admin', 'super_admin')
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Patch(':id')
  @Roles('admin', 'super_admin')
  update(@Param('id') id: string, @Body() updateUserDto: any) {
    // This is how super_admin/admin assigns roles to users
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  @Roles('super_admin')
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}
