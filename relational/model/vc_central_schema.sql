-- comment out "drop database" when running for the first time
drop database votecube cascade;

create database votecube;

CREATE SEQUENCE "votecube"."opinion_id" MINVALUE 1 MAXVALUE 9223372036854775807 INCREMENT 100 START 100;
CREATE SEQUENCE "votecube"."feedback_id" MINVALUE 1 MAXVALUE 9223372036854775807 INCREMENT 100 START 100;
CREATE SEQUENCE "votecube"."feedback_comment_id" MINVALUE 1 MAXVALUE 9223372036854775807 INCREMENT 100 START 100;
CREATE SEQUENCE "votecube"."poll_id" MINVALUE 1 MAXVALUE 9223372036854775807 INCREMENT 100 START 100;
CREATE SEQUENCE "votecube"."user_id" MINVALUE 1 MAXVALUE 9223372036854775807 INCREMENT 100 START 100;

CREATE TABLE "votecube"."feedback"
(
    "age_suitability"  Bigint                   NOT NULL,
    "created_at"       Timestamp With Time Zone NOT NULL,
    "feedback_type_id" Bigint                 NOT NULL,
    "id"               Bigint                   NOT NULL,
    "title"            Character Varying(256)   NOT NULL,
    "text"             Character Varying(4000)  NOT NULL,
    "user_account_id"  Bigint                   NOT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "votecube"."feedback_comments"
(
    "age_suitability" Bigint                   NOT NULL,
    "created_at"      Timestamp With Time Zone NOT NULL,
    "feedback_id"     Bigint                   NOT NULL,
    "id"              Bigint                   NOT NULL,
    "text"            Character Varying(4000)  NOT NULL,
    "user_account_id" Bigint                   NOT NULL,
    PRIMARY KEY ("id")
);

-- CREATE LINK "fk_Messages_Messages_ParentMessageId" ----------
ALTER TABLE "votecube"."feedback_comments"
    ADD CONSTRAINT "fk_FeedbackComments_Feedback_FeedbackId" FOREIGN KEY ("feedback_id")
        REFERENCES "votecube"."feedback" ("id") MATCH FULL
        ON DELETE Cascade
        ON UPDATE Cascade;


-- CREATE TABLE "user_account" ---------------------------------
CREATE TABLE "votecube"."user_accounts"
(
    "user_account_id"         Bigint                                 NOT NULL,
    "user_name"               Character Varying(64)                  NOT NULL,
    "first_name"              Character Varying(256),
    "middle_name_or_initials" Character Varying(256),
    "prefix_last_name_id"     Bigint, -- NOT NULL,
    "last_name"               Character Varying(256),
    "name_after_last_name_id" Bigint, -- NOT NULL,
    "birth_date"              Date                                   NOT NULL,
    "created_at"              Timestamp With Time Zone DEFAULT Now() NOT NULL,
    PRIMARY KEY ("user_account_id"),
    CONSTRAINT "u_UserAccount_UserName" UNIQUE ("user_name"),
    CONSTRAINT "u_UserAccount_UserAccountId" UNIQUE ("user_account_id")
);
;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_UserAccount_UserAccountId" -----------------
CREATE INDEX "pk_UserAccount_UserAccountId" ON "votecube"."user_accounts" USING btree ("user_account_id" Asc);
-- -------------------------------------------------------------

-- CREATE INDEX "ak_UserAccount_UserName" ----------------------
CREATE INDEX "ak_UserAccount_UserName" ON "votecube"."user_accounts" USING btree ("user_name" Asc);
-- -------------------------------------------------------------

-- CREATE INDEX "ix_UserAccount_LastName" ----------------------
CREATE INDEX "ix_UserAccount_LastName" ON "votecube"."user_accounts" USING btree ("last_name" Asc);
-- -------------------------------------------------------------
