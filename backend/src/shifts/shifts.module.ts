import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ShiftsService } from './shifts.service';
import { ShiftsController } from './shifts.controller';
import { ShiftSchema,  Shift } from './entities/shift.entity';

@Module({
  imports: [MongooseModule.forFeature([{ name: Shift.name, schema: ShiftSchema }])],
  controllers: [ShiftsController],
  providers: [ShiftsService],
})
export class ShiftsModule {}
