import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ContractorDocument = Contractor & Document;

@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }, collection: 'contractors' })
export class Contractor {
  id?: string;
  // id is natively handled by Mongoose as _id (ObjectId)

  @Prop({ unique: true })
  name: string;
}

export const ContractorSchema = SchemaFactory.createForClass(Contractor);
