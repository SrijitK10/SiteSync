import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type FlatDocument = Flat & Document;
import { Project } from '../../projects/entities/project.entity';

@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }, collection: 'flats' })
export class Flat {
  id?: string;
  // id is natively handled by Mongoose as _id (ObjectId)

  @Prop()
  flat_number: string;

  @Prop({ default: false })
  is_completed: boolean;

  // // @Index - handled in @Prop
  // @ManyToOne => Project, { onDelete: 'CASCADE' })
  // @JoinColumn
  project: Project;

  // // @CreateDateColumn
  created_at: Date;
}

export const FlatSchema = SchemaFactory.createForClass(Flat);
