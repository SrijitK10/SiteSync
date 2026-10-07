import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { randomUUID } from 'crypto';

export type TaskDocument = Task & Document;

export enum TaskStatus {
  TODO = 'todo',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
}

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'tasks',
  toJSON: {
    virtuals: true,
    transform: (_doc, ret: any) => {
      ret.id = ret.id || ret._id?.toString();
      delete ret.__v;
      return ret;
    },
  },
  toObject: {
    virtuals: true,
    transform: (_doc, ret: any) => {
      ret.id = ret.id || ret._id?.toString();
      delete ret.__v;
      return ret;
    },
  },
})
export class Task {
  @Prop({ type: String, default: () => randomUUID(), index: true })
  id: string;

  @Prop({ required: true })
  title: string;

  @Prop({ type: String, default: null })
  description: string;

  @Prop({ type: Object, default: {} })
  title_translations: any;

  @Prop({ type: Object, default: {} })
  description_translations: any;

  @Prop({
    type: String,
    enum: TaskStatus,
    default: TaskStatus.TODO,
  })
  status: TaskStatus;

  @Prop({ type: Date, default: null })
  due_date: Date;

  @Prop({ type: String, required: true, index: true })
  project_id: string;

  @Prop({ type: String, default: null, index: true })
  flat_id: string;

  @Prop({ type: String, default: null, index: true })
  assigned_to: string;

  @Prop({ type: String, default: null, index: true })
  created_by: string;

  @Prop({ type: String, default: null, index: true })
  completed_by: string;

  @Prop({ type: Date, default: null })
  completed_at: Date;

  created_at: Date;
  updated_at: Date;

  // Virtual relation holders attached by service for frontend
  project?: any;
  flat?: any;
  assignee?: any;
  createdBy?: any;
  completedBy?: any;
}

export const TaskSchema = SchemaFactory.createForClass(Task);
TaskSchema.index({ project_id: 1, created_at: -1 });
TaskSchema.index({ project_id: 1, flat_id: 1 });
