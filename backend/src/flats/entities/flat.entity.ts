import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn, CreateDateColumn, Index, Unique } from 'typeorm';
import { Project } from '../../projects/entities/project.entity';

@Entity('flats')
@Unique(['project', 'flat_number'])
export class Flat {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  flat_number: string;

  @Column({ default: false })
  is_completed: boolean;

  @Index()
  @ManyToOne(() => Project, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'project_id' })
  project: Project;

  @CreateDateColumn()
  created_at: Date;
}
