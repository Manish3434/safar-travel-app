import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { State } from './state.entity';

@Entity('districts')
export class District {
  @PrimaryColumn({ type: 'varchar', length: 50, name: 'lgd_code' })
  lgdCode: string; // e.g. 'IN-AP-01' or LGD canonical code

  @Index('idx_districts_state_code')
  @Column({ type: 'varchar', length: 10, name: 'state_code' })
  stateCode: string; // References states.code

  @Index('idx_districts_name')
  @Column({ type: 'varchar', length: 100 })
  name: string; // Official English name

  @Column({ type: 'jsonb', default: () => "'{}'::jsonb", name: 'name_local' })
  nameLocal: Record<string, string>; // e.g. {"te": "...", "ta": "...", "hi": "..."}

  @Column({ type: 'text', array: true, default: () => "'{}'::text[]" })
  aliases: string[]; // Old spellings, bifurcated parent names, alternative names

  @Column({ type: 'varchar', length: 100, nullable: true })
  headquarters?: string;

  @Column({ type: 'numeric', precision: 10, scale: 2, nullable: true, name: 'area_km2' })
  areaKm2?: number;

  @Column({ type: 'integer', nullable: true, name: 'population_2011' })
  population2011?: number;

  @Column({ type: 'varchar', length: 50, default: 'district', name: 'subdivision_type' })
  subdivisionType: string;

  @Index('idx_districts_slug', { unique: true })
  @Column({ type: 'varchar', length: 150, unique: true })
  slug: string;

  @Column({ type: 'boolean', default: true })
  active: boolean;

  @Column({ type: 'varchar', length: 50, default: 'LGD/igod.gov.in' })
  source: string;

  @Column({ type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP', name: 'fetched_at' })
  fetchedAt: Date;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @ManyToOne(() => State, (state) => state.districts, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'state_code', referencedColumnName: 'code' })
  state: State;
}
