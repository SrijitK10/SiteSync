import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { randomUUID } from 'crypto';

export type ContractorDocument = Contractor & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'contractors',
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
export class Contractor {
  @Prop({ type: String, default: () => randomUUID(), index: true })
  id: string;

  @Prop({ required: true, unique: true })
  name: string;

  created_at: Date;
  updated_at: Date;
}

export const ContractorSchema = SchemaFactory.createForClass(Contractor);
