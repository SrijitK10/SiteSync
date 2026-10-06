import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ProjectDocument = Project & Document;
import { User } from '../../users/entities/user.entity';

@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }, collection: 'projects' })
export class Project {
  id?: string;
  // id is natively handled by Mongoose as _id (ObjectId)

  @Prop()
  name: string;

  @Prop({ type: String, nullable: true })
  description: string;

  @Prop()
  location: string;

  // // @Index - handled in @Prop
  @Prop({ default: 'active' }) // active, archived, completed
  status: string;

  @Prop({ type: Date, nullable: true })
  start_date: string;

  @Prop({ type: Date, nullable: true })
  end_date: string;

  // @ManyToOne => User)
  // @JoinColumn
  createdBy: User;

  // // @CreateDateColumn
  created_at: Date;

  // // @UpdateDateColumn
  updated_at: Date;
}

export const ProjectSchema = SchemaFactory.createForClass(Project);
