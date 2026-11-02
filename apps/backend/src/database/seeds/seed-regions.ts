import * as fs from 'fs';
import * as path from 'path';
import { AppDataSource } from '../data-source';
import { State, RegionType } from '../../regions/entities/state.entity';
import { District } from '../../regions/entities/district.entity';

// Utility: parse standard CSV row handling quotes
function parseCsvLine(line: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (char === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++; // skip escaped quote
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      result.push(current);
      current = '';
    } else {
      current += char;
    }
  }
  result.push(current);
  return result;
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')
    .trim()
    .replace(/[-\s]+/g, '-');
}

export async function seedRegions(): Promise<{ statesCount: number; districtsCount: number }> {
  const isInitialized = AppDataSource.isInitialized;
  if (!isInitialized) {
    await AppDataSource.initialize();
  }

  const queryRunner = AppDataSource.createQueryRunner();
  await queryRunner.connect();

  const rootDir = path.resolve(__dirname, '../../../../');
  const statesCsvPath = path.join(rootDir, 'data/states.csv');
  const regionsRefCsvPath = path.join(rootDir, 'data/reference/regions_reference.csv');

  console.log(`[SeedRegions] Reading States from: ${statesCsvPath}`);
  console.log(`[SeedRegions] Reading Districts from: ${regionsRefCsvPath}`);

  // 1. Ingest States from data/states.csv
  const statesRaw = fs.readFileSync(statesCsvPath, 'utf-8').trim().split('\n');
  const stateHeaders = parseCsvLine(statesRaw[0]);
  const stateRows = statesRaw.slice(1);

  const stateRepo = AppDataSource.getRepository(State);
  const districtRepo = AppDataSource.getRepository(District);

  let statesCount = 0;
  for (const line of stateRows) {
    if (!line.trim()) continue;
    const cols = parseCsvLine(line);
    const row: Record<string, string> = {};
    stateHeaders.forEach((h, idx) => {
      row[h.trim()] = cols[idx]?.trim() || '';
    });

    const code = row['code'];
    const name = row['name'];
    const type = (row['type'] || 'state') as RegionType;
    const lgdCode = row['census_2011_code'] || code;
    const capitalName = row['capital_name'] || null;
    const capitalLat = row['capital_lat'] ? parseFloat(row['capital_lat']) : null;
    const capitalLon = row['capital_lon'] ? parseFloat(row['capital_lon']) : null;
    const slug = row['slug'] || slugify(name);

    let languages: string[] = [];
    try {
      if (row['languages']) {
        languages = JSON.parse(row['languages']);
      }
    } catch {
      languages = ['English', 'Hindi'];
    }

    const aliases: string[] = [];
    if (code === 'AN') aliases.push('Andaman & Nicobar Islands', 'Andaman and Nicobar');
    if (code === 'JK') aliases.push('Jammu & Kashmir', 'J&K');
    if (code === 'DN') aliases.push('Dadra and Nagar Haveli', 'Daman and Diu', 'DNHDD');
    if (code === 'DL') aliases.push('NCT of Delhi', 'National Capital Territory of Delhi');

    // Idempotent upsert for State
    await queryRunner.query(
      `
      INSERT INTO "states" (
        "code", "lgd_code", "name", "name_local", "type",
        "capital_name", "capital_lat", "capital_lon",
        "languages", "aliases", "slug", "active", "source", "fetched_at"
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, true, $12, NOW())
      ON CONFLICT ("code") DO UPDATE SET
        "lgd_code" = EXCLUDED."lgd_code",
        "name" = EXCLUDED."name",
        "type" = EXCLUDED."type",
        "capital_name" = EXCLUDED."capital_name",
        "capital_lat" = EXCLUDED."capital_lat",
        "capital_lon" = EXCLUDED."capital_lon",
        "languages" = EXCLUDED."languages",
        "aliases" = EXCLUDED."aliases",
        "slug" = EXCLUDED."slug",
        "active" = true,
        "updated_at" = NOW();
      `,
      [
        code,
        lgdCode,
        name,
        JSON.stringify({}),
        type,
        capitalName,
        capitalLat,
        capitalLon,
        JSON.stringify(languages),
        aliases,
        slug,
        'LGD/igod.gov.in',
      ]
    );
    statesCount++;
  }

  console.log(`✓ Seeded ${statesCount} States and Union Territories (28 States + 8 UTs)`);

  // 2. Ingest Canonical Districts from data/reference/regions_reference.csv
  const distRaw = fs.readFileSync(regionsRefCsvPath, 'utf-8').trim().split('\n');
  const distHeaders = parseCsvLine(distRaw[0]);
  const distRows = distRaw.slice(1);

  let districtsCount = 0;
  for (const line of distRows) {
    if (!line.trim()) continue;
    const cols = parseCsvLine(line);
    const row: Record<string, string> = {};
    distHeaders.forEach((h, idx) => {
      row[h.trim()] = cols[idx]?.trim() || '';
    });

    const lgdCode = row['district_code'];
    const stateCode = row['state_code'];
    const name = row['district_name'];
    const slug = `${slugify(name)}-${stateCode.toLowerCase()}`;

    // Aliases for renamed / historically known districts
    const aliases: string[] = [];
    if (name === 'Ahilyanagar') aliases.push('Ahmednagar');
    if (name === 'Chhatrapati Sambhajinagar') aliases.push('Aurangabad');
    if (name === 'Dharashiv') aliases.push('Osmanabad');
    if (name === 'Prayagraj') aliases.push('Allahabad');
    if (name === 'Ayodhya') aliases.push('Faizabad');
    if (name === 'Narmadapuram') aliases.push('Hoshangabad');
    if (name === 'Sribhumi') aliases.push('Karimganj');

    // Idempotent upsert for District
    await queryRunner.query(
      `
      INSERT INTO "districts" (
        "lgd_code", "state_code", "name", "name_local", "aliases",
        "headquarters", "subdivision_type", "slug", "active", "source", "fetched_at"
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, $9, NOW())
      ON CONFLICT ("lgd_code") DO UPDATE SET
        "state_code" = EXCLUDED."state_code",
        "name" = EXCLUDED."name",
        "aliases" = EXCLUDED."aliases",
        "headquarters" = EXCLUDED."headquarters",
        "slug" = EXCLUDED."slug",
        "active" = true,
        "updated_at" = NOW();
      `,
      [
        lgdCode,
        stateCode,
        name,
        JSON.stringify({}),
        aliases,
        name,
        'district',
        slug,
        'LGD/igod.gov.in',
      ]
    );
    districtsCount++;
  }

  console.log(`✓ Seeded ${districtsCount} Canonical Districts across 36 Regions`);
  await queryRunner.release();

  if (!isInitialized) {
    await AppDataSource.destroy();
  }

  return { statesCount, districtsCount };
}

// Allow direct CLI execution: ts-node src/database/seeds/seed-regions.ts
if (require.main === module) {
  seedRegions()
    .then(({ statesCount, districtsCount }) => {
      console.log(`=======================================================`);
      console.log(`✓ IDEMPOTENT SEED FINISHED: ${statesCount} States/UTs, ${districtsCount} Districts`);
      console.log(`=======================================================`);
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ Error during region seeding:', err);
      process.exit(1);
    });
}
