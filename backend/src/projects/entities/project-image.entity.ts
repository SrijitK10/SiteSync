import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';
import { randomUUID } from 'crypto';

export type ProjectImageDocument = ProjectImage & Document;

@Schema({
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'project_images',
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
export class ProjectImage {
  @Prop({ type: String, default: () => randomUUID(), index: true })
  id: string;

  @Prop({ type: String, required: true })
  url: string;

  @Prop({ type: String, default: null })
  caption: string;

  @Prop({ type: Date, default: Date.now })
  date: Date;

  @Prop({ type: String, required: true, index: true })
  project_id: string;

  @Prop({ type: String, required: true, index: true })
  uploaded_by: string;

  // Attached for frontend
  uploadedBy?: any;
}

export const ProjectImageSchema = SchemaFactory.createForClass(ProjectImage);
