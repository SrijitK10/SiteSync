import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn, CreateDateColumn } from 'typeorm';
import { Task } from './task.entity';
import { User } from '../../users/entities/user.entity';

@Entity('task_attachments')
export class TaskAttachment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'text' })
  url: string;

  @Column({ type: 'text' })
  display_name: string;

  @Column({ type: 'text' })
  original_name: string;

  @Column({ type: 'text' })
  file_type: string; // 'image', 'pdf', 'document'

  @Column({ type: 'text', nullable: true })
  mime_type: string;

  @Column({ type: 'bigint', nullable: true })
  file_size: number;

  @ManyToOne(() => Task, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'task_id' })
  task: Task;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'uploaded_by' })
  uploadedBy: User;

  @CreateDateColumn()
  created_at: Date;
}
