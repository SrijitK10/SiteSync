import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('contractors')
export class Contractor {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  name: string;
}
