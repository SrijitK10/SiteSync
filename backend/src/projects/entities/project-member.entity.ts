import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { randomUUID } from 'crypto';

export type ProjectMemberDocument = ProjectMember & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'project_members',
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
export class ProjectMember {
  @Prop({ type: String, default: () => randomUUID(), index: true })
  id: string;

  @Prop({ type: String, required: true, index: true })
  project_id: string;

  @Prop({ type: String, required: true, index: true })
  user_id: string;

  @Prop({ default: 'member' })
  role_in_project: string;

  @Prop({ type: Date, default: Date.now })
  assigned_at: Date;

  // Populated relations (virtuals / attached in service)
  user?: any;
  project?: any;
}

export const ProjectMemberSchema = SchemaFactory.createForClass(ProjectMember);
ProjectMemberSchema.index({ project_id: 1, user_id: 1 }, { unique: true });
