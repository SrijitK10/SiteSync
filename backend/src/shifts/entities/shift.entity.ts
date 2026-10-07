import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { randomUUID } from 'crypto';

export type ShiftDocument = Shift & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'shifts',
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
export class Shift {
  @Prop({ type: String, default: () => randomUUID(), index: true })
  id: string;

  @Prop({ type: String, required: true, index: true })
  user_id: string;

  @Prop({ type: String, required: true, index: true })
  project_id: string;

  @Prop({ type: Date, required: true })
  start_time: Date;

  @Prop({ type: Date, default: null })
  end_time: Date;

  @Prop({ type: String, default: null })
  notes: string;

  created_at: Date;
  updated_at: Date;

  // Attached for frontend
  user?: any;
  project?: any;
}

export const ShiftSchema = SchemaFactory.createForClass(Shift);
ShiftSchema.index({ user_id: 1, start_time: -1 });
ShiftSchema.index({ project_id: 1, start_time: -1 });
