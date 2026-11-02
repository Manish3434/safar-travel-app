import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateRegionsTables1700000000002 implements MigrationInterface {
  name = 'CreateRegionsTables1700000000002';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Create States and Union Territories Table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "states" (
        "code" character varying(10) NOT NULL,
        "lgd_code" character varying(20),
        "name" character varying(100) NOT NULL,
        "name_local" jsonb NOT NULL DEFAULT '{}'::jsonb,
        "type" character varying(20) NOT NULL DEFAULT 'state',
        "capital_name" character varying(100),
        "capital_lat" numeric(9, 6),
        "capital_lon" numeric(9, 6),
        "languages" jsonb NOT NULL DEFAULT '[]'::jsonb,
        "aliases" text[] NOT NULL DEFAULT '{}'::text[],
        "slug" character varying(100) NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "source" character varying(50) NOT NULL DEFAULT 'LGD/igod.gov.in',
        "fetched_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "pk_states_code" PRIMARY KEY ("code"),
        CONSTRAINT "uq_states_slug" UNIQUE ("slug")
      );
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_states_type" ON "states" ("type");
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_states_name" ON "states" ("name");
    `);

    // 2. Create Canonical Districts Table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "districts" (
        "lgd_code" character varying(50) NOT NULL,
        "state_code" character varying(10) NOT NULL,
        "name" character varying(100) NOT NULL,
        "name_local" jsonb NOT NULL DEFAULT '{}'::jsonb,
        "aliases" text[] NOT NULL DEFAULT '{}'::text[],
        "headquarters" character varying(100),
        "area_km2" numeric(10, 2),
        "population_2011" integer,
        "subdivision_type" character varying(50) NOT NULL DEFAULT 'district',
        "slug" character varying(150) NOT NULL,
        "active" boolean NOT NULL DEFAULT true,
        "source" character varying(50) NOT NULL DEFAULT 'LGD/igod.gov.in',
        "fetched_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "pk_districts_lgd_code" PRIMARY KEY ("lgd_code"),
        CONSTRAINT "uq_districts_slug" UNIQUE ("slug"),
        CONSTRAINT "fk_districts_state" FOREIGN KEY ("state_code") REFERENCES "states"("code") ON DELETE CASCADE
      );
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_districts_state_code" ON "districts" ("state_code");
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_districts_name" ON "districts" ("name");
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_districts_slug" ON "districts" ("slug");
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "districts";`);
    await queryRunner.query(`DROP INDEX IF EXISTS "idx_states_name";`);
    await queryRunner.query(`DROP INDEX IF EXISTS "idx_states_type";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "states";`);
  }
}
