import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AssistantService } from './assistant.service';
import { AssistantController } from './assistant.controller';
import { AssistantMessage, AssistantMessageSchema } from './entities/assistant-message.entity';
import { Project, ProjectSchema } from '../projects/entities/project.entity';
import { Flat, FlatSchema } from '../flats/entities/flat.entity';
import { Contractor, ContractorSchema } from '../contractors/entities/contractor.entity';
import { User, UserSchema } from '../users/entities/user.entity';
import { TasksModule } from '../tasks/tasks.module';
import { AttendanceModule } from '../attendance/attendance.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: AssistantMessage.name, schema: AssistantMessageSchema },
      { name: Project.name, schema: ProjectSchema },
      { name: Flat.name, schema: FlatSchema },
      { name: Contractor.name, schema: ContractorSchema },
      { name: User.name, schema: UserSchema },
    ]),
    TasksModule,
    AttendanceModule,
  ],
  controllers: [AssistantController],
  providers: [AssistantService],
  exports: [AssistantService],
})
export class AssistantModule {}
