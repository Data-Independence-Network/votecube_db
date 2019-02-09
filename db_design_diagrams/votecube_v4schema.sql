-- drop database votecube cascade;

create database votecube;


-- CREATE TABLE "messages" -------------------------------------
CREATE TABLE "votecube"."messages" ( 
	"message_id" Bigint NOT NULL,
	"parent_message_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"message_subject" Character Varying( 256 ) NOT NULL,
	"message_text" Character Varying( 10000 ) NOT NULL,
	"message_type" Character Varying( 8 ) NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "message_id" ),
	CONSTRAINT "u_Messages_MessageId" UNIQUE( "parent_message_id" ),
	CONSTRAINT "ck_Messages_MessageType" CHECK(message_type IN ('user',  'admin')) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "ix_Messages_CreatedAt" ------------------------
CREATE INDEX "ix_Messages_CreatedAt" ON "votecube"."messages" USING btree( "created_at" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "index_user_account_id5" -----------------------
CREATE INDEX "index_user_account_id5" ON "votecube"."messages" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "index_parent_message_id" ----------------------
CREATE INDEX "index_parent_message_id" ON "votecube"."messages" USING btree( "parent_message_id" );
-- -------------------------------------------------------------



-- CREATE TABLE "polls_messages" -------------------------------
CREATE TABLE "votecube"."polls_messages" ( 
	"poll_message_id" Bigint NOT NULL,
	"message_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	PRIMARY KEY ( "poll_message_id" ),
	CONSTRAINT "u_PollsMessages_PollMessageId" UNIQUE( "poll_message_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsMessages_MessageId" -------------------
CREATE INDEX "fk_PollsMessages_MessageId" ON "votecube"."polls_messages" USING btree( "message_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsMessages_PollId" ----------------------
CREATE INDEX "fk_PollsMessages_PollId" ON "votecube"."polls_messages" USING btree( "poll_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsMessages_PollMessageId" ---------------
CREATE INDEX "pk_PollsMessages_PollMessageId" ON "votecube"."polls_messages" USING btree( "poll_message_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "messages_links" -------------------------------
CREATE TABLE "votecube"."messages_links" ( 
	"message_link_id" Bigint NOT NULL,
	"message_id" Bigint NOT NULL,
	"link_id" Bigint NOT NULL,
	PRIMARY KEY ( "message_link_id" ),
	CONSTRAINT "u_MessagesLinks_MessageLinkId" UNIQUE( "message_link_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_MessagesLinks_MessageLinkId" ---------------
CREATE INDEX "pk_MessagesLinks_MessageLinkId" ON "votecube"."messages_links" USING btree( "message_link_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_MessagesLinks_LinkId" ----------------------
CREATE INDEX "fk_MessagesLinks_LinkId" ON "votecube"."messages_links" USING btree( "link_id" );
-- -------------------------------------------------------------



-- CREATE TABLE "labels" ---------------------------------------
CREATE TABLE "votecube"."labels" ( 
	"label_id" Bigint NOT NULL,
	"name" Character Varying( 16 ) NOT NULL,
	"description" Character Varying( 2044 ) NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "label_id" ),
	CONSTRAINT "u_Labels_Name" UNIQUE( "name" ),
	CONSTRAINT "u_Labels_Description" UNIQUE( "description" ),
	CONSTRAINT "u_Labels_LabelId" UNIQUE( "label_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Labels_UserAccountId" ----------------------
CREATE INDEX "fk_Labels_UserAccountId" ON "votecube"."labels" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Labels_LabelId" ----------------------------
CREATE INDEX "pk_Labels_LabelId" ON "votecube"."labels" USING btree( "label_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Labels_Name" -------------------------------
CREATE INDEX "ak_Labels_Name" ON "votecube"."labels" USING btree( "name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ak_Labels_Name" ---------------
ALTER TABLE "votecube"."labels" CLUSTER ON "votecube"."ak_Labels_Name";
-- -------------------------------------------------------------



-- CREATE TABLE "themes" ---------------------------------------
CREATE TABLE "votecube"."themes" ( 
	"theme_id" Bigint NOT NULL,
	"name" Character Varying( 64 ) NOT NULL,
	"description" Character Varying( 256 ) NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "theme_id" ),
	CONSTRAINT "u_Themes_Name" UNIQUE( "name" ),
	CONSTRAINT "u_Themes_Description" UNIQUE( "description" ),
	CONSTRAINT "u_Themes_ThemeId" UNIQUE( "theme_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Themes_ThemeId" ----------------------------
CREATE INDEX "pk_Themes_ThemeId" ON "votecube"."themes" USING btree( "theme_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "pk_Themes_ThemeId" ------------
ALTER TABLE "votecube"."themes" CLUSTER ON "votecube"."pk_Themes_ThemeId";
-- -------------------------------------------------------------



-- CREATE TABLE "polls_labels" ---------------------------------
CREATE TABLE "votecube"."polls_labels" ( 
	"poll_label_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	"label_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "poll_label_id" ),
	CONSTRAINT "u_PollsLabels_PollLabelId" UNIQUE( "poll_label_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsLabels_PollId" ------------------------
CREATE INDEX "fk_PollsLabels_PollId" ON "votecube"."polls_labels" USING btree( "poll_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsLabels_LabelId" -----------------------
CREATE INDEX "fk_PollsLabels_LabelId" ON "votecube"."polls_labels" USING btree( "label_id" );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "fk_PollsLabels_LabelId" -------
ALTER TABLE "votecube"."polls_labels" CLUSTER ON "votecube"."fk_PollsLabels_LabelId";
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsLabels_UserAccountId" -----------------
CREATE INDEX "fk_PollsLabels_UserAccountId" ON "votecube"."polls_labels" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsLabels_PollLabelId" -------------------
CREATE INDEX "pk_PollsLabels_PollLabelId" ON "votecube"."polls_labels" USING btree( "poll_label_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "polls_links" ----------------------------------
CREATE TABLE "votecube"."polls_links" ( 
	"poll_link_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	"link_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	CONSTRAINT "u_PollsLinks_PollLinkId" UNIQUE( "poll_link_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsLinks_PollLinkId" ---------------------
CREATE INDEX "pk_PollsLinks_PollLinkId" ON "votecube"."polls_links" USING btree( "poll_link_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsLinks_PollId" -------------------------
CREATE INDEX "fk_PollsLinks_PollId" ON "votecube"."polls_links" USING btree( "poll_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsLinks_LinkId" -------------------------
CREATE INDEX "fk_PollsLinks_LinkId" ON "votecube"."polls_links" USING btree( "link_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsLinks_UserAccountId" ------------------
CREATE INDEX "fk_PollsLinks_UserAccountId" ON "votecube"."polls_links" USING btree( "user_account_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "polls_groups" ---------------------------------
CREATE TABLE "votecube"."polls_groups" ( 
	"poll_group_id" Bigint NOT NULL,
	"poll_group_name" Character Varying( 64 ) NOT NULL,
	"poll_group_description" Character Varying( 10000 ) NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"theme_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "poll_group_id" ),
	CONSTRAINT "u_PollsGroups_PollGroupName" UNIQUE( "poll_group_name" ),
	CONSTRAINT "u_PollsGroups_PollGroupDescription" UNIQUE( "poll_group_description" ),
	CONSTRAINT "u_PollsGroups_PollGroupId" UNIQUE( "poll_group_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsGroups_UserAccountId" -----------------
CREATE INDEX "fk_PollsGroups_UserAccountId" ON "votecube"."polls_groups" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsGroups_ThemeId" -----------------------
CREATE INDEX "fk_PollsGroups_ThemeId" ON "votecube"."polls_groups" USING btree( "theme_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsGroups_PollGroupId" -------------------
CREATE UNIQUE INDEX "pk_PollsGroups_PollGroupId" ON "votecube"."polls_groups" USING btree( "poll_group_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "polls_polls_groups" ---------------------------
CREATE TABLE "votecube"."polls_polls_groups" ( 
	"poll_poll_group_id" Bigint NOT NULL,
	"poll_group_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "poll_poll_group_id" ),
	CONSTRAINT "u_PollsPollsGroups_PollPollGroupId" UNIQUE( "poll_poll_group_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsPollsGroups_PollGroupid" --------------
CREATE INDEX "fk_PollsPollsGroups_PollGroupid" ON "votecube"."polls_polls_groups" USING btree( "poll_group_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsPollsGroups_UserAccountId" ------------
CREATE INDEX "fk_PollsPollsGroups_UserAccountId" ON "votecube"."polls_polls_groups" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsPollsGroups_PollPollGroupId" ----------
CREATE INDEX "pk_PollsPollsGroups_PollPollGroupId" ON "votecube"."polls_polls_groups" USING btree( "poll_poll_group_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsPollsGroups_Pollid" -------------------
CREATE INDEX "fk_PollsPollsGroups_Pollid" ON "votecube"."polls_polls_groups" USING btree( "poll_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "polls_groups_links" ---------------------------
CREATE TABLE "votecube"."polls_groups_links" ( 
	"poll_group_link_id" Bigint NOT NULL,
	"poll_group_id" Bigint NOT NULL,
	"link_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "poll_group_link_id" ),
	CONSTRAINT "u_PollsGroupsLinks_PollGroupLinkId" UNIQUE( "poll_group_link_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsGroupsLinks_PollGroupId" --------------
CREATE INDEX "fk_PollsGroupsLinks_PollGroupId" ON "votecube"."polls_groups_links" USING btree( "poll_group_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsGroupsLinks_LinkId" -------------------
CREATE INDEX "fk_PollsGroupsLinks_LinkId" ON "votecube"."polls_groups_links" USING btree( "link_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsGroupsLinks_UserAccountId" ------------
CREATE INDEX "fk_PollsGroupsLinks_UserAccountId" ON "votecube"."polls_groups_links" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsGroupsLinks_PollGroupLinkId" ----------
CREATE INDEX "pk_PollsGroupsLinks_PollGroupLinkId" ON "votecube"."polls_groups_links" USING btree( "poll_group_link_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "dimensions" -----------------------------------
CREATE TABLE "votecube"."dimensions" ( 
	"dimension_id" Bigint NOT NULL,
	"parent_dimension_id" Bigint,
	"user_account_id" Bigint NOT NULL,
	"dimension_name" Character Varying( 16 ) NOT NULL,
	"dimension_description" Character Varying( 10000 ) NOT NULL,
	"color_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "dimension_id" ),
	CONSTRAINT "u_Dimensions_DimensionId
" UNIQUE( "dimension_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Dimensions_ParentDimensionId" --------------
CREATE INDEX "fk_Dimensions_ParentDimensionId" ON "votecube"."dimensions" USING btree( "parent_dimension_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Dimensions_DimensionId" --------------------
CREATE INDEX "pk_Dimensions_DimensionId" ON "votecube"."dimensions" USING btree( "dimension_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Dimensions_UserAccountId" ------------------
CREATE INDEX "fk_Dimensions_UserAccountId" ON "votecube"."dimensions" USING btree( "user_account_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ix_Dimensions_DimensionNameId" ----------------
CREATE INDEX "ix_Dimensions_DimensionNameId" ON "votecube"."dimensions" USING btree( "dimension_name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ix_Dimensions_DimensionNameId" 
ALTER TABLE "votecube"."dimensions" CLUSTER ON "votecube"."ix_Dimensions_DimensionNameId";
-- -------------------------------------------------------------



-- CREATE TABLE "dimensions_links" -----------------------------
CREATE TABLE "votecube"."dimensions_links" ( 
	"dimensions_link_id" Bigint NOT NULL,
	"dimensions_id" Bigint NOT NULL,
	"links_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "dimensions_link_id" ),
	CONSTRAINT "u_DimensionsLinks_DimensionLinkId" UNIQUE( "dimensions_link_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_DimensionsLinks_DimensionId" ---------------
CREATE INDEX "fk_DimensionsLinks_DimensionId" ON "votecube"."dimensions_links" USING btree( "dimensions_id" );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "fk_DimensionsLinks_DimensionId" 
ALTER TABLE "votecube"."dimensions_links" CLUSTER ON "votecube"."fk_DimensionsLinks_DimensionId";
-- -------------------------------------------------------------

-- CREATE INDEX "fk_DimensionsLinks_LinkId" --------------------
CREATE INDEX "fk_DimensionsLinks_LinkId" ON "votecube"."dimensions_links" USING btree( "links_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_DimensionsLinks_UserAccountId" -------------
CREATE INDEX "fk_DimensionsLinks_UserAccountId" ON "votecube"."dimensions_links" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_DimensionsLinks_DimensionLinkId" -----------
CREATE INDEX "pk_DimensionsLinks_DimensionLinkId" ON "votecube"."dimensions_links" USING btree( "dimensions_link_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "directions" -----------------------------------
CREATE TABLE "votecube"."directions" ( 
	"direction_id" Bigint NOT NULL,
	"parent_direction_id" Bigint NOT NULL,
	"direction_description" Character Varying( 128 ) NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"design_pattern_id" Bigint NOT NULL,
	"emoji_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "direction_id" ),
	CONSTRAINT "u_Directions_DirectionId" UNIQUE( "direction_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Directions_ParentDirectionId" --------------
CREATE INDEX "fk_Directions_ParentDirectionId" ON "votecube"."directions" USING btree( "parent_direction_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "ix_Directions_DirectionDescription" -----------
CREATE INDEX "ix_Directions_DirectionDescription" ON "votecube"."directions" USING btree( "direction_description" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Directions_UserAccountId" ------------------
CREATE INDEX "fk_Directions_UserAccountId" ON "votecube"."directions" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Directions_DirectionId" --------------------
CREATE INDEX "pk_Directions_DirectionId" ON "votecube"."directions" USING btree( "direction_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "dimension_directions" -------------------------
CREATE TABLE "votecube"."dimension_directions" ( 
	"dimension_direction_id" Bigint NOT NULL,
	"dimension_id" Bigint NOT NULL,
	"direction_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "dimension_direction_id" ),
	CONSTRAINT "u_DimensionDirections_DimensionDirectionId" UNIQUE( "dimension_direction_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_DimensionDirections_DimensionId" -----------
CREATE INDEX "fk_DimensionDirections_DimensionId" ON "votecube"."dimension_directions" USING btree( "dimension_id" );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "fk_DimensionDirections_DimensionId" 
ALTER TABLE "votecube"."dimension_directions" CLUSTER ON "votecube"."fk_DimensionDirections_DimensionId";
-- -------------------------------------------------------------

-- CREATE INDEX "fk_DimensionDirections_DirectionId" -----------
CREATE INDEX "fk_DimensionDirections_DirectionId" ON "votecube"."dimension_directions" USING btree( "direction_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_DimensionDirections_DimensionDirectionId" --
CREATE INDEX "pk_DimensionDirections_DimensionDirectionId" ON "votecube"."dimension_directions" USING btree( "dimension_direction_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "polls_dimensions_directions" ------------------
CREATE TABLE "votecube"."polls_dimensions_directions" ( 
	"poll_dimension_direction_id" Bigint NOT NULL,
	"dimension_direction_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	"dimension_coordinate_axis" Character Varying( 1 ) NOT NULL,
	"direction_orientation" Boolean NOT NULL,
	"color_id" Bigint NOT NULL,
	"design_pattern_id" Bigint NOT NULL,
	"emoji_id" Bigint NOT NULL,
	PRIMARY KEY ( "poll_dimension_direction_id" ),
	CONSTRAINT "u_PollsDimensionsDirections_PollDimensionDirectionId" UNIQUE( "poll_dimension_direction_id" ),
	CONSTRAINT "ck_PollsDimensionsDirections_DimensionCoordinateAxis" CHECK(dimension_coordinate_axis IN ('x', 'y', 'z')) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsDimensionsDirections_DimensionDirectionId" 
CREATE INDEX "fk_PollsDimensionsDirections_DimensionDirectionId" ON "votecube"."polls_dimensions_directions" USING btree( "dimension_direction_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsDimensionsDirections_PollId" ----------
CREATE INDEX "fk_PollsDimensionsDirections_PollId" ON "votecube"."polls_dimensions_directions" USING btree( "poll_id" );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "fk_PollsDimensionsDirections_PollId" 
ALTER TABLE "votecube"."polls_dimensions_directions" CLUSTER ON "votecube"."fk_PollsDimensionsDirections_PollId";
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsDimensionsDirections_PollDimensionDirectionId" 
CREATE INDEX "pk_PollsDimensionsDirections_PollDimensionDirectionId" ON "votecube"."polls_dimensions_directions" USING btree( "poll_dimension_direction_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "vote" -----------------------------------------
CREATE TABLE "votecube"."vote" ( 
	"vote_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	"x_poll_dimension_direction_id" Bigint NOT NULL,
	"y_poll_dimension_direction_id" Bigint NOT NULL,
	"z_poll_dimension_direction_id" Bigint NOT NULL,
	"x_share" SmallInt NOT NULL,
	"y_share" SmallInt NOT NULL,
	"z_share" SmallInt NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "vote_id" ),
	CONSTRAINT "u_Vote_VoteId" UNIQUE( "vote_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Votes_UserAccountId" -----------------------
CREATE INDEX "fk_Votes_UserAccountId" ON "votecube"."vote" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Votes_PollId" ------------------------------
CREATE INDEX "fk_Votes_PollId" ON "votecube"."vote" USING btree( "poll_id" );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "fk_Votes_PollId" --------------
ALTER TABLE "votecube"."vote" CLUSTER ON "votecube"."fk_Votes_PollId";
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Votes_VoteId" ------------------------------
CREATE INDEX "pk_Votes_VoteId" ON "votecube"."vote" USING btree( "vote_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "polls" ----------------------------------------
CREATE TABLE "votecube"."polls" ( 
	"poll_id" Bigint NOT NULL,
	"parent_poll_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"poll_title" Character Varying( 256 ) NOT NULL,
	"poll_description" Character Varying( 10000 ) NOT NULL,
	"theme_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	"start_date" Date NOT NULL,
	"end_date" Date NOT NULL,
	PRIMARY KEY ( "poll_id" ),
	CONSTRAINT "u_Polls_PollTitle" UNIQUE( "poll_title" ),
	CONSTRAINT "u_Polls_PollId" UNIQUE( "parent_poll_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Polls_UserAccountId" -----------------------
CREATE INDEX "fk_Polls_UserAccountId" ON "votecube"."polls" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Polls_PollThemeId" -------------------------
CREATE INDEX "fk_Polls_PollThemeId" ON "votecube"."polls" USING btree( "theme_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Polls_PollTitle" ---------------------------
CREATE INDEX "ak_Polls_PollTitle" ON "votecube"."polls" USING btree( "poll_title" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ak_Polls_PollTitle" -----------
ALTER TABLE "votecube"."polls" CLUSTER ON "votecube"."ak_Polls_PollTitle";
-- -------------------------------------------------------------

-- CREATE INDEX "ix_Polls_StartDate" ---------------------------
CREATE INDEX "ix_Polls_StartDate" ON "votecube"."polls" USING btree( "start_date" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ix_Polls_EndDate" -----------------------------
CREATE INDEX "ix_Polls_EndDate" ON "votecube"."polls" USING btree( "end_date" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Polls_ParentPollId" ------------------------
CREATE INDEX "fk_Polls_ParentPollId" ON "votecube"."polls" USING btree( "parent_poll_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Polls_PollId" ------------------------------
CREATE INDEX "pk_Polls_PollId" ON "votecube"."polls" USING btree( "poll_id" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "colors" ---------------------------------------
CREATE TABLE "votecube"."colors" ( 
	"color_id" Bigint NOT NULL,
	"rgb_hex_value" Character Varying( 16 ) NOT NULL,
	PRIMARY KEY ( "color_id" ),
	CONSTRAINT "u_Colors_RgbHexValue" UNIQUE( "rgb_hex_value" ),
	CONSTRAINT "u_Colors_ColorId" UNIQUE( "color_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Colors_ColorId" ----------------------------
CREATE INDEX "pk_Colors_ColorId" ON "votecube"."colors" USING btree( "color_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Colors_RgbHexValue" ------------------------
CREATE INDEX "ak_Colors_RgbHexValue" ON "votecube"."colors" USING btree( "rgb_hex_value" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ak_Colors_RgbHexValue" --------
ALTER TABLE "votecube"."colors" CLUSTER ON "votecube"."ak_Colors_RgbHexValue";
-- -------------------------------------------------------------



-- CREATE TABLE "design_patterns" ------------------------------
CREATE TABLE "votecube"."design_patterns" ( 
	"design_pattern_id" Bigint NOT NULL,
	"design_pattern_name" Character Varying( 16 ) NOT NULL,
	PRIMARY KEY ( "design_pattern_id" ),
	CONSTRAINT "u_DesignPatterns_DesignPatternName" UNIQUE( "design_pattern_name" ),
	CONSTRAINT "u_DesignPatterns_DesignPatternId" UNIQUE( "design_pattern_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_DesignPatterns_DesignPatternId" ------------
CREATE INDEX "pk_DesignPatterns_DesignPatternId" ON "votecube"."design_patterns" USING btree(  );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_DesignPatterns_DesignPatternName" ----------
CREATE INDEX "ak_DesignPatterns_DesignPatternName" ON "votecube"."design_patterns" USING btree(  );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ak_DesignPatterns_DesignPatternName" 
ALTER TABLE "votecube"."design_patterns" CLUSTER ON "votecube"."ak_DesignPatterns_DesignPatternName";
-- -------------------------------------------------------------



-- CREATE TABLE "emoji" ----------------------------------------
CREATE TABLE "votecube"."emoji" ( 
	"emoji_id" Bigint NOT NULL,
	"css_class" Character Varying( 16 ) NOT NULL,
	PRIMARY KEY ( "emoji_id" ),
	CONSTRAINT "u_Emoji_CssClass" UNIQUE( "css_class" ),
	CONSTRAINT "u_Emoji_EmojiId" UNIQUE( "emoji_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Emoji_EmojiId" -----------------------------
CREATE INDEX "pk_Emoji_EmojiId" ON "votecube"."emoji" USING btree( "emoji_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Emoji_CssClass" ----------------------------
CREATE INDEX "ak_Emoji_CssClass" ON "votecube"."emoji" USING btree( "css_class" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "links" ----------------------------------------
CREATE TABLE "votecube"."links" ( 
	"link_id" Bigint NOT NULL,
	"link_server" Character Varying( 256 ) NOT NULL,
	"link_addres" Character Varying( 2044 ) NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "link_id" ),
	CONSTRAINT "u_Links_LinkServer_LinkAddress" UNIQUE( "link_server", "link_addres" ),
	CONSTRAINT "u_Links_LinkId" UNIQUE( "link_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Links_LinkServer" --------------------------
CREATE INDEX "ak_Links_LinkServer" ON "votecube"."links" USING btree( "link_server" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Links_UserAccountID" -----------------------
CREATE INDEX "fk_Links_UserAccountID" ON "votecube"."links" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Links_LinkId" ------------------------------
CREATE INDEX "pk_Links_LinkId" ON "votecube"."links" USING btree( "link_id" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "polls_continent" ------------------------------
CREATE TABLE "votecube"."polls_continent" ( 
	"poll_continent_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	"continent_id" Bigint NOT NULL,
	PRIMARY KEY ( "poll_continent_id" ),
	CONSTRAINT "u_PollsContinent_PollContinentId" UNIQUE( "poll_continent_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsContinent_PollContinentId" ------------
CREATE INDEX "pk_PollsContinent_PollContinentId" ON "votecube"."polls_continent" USING btree( "poll_continent_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsContinent_PollId" ---------------------
CREATE INDEX "fk_PollsContinent_PollId" ON "votecube"."polls_continent" USING btree( "poll_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "fk_PollsContinent_PollId" -----
ALTER TABLE "votecube"."polls_continent" CLUSTER ON "votecube"."fk_PollsContinent_PollId";
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsContinent_ContinentId" ----------------
CREATE INDEX "fk_PollsContinent_ContinentId" ON "votecube"."polls_continent" USING btree( "continent_id" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "polls_country" --------------------------------
CREATE TABLE "votecube"."polls_country" ( 
	"poll_country_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	"country_id" Bigint NOT NULL,
	PRIMARY KEY ( "poll_country_id" ),
	CONSTRAINT "u_PollsCountries_PollCountryId" UNIQUE( "poll_country_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsCountry_PollCountryId" ----------------
CREATE INDEX "pk_PollsCountry_PollCountryId" ON "votecube"."polls_country" USING btree( "poll_country_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsCountry_PollId" -----------------------
CREATE INDEX "fk_PollsCountry_PollId" ON "votecube"."polls_country" USING btree( "poll_id" );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "fk_PollsCountry_PollId" -------
ALTER TABLE "votecube"."polls_country" CLUSTER ON "votecube"."fk_PollsCountry_PollId";
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsCountry_CountryId" --------------------
CREATE INDEX "fk_PollsCountry_CountryId" ON "votecube"."polls_country" USING btree( "country_id" );
-- -------------------------------------------------------------




-- CREATE TABLE "polls_state" ----------------------------------
CREATE TABLE "votecube"."polls_state" ( 
	"poll_state_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	"state_id" Bigint NOT NULL,
	PRIMARY KEY ( "poll_state_id" ),
	CONSTRAINT "u_PollsState_PollStateId" UNIQUE( "poll_state_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsState_PollStateId" --------------------
CREATE INDEX "pk_PollsState_PollStateId" ON "votecube"."polls_state" USING btree( "poll_state_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsState_StateId" ------------------------
CREATE INDEX "fk_PollsState_StateId" ON "votecube"."polls_state" USING btree( "state_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsState_PollId" -------------------------
CREATE INDEX "fk_PollsState_PollId" ON "votecube"."polls_state" USING btree( "poll_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "fk_PollsState_PollId" ---------
ALTER TABLE "votecube"."polls_state" CLUSTER ON "votecube"."fk_PollsState_PollId";
-- -------------------------------------------------------------




-- CREATE TABLE "polls_county" ---------------------------------
CREATE TABLE "votecube"."polls_county" ( 
	"poll_county_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	"county_id" Bigint NOT NULL,
	PRIMARY KEY ( "poll_county_id" ),
	CONSTRAINT "u_PollsCounty_PollCountyId" UNIQUE( "poll_county_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsCounty_PollCountyId" ------------------
CREATE INDEX "pk_PollsCounty_PollCountyId" ON "votecube"."polls_county" USING btree( "poll_county_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsCounty_PollId" ------------------------
CREATE INDEX "fk_PollsCounty_PollId" ON "votecube"."polls_county" USING btree( "poll_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsCounty_CountyId" ----------------------
CREATE INDEX "fk_PollsCounty_CountyId" ON "votecube"."polls_county" USING btree( "county_id" );
-- -------------------------------------------------------------




-- CREATE TABLE "polls_town" -----------------------------------
CREATE TABLE "votecube"."polls_town" ( 
	"poll_town_id" Bigint NOT NULL,
	"poll_id" Bigint NOT NULL,
	"town_id" Bigint NOT NULL,
	PRIMARY KEY ( "poll_town_id" ),
	CONSTRAINT "u_PollsTown_PollTownId" UNIQUE( "poll_town_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PollsTown_PollTownId" ----------------------
CREATE INDEX "pk_PollsTown_PollTownId" ON "votecube"."polls_town" USING btree( "poll_town_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsTown_PollId" --------------------------
CREATE INDEX "fk_PollsTown_PollId" ON "votecube"."polls_town" USING btree( "poll_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_PollsTown_TownId" --------------------------
CREATE INDEX "fk_PollsTown_TownId" ON "votecube"."polls_town" USING btree( "town_id" );
-- -------------------------------------------------------------




-- CREATE TABLE "prefix_last_name" -----------------------------
CREATE TABLE "votecube"."prefix_last_name" ( 
	"prefix_last_name_id" Bigint NOT NULL,
	"prefix_last_name" Character Varying( 16 ) NOT NULL,
	PRIMARY KEY ( "prefix_last_name_id" ),
	CONSTRAINT "u_PrefixLastName_PrefixLastName" UNIQUE( "prefix_last_name" ),
	CONSTRAINT "u_PrefixLastName_PrefixLastNameId" UNIQUE( "prefix_last_name_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PrefixLastName_PrefixLastNameId" -----------
CREATE INDEX "pk_PrefixLastName_PrefixLastNameId" ON "votecube"."prefix_last_name" USING btree( "prefix_last_name_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_PrefixLastName_PrefixLastName" -------------
CREATE INDEX "ak_PrefixLastName_PrefixLastName" ON "votecube"."prefix_last_name" USING btree( "prefix_last_name" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "name_after_last_name" -------------------------
CREATE TABLE "votecube"."name_after_last_name" ( 
	"name_after_last_name_id" Bigint NOT NULL,
	"name_after_last_name" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "name_after_last_name_id" ),
	CONSTRAINT "u_NameAfterLastName_NameAfterLastName" UNIQUE( "name_after_last_name" ),
	CONSTRAINT "u_NameAfterLastName_NameAfterLastNameId" UNIQUE( "name_after_last_name_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_NameAfterLastName_NameAfterLastNameId" -----
CREATE INDEX "pk_NameAfterLastName_NameAfterLastNameId" ON "votecube"."name_after_last_name" USING btree( "name_after_last_name_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_NameAfterLastName_NameAfterLastName" -------
CREATE INDEX "ak_NameAfterLastName_NameAfterLastName" ON "votecube"."name_after_last_name" USING btree( "name_after_last_name" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "suffix" ---------------------------------------
CREATE TABLE "votecube"."suffix" ( 
	"suffix_id" Bigint NOT NULL,
	"suffix_name" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "suffix_id" ),
	CONSTRAINT "u_Suffix_SuffixName" UNIQUE( "suffix_name" ),
	CONSTRAINT "u_Suffix_SuffixId" UNIQUE( "suffix_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Suffix_SuffixId" ---------------------------
CREATE INDEX "pk_Suffix_SuffixId" ON "votecube"."suffix" USING btree( "suffix_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Suffix_SuffixName" -------------------------
CREATE INDEX "ak_Suffix_SuffixName" ON "votecube"."suffix" USING btree( "suffix_name" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "user_account_suffix" --------------------------
CREATE TABLE "votecube"."user_account_suffix" ( 
	"user_account_suffix_id" Bigint NOT NULL,
	"suffix_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"suffix_position" SmallInt NOT NULL,
	PRIMARY KEY ( "user_account_suffix_id" ),
	CONSTRAINT "u_UserAccountSuffix_UserAccountSuffixId" UNIQUE( "user_account_suffix_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserAccountSuffix_SuffixId" ----------------
CREATE INDEX "fk_UserAccountSuffix_SuffixId" ON "votecube"."user_account_suffix" USING btree( "suffix_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserAccountSuffix_UserAccountId" -----------
CREATE INDEX "fk_UserAccountSuffix_UserAccountId" ON "votecube"."user_account_suffix" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_UserAccountSuffix_UserAccountSuffixId" -----
CREATE INDEX "pk_UserAccountSuffix_UserAccountSuffixId" ON "votecube"."user_account_suffix" USING btree( "user_account_suffix_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "ethnic_group" ---------------------------------
CREATE TABLE "votecube"."ethnic_group" ( 
	"ethnic_group_id" Bigint NOT NULL,
	"ethnic_group_code" Character Varying( 16 ) NOT NULL,
	"ethnic_group_name" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "ethnic_group_id" ),
	CONSTRAINT "u_EthnicGroup_EthnicGroupCode" UNIQUE( "ethnic_group_code" ),
	CONSTRAINT "u_EthnicGroup_EthnicGroupName" UNIQUE( "ethnic_group_name" ),
	CONSTRAINT "u_EthnicGroup_EthnicGroupId" UNIQUE( "ethnic_group_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "index_ethnic_group_id1" -----------------------
CREATE INDEX "index_ethnic_group_id1" ON "votecube"."ethnic_group" USING btree( "ethnic_group_id" );
-- -------------------------------------------------------------



-- CREATE TABLE "ethnic_group_country" -------------------------
CREATE TABLE "votecube"."ethnic_group_country" ( 
	"ethnic_group_country_id" Bigint NOT NULL,
	"ethnic_group_id" Bigint NOT NULL,
	"country_id" Bigint NOT NULL,
	PRIMARY KEY ( "ethnic_group_country_id" ),
	CONSTRAINT "u_EthnicGroupCountry_EthnicGroupCountryId" UNIQUE( "ethnic_group_country_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_EthnicGroupCountry_EthnicGroupId" ----------
CREATE INDEX "fk_EthnicGroupCountry_EthnicGroupId" ON "votecube"."ethnic_group_country" USING btree( "ethnic_group_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_EthnicGroupCountry_CountryId" --------------
CREATE INDEX "fk_EthnicGroupCountry_CountryId" ON "votecube"."ethnic_group_country" USING btree( "country_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_EthnicGroupCountry_EthnicGroupCountryId" ---
CREATE INDEX "pk_EthnicGroupCountry_EthnicGroupCountryId" ON "votecube"."ethnic_group_country" USING btree( "ethnic_group_country_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "ethnic_subgroup" ------------------------------
CREATE TABLE "votecube"."ethnic_subgroup" ( 
	"ethnic_subgroup_id" Bigint NOT NULL,
	"ethnic_subgroup_code" Character Varying( 16 ) NOT NULL,
	"ethnic_subgroup_name" Character Varying( 64 ) NOT NULL,
	"ethnic_group_id" Bigint NOT NULL,
	PRIMARY KEY ( "ethnic_subgroup_id" ),
	CONSTRAINT "u_EthnicSubgroup_EthnicGroupId" UNIQUE( "ethnic_subgroup_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_EthnicSubgroup_EthnicGroupId" --------------
CREATE INDEX "fk_EthnicSubgroup_EthnicGroupId" ON "votecube"."ethnic_subgroup" USING btree( "ethnic_group_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "ix_EthnicSubgroup_EthnicSubgroupCode" ---------
CREATE INDEX "ix_EthnicSubgroup_EthnicSubgroupCode" ON "votecube"."ethnic_subgroup" USING btree( "ethnic_subgroup_code" );
-- -------------------------------------------------------------

-- CREATE INDEX "index_ethnic_subgroup_name" -------------------
CREATE INDEX "index_ethnic_subgroup_name" ON "votecube"."ethnic_subgroup" USING btree( "ethnic_subgroup_name" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_EthnicSubgroup_EthnicSubgroupId" -----------
CREATE INDEX "pk_EthnicSubgroup_EthnicSubgroupId" ON "votecube"."ethnic_subgroup" USING btree( "ethnic_subgroup_id" );
-- -------------------------------------------------------------



-- CREATE TABLE "user_account_ethnicity" -----------------------
CREATE TABLE "votecube"."user_account_ethnicity" ( 
	"user_account_ethnicity_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"ethnic_subgroup_id" Bigint NOT NULL,
	"ethnicity_percent" SmallInt,
	PRIMARY KEY ( "user_account_ethnicity_id" ),
	CONSTRAINT "u_UserAccountEthnicity_UserAccountEthnicityId" UNIQUE( "user_account_ethnicity_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserAccountEthnicity_UserAccountId" --------
CREATE INDEX "fk_UserAccountEthnicity_UserAccountId" ON "votecube"."user_account_ethnicity" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserAccountEthnicity_EthnicSubgroupId" -----
CREATE INDEX "fk_UserAccountEthnicity_EthnicSubgroupId" ON "votecube"."user_account_ethnicity" USING btree( "ethnic_subgroup_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_UserAccountEthnicity_UserAccountEthnicityId" 
CREATE INDEX "pk_UserAccountEthnicity_UserAccountEthnicityId" ON "votecube"."user_account_ethnicity" USING btree( "user_account_ethnicity_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "user_account" ---------------------------------
CREATE TABLE "votecube"."user_account" ( 
	"user_account_id" Bigint DEFAULT gen_random_uuid() NOT NULL,
	"user_name" Character Varying( 64 ) NOT NULL,
	"first_name" Character Varying( 256 ),
	"middle_name_or_initials" Character Varying( 256 ),
	"prefix_last_name_id" Bigint NOT NULL,
	"last_name" Character Varying( 256 ),
	"name_after_last_name_id" Bigint NOT NULL,
	"birth_date" Date NOT NULL,
	"created_at" Timestamp With Time Zone DEFAULT Now() NOT NULL,
	PRIMARY KEY ( "user_account_id" ),
	CONSTRAINT "u_UserAccount_UserName" UNIQUE( "user_name" ),
	CONSTRAINT "u_UserAccount_UserAccountId" UNIQUE( "user_account_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_UserAccount_UserAccountId" -----------------
CREATE INDEX "pk_UserAccount_UserAccountId" ON "votecube"."user_account" USING btree( "user_account_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_UserAccount_UserName" ----------------------
CREATE INDEX "ak_UserAccount_UserName" ON "votecube"."user_account" USING btree( "user_name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ak_UserAccount_UserName" ------
ALTER TABLE "votecube"."user_account" CLUSTER ON "votecube"."ak_UserAccount_UserName";
-- -------------------------------------------------------------

-- CREATE INDEX "ix_UserAccount_LastName" ----------------------
CREATE INDEX "ix_UserAccount_LastName" ON "votecube"."user_account" USING btree( "last_name" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "title" ----------------------------------------
CREATE TABLE "votecube"."title" ( 
	"title_id" Bigint NOT NULL,
	"title_name" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "title_id" ),
	CONSTRAINT "u_Title_TitleName" UNIQUE( "title_name" ),
	CONSTRAINT "u_Title_TitleId" UNIQUE( "title_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Title_TitleId" -----------------------------
CREATE INDEX "pk_Title_TitleId" ON "votecube"."title" USING btree( "title_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Title_TitleName" ---------------------------
CREATE INDEX "ak_Title_TitleName" ON "votecube"."title" USING btree( "title_name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ak_Title_TitleName" -----------
ALTER TABLE "votecube"."title" CLUSTER ON "votecube"."ak_Title_TitleName";
-- -------------------------------------------------------------



-- CREATE TABLE "user_personal_info_title" ---------------------
CREATE TABLE "votecube"."user_personal_info_title" ( 
	"user_personal_info_title_id" Bigint NOT NULL,
	"title_id" Bigint NOT NULL,
	"user_personal_info_id" Bigint NOT NULL,
	"title_position" SmallInt NOT NULL,
	PRIMARY KEY ( "user_personal_info_title_id" ),
	CONSTRAINT "u_UserPersonalInfoTitle_UserPersonalInfoTitleId" UNIQUE( "user_personal_info_title_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserPersonalInfoTitle_TitleId" -------------
CREATE INDEX "fk_UserPersonalInfoTitle_TitleId" ON "votecube"."user_personal_info_title" USING btree( "title_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_UserPersonalInfoTitle_UserPersonalInfoTitleId" 
CREATE INDEX "pk_UserPersonalInfoTitle_UserPersonalInfoTitleId" ON "votecube"."user_personal_info_title" USING btree( "user_personal_info_title_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserPersonalInfoTitle_UserPersonalInfoId" --
CREATE INDEX "fk_UserPersonalInfoTitle_UserPersonalInfoId" ON "votecube"."user_personal_info_title" USING btree( "user_personal_info_id" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "title_after_last_name" ------------------------
CREATE TABLE "votecube"."title_after_last_name" ( 
	"title_after_last_name_id" Bigint NOT NULL,
	"title_after_last_name" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "title_after_last_name_id" ),
	CONSTRAINT "u_TitleAfterLastName_TitleAfterLastNameId" UNIQUE( "title_after_last_name_id" ),
	CONSTRAINT "u_TitleAfterLastName_TitleAfterLastName" UNIQUE( "title_after_last_name" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_TitleAfterLastName_TitleAfterLastNameId" ---
CREATE INDEX "pk_TitleAfterLastName_TitleAfterLastNameId" ON "votecube"."title_after_last_name" USING btree( "title_after_last_name_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_TitleAfterLastName_TitleAfterLastName" -----
CREATE INDEX "ak_TitleAfterLastName_TitleAfterLastName" ON "votecube"."title_after_last_name" USING btree( "title_after_last_name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ak_TitleAfterLastName_TitleAfterLastName" 
ALTER TABLE "votecube"."title_after_last_name" CLUSTER ON "votecube"."ak_TitleAfterLastName_TitleAfterLastName";
-- -------------------------------------------------------------



-- CREATE TABLE "user_personal_info_title_after_last_name" -----
CREATE TABLE "votecube"."user_personal_info_title_after_last_name" ( 
	"user_personal_info_title_after_last_name_id" Bigint NOT NULL,
	"title_after_last_name_id" Bigint NOT NULL,
	"user_personal_info_id" Bigint NOT NULL,
	"title_after_last_name_position" SmallInt NOT NULL,
	PRIMARY KEY ( "user_personal_info_title_after_last_name_id" ),
	CONSTRAINT "u_UserPersonalInfoTitleAfterLastName_UserPersonalInfoTitleAfterLastNameId" UNIQUE( "user_personal_info_title_after_last_name_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_UserPersonalInfoTitleAfterLastName_UserPersonalInfoTitleAfterLastNameId" 
CREATE INDEX "pk_UserPersonalInfoTitleAfterLastName_UserPersonalInfoTitleAfterLastNameId" ON "votecube"."user_personal_info_title_after_last_name" USING btree( "title_after_last_name_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserPersonalInfoTitleAfterLastName_UserPersonalInfoId" 
CREATE INDEX "fk_UserPersonalInfoTitleAfterLastName_UserPersonalInfoId" ON "votecube"."user_personal_info_title_after_last_name" USING btree( "user_personal_info_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserPersonalInfoTitleAfterLastName_TitleAfterLastNameId" 
CREATE INDEX "fk_UserPersonalInfoTitleAfterLastName_TitleAfterLastNameId" ON "votecube"."user_personal_info_title_after_last_name" USING btree( "title_after_last_name_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "fk_UserPersonalInfoTitleAfterLastName_TitleAfterLastNameId" 
ALTER TABLE "votecube"."user_personal_info_title_after_last_name" CLUSTER ON "votecube"."fk_UserPersonalInfoTitleAfterLastName_TitleAfterLastNameId";
-- -------------------------------------------------------------



-- CREATE TABLE "email_domain" ---------------------------------
CREATE TABLE "votecube"."email_domain" ( 
	"email_domain_id" Bigint NOT NULL,
	"email_domain_name" Character Varying( 256 ) NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "email_domain_id" ),
	CONSTRAINT "u_EmailDomain_EmailDomainId" UNIQUE( "email_domain_id" ),
	CONSTRAINT "u_EmailDomain_EmailDomainName" UNIQUE( "email_domain_name" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_EmailDomain_EmailDomainId" -----------------
CREATE INDEX "pk_EmailDomain_EmailDomainId" ON "votecube"."email_domain" USING btree( "email_domain_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_EmailDomain_EmailDomainName" ---------------
CREATE INDEX "ak_EmailDomain_EmailDomainName" ON "votecube"."email_domain" USING btree( "email_domain_name" Asc NULLS Last );
-- -------------------------------------------------------------



-- CREATE TABLE "email_address" --------------------------------
CREATE TABLE "votecube"."email_address" ( 
	"email_name" Character Varying( 64 ) NOT NULL,
	"email_domain_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"created_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "email_name", "email_domain_id" ),
	CONSTRAINT "u_EmailAddress_EmailDomainId_EmailName" UNIQUE( "email_domain_id", "email_name" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_EmailAddress_EmailDomainId" ----------------
CREATE INDEX "fk_EmailAddress_EmailDomainId" ON "votecube"."email_address" USING btree( "email_domain_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_EmailAddress_UserAccountId" ----------------
CREATE INDEX "fk_EmailAddress_UserAccountId" ON "votecube"."email_address" USING btree( "user_account_id" );
-- -------------------------------------------------------------



-- CREATE TABLE "person_type" ----------------------------------
CREATE TABLE "votecube"."person_type" ( 
	"person_type_id" Bigint NOT NULL,
	"person_type_name" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "person_type_id" ),
	CONSTRAINT "u_PersonType_PersonTypeId" UNIQUE( "person_type_id" ),
	CONSTRAINT "u_PersonType_PersonTypeName" UNIQUE( "person_type_name" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_PersonType_PersonTypeId" -------------------
CREATE INDEX "pk_PersonType_PersonTypeId" ON "votecube"."person_type" USING btree( "person_type_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_PersonType_PersonTypeName" -----------------
CREATE INDEX "ak_PersonType_PersonTypeName" ON "votecube"."person_type" USING btree( "person_type_name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ak_PersonType_PersonTypeName" -
ALTER TABLE "votecube"."person_type" CLUSTER ON "votecube"."ak_PersonType_PersonTypeName";
-- -------------------------------------------------------------



-- CREATE TABLE "honors" ---------------------------------------
CREATE TABLE "votecube"."honors" ( 
	"honor_id" Bigint NOT NULL,
	"honor_name" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "honor_id" ),
	CONSTRAINT "u_Honors_HonorId" UNIQUE( "honor_id" ),
	CONSTRAINT "u_Honors_HonorName" UNIQUE( "honor_name" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Honors_HonorId" ----------------------------
CREATE INDEX "pk_Honors_HonorId" ON "votecube"."honors" USING btree( "honor_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Honors_HonorName" --------------------------
CREATE INDEX "ak_Honors_HonorName" ON "votecube"."honors" USING btree( "honor_name" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "user_personal_info_honors" --------------------
CREATE TABLE "votecube"."user_personal_info_honors" ( 
	"user_personal_info_honor_id" Bigint NOT NULL,
	"honor_id" Bigint NOT NULL,
	"user_personal_info_id" Bigint NOT NULL,
	"honors_position" SmallInt NOT NULL,
	PRIMARY KEY ( "user_personal_info_honor_id" ),
	CONSTRAINT "u_UserPersonalInfoHonors_UserPersonalInfoHonorId" UNIQUE( "user_personal_info_honor_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserPersonalInfoHonors_HonorsId" -----------
CREATE INDEX "fk_UserPersonalInfoHonors_HonorsId" ON "votecube"."user_personal_info_honors" USING btree( "honor_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_UserPersonalInfoHonors_UserPersonalInfoHonorId" 
CREATE INDEX "pk_UserPersonalInfoHonors_UserPersonalInfoHonorId" ON "votecube"."user_personal_info_honors" USING btree( "user_personal_info_honor_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserPersonalInfoHonors_UserPersonalInfoId" -
CREATE INDEX "fk_UserPersonalInfoHonors_UserPersonalInfoId" ON "votecube"."user_personal_info_honors" USING btree( "user_personal_info_id" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "continent" ------------------------------------
CREATE TABLE "votecube"."continent" ( 
	"continent_id" Bigint NOT NULL,
	"continent_code" Character Varying( 16 ) NOT NULL,
	"continent_name" Character Varying( 16 ) NOT NULL,
	"continent_full_name" Character Varying( 16 ) NOT NULL,
	"created_date" Timestamp With Time Zone NOT NULL,
	"continent_id_2" Bigint NOT NULL,
	PRIMARY KEY ( "continent_id_2" ),
	CONSTRAINT "u_Continent_ContinentCode" UNIQUE( "continent_code" ),
	CONSTRAINT "u_Continent_ContinentName" UNIQUE( "continent_name" ),
	CONSTRAINT "u_Continent_ContinentFullName" UNIQUE( "continent_full_name" ),
	CONSTRAINT "u_Continent_ContinentId" UNIQUE( "continent_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Continent_ContinentId" ---------------------
CREATE INDEX "pk_Continent_ContinentId" ON "votecube"."continent" USING btree( "continent_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Continent_ContinentCode" -------------------
CREATE INDEX "ak_Continent_ContinentCode" ON "votecube"."continent" USING btree( "continent_code" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Continent_ContinentName" -------------------
CREATE INDEX "ak_Continent_ContinentName" ON "votecube"."continent" USING btree( "continent_name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ak_Continent_ContinentName" ---
ALTER TABLE "votecube"."continent" CLUSTER ON "votecube"."ak_Continent_ContinentName";
-- -------------------------------------------------------------




-- CREATE TABLE "country" --------------------------------------
CREATE TABLE "votecube"."country" ( 
	"country_id" Bigint NOT NULL,
	"country_code" Character Varying( 16 ) NOT NULL,
	"country_code3" Character Varying( 16 ) NOT NULL,
	"country_name" Character Varying( 64 ) NOT NULL,
	"country_full_name" Character Varying( 64 ) NOT NULL,
	"created_date" Timestamp With Time Zone NOT NULL,
	"expired_date" Timestamp With Time Zone NOT NULL,
	"continent_id" Bigint NOT NULL,
	PRIMARY KEY ( "country_id" ),
	CONSTRAINT "u_Country_CountryId" UNIQUE( "country_id" ),
	CONSTRAINT "u_Country_CountryCode" UNIQUE( "country_code" ),
	CONSTRAINT "u_Country_CountryCode3" UNIQUE( "country_code3" ),
	CONSTRAINT "u_Country_CountryName" UNIQUE( "country_name" ),
	CONSTRAINT "u_Country_CountryFullName" UNIQUE( "country_full_name" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Country_CountryId" -------------------------
CREATE INDEX "pk_Country_CountryId" ON "votecube"."country" USING btree( "country_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Country_CountryCode" -----------------------
CREATE INDEX "ak_Country_CountryCode" ON "votecube"."country" USING btree( "country_code" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Country_CountryName" -----------------------
CREATE INDEX "ak_Country_CountryName" ON "votecube"."country" USING btree( "country_name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Country_ContinentId" -----------------------
CREATE INDEX "fk_Country_ContinentId" ON "votecube"."country" USING btree( "continent_id" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "state" ----------------------------------------
CREATE TABLE "votecube"."state" ( 
	"state_id" Bigint NOT NULL,
	"country_id" Bigint NOT NULL,
	"timezone_id" Bigint NOT NULL,
	"state_code" Character Varying( 16 ) NOT NULL,
	"state_name" Character Varying( 64 ) NOT NULL,
	"state_full_name" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "state_id" ),
	CONSTRAINT "u_State_StateId" UNIQUE( "state_id" ),
	CONSTRAINT "u_State_StateCode" UNIQUE( "state_code" ),
	CONSTRAINT "u_State_StateName" UNIQUE( "state_name" ),
	CONSTRAINT "u_State_StateFullName" UNIQUE( "state_full_name" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_State_CountryId" ---------------------------
CREATE INDEX "fk_State_CountryId" ON "votecube"."state" USING btree( "country_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_State_StateId" -----------------------------
CREATE INDEX "pk_State_StateId" ON "votecube"."state" USING btree( "state_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_State_StateCode" ---------------------------
CREATE INDEX "ak_State_StateCode" ON "votecube"."state" USING btree( "state_code" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_State_StateName" ---------------------------
CREATE INDEX "ak_State_StateName" ON "votecube"."state" USING btree( "state_name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CHANGE "CLUSTERED" OF "INDEX "ak_State_StateName" -----------
ALTER TABLE "votecube"."state" CLUSTER ON "votecube"."ak_State_StateName";
-- -------------------------------------------------------------



-- CREATE TABLE "county" ---------------------------------------
CREATE TABLE "votecube"."county" ( 
	"county_id" Bigint NOT NULL,
	"state_id" Bigint NOT NULL,
	"county_code" Character Varying( 16 ) NOT NULL,
	"county_name" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "county_id" ),
	CONSTRAINT "u_County_CountyId" UNIQUE( "county_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_County_StateId" ----------------------------
CREATE INDEX "fk_County_StateId" ON "votecube"."county" USING btree( "state_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_County_CountyId" ---------------------------
CREATE INDEX "pk_County_CountyId" ON "votecube"."county" USING btree( "county_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_County_CountyCode" -------------------------
CREATE INDEX "ak_County_CountyCode" ON "votecube"."county" USING btree( "county_code" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_County_CountyName" -------------------------
CREATE INDEX "ak_County_CountyName" ON "votecube"."county" USING btree( "county_name" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "town" -----------------------------------------
CREATE TABLE "votecube"."town" ( 
	"town_id" Bigint NOT NULL,
	"county_id" Bigint NOT NULL,
	"town_code" Character Varying( 16 ) NOT NULL,
	"town_name" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "town_id" ),
	CONSTRAINT "u_Town_TownId" UNIQUE( "town_code", "town_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Town_TownId" -------------------------------
CREATE INDEX "pk_Town_TownId" ON "votecube"."town" USING btree( "town_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Town_TownCode" -----------------------------
CREATE INDEX "ak_Town_TownCode" ON "votecube"."town" USING btree( "town_code" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Town_TownName" -----------------------------
CREATE INDEX "ak_Town_TownName" ON "votecube"."town" USING btree( "town_name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Town_CountyId" -----------------------------
CREATE INDEX "fk_Town_CountyId" ON "votecube"."town" USING btree( "county_id" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "suburb" ---------------------------------------
CREATE TABLE "votecube"."suburb" ( 
	"suburb_id" Bigint NOT NULL,
	"town_id" Bigint NOT NULL,
	"suburb_code" Character Varying( 16 ) NOT NULL,
	"suburb_name" Character Varying( 64 ) NOT NULL,
	"longitude" Numeric( 9, 6 ) NOT NULL,
	"latitude" Numeric( 8, 6 ) NOT NULL,
	PRIMARY KEY ( "suburb_id" ),
	CONSTRAINT "u_Suburb_SuburbId" UNIQUE( "suburb_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Suberb_TownId" -----------------------------
CREATE INDEX "fk_Suberb_TownId" ON "votecube"."suburb" USING btree( "town_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Suberb_SuberbId" ---------------------------
CREATE INDEX "pk_Suberb_SuberbId" ON "votecube"."suburb" USING btree( "suburb_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Suberb_SuberbCode" -------------------------
CREATE INDEX "ak_Suberb_SuberbCode" ON "votecube"."suburb" USING btree( "suburb_code" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Suberb_SuberbName" -------------------------
CREATE INDEX "ak_Suberb_SuberbName" ON "votecube"."suburb" USING btree( "suburb_name" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "street_name" ----------------------------------
CREATE TABLE "votecube"."street_name" ( 
	"street_name_id" Bigint NOT NULL,
	"street_name" Character Varying( 256 ) NOT NULL,
	PRIMARY KEY ( "street_name_id" ),
	CONSTRAINT "u_StreetName_StreetNameId" UNIQUE( "street_name_id" ),
	CONSTRAINT "u_StreetName_StreetName" UNIQUE( "street_name" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_StreetName_StreetNameId" -------------------
CREATE INDEX "pk_StreetName_StreetNameId" ON "votecube"."street_name" USING btree(  );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_StreetName_StreetName" ---------------------
CREATE INDEX "ak_StreetName_StreetName" ON "votecube"."street_name" USING btree(  );
-- -------------------------------------------------------------




-- CREATE TABLE "street_type" ----------------------------------
CREATE TABLE "votecube"."street_type" ( 
	"street_type_id" Bigint NOT NULL,
	"street_type" Character Varying( 64 ) NOT NULL,
	PRIMARY KEY ( "street_type_id" ),
	CONSTRAINT "u_StreetType_StreetTypeId" UNIQUE( "street_type_id" ),
	CONSTRAINT "u_StreetType_StreetType" UNIQUE( "street_type" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_StreetType_StreetTypeId" -------------------
CREATE INDEX "pk_StreetType_StreetTypeId" ON "votecube"."street_type" USING btree( "street_type_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_StreetType_StreetType" ---------------------
CREATE INDEX "ak_StreetType_StreetType" ON "votecube"."street_type" USING btree( "street_type" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "street" ---------------------------------------
CREATE TABLE "votecube"."street" ( 
	"street_id" Bigint NOT NULL,
	"street_name_id" Bigint NOT NULL,
	"street_type_id" Bigint NOT NULL,
	"suburb_id" Bigint NOT NULL,
	PRIMARY KEY ( "street_id" ),
	CONSTRAINT "u_Street_StreetId" UNIQUE( "street_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Street_StreetNameId" -----------------------
CREATE INDEX "fk_Street_StreetNameId" ON "votecube"."street" USING btree( "street_name_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Street_StreetTypeId" -----------------------
CREATE INDEX "fk_Street_StreetTypeId" ON "votecube"."street" USING btree( "street_type_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Street_SuburbId" ---------------------------
CREATE INDEX "fk_Street_SuburbId" ON "votecube"."street" USING btree( "suburb_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Street_StreetId" ---------------------------
CREATE INDEX "pk_Street_StreetId" ON "votecube"."street" USING btree( "street_id" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "address" --------------------------------------
CREATE TABLE "votecube"."address" ( 
	"address_id" Bigint NOT NULL,
	"street_id" Bigint NOT NULL,
	"street_number" SmallInt,
	"building_unit" Character Varying( 16 ),
	"is_building_unit" Boolean,
	"post_code" Character Varying( 16 ) NOT NULL,
	PRIMARY KEY ( "address_id" ),
	CONSTRAINT "u_Address_AddressId" UNIQUE( "address_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Address_StreetId" --------------------------
CREATE INDEX "fk_Address_StreetId" ON "votecube"."address" USING btree( "street_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Address_AddressId" -------------------------
CREATE INDEX "pk_Address_AddressId" ON "votecube"."address" USING btree( "address_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_Address_PostCode" --------------------------
CREATE INDEX "fk_Address_PostCode" ON "votecube"."address" USING btree( "post_code" Asc NULLS Last );
-- -------------------------------------------------------------





-- CREATE TABLE "timezone" -------------------------------------
CREATE TABLE "votecube"."timezone" ( 
	"timezone_id" Bigint NOT NULL,
	"timezone_name" Character Varying( 16 ) NOT NULL,
	"timezone_offset" SmallInt NOT NULL,
	PRIMARY KEY ( "timezone_id" ),
	CONSTRAINT "u_Timezone_TimezoneId" UNIQUE( "timezone_id" ),
	CONSTRAINT "u_Timezone_TimezoneName" UNIQUE( "timezone_name" ),
	CONSTRAINT "u_Timezone_TimezoneOffset" UNIQUE( "timezone_offset" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "pk_Timezone_TimezoneId" -----------------------
CREATE INDEX "pk_Timezone_TimezoneId" ON "votecube"."timezone" USING btree( "timezone_id" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Timezone_TimezoneName" ---------------------
CREATE INDEX "ak_Timezone_TimezoneName" ON "votecube"."timezone" USING btree( "timezone_name" Asc NULLS Last );
-- -------------------------------------------------------------

-- CREATE INDEX "ak_Timezone_TimezoneOffset" -------------------
CREATE INDEX "ak_Timezone_TimezoneOffset" ON "votecube"."timezone" USING btree( "timezone_offset" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE TABLE "user_personal_info" ---------------------------
CREATE TABLE "votecube"."user_personal_info" ( 
	"user_personal_info_id" Bigint NOT NULL,
	"user_account_id" Bigint NOT NULL,
	"email_address_id" Bigint NOT NULL,
	"password_hashkey" Character Varying( 64 ) NOT NULL,
	"password_salt" Character Varying( 64 ) NOT NULL,
	"password_hash_algorithm" Character Varying( 64 ) NOT NULL,
	"person_type_id" Bigint NOT NULL,
	"phone" Character Varying( 16 ) NOT NULL,
	"address_id" Bigint NOT NULL,
	"updated_at" Timestamp With Time Zone NOT NULL,
	PRIMARY KEY ( "user_personal_info_id" ),
	CONSTRAINT "u_UserPersonalInfo_UserPersonalInfoId" UNIQUE( "user_personal_info_id" ) );
 ;
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserPersonalInfo_UserAccountId" ------------
CREATE INDEX "fk_UserPersonalInfo_UserAccountId" ON "votecube"."user_personal_info" USING btree( "user_account_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "fk_UserPersonalInfo_EmailAddressId" -----------
CREATE INDEX "fk_UserPersonalInfo_EmailAddressId" ON "votecube"."user_personal_info" USING btree( "email_address_id" );
-- -------------------------------------------------------------

-- CREATE INDEX "pk_UserPersonalInfo_UserPersonalInfoId" -------
CREATE INDEX "pk_UserPersonalInfo_UserPersonalInfoId" ON "votecube"."user_personal_info" USING btree( "user_personal_info_id" Asc NULLS Last );
-- -------------------------------------------------------------




-- CREATE LINK "fk_Messages_Messages_ParentMessageId" ----------
ALTER TABLE "votecube"."messages"
	ADD CONSTRAINT "fk_Messages_Messages_ParentMessageId" FOREIGN KEY ( "parent_message_id" )
	REFERENCES "votecube"."messages" ( "message_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Messages_UserAccount_UserAccountId" ---------
ALTER TABLE "votecube"."messages"
	ADD CONSTRAINT "fk_Messages_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsMessages_Message_MessageId" ------------
ALTER TABLE "votecube"."polls_messages"
	ADD CONSTRAINT "fk_PollsMessages_Message_MessageId" FOREIGN KEY ( "message_id" )
	REFERENCES "votecube"."messages" ( "message_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsMessages_Polls_PollId" -----------------
ALTER TABLE "votecube"."polls_messages"
	ADD CONSTRAINT "fk_PollsMessages_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_MessagesLinks_Messages_MessageId" -----------
ALTER TABLE "votecube"."messages_links"
	ADD CONSTRAINT "fk_MessagesLinks_Messages_MessageId" FOREIGN KEY ( "message_id" )
	REFERENCES "votecube"."messages" ( "message_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_MessagesLinks_Links_LinkId" -----------------
ALTER TABLE "votecube"."messages_links"
	ADD CONSTRAINT "fk_MessagesLinks_Links_LinkId" FOREIGN KEY ( "link_id" )
	REFERENCES "votecube"."links" ( "link_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Labels_UserAccount_UserAccountId" -----------
ALTER TABLE "votecube"."labels"
	ADD CONSTRAINT "fk_Labels_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsLabels_Polls_PollId" -------------------
ALTER TABLE "votecube"."polls_labels"
	ADD CONSTRAINT "fk_PollsLabels_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsLabels_Labels_LabelId" -----------------
ALTER TABLE "votecube"."polls_labels"
	ADD CONSTRAINT "fk_PollsLabels_Labels_LabelId" FOREIGN KEY ( "label_id" )
	REFERENCES "votecube"."labels" ( "label_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsLabels_UserAccount_UserAccountId" ------
ALTER TABLE "votecube"."polls_labels"
	ADD CONSTRAINT "fk_PollsLabels_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsLinks_Polls_PollId" --------------------
ALTER TABLE "votecube"."polls_links"
	ADD CONSTRAINT "fk_PollsLinks_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsLinks_Links_LinkId" --------------------
ALTER TABLE "votecube"."polls_links"
	ADD CONSTRAINT "fk_PollsLinks_Links_LinkId" FOREIGN KEY ( "link_id" )
	REFERENCES "votecube"."links" ( "link_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsLinks_UserAccount_UserAccountId" -------
ALTER TABLE "votecube"."polls_links"
	ADD CONSTRAINT "fk_PollsLinks_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsGroups_UserAccount_UserAccountId" ------
ALTER TABLE "votecube"."polls_groups"
	ADD CONSTRAINT "fk_PollsGroups_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsGroups_Themes_ThemeId" -----------------
ALTER TABLE "votecube"."polls_groups"
	ADD CONSTRAINT "fk_PollsGroups_Themes_ThemeId" FOREIGN KEY ( "theme_id" )
	REFERENCES "votecube"."themes" ( "theme_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsPollsGroups_PollsGroups_PollGroupId" ---
ALTER TABLE "votecube"."polls_polls_groups"
	ADD CONSTRAINT "fk_PollsPollsGroups_PollsGroups_PollGroupId" FOREIGN KEY ( "poll_group_id" )
	REFERENCES "votecube"."polls_groups" ( "poll_group_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsPollsGroups_Polls_PollId" --------------
ALTER TABLE "votecube"."polls_polls_groups"
	ADD CONSTRAINT "fk_PollsPollsGroups_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsPollsGroups_UserAccount_UserAccountId" -
ALTER TABLE "votecube"."polls_polls_groups"
	ADD CONSTRAINT "fk_PollsPollsGroups_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE self LINK "fk_Dimensions_Dimensions_ParentDimensionId" ----
ALTER TABLE "votecube"."dimensions"
	ADD CONSTRAINT "fk_Dimensions_Dimensions_ParentDimensionId" FOREIGN KEY ( "parent_dimension_id" )
	REFERENCES "votecube"."dimensions" ( "dimension_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Dimensions_UserAccount_UserAccountId" -------
ALTER TABLE "votecube"."dimensions"
	ADD CONSTRAINT "fk_Dimensions_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Dimensions_Colors_ColorId" ------------------
ALTER TABLE "votecube"."dimensions"
	ADD CONSTRAINT "fk_Dimensions_Colors_ColorId" FOREIGN KEY ( "color_id" )
	REFERENCES "votecube"."colors" ( "color_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_DimensionsLinks_Dimensions_DimensionId" -----
ALTER TABLE "votecube"."dimensions_links"
	ADD CONSTRAINT "fk_DimensionsLinks_Dimensions_DimensionId" FOREIGN KEY ( "dimensions_id" )
	REFERENCES "votecube"."dimensions" ( "dimension_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_DimensionsLinks_UserAccount_UserAccountId" --
ALTER TABLE "votecube"."dimensions_links"
	ADD CONSTRAINT "fk_DimensionsLinks_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_DimensionsLinks_Links_LinkId" ---------------
ALTER TABLE "votecube"."dimensions_links"
	ADD CONSTRAINT "fk_DimensionsLinks_Links_LinkId" FOREIGN KEY ( "links_id" )
	REFERENCES "votecube"."links" ( "link_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE self LINK "fk_Directions_Directions_ParentDirectionId" ----
ALTER TABLE "votecube"."directions"
	ADD CONSTRAINT "fk_Directions_Directions_ParentDirectionId" FOREIGN KEY ( "parent_direction_id" )
	REFERENCES "votecube"."directions" ( "parent_direction_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Directions_UserAccount_UserAccountId" -------
ALTER TABLE "votecube"."directions"
	ADD CONSTRAINT "fk_Directions_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Directions_DesignPatterns_DesignPatternId" --
ALTER TABLE "votecube"."directions"
	ADD CONSTRAINT "fk_Directions_DesignPatterns_DesignPatternId" FOREIGN KEY ( "design_pattern_id" )
	REFERENCES "votecube"."design_patterns" ( "design_pattern_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Directions_Emoji_EmojiId" -------------------
ALTER TABLE "votecube"."directions"
	ADD CONSTRAINT "fk_Directions_Emoji_EmojiId" FOREIGN KEY ( "emoji_id" )
	REFERENCES "votecube"."emoji" ( "emoji_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_Links_UserAccount_UserAccountID" ------------
ALTER TABLE "votecube"."links"
	ADD CONSTRAINT "fk_Links_UserAccount_UserAccountID" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_PollsContinent_Polls_PollId" ----------------
ALTER TABLE "votecube"."polls_continent"
	ADD CONSTRAINT "fk_PollsContinent_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_PollsContinent_Continent_ContinentId" -------
ALTER TABLE "votecube"."polls_continent"
	ADD CONSTRAINT "fk_PollsContinent_Continent_ContinentId" FOREIGN KEY ( "continent_id" )
	REFERENCES "votecube"."continent" ( "continent_id_2" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_PollsCountry_Polls_PollId" ------------------
ALTER TABLE "votecube"."polls_country"
	ADD CONSTRAINT "fk_PollsCountry_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_PollsCountry_Country_CountryId" -------------
ALTER TABLE "votecube"."polls_country"
	ADD CONSTRAINT "fk_PollsCountry_Country_CountryId" FOREIGN KEY ( "country_id" )
	REFERENCES "votecube"."country" ( "country_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_PollsState_Polls_PollId" --------------------
ALTER TABLE "votecube"."polls_state"
	ADD CONSTRAINT "fk_PollsState_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_PollsState_State_StateId" -------------------
ALTER TABLE "votecube"."polls_state"
	ADD CONSTRAINT "fk_PollsState_State_StateId" FOREIGN KEY ( "state_id" )
	REFERENCES "votecube"."state" ( "state_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_PollsCounty_Polls_PollId" -------------------
ALTER TABLE "votecube"."polls_county"
	ADD CONSTRAINT "fk_PollsCounty_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_PollsCounty_County_CountyId" ----------------
ALTER TABLE "votecube"."polls_county"
	ADD CONSTRAINT "fk_PollsCounty_County_CountyId" FOREIGN KEY ( "county_id" )
	REFERENCES "votecube"."county" ( "county_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_PollsTown_Polls_PollId" ---------------------
ALTER TABLE "votecube"."polls_town"
	ADD CONSTRAINT "fk_PollsTown_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_PollsTown_Town_TownId" ----------------------
ALTER TABLE "votecube"."polls_town"
	ADD CONSTRAINT "fk_PollsTown_Town_TownId" FOREIGN KEY ( "town_id" )
	REFERENCES "votecube"."town" ( "town_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_DimensionDirections_Dimensions_DimensionId" -
ALTER TABLE "votecube"."dimension_directions"
	ADD CONSTRAINT "fk_DimensionDirections_Dimensions_DimensionId" FOREIGN KEY ( "dimension_id" )
	REFERENCES "votecube"."dimensions" ( "dimension_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_DimensionDirections_Directions_DirectionId" -
ALTER TABLE "votecube"."dimension_directions"
	ADD CONSTRAINT "fk_DimensionDirections_Directions_DirectionId" FOREIGN KEY ( "direction_id" )
	REFERENCES "votecube"."directions" ( "direction_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsDimensionsDirections_DimensionsDirections_DimensionDirectionId" 
ALTER TABLE "votecube"."polls_dimensions_directions"
	ADD CONSTRAINT "fk_PollsDimensionsDirections_DimensionsDirections_DimensionDirectionId" FOREIGN KEY ( "dimension_direction_id" )
	REFERENCES "votecube"."dimension_directions" ( "dimension_direction_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollsDimensionsDirections_Polls_PollId" -----
ALTER TABLE "votecube"."polls_dimensions_directions"
	ADD CONSTRAINT "fk_PollsDimensionsDirections_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "parent_poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollDimensionsDirections_Colorss_ColorId" ---
ALTER TABLE "votecube"."polls_dimensions_directions"
	ADD CONSTRAINT "fk_PollDimensionsDirections_Colorss_ColorId" FOREIGN KEY ( "color_id" )
	REFERENCES "votecube"."colors" ( "color_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollDimensionsDirections_DesignPatterns_DesignPatternId" 
ALTER TABLE "votecube"."polls_dimensions_directions"
	ADD CONSTRAINT "fk_PollDimensionsDirections_DesignPatterns_DesignPatternId" FOREIGN KEY ( "design_pattern_id" )
	REFERENCES "votecube"."design_patterns" ( "design_pattern_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_PollDimensionsDirections_Emoji_EmojiId" -----
ALTER TABLE "votecube"."polls_dimensions_directions"
	ADD CONSTRAINT "fk_PollDimensionsDirections_Emoji_EmojiId" FOREIGN KEY ( "emoji_id" )
	REFERENCES "votecube"."emoji" ( "emoji_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Votes_UserAccount_UserAccountId" ------------
ALTER TABLE "votecube"."vote"
	ADD CONSTRAINT "fk_Votes_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Votes_Polls_PollId" -------------------------
ALTER TABLE "votecube"."vote"
	ADD CONSTRAINT "fk_Votes_Polls_PollId" FOREIGN KEY ( "poll_id" )
	REFERENCES "votecube"."polls" ( "parent_poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Votes_PollsDimensionsDirections_XpollDirectionDimensionId" 
ALTER TABLE "votecube"."vote"
	ADD CONSTRAINT "fk_Votes_PollsDimensionsDirections_XpollDirectionDimensionId" FOREIGN KEY ( "x_poll_dimension_direction_id" )
	REFERENCES "votecube"."polls_dimensions_directions" ( "poll_dimension_direction_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Votes_PollsDimensionsDirections_YpollDirectionDimensionId" 
ALTER TABLE "votecube"."vote"
	ADD CONSTRAINT "fk_Votes_PollsDimensionsDirections_YpollDirectionDimensionId" FOREIGN KEY ( "y_poll_dimension_direction_id" )
	REFERENCES "votecube"."polls_dimensions_directions" ( "poll_dimension_direction_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Votes_PollsDimensionsDirections_ZpollDirectionDimensionId" 
ALTER TABLE "votecube"."vote"
	ADD CONSTRAINT "fk_Votes_PollsDimensionsDirections_ZpollDirectionDimensionId" FOREIGN KEY ( "z_poll_dimension_direction_id" )
	REFERENCES "votecube"."polls_dimensions_directions" ( "poll_dimension_direction_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Polls_Polls_ParentPollId" -------------------
ALTER TABLE "votecube"."polls"
	ADD CONSTRAINT "fk_Polls_Polls_ParentPollId" FOREIGN KEY ( "parent_poll_id" )
	REFERENCES "votecube"."polls" ( "poll_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_Polls_UserAccount_UserAccountId" ------------
ALTER TABLE "votecube"."polls"
	ADD CONSTRAINT "fk_Polls_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Polls_PollTheme_PollThemeId" ----------------
ALTER TABLE "votecube"."polls"
	ADD CONSTRAINT "fk_Polls_PollTheme_PollThemeId" FOREIGN KEY ( "theme_id" )
	REFERENCES "votecube"."themes" ( "theme_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------




-- CREATE LINK "fk_UserAccountSuffix_Suffix_SuffixId" ----------
ALTER TABLE "votecube"."user_account_suffix"
	ADD CONSTRAINT "fk_UserAccountSuffix_Suffix_SuffixId" FOREIGN KEY ( "suffix_id" )
	REFERENCES "votecube"."suffix" ( "suffix_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserAccountSuffix_UserAccount_UserAccountId" 
ALTER TABLE "votecube"."user_account_suffix"
	ADD CONSTRAINT "fk_UserAccountSuffix_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_EthnicGroupCountry_EthnicGroup_EthnicGroupId" 
ALTER TABLE "votecube"."ethnic_group_country"
	ADD CONSTRAINT "fk_EthnicGroupCountry_EthnicGroup_EthnicGroupId" FOREIGN KEY ( "ethnic_group_id" )
	REFERENCES "votecube"."ethnic_group" ( "ethnic_group_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_EthnicGroupCountry_Country_CountryId" -------
ALTER TABLE "votecube"."ethnic_group_country"
	ADD CONSTRAINT "fk_EthnicGroupCountry_Country_CountryId" FOREIGN KEY ( "country_id" )
	REFERENCES "votecube"."country" ( "country_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_EthnicSubgroup_EthnicGroup_EthnicGroupId" ---
ALTER TABLE "votecube"."ethnic_subgroup"
	ADD CONSTRAINT "fk_EthnicSubgroup_EthnicGroup_EthnicGroupId" FOREIGN KEY ( "ethnic_group_id" )
	REFERENCES "votecube"."ethnic_group" ( "ethnic_group_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserAccountEthnicity_UserAccount_UserAccountId" 
ALTER TABLE "votecube"."user_account_ethnicity"
	ADD CONSTRAINT "fk_UserAccountEthnicity_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserAccountEthnicity_EthnicSubgroup_EthnicSubgroupId" 
ALTER TABLE "votecube"."user_account_ethnicity"
	ADD CONSTRAINT "fk_UserAccountEthnicity_EthnicSubgroup_EthnicSubgroupId" FOREIGN KEY ( "ethnic_subgroup_id" )
	REFERENCES "votecube"."ethnic_subgroup" ( "ethnic_subgroup_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserAccount_PrefixLastName_PrefixLastNameId" 
ALTER TABLE "votecube"."user_account"
	ADD CONSTRAINT "fk_UserAccount_PrefixLastName_PrefixLastNameId" FOREIGN KEY ( "prefix_last_name_id" )
	REFERENCES "votecube"."prefix_last_name" ( "prefix_last_name_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserAccount_NameAfterLastName_NameAfterLastNameId" 
ALTER TABLE "votecube"."user_account"
	ADD CONSTRAINT "fk_UserAccount_NameAfterLastName_NameAfterLastNameId" FOREIGN KEY ( "name_after_last_name_id" )
	REFERENCES "votecube"."name_after_last_name" ( "name_after_last_name_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserPersonalInfoTitle_Title_TitleId" --------
ALTER TABLE "votecube"."user_personal_info_title"
	ADD CONSTRAINT "fk_UserPersonalInfoTitle_Title_TitleId" FOREIGN KEY ( "title_id" )
	REFERENCES "votecube"."title" ( "title_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserPersonalInfoTitle_UserPersonalInfo_UserPersonalInfoId" 
ALTER TABLE "votecube"."user_personal_info_title"
	ADD CONSTRAINT "fk_UserPersonalInfoTitle_UserPersonalInfo_UserPersonalInfoId" FOREIGN KEY ( "user_personal_info_id" )
	REFERENCES "votecube"."user_personal_info" ( "user_personal_info_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserPersonalInfoTitleAfterLastName_TitleAfterLastName_TitleAfterLastNameId" 
ALTER TABLE "votecube"."user_personal_info_title_after_last_name"
	ADD CONSTRAINT "fk_UserPersonalInfoTitleAfterLastName_TitleAfterLastName_TitleAfterLastNameId" FOREIGN KEY ( "title_after_last_name_id" )
	REFERENCES "votecube"."title_after_last_name" ( "title_after_last_name_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserPersonalInfoTitleAfterLastName_UserPersonalInfo_UserPersonalInfoId" 
ALTER TABLE "votecube"."user_personal_info_title_after_last_name"
	ADD CONSTRAINT "fk_UserPersonalInfoTitleAfterLastName_UserPersonalInfo_UserPersonalInfoId" FOREIGN KEY ( "user_personal_info_id" )
	REFERENCES "votecube"."user_personal_info" ( "user_personal_info_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_EmailDomain_UserAccount_UserAccountId" ------
ALTER TABLE "votecube"."email_domain"
	ADD CONSTRAINT "fk_EmailDomain_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_EmailAddress_UserAccount_UserAccountId" -----
ALTER TABLE "votecube"."email_address"
	ADD CONSTRAINT "fk_EmailAddress_UserAccount_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_EmailAddress_EmailDomain_EmailDomainId" -----
ALTER TABLE "votecube"."email_address"
	ADD CONSTRAINT "fk_EmailAddress_EmailDomain_EmailDomainId" FOREIGN KEY ( "email_domain_id" )
	REFERENCES "votecube"."email_domain" ( "email_domain_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserPersonalInfoHonors_Honors_HonorId" ------
ALTER TABLE "votecube"."user_personal_info_honors"
	ADD CONSTRAINT "fk_UserPersonalInfoHonors_Honors_HonorId" FOREIGN KEY ( "honor_id" )
	REFERENCES "votecube"."honors" ( "honor_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserPersonalInfoHonors_UserPersonalInfo_UserPersonalInfoId" 
ALTER TABLE "votecube"."user_personal_info_honors"
	ADD CONSTRAINT "fk_UserPersonalInfoHonors_UserPersonalInfo_UserPersonalInfoId" FOREIGN KEY ( "user_personal_info_id" )
	REFERENCES "votecube"."user_personal_info" ( "user_personal_info_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Country_Continent_ContinentId" --------------
ALTER TABLE "votecube"."country"
	ADD CONSTRAINT "fk_Country_Continent_ContinentId" FOREIGN KEY ( "continent_id" )
	REFERENCES "votecube"."continent" ( "continent_id_2" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_State_Country_CountryId" --------------------
ALTER TABLE "votecube"."state"
	ADD CONSTRAINT "fk_State_Country_CountryId" FOREIGN KEY ( "country_id" )
	REFERENCES "votecube"."country" ( "country_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_State_Timezone_TimezoneId" ------------------
ALTER TABLE "votecube"."state"
	ADD CONSTRAINT "fk_State_Timezone_TimezoneId" FOREIGN KEY ( "timezone_id" )
	REFERENCES "votecube"."timezone" ( "timezone_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_County_State_StateId" -----------------------
ALTER TABLE "votecube"."county"
	ADD CONSTRAINT "fk_County_State_StateId" FOREIGN KEY ( "state_id" )
	REFERENCES "votecube"."state" ( "state_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Town_County_CountyId" -----------------------
ALTER TABLE "votecube"."town"
	ADD CONSTRAINT "fk_Town_County_CountyId" FOREIGN KEY ( "county_id" )
	REFERENCES "votecube"."county" ( "county_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Suberb_Town_TownId" -------------------------
ALTER TABLE "votecube"."suburb"
	ADD CONSTRAINT "fk_Suberb_Town_TownId" FOREIGN KEY ( "town_id" )
	REFERENCES "votecube"."town" ( "town_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Street_StreetName_StreetNameId" -------------
ALTER TABLE "votecube"."street"
	ADD CONSTRAINT "fk_Street_StreetName_StreetNameId" FOREIGN KEY ( "street_name_id" )
	REFERENCES "votecube"."street_name" ( "street_name_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Street_StreetType_StreetTypeId" -------------
ALTER TABLE "votecube"."street"
	ADD CONSTRAINT "fk_Street_StreetType_StreetTypeId" FOREIGN KEY ( "street_type_id" )
	REFERENCES "votecube"."street_type" ( "street_type_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Street_Suburb_SuburbId" ---------------------
ALTER TABLE "votecube"."street"
	ADD CONSTRAINT "fk_Street_Suburb_SuburbId" FOREIGN KEY ( "suburb_id" )
	REFERENCES "votecube"."suburb" ( "suburb_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_Address_Street_StreetId" --------------------
ALTER TABLE "votecube"."address"
	ADD CONSTRAINT "fk_Address_Street_StreetId" FOREIGN KEY ( "street_id" )
	REFERENCES "votecube"."street" ( "street_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserPersonalInfo_User_account_UserAccountId" 
ALTER TABLE "votecube"."user_personal_info"
	ADD CONSTRAINT "fk_UserPersonalInfo_User_account_UserAccountId" FOREIGN KEY ( "user_account_id" )
	REFERENCES "votecube"."user_account" ( "user_account_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserPersonalInfo_EmailAddress_EmailAddressId" 
ALTER TABLE "votecube"."user_personal_info"
	ADD CONSTRAINT "fk_UserPersonalInfo_EmailAddress_EmailAddressId" FOREIGN KEY ( "email_address_id" )
	REFERENCES "votecube"."email_address" ( "email_name", "email_domain_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "UserPersonalInfo_PersonType_PersonTypeId" ------
ALTER TABLE "votecube"."user_personal_info"
	ADD CONSTRAINT "UserPersonalInfo_PersonType_PersonTypeId" FOREIGN KEY ( "person_type_id" )
	REFERENCES "votecube"."person_type" ( "person_type_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------



-- CREATE LINK "fk_UserPersonalInfo_Address_AddressId" ---------
ALTER TABLE "votecube"."user_personal_info"
	ADD CONSTRAINT "fk_UserPersonalInfo_Address_AddressId" FOREIGN KEY ( "address_id" )
	REFERENCES "votecube"."address" ( "address_id" ) MATCH FULL
	ON DELETE Cascade
	ON UPDATE Cascade;
-- -------------------------------------------------------------























