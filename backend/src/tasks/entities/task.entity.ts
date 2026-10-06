import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type TaskDocument = Task & Document;
import { User } from '../../users/entities/user.entity';
import { Project } from '../../projects/entities/project.entity';
import { Flat } from '../../flats/entities/flat.entity';

export enum TaskStatus {
  TODO = 'todo',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
}

@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }, collection: 'tasks' })
export class Task {
  id?: string;
  // id is natively handled by Mongoose as _id (ObjectId)

  @Prop()
  title: string;

  @Prop({ type: String, nullable: true })
  description: string;

  @Prop({ type: Object })
  title_translations: any;

  @Prop({ type: Object })
  description_translations: any;

  @Prop({
    type: String,
    enum: TaskStatus,
    default: TaskStatus.TODO,
  })
  status: TaskStatus;

  @Prop({ type: Date, nullable: true })
  due_date: string;

  // // @Index - handled in @Prop
  // @ManyToOne => Project, { onDelete: 'CASCADE' })
  // @JoinColumn
  project: Project;

  // // @Index - handled in @Prop
  // @ManyToOne => Flat, { nullable: true, onDelete: 'SET NULL' })
  // @JoinColumn
  flat: Flat;

  // // @Index - handled in @Prop
  // @ManyToOne => User, { nullable: true, onDelete: 'SET NULL' })
  // @JoinColumn
  assignee: User;

  // // @Index - handled in @Prop
  // @ManyToOne => User, { nullable: true, onDelete: 'SET NULL' })
  // @JoinColumn
  createdBy: User;

  // // @Index - handled in @Prop
  // @ManyToOne => User, { nullable: true, onDelete: 'SET NULL' })
  // @JoinColumn
  completedBy: User;

  // // @Index - handled in @Prop
  // @CreateDateColumn
  created_at: Date;

  @Prop({ type: Date, nullable: true })
  completed_at: Date;

  // // @UpdateDateColumn
  updated_at: Date;
}

export const TaskSchema = SchemaFactory.createForClass(Task);
