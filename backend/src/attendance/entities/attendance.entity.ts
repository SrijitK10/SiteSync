import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn, CreateDateColumn, Index } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Project } from '../../projects/entities/project.entity';

@Entity('attendance')
export class Attendance {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', nullable: true })
  contractor_name: string | null;

  @Column({ default: 0 })
  labourers_count: number;

  @Column({ default: 0 })
  mistris_count: number;

  @Column({ default: 0 })
  maati_kata_count: number;

  @Column({ default: 0 })
  santras_count: number;

  @Column({ type: 'text', nullable: true })
  work_description: string | null;

  @Column()
  site_address: string;

  // Strips the Time Signature returning exact YYYY-MM-DD bounds dynamically
  @Index()
  @CreateDateColumn({ type: 'date' })
  date: Date;

  @CreateDateColumn()
  created_at: Date;

  @Index()
  @ManyToOne(() => Project, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'project_id' })
  project: Project;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'recorded_by' })
  recorder: User;
}
