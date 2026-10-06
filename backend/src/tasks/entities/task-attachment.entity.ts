import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type TaskAttachmentDocument = TaskAttachment & Document;
import { Task } from './task.entity';
import { User } from '../../users/entities/user.entity';

@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }, collection: 'task_attachments' })
export class TaskAttachment {
  id?: string;
  // id is natively handled by Mongoose as _id (ObjectId)

  @Prop({ type: String })
  url: string;

  @Prop({ type: String, default: 'external' })
  storage_provider: string;

  @Prop({ type: String })
  display_name: string;

  @Prop({ type: String })
  original_name: string;

  @Prop({ type: String })
  file_type: string; // 'image', 'pdf', 'document'

  @Prop({ type: String, nullable: true })
  mime_type: string;

  @Prop({ type: Number, nullable: true })
  file_size: number;

  @Prop({ type: Buffer, nullable: true, select: false })
  file_data: Buffer | null;

  // @ManyToOne => Task, { onDelete: 'CASCADE' })
  // @JoinColumn
  task: Task;

  // @ManyToOne => User, { nullable: true, onDelete: 'SET NULL' })
  // @JoinColumn
  uploadedBy: User;

  // // @CreateDateColumn
  created_at: Date;
}

export const TaskAttachmentSchema = SchemaFactory.createForClass(TaskAttachment);
