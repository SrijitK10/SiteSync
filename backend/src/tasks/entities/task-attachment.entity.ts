import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { randomUUID } from 'crypto';

export type TaskAttachmentDocument = TaskAttachment & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'task_attachments',
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
export class TaskAttachment {
  @Prop({ type: String, default: () => randomUUID(), index: true })
  id: string;

  @Prop({ type: String, default: '' })
  url: string;

  @Prop({ type: String, default: 'external' })
  storage_provider: string;

  @Prop({ type: String, required: true })
  display_name: string;

  @Prop({ type: String, required: true })
  original_name: string;

  @Prop({ type: String, default: 'document' })
  file_type: string; // 'image', 'pdf', 'document'

  @Prop({ type: String, default: null })
  mime_type: string;

  @Prop({ type: String, default: null })
  file_size: string;

  @Prop({ type: Buffer, default: null, select: false })
  file_data: Buffer | null;

  @Prop({ type: String, required: true, index: true })
  task_id: string;

  @Prop({ type: String, default: null, index: true })
  uploaded_by: string;

  created_at: Date;
  updated_at: Date;

  // Attached for frontend
  uploadedBy?: any;
}

export const TaskAttachmentSchema = SchemaFactory.createForClass(TaskAttachment);
