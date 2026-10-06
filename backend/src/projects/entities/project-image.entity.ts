import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ProjectImageDocument = ProjectImage & Document;
import { Project } from './project.entity';
import { User } from '../../users/entities/user.entity';

@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }, collection: 'project_images' })
export class ProjectImage {
  id?: string;
  // id is natively handled by Mongoose as _id (ObjectId)

  @Prop({ type: String })
  url: string;

  @Prop({ type: String, nullable: true })
  caption: string;

  // TypeORM defaults this to the timestamp when the row is inserted, effectively enforcing current date.
  // // @CreateDateColumn
  date: Date;

  // @ManyToOne => Project, { onDelete: 'CASCADE' })
  // @JoinColumn
  project: Project;

  // @ManyToOne => User, { onDelete: 'CASCADE' })
  // @JoinColumn
  uploadedBy: User;
}

export const ProjectImageSchema = SchemaFactory.createForClass(ProjectImage);
