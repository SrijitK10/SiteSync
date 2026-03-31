import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true, nullable: true })
  phone: string; // E.164 format: +919876543210 (Android users)

  @Column({ unique: true, nullable: true })
  email: string; // For iOS email-link auth users

  @Column({ unique: true, nullable: true })
  firebase_uid: string;

  @Column({ nullable: true, select: false })
  password_hash: string;

  @Column({ default: 'viewer' })
  role: string; // super_admin, admin, site_manager, viewer

  @CreateDateColumn()
  created_at: Date;
}
