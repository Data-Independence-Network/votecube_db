drop database votecube cascade;

create database votecube;


-- CREATE TABLE "CATEGORIES" -------------------------
CREATE TABLE "votecube"."CATEGORIES"
(
  "REPOSITORY_ID"             Bigint                   NOT NULL,
  "ACTOR_ID"                  Bigint                   NOT NULL,
  "ACTOR_RECORD_ID"           Bigint                   NOT NULL,
  "AGE_SUITABILITY"           Smallint                 NOT NULL,
  "SYSTEM_WIDE_OPERATION_ID"  Bigint                   NOT NULL,
  "NAME"                      Text                     NOT NULL,
  "CATEGORIES_RID_1"          Bigint                   ,
  "CATEGORIES_AID_1"          Bigint                   ,
  "CATEGORIES_ARID_1"         Bigint                   ,
  PRIMARY KEY ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
);
-- -------------------------------------------------------------

-- CREATE INDEX "idx_CATEGORIES__CATEGORIES_1" -
CREATE INDEX "idx_CATEGORIES__CATEGORIES_1" ON "votecube"."CATEGORIES" 
USING btree ("CATEGORIES_RID_1", "CATEGORIES_AID_1", "CATEGORIES_ARID_1");
-- -------------------------------------------------------------


-- CREATE TABLE "FACTORS" -------------------------
CREATE TABLE "votecube"."FACTORS"
(
  "REPOSITORY_ID"             Bigint                   NOT NULL,
  "ACTOR_ID"                  Bigint                   NOT NULL,
  "ACTOR_RECORD_ID"           Bigint                   NOT NULL,
  "AGE_SUITABILITY"           Smallint                 NOT NULL,
  "SYSTEM_WIDE_OPERATION_ID"  Bigint                   NOT NULL,
  "NAME"                      Text                     NOT NULL,
  PRIMARY KEY ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
);
-- -------------------------------------------------------------


-- CREATE TABLE "POSITIONS" -------------------------
CREATE TABLE "votecube"."POSITIONS"
(
  "REPOSITORY_ID"             Bigint                   NOT NULL,
  "ACTOR_ID"                  Bigint                   NOT NULL,
  "ACTOR_RECORD_ID"           Bigint                   NOT NULL,
  "AGE_SUITABILITY"           Smallint                 NOT NULL,
  "SYSTEM_WIDE_OPERATION_ID"  Bigint                   NOT NULL,
  "NAME"                      Text                     NOT NULL,
  PRIMARY KEY ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
);
-- -------------------------------------------------------------


-- CREATE TABLE "FACTOR_POSITIONS" -------------------------
CREATE TABLE "votecube"."FACTOR_POSITIONS"
(
  "REPOSITORY_ID"             Bigint                   NOT NULL,
  "ACTOR_ID"                  Bigint                   NOT NULL,
  "ACTOR_RECORD_ID"           Bigint                   NOT NULL,
  "AGE_SUITABILITY"           Smallint                 NOT NULL,
  "SYSTEM_WIDE_OPERATION_ID"  Bigint                   NOT NULL,
  "NAME"                      Text                     NOT NULL,
  "FACTORS_RID_1"             Bigint                   NOT NULL,
  "FACTORS_AID_1"             Bigint                   NOT NULL,
  "FACTORS_ARID_1"            Bigint                   NOT NULL,
  "POSITIONS_RID_1"           Bigint                   NOT NULL,
  "POSITIONS_AID_1"           Bigint                   NOT NULL,
  "POSITIONS_ARID_1"          Bigint                   NOT NULL,
  PRIMARY KEY ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
);
-- -------------------------------------------------------------

-- CREATE INDEX "idx_FACTOR_POSITIONS__FACTORS_1" -
CREATE INDEX "idx_FACTOR_POSITIONS__FACTORS_1" ON "votecube"."FACTOR_POSITIONS" 
USING btree ("FACTORS_RID_1", "FACTORS_AID_1", "FACTORS_ARID_1");
-- -------------------------------------------------------------

-- CREATE INDEX "idx_FACTOR_POSITIONS__POSITIONS_1" -
CREATE INDEX "idx_FACTOR_POSITIONS__POSITIONS_1" ON "votecube"."FACTOR_POSITIONS" 
USING btree ("POSITIONS_RID_1", "POSITIONS_AID_1", "POSITIONS_ARID_1");
-- -------------------------------------------------------------


-- CREATE TABLE "OUTCOMES" -------------------------
CREATE TABLE "votecube"."OUTCOMES"
(
  "REPOSITORY_ID"             Bigint                   NOT NULL,
  "ACTOR_ID"                  Bigint                   NOT NULL,
  "ACTOR_RECORD_ID"           Bigint                   NOT NULL,
  "AGE_SUITABILITY"           Smallint                 NOT NULL,
  "SYSTEM_WIDE_OPERATION_ID"  Bigint                   NOT NULL,
  "NAME"                      Text                     NOT NULL,
  PRIMARY KEY ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
);
-- -------------------------------------------------------------


-- CREATE TABLE "SITUATION_FACTOR_POSITIONS" -------------------------
CREATE TABLE "votecube"."SITUATION_FACTOR_POSITIONS"
(
  "REPOSITORY_ID"             Bigint                   NOT NULL,
  "ACTOR_ID"                  Bigint                   NOT NULL,
  "ACTOR_RECORD_ID"           Bigint                   NOT NULL,
  "AGE_SUITABILITY"           Smallint                 NOT NULL,
  "SYSTEM_WIDE_OPERATION_ID"  Bigint                   NOT NULL,
  "NAME"                      Text                     NOT NULL,
  "FACTOR_COORDINATE_AXIS"    Character(1)             NOT NULL,
  "POSITION_ORIENTATION"      Smallint                 NOT NULL,
  "FACTOR_NUMBER"             Smallint                 NOT NULL,
  "COLOR_BLUE"                Smallint                 NOT NULL,
  "COLOR_GREEN"               Smallint                 NOT NULL,
  "COLOR_RED"                 Smallint                 NOT NULL,
  "OUTCOME_ORDINAL"           Character(1)             NOT NULL,
  "SITUATIONS_RID_1"          Bigint                   NOT NULL,
  "SITUATIONS_AID_1"          Bigint                   NOT NULL,
  "SITUATIONS_ARID_1"         Bigint                   NOT NULL,
  "FACTOR_POSITIONS_RID_1"    Bigint                   NOT NULL,
  "FACTOR_POSITIONS_AID_1"    Bigint                   NOT NULL,
  "FACTOR_POSITIONS_ARID_1"   Bigint                   NOT NULL,
  PRIMARY KEY ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
);
-- -------------------------------------------------------------

-- CREATE INDEX "idx_SITUATION_FACTOR_POSITIONS__SITUATIONS_1" -
CREATE INDEX "idx_SITUATION_FACTOR_POSITIONS__SITUATIONS_1" ON "votecube"."SITUATION_FACTOR_POSITIONS" 
USING btree ("SITUATIONS_RID_1", "SITUATIONS_AID_1", "SITUATIONS_ARID_1");
-- -------------------------------------------------------------

-- CREATE INDEX "idx_SITUATION_FACTOR_POSITIONS__FACTOR_POSITIONS_1" -
CREATE INDEX "idx_SITUATION_FACTOR_POSITIONS__FACTOR_POSITIONS_1" ON "votecube"."SITUATION_FACTOR_POSITIONS" 
USING btree ("FACTOR_POSITIONS_RID_1", "FACTOR_POSITIONS_AID_1", "FACTOR_POSITIONS_ARID_1");
-- -------------------------------------------------------------


-- CREATE TABLE "SITUATIONS" -------------------------
CREATE TABLE "votecube"."SITUATIONS"
(
  "REPOSITORY_ID"             Bigint                   NOT NULL,
  "ACTOR_ID"                  Bigint                   NOT NULL,
  "ACTOR_RECORD_ID"           Bigint                   NOT NULL,
  "AGE_SUITABILITY"           Smallint                 NOT NULL,
  "SYSTEM_WIDE_OPERATION_ID"  Bigint                   NOT NULL,
  "NAME"                      Text                     NOT NULL,
  "CATEGORIES_RID_1"          Bigint                   NOT NULL,
  "CATEGORIES_AID_1"          Bigint                   NOT NULL,
  "CATEGORIES_ARID_1"         Bigint                   NOT NULL,
  "SITUATIONS_RID_1"          Bigint                   ,
  "SITUATIONS_AID_1"          Bigint                   ,
  "SITUATIONS_ARID_1"         Bigint                   ,
  "OUTCOMES_RID_1"            Bigint                   NOT NULL,
  "OUTCOMES_AID_1"            Bigint                   NOT NULL,
  "OUTCOMES_ARID_1"           Bigint                   NOT NULL,
  "OUTCOMES_RID_2"            Bigint                   NOT NULL,
  "OUTCOMES_AID_2"            Bigint                   NOT NULL,
  "OUTCOMES_ARID_2"           Bigint                   NOT NULL,
  PRIMARY KEY ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
);
-- -------------------------------------------------------------

-- CREATE INDEX "idx_SITUATIONS__CATEGORIES_1" -
CREATE INDEX "idx_SITUATIONS__CATEGORIES_1" ON "votecube"."SITUATIONS" 
USING btree ("CATEGORIES_RID_1", "CATEGORIES_AID_1", "CATEGORIES_ARID_1");
-- -------------------------------------------------------------

-- CREATE INDEX "idx_SITUATIONS__SITUATIONS_1" -
CREATE INDEX "idx_SITUATIONS__SITUATIONS_1" ON "votecube"."SITUATIONS" 
USING btree ("SITUATIONS_RID_1", "SITUATIONS_AID_1", "SITUATIONS_ARID_1");
-- -------------------------------------------------------------

-- CREATE INDEX "idx_SITUATIONS__OUTCOMES_1" -
CREATE INDEX "idx_SITUATIONS__OUTCOMES_1" ON "votecube"."SITUATIONS" 
USING btree ("OUTCOMES_RID_1", "OUTCOMES_AID_1", "OUTCOMES_ARID_1");
-- -------------------------------------------------------------

-- CREATE INDEX "idx_SITUATIONS__OUTCOMES_1" -
CREATE INDEX "idx_SITUATIONS__OUTCOMES_2" ON "votecube"."SITUATIONS" 
USING btree ("OUTCOMES_RID_2", "OUTCOMES_AID_2", "OUTCOMES_ARID_1");
-- -------------------------------------------------------------


-- CREATE LINK "fk_CATEGORIES__CATEGORIES_1" ----------
ALTER TABLE "votecube"."CATEGORIES"
  ADD CONSTRAINT "fk_CATEGORIES__CATEGORIES_1"
  FOREIGN KEY ("CATEGORIES_RID_1", "CATEGORIES_AID_1", "CATEGORIES_ARID_1")
    REFERENCES "votecube"."CATEGORIES" ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
    ON DELETE Cascade
    ON UPDATE Cascade;
-- -------------------------------------------------------------


-- CREATE LINK "fk_FACTOR_POSITIONS__FACTORS_1" ----------
ALTER TABLE "votecube"."FACTOR_POSITIONS"
  ADD CONSTRAINT "fk_FACTOR_POSITIONS__FACTORS_1"
  FOREIGN KEY ("FACTORS_RID_1", "FACTORS_AID_1", "FACTORS_ARID_1")
    REFERENCES "votecube"."FACTORS" ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
    ON DELETE Cascade
    ON UPDATE Cascade;
-- -------------------------------------------------------------


-- CREATE LINK "fk_FACTOR_POSITIONS__POSITIONS_1" ----------
ALTER TABLE "votecube"."FACTOR_POSITIONS"
  ADD CONSTRAINT "fk_FACTOR_POSITIONS__POSITIONS_1"
  FOREIGN KEY ("POSITIONS_RID_1", "POSITIONS_AID_1", "POSITIONS_ARID_1")
    REFERENCES "votecube"."POSITIONS" ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
    ON DELETE Cascade
    ON UPDATE Cascade;
-- -------------------------------------------------------------


-- CREATE LINK "fk_SITUATION_FACTOR_POSITIONS__SITUATIONS_1" ----------
ALTER TABLE "votecube"."SITUATION_FACTOR_POSITIONS"
  ADD CONSTRAINT "fk_SITUATION_FACTOR_POSITIONS__SITUATIONS_1"
  FOREIGN KEY ("SITUATIONS_RID_1", "SITUATIONS_AID_1", "SITUATIONS_ARID_1")
    REFERENCES "votecube"."SITUATIONS" ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
    ON DELETE Cascade
    ON UPDATE Cascade;
-- -------------------------------------------------------------


-- CREATE LINK "fk_SITUATION_FACTOR_POSITIONS__FACTOR_POSITIONS_1" ----------
ALTER TABLE "votecube"."SITUATION_FACTOR_POSITIONS"
  ADD CONSTRAINT "fk_SITUATION_FACTOR_POSITIONS__FACTOR_POSITIONS_1"
  FOREIGN KEY ("FACTOR_POSITIONS_RID_1", "FACTOR_POSITIONS_AID_1", "FACTOR_POSITIONS_ARID_1")
    REFERENCES "votecube"."FACTOR_POSITIONS" ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
    ON DELETE Cascade
    ON UPDATE Cascade;
-- -------------------------------------------------------------


-- CREATE LINK "fk_SITUATIONS__CATEGORIES_1" ----------
ALTER TABLE "votecube"."SITUATIONS"
  ADD CONSTRAINT "fk_SITUATIONS__CATEGORIES_1"
  FOREIGN KEY ("CATEGORIES_RID_1", "CATEGORIES_AID_1", "CATEGORIES_ARID_1")
    REFERENCES "votecube"."CATEGORIES" ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
    ON DELETE Cascade
    ON UPDATE Cascade;
-- -------------------------------------------------------------


-- CREATE LINK "fk_SITUATIONS__SITUATIONS_1" ----------
ALTER TABLE "votecube"."SITUATIONS"
  ADD CONSTRAINT "fk_SITUATIONS__SITUATIONS_1"
  FOREIGN KEY ("SITUATIONS_RID_1", "SITUATIONS_AID_1", "SITUATIONS_ARID_1")
    REFERENCES "votecube"."SITUATIONS" ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
    ON DELETE Cascade
    ON UPDATE Cascade;
-- -------------------------------------------------------------


-- CREATE LINK "fk_SITUATIONS__OUTCOMES_1" ----------
ALTER TABLE "votecube"."SITUATIONS"
  ADD CONSTRAINT "fk_SITUATIONS__OUTCOMES_1"
  FOREIGN KEY ("OUTCOMES_RID_1", "OUTCOMES_AID_1", "OUTCOMES_ARID_1")
    REFERENCES "votecube"."OUTCOMES" ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
    ON DELETE Cascade
    ON UPDATE Cascade;
-- -------------------------------------------------------------


-- CREATE LINK "fk_SITUATIONS__OUTCOMES_2" ----------
ALTER TABLE "votecube"."SITUATIONS"
  ADD CONSTRAINT "fk_SITUATIONS__OUTCOMES_2"
  FOREIGN KEY ("OUTCOMES_RID_2", "OUTCOMES_AID_2", "OUTCOMES_ARID_2")
    REFERENCES "votecube"."OUTCOMES" ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
    ON DELETE Cascade
    ON UPDATE Cascade;
-- -------------------------------------------------------------
