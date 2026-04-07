import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FlatsService } from './flats.service';
import { FlatsController } from './flats.controller';
import { Flat } from './entities/flat.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Flat])],
  controllers: [FlatsController],
  providers: [FlatsService],
  exports: [TypeOrmModule],
})
export class FlatsModule {}
