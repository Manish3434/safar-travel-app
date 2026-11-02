import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
  OneToMany,
} from 'typeorm';
import { SavedPlace } from '../../saved-places/entities/saved-place.entity';

export interface GeoPoint {
  type: 'Point';
  coordinates: [number, number]; // [lng, lat] per GeoJSON specification
}

@Entity('places')
export class Place {
  @PrimaryColumn({ type: 'varchar', length: 100 })
  id: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'varchar', length: 255, nullable: true, name: 'name_ta' })
  nameTa?: string;

  @Column({ type: 'varchar', length: 255, nullable: true, name: 'name_hi' })
  nameHi?: string;

  @Index('idx_places_state')
  @Column({ type: 'varchar', length: 10, nullable: true, name: 'state_code' })
  stateCode?: string;

  @Column({ type: 'varchar', length: 50, nullable: true, name: 'state_name' })
  stateName?: string;

  @Index('idx_places_district')
  @Column({ type: 'varchar', length: 50, nullable: true, name: 'district_id' })
  districtId?: string;

  @Column({ type: 'varchar', length: 100, nullable: true, name: 'district_name' })
  districtName?: string;

  @Index('idx_places_category')
  @Column({ type: 'varchar', length: 50 })
  category: string;

  @Column({ type: 'text' })
  description: string;

  @Column({ type: 'text', nullable: true, name: 'main_photo_url' })
  mainPhotoUrl?: string;

  @Column({ type: 'jsonb', default: () => "'[]'::jsonb" })
  photos: string[];

  @Index('idx_places_location', { spatial: true })
  @Column({
    type: 'geometry',
    spatialFeatureType: 'Point',
    srid: 4326,
  })
  location: GeoPoint;

  @Index('idx_places_sensitive')
  @Column({ type: 'boolean', default: false })
  sensitive: boolean;

  @Column({ type: 'boolean', default: false, name: 'permit_required' })
  permitRequired: boolean;

  @Column({ type: 'boolean', default: false, name: 'guide_required' })
  guideRequired: boolean;

  @Column({ type: 'varchar', length: 20, nullable: true })
  difficulty?: 'easy' | 'moderate' | 'hard';

  @Column({ type: 'varchar', length: 100, nullable: true, name: 'best_season' })
  bestSeason?: string;

  @Column({ type: 'text', nullable: true, name: 'how_to_reach' })
  howToReach?: string;

  @Column({ type: 'varchar', length: 100, nullable: true, name: 'opening_hours' })
  openingHours?: string;

  @Column({ type: 'varchar', length: 100, nullable: true, name: 'network_info' })
  networkInfo?: string;

  @Column({ type: 'jsonb', default: () => "'[]'::jsonb" })
  warnings: string[];

  @Column({ type: 'varchar', length: 255, nullable: true, name: 'nearest_road' })
  nearestRoad?: string;

  @Column({ type: 'varchar', length: 255, nullable: true, name: 'nearest_hospital' })
  nearestHospital?: string;

  @Column({ type: 'numeric', precision: 3, scale: 2, nullable: true })
  rating?: number;

  @Column({ type: 'varchar', length: 50, default: 'local' })
  source: string;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz', name: 'updated_at' })
  updatedAt: Date;

  @OneToMany(() => SavedPlace, (savedPlace) => savedPlace.place)
  savedBy?: SavedPlace[];
}
