import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TasksService } from './tasks.service';
import { TasksController } from './tasks.controller';
import { TaskSchema, Task } from './entities/task.entity';
import { TaskAttachmentSchema, TaskAttachment } from './entities/task-attachment.entity';
import { ProjectSchema, Project } from '../projects/entities/project.entity';
import { FlatSchema, Flat } from '../flats/entities/flat.entity';
import { UserSchema, User } from '../users/entities/user.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { TranslationModule } from '../translation/translation.module';
import { TranslationInterceptor } from '../translation/translation.interceptor';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Task.name, schema: TaskSchema },
      { name: TaskAttachment.name, schema: TaskAttachmentSchema },
      { name: Project.name, schema: ProjectSchema },
      { name: Flat.name, schema: FlatSchema },
      { name: User.name, schema: UserSchema },
    ]),
    NotificationsModule,
    TranslationModule,
  ],
  controllers: [TasksController],
  providers: [TasksService, TranslationInterceptor],
  exports: [TasksService],
})
export class TasksModule {}
