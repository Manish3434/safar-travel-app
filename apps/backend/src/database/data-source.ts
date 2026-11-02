import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load .env from backend root or workspace root
dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

import { User } from '../auth/entities/user.entity';
import { Place } from '../places/entities/place.entity';
import { SavedPlace } from '../saved-places/entities/saved-place.entity';
import { State } from '../regions/entities/state.entity';
import { District } from '../regions/entities/district.entity';

export const AppDataSource = new DataSource({
  type: 'postgres',
  url: process.env.DATABASE_URL || 'postgresql://safar:safar@localhost:5432/safar',
  entities: [User, Place, SavedPlace, State, District],
  migrations: [path.join(__dirname, 'migrations/*{.ts,.js}')],
  synchronize: false,
  logging: process.env.NODE_ENV === 'development',
});

export default AppDataSource;
