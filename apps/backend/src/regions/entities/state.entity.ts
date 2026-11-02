import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  Index,
} from 'typeorm';
import { District } from './district.entity';

export type RegionType = 'state' | 'union_territory';

@Entity('states')
export class State {
  @PrimaryColumn({ type: 'varchar', length: 10 })
  code: string; // ISO 3166-2:IN code, e.g., 'AP', 'TN', 'DL'

  @Index('idx_states_lgd_code')
  @Column({ type: 'varchar', length: 20, nullable: true, name: 'lgd_code' })
  lgdCode?: string;

  @Index('idx_states_name')
  @Column({ type: 'varchar', length: 100 })
  name: string; // Official English name

  @Column({ type: 'jsonb', default: () => "'{}'::jsonb", name: 'name_local' })
  nameLocal: Record<string, string>; // e.g. {"te": "ఆంధ్ర ప్రదేశ్", "ta": "ஆந்திரப் பிரதேசம்", "hi": "आन्ध्र प्रदेश"}

  @Index('idx_states_type')
  @Column({ type: 'varchar', length: 20, default: 'state' })
  type: RegionType; // 'state' | 'union_territory'

  @Column({ type: 'varchar', length: 100, nullable: true, name: 'capital_name' })
  capitalName?: string;

  @Column({ type: 'numeric', precision: 9, scale: 6, nullable: true, name: 'capital_lat' })
  capitalLat?: number;

  @Column({ type: 'numeric', precision: 9, scale: 6, nullable: true, name: 'capital_lon' })
  capitalLon?: number;

  @Column({ type: 'jsonb', default: () => "'[]'::jsonb" })
  languages: string[];

  @Column({ type: 'text', array: true, default: () => "'{}'::text[]" })
  aliases: string[];

  @Index('idx_states_slug', { unique: true })
  @Column({ type: 'varchar', length: 100, unique: true })
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

  @OneToMany(() => District, (district) => district.state)
  districts: District[];
}
