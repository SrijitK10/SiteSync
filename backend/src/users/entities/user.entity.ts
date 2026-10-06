import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema({ timestamps: { createdAt: 'created_at', updatedAt: false }, collection: 'users' })
export class User {
  id?: string;
  @Prop()
  name: string;

  @Prop({ unique: true, sparse: true })
  phone: string; // E.164 format: +919876543210 (Android users)

  @Prop({ unique: true, sparse: true, index: true })
  email: string; // For iOS email-link auth users

  @Prop({ unique: true, sparse: true })
  firebase_uid: string;

  @Prop({ select: false })
  password_hash: string;

  @Prop()
  fcm_token: string;

  @Prop({ default: 'viewer' })
  role: string; // super_admin, admin, site_manager, viewer
}

export const UserSchema = SchemaFactory.createForClass(User);
