import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { randomUUID } from 'crypto';

export type FlatDocument = Flat & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'flats',
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
export class Flat {
  @Prop({ type: String, default: () => randomUUID(), index: true })
  id: string;

  @Prop({ required: true })
  flat_number: string;

  @Prop({ default: false })
  is_completed: boolean;

  @Prop({ type: String, required: true, index: true })
  project_id: string;

  created_at: Date;
  updated_at: Date;
}

export const FlatSchema = SchemaFactory.createForClass(Flat);
FlatSchema.index({ project_id: 1, flat_number: 1 }, { unique: true });
