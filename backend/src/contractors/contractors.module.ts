import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ContractorsService } from './contractors.service';
import { ContractorsController } from './contractors.controller';
import { ContractorSchema,  Contractor } from './entities/contractor.entity';

@Module({
  imports: [MongooseModule.forFeature([{ name: Contractor.name, schema: ContractorSchema }])],
  controllers: [ContractorsController],
  providers: [ContractorsService],
})
export class ContractorsModule {}
