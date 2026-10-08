import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { randomUUID } from 'crypto';

export type AssistantMessageDocument = AssistantMessage & Document;

export enum AssistantIntent {
  TASK = 'task',
  ATTENDANCE = 'attendance',
  CLARIFICATION = 'clarification',
  UNKNOWN = 'unknown',
}

export enum AssistantExecutionStatus {
  PENDING = 'pending',
  EXECUTED = 'executed',
  CANCELLED = 'cancelled',
  FAILED = 'failed',
}

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'assistant_messages',
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
export class AssistantMessage {
  @Prop({ type: String, default: () => randomUUID(), index: true })
  id: string;

  @Prop({ required: true, index: true })
  user_id: string;

  @Prop({ default: 'Worker' })
  user_name: string;

  @Prop({ default: 'site_manager' })
  user_role: string;

  @Prop({ required: true })
  raw_input: string;

  @Prop({
    type: String,
    enum: AssistantIntent,
    default: AssistantIntent.UNKNOWN,
    index: true,
  })
  intent: AssistantIntent;

  @Prop({ type: Object, default: {} })
  parsed_data: Record<string, any>;

  @Prop({
    type: String,
    enum: AssistantExecutionStatus,
    default: AssistantExecutionStatus.PENDING,
    index: true,
  })
  execution_status: AssistantExecutionStatus;

  @Prop({ type: String, default: null })
  created_record_id: string | null;

  @Prop({ type: String, default: '' })
  assistant_reply: string;

  created_at: Date;
  updated_at: Date;
}

export const AssistantMessageSchema = SchemaFactory.createForClass(AssistantMessage);
AssistantMessageSchema.index({ created_at: -1 });
