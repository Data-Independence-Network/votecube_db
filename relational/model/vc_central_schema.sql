-- comment out "drop database" when running for the first time
drop database votecube cascade;

create database votecube;

CREATE SEQUENCE "votecube"."opinion_id" MINVALUE 1 MAXVALUE 9223372036854775807 INCREMENT 100 START 100;
CREATE SEQUENCE "votecube"."poll_id" MINVALUE 1 MAXVALUE 9223372036854775807 INCREMENT 100 START 100;
CREATE SEQUENCE "votecube"."user_id" MINVALUE 1 MAXVALUE 9223372036854775807 INCREMENT 100 START 100;
