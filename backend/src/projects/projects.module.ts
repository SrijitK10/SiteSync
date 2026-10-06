import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProjectsService } from './projects.service';
import { ProjectsController } from './projects.controller';
import { ProjectSchema,  Project } from './entities/project.entity';
import { ProjectMemberSchema,  ProjectMember } from './entities/project-member.entity';
import { ProjectImageSchema,  ProjectImage } from './entities/project-image.entity';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Project.name, schema: ProjectSchema }, { name: ProjectMember.name, schema: ProjectMemberSchema }, { name: ProjectImage.name, schema: ProjectImageSchema }]),
    NotificationsModule,
  ],
  controllers: [ProjectsController],
  providers: [ProjectsService],
})
export class ProjectsModule {}
