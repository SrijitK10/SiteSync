import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ShiftDocument = Shift & Document;
import { User } from '../../users/entities/user.entity';
import { Project } from '../../projects/entities/project.entity';

@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }, collection: 'shifts' })
export class Shift {
  id?: string;
  // id is natively handled by Mongoose as _id (ObjectId)

  // // @Index - handled in @Prop
  // @ManyToOne => User, { onDelete: 'CASCADE' })
  // @JoinColumn
  user: User;

  // // @Index - handled in @Prop
  // @ManyToOne => Project, { onDelete: 'CASCADE' })
  // @JoinColumn
  project: Project;

  // // @Index - handled in @Prop
  @Prop({ type: Date })
  start_time: Date;

  @Prop({ type: Date })
  end_time: Date;

  @Prop({ nullable: true })
  notes: string;

  // // @CreateDateColumn
  created_at: Date;

  // // @UpdateDateColumn
  updated_at: Date;
}

export const ShiftSchema = SchemaFactory.createForClass(Shift);
