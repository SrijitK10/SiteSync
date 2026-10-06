import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AttendanceService } from './attendance.service';
import { AttendanceController } from './attendance.controller';
import { AttendanceSchema,  Attendance } from './entities/attendance.entity';

@Module({
  imports: [MongooseModule.forFeature([{ name: Attendance.name, schema: AttendanceSchema }])],
  controllers: [AttendanceController],
  providers: [AttendanceService],
})
export class AttendanceModule {}
