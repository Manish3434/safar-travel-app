import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
  Index,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';
import { Place } from '../../places/entities/place.entity';

@Entity('saved_places')
@Unique('uq_saved_places_user_place', ['userId', 'placeId'])
export class SavedPlace {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index('idx_saved_places_user')
  @Column({ type: 'uuid', name: 'user_id' })
  userId: string;

  @Index('idx_saved_places_place')
  @Column({ type: 'varchar', length: 100, name: 'place_id' })
  placeId: string;

  @CreateDateColumn({ type: 'timestamptz', name: 'created_at' })
  createdAt: Date;

  @ManyToOne(() => User, (user) => user.savedPlaces, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @ManyToOne(() => Place, (place) => place.savedBy, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'place_id' })
  place?: Place;
}
