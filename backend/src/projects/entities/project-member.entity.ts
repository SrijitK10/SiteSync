import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ProjectMemberDocument = ProjectMember & Document;
import { User } from '../../users/entities/user.entity';
import { Project } from './project.entity';

@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }, collection: 'project_members' })
export class ProjectMember {
  id?: string;
  // id is natively handled by Mongoose as _id (ObjectId)

  // @ManyToOne => Project, { onDelete: 'CASCADE' })
  // @JoinColumn
  project: Project;

  // @ManyToOne => User, { onDelete: 'CASCADE', eager: true })
  // @JoinColumn
  user: User;

  @Prop({ default: 'member' })
  role_in_project: string; // member (access granted)

  // // @CreateDateColumn
  assigned_at: Date;
}

export const ProjectMemberSchema = SchemaFactory.createForClass(ProjectMember);
