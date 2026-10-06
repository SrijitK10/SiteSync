import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TasksService } from './tasks.service';
import { TasksController } from './tasks.controller';
import { TaskSchema,  Task } from './entities/task.entity';
import { TaskAttachmentSchema,  TaskAttachment } from './entities/task-attachment.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { TranslationModule } from '../translation/translation.module';
import { TranslationInterceptor } from '../translation/translation.interceptor';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Task.name, schema: TaskSchema }, { name: TaskAttachment.name, schema: TaskAttachmentSchema }]),
    NotificationsModule,
    TranslationModule,
  ],
  controllers: [TasksController],
  providers: [TasksService, TranslationInterceptor],
})
export class TasksModule {}

