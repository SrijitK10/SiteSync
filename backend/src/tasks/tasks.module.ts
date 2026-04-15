import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TasksService } from './tasks.service';
import { TasksController } from './tasks.controller';
import { Task } from './entities/task.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { TranslationModule } from '../translation/translation.module';
import { TranslationInterceptor } from '../translation/translation.interceptor';

@Module({
  imports: [
    TypeOrmModule.forFeature([Task]),
    NotificationsModule,
    TranslationModule,
  ],
  controllers: [TasksController],
  providers: [TasksService, TranslationInterceptor],
})
export class TasksModule {}

