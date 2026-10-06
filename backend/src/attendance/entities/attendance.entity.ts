import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type AttendanceDocument = Attendance & Document;
import { User } from '../../users/entities/user.entity';
import { Project } from '../../projects/entities/project.entity';

@Schema({ timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' }, collection: 'attendance' })
export class Attendance {
  id?: string;
  // id is natively handled by Mongoose as _id (ObjectId)

  @Prop({ type: String, nullable: true })
  contractor_name: string | null;

  @Prop({ default: 0 })
  labourers_count: number;

  @Prop({ default: 0 })
  mistris_count: number;

  @Prop({ default: 0 })
  maati_kata_count: number;

  @Prop({ default: 0 })
  santras_count: number;

  @Prop({ type: String, nullable: true })
  work_description: string | null;

  @Prop()
  site_address: string;

  // Strips the Time Signature returning exact YYYY-MM-DD bounds dynamically
  // // @Index - handled in @Prop
  // @CreateDateColumn
  date: Date;

  // // @CreateDateColumn
  created_at: Date;

  // // @Index - handled in @Prop
  // @ManyToOne => Project, { onDelete: 'CASCADE' })
  // @JoinColumn
  project: Project;

  // @ManyToOne => User, { nullable: true, onDelete: 'SET NULL' })
  // @JoinColumn
  recorder: User;
}

export const AttendanceSchema = SchemaFactory.createForClass(Attendance);
