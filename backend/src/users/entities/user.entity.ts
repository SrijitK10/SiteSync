import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true })
  phone: string; // E.164 format: +919876543210

  @Column({ unique: true, nullable: true })
  firebase_uid: string;

  @Column({ default: 'viewer' })
  role: string; // super_admin, admin, site_manager, viewer

  @CreateDateColumn()
  created_at: Date;
}
