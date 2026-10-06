import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { FlatsService } from './flats.service';
import { FlatsController } from './flats.controller';
import { FlatSchema,  Flat } from './entities/flat.entity';

@Module({
  imports: [MongooseModule.forFeature([{ name: Flat.name, schema: FlatSchema }])],
  controllers: [FlatsController],
  providers: [FlatsService],
  
})
export class FlatsModule {}
