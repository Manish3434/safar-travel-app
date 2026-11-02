import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitialSchema1700000000000 implements MigrationInterface {
  name = 'InitialSchema1700000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Enable Required Extensions
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`);
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS postgis;`);

    // 2. Users Table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "users" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "email" character varying(255) NOT NULL,
        "password_hash" character varying(255) NOT NULL,
        "name" character varying(100),
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "uq_users_email" UNIQUE ("email"),
        CONSTRAINT "pk_users_id" PRIMARY KEY ("id")
      );
    `);

    // 3. Places Table with PostGIS Spatial Point
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "places" (
        "id" character varying(100) NOT NULL,
        "name" character varying(255) NOT NULL,
        "name_ta" character varying(255),
        "name_hi" character varying(255),
        "category" character varying(50) NOT NULL,
        "description" text NOT NULL,
        "main_photo_url" text,
        "photos" jsonb NOT NULL DEFAULT '[]'::jsonb,
        "location" geometry(Point, 4326) NOT NULL,
        "sensitive" boolean NOT NULL DEFAULT false,
        "permit_required" boolean NOT NULL DEFAULT false,
        "guide_required" boolean NOT NULL DEFAULT false,
        "difficulty" character varying(20),
        "best_season" character varying(100),
        "how_to_reach" text,
        "opening_hours" character varying(100),
        "network_info" character varying(100),
        "warnings" jsonb NOT NULL DEFAULT '[]'::jsonb,
        "nearest_road" character varying(255),
        "nearest_hospital" character varying(255),
        "rating" numeric(3, 2),
        "source" character varying(50) NOT NULL DEFAULT 'local',
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "pk_places_id" PRIMARY KEY ("id")
      );
    `);

    // 4. Spatial and Query Indexes
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_places_location" ON "places" USING GIST ("location");
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_places_category" ON "places" ("category");
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_places_sensitive" ON "places" ("sensitive");
    `);

    // 5. Saved Places Table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "saved_places" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "user_id" uuid NOT NULL,
        "place_id" character varying(100) NOT NULL,
        "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
        CONSTRAINT "pk_saved_places_id" PRIMARY KEY ("id"),
        CONSTRAINT "uq_saved_places_user_place" UNIQUE ("user_id", "place_id"),
        CONSTRAINT "fk_saved_places_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "fk_saved_places_place" FOREIGN KEY ("place_id") REFERENCES "places"("id") ON DELETE CASCADE
      );
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_saved_places_user" ON "saved_places" ("user_id");
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS "idx_saved_places_place" ON "saved_places" ("place_id");
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "saved_places";`);
    await queryRunner.query(`DROP INDEX IF EXISTS "idx_places_sensitive";`);
    await queryRunner.query(`DROP INDEX IF EXISTS "idx_places_category";`);
    await queryRunner.query(`DROP INDEX IF EXISTS "idx_places_location";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "places";`);
    await queryRunner.query(`DROP TABLE IF EXISTS "users";`);
  }
}
