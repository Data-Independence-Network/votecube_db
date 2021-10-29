-- CREATE TABLE "CATEGORIES" -------------------------
CREATE TABLE "votecube"."CATEGORIES"
(
  "REPOSITORY_ID"             Bigint                   NOT NULL,
  "ACTOR_ID"                  Bigint                   NOT NULL,
  "ACTOR_RECORD_ID"           Bigint                   NOT NULL,
  "AGE_SUITABILITY"           Smallint                 NOT NULL,
  "SYSTEM_WIDE_OPERATION_ID"  Bigint                   NOT NULL,
  "NAME"                      Text                     NOT NULL,
  "DESCRIPTION"               Text                     NOT NULL,
  "CATEGORIES_RID_1"          Bigint                   NOT NULL,
  "CATEGORIES_AID_1"          Bigint                   NOT NULL,
  "CATEGORIES_ARID_1"         Bigint                   NOT NULL,
  PRIMARY KEY ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
);
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
  "DESCRIPTION"               Text                     NOT NULL,
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
  "DESCRIPTION"               Text                     NOT NULL,
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
  "DESCRIPTION"               Text                     NOT NULL,
  "FACTORS_RID_1"             Bigint                   NOT NULL,
  "FACTORS_AID_1"             Bigint                   NOT NULL,
  "FACTORS_ARID_1"            Bigint                   NOT NULL,
  "POSITIONS_RID_1"           Bigint                   NOT NULL,
  "POSITIONS_AID_1"           Bigint                   NOT NULL,
  "POSITIONS_ARID_1"          Bigint                   NOT NULL,
  PRIMARY KEY ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
);
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
  "DESCRIPTION"               Text                     NOT NULL,
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
  "DESCRIPTION"               Text                     NOT NULL,
  "FACTORS_RID_1"             Bigint                   NOT NULL,
  "FACTORS_AID_1"             Bigint                   NOT NULL,
  "FACTORS_ARID_1"            Bigint                   NOT NULL,
  "POSITIONS_RID_1"           Bigint                   NOT NULL,
  "POSITIONS_AID_1"           Bigint                   NOT NULL,
  "POSITIONS_ARID_1"          Bigint                   NOT NULL,
  PRIMARY KEY ("REPOSITORY_ID", "ACTOR_ID", "ACTOR_RECORD_ID")
);
-- -------------------------------------------------------------


