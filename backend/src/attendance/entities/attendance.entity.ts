import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { randomUUID } from 'crypto';

export type AttendanceDocument = Attendance & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'attendance',
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
export class Attendance {
  @Prop({ type: String, default: () => randomUUID(), index: true })
  id: string;

  @Prop({ type: String, default: null })
  contractor_name: string | null;

  @Prop({ default: 0 })
  labourers_count: number;

  @Prop({ default: 0 })
  mistris_count: number;

  @Prop({ default: 0 })
  maati_kata_count: number;

  @Prop({ default: 0 })
  santras_count: number;

  @Prop({ type: String, default: null })
  work_description: string | null;

  @Prop({ default: '' })
  site_address: string;

  @Prop({ type: Date, default: Date.now })
  date: Date;

  @Prop({ type: String, required: true, index: true })
  project_id: string;

  @Prop({ type: String, default: null, index: true })
  recorded_by: string;

  created_at: Date;
  updated_at: Date;

  // Attached for frontend
  recorder?: any;
}

export const AttendanceSchema = SchemaFactory.createForClass(Attendance);
AttendanceSchema.index({ project_id: 1, date: -1 });
