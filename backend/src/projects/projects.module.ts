import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProjectsService } from './projects.service';
import { ProjectsController } from './projects.controller';
import { Project } from './entities/project.entity';
import { ProjectMember } from './entities/project-member.entity';
import { ProjectImage } from './entities/project-image.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Project, ProjectMember, ProjectImage])],
  controllers: [ProjectsController],
  providers: [ProjectsService],
})
export class ProjectsModule {}
