import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { randomUUID } from 'crypto';

export type ProjectDocument = Project & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'projects',
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
export class Project {
  @Prop({ type: String, default: () => randomUUID(), index: true })
  id: string;

  @Prop({ required: true })
  name: string;

  @Prop({ type: String, default: null })
  description: string;

  @Prop({ default: '' })
  location: string;

  @Prop({ default: 'active' }) // active, archived, completed
  status: string;

  @Prop({ type: Date, default: null })
  start_date: Date;

  @Prop({ type: Date, default: null })
  end_date: Date;

  @Prop({ type: String, index: true, default: null })
  created_by: string;

  created_at: Date;
  updated_at: Date;
}

export const ProjectSchema = SchemaFactory.createForClass(Project);
