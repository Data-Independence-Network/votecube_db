-- comment out "drop keyspace" when running for the first time
drop keyspace votecube;

create keyspace votecube WITH replication = {'class': 'SimpleStrategy', 'replication_factor' : 1};

use votecube;

-- for lookup of poll data
CREATE TABLE polls
(
    poll_id       bigint,
    theme_id      bigint, // needed HERE because of materialized views
    location_id   int,    // needed HERE because of materialized views, and eventual sharding
    user_id       bigint,
    create_period ascii,  // needed HERE because of materialized views
    create_es     bigint,
    data          blob,
    batch_id      bigint, // needed HERE because of materialized views
    PRIMARY KEY ((poll_id), theme_id, location_id, create_es)
);

-- for looking up all polls created by user
CREATE MATERIALIZED VIEW poll_ids_by_user AS
SELECT user_id, create_es, poll_id
FROM polls
WHERE create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
  AND user_id IS NOT NULL
PRIMARY KEY ((user_id), create_es, location_id, theme_id, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for ingest into CRDB and Vespa (to lookup all newly created polls, in batches)
CREATE MATERIALIZED VIEW poll_keys AS
SELECT poll_id, batch_id
FROM polls
WHERE batch_id IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((poll_id), batch_id, create_es, location_id, theme_id);

-- for displaying most recent polls
CREATE MATERIALIZED VIEW poll_chronology AS
SELECT create_period, create_es, poll_id
FROM polls
WHERE create_period IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((create_period), create_es, location_id, theme_id, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for displaying most recent polls by location
CREATE MATERIALIZED VIEW poll_chronology_by_location AS
SELECT create_period, location_id, create_es, poll_id
FROM polls
WHERE create_period IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((create_period, location_id), create_es, theme_id, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for displaying most recent polls by location AND theme
CREATE MATERIALIZED VIEW poll_chronology_by_location_and_theme AS
SELECT create_period, location_id, theme_id, create_es, poll_id
FROM polls
WHERE create_period IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((create_period, location_id, theme_id), create_es, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for displaying most recent polls by theme
CREATE MATERIALIZED VIEW poll_chronology_by_theme AS
SELECT create_period, theme_id, create_es, poll_id
FROM polls
WHERE create_period IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((create_period, theme_id), create_es, location_id, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for lookup of the opinion data
CREATE TABLE opinions
(
    opinion_id       bigint,
    root_opinion_id  bigint,
    poll_id          bigint,
    parent_id        bigint,
    position         ascii, // 13.23.1... Estimate Only for data load splitting,
    -- final on (chronological) on screen position is determined by parent_id
    -- and create_es
    create_period    ascii,
    user_id          bigint,
    create_es        bigint,
    update_es        bigint,
    version          int,
    data             blob,
    insert_processed boolean,
    PRIMARY KEY ((poll_id, create_period), create_es, opinion_id)
)
            WITH CLUSTERING ORDER BY (create_es DESC);

-- for lookup of all opinions created by user
CREATE MATERIALIZED VIEW opinion_ids_by_user AS
SELECT user_id, create_es, poll_id, opinion_id
FROM opinions
WHERE user_id IS NOT NULL
  AND poll_id IS NOT NULL
  AND create_period IS NOT NULL
  AND create_es IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((user_id), create_es, poll_id, create_period, opinion_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for lookup of all recent opinion ids when first displaying the thread
-- and for notifications of newly created records once the thread is loaded
-- (with using create_es >= $DATE)
-- its more compact than opinions and hence iterating and returning
-- a block of ids (opinion_id + create_es + version) should be faster
-- (less disk io)
CREATE MATERIALIZED VIEW opinion_ids AS
SELECT poll_id, create_es, opinion_id, version
FROM opinions
WHERE poll_id IS NOT NULL
  AND create_period IS NOT NULL
  AND create_es IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((poll_id, create_period), create_es, opinion_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- For lookup at creation time (to figure out the right position)
-- SELECT COUNT(parent_id) WHERE poll_id = X AND parent_id = Y
CREATE MATERIALIZED VIEW opinion_child_count_base AS
SELECT poll_id, parent_id
FROM opinions
WHERE poll_id IS NOT NULL
  AND parent_id IS NOT NULL
  AND create_es IS NOT NULL
  AND create_period IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((poll_id, parent_id), create_es, create_period, opinion_id)
    -- ORDER BY is not currently needed but is useful to have in case we'll have
    -- queries for all sibling records in reverse order of creation
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for ingest of updates into CRDB and Vespa
CREATE TABLE opinion_updates
(
    opinion_id       bigint,
    root_opinion_id  bigint,
    poll_id          bigint,
    update_period    ascii,
    user_id          bigint,
    update_es        bigint,
    data             blob,
    version          int,
    update_processed boolean,
    PRIMARY KEY ((poll_id, update_period), update_es, opinion_id)
)
            WITH CLUSTERING ORDER BY (update_es DESC);

-- For notifications in the UI as the user is looking at the thread
-- its more compact than opinion_updates and hence iterating and
-- returning a block of ids (opinion_id + create_es + version)
-- should be faster (less disk io)
CREATE MATERIALIZED VIEW opinion_update_lookups AS
SELECT poll_id, update_period, update_es, opinion_id, version
FROM opinion_updates
WHERE poll_id IS NOT NULL
  AND update_period IS NOT NULL
  AND update_es IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((poll_id, update_period), update_es, opinion_id)
        WITH CLUSTERING ORDER BY (update_es DESC);

CREATE TABLE root_opinions
(
    root_opinion_id bigint,
    poll_id         bigint,
    position        int,
    user_id         bigint,
    create_es       bigint,
    version         int,
    data            blob,
    /*
     Shouldn't need this column.  In case of batch failures there may be an point when
     a later batch succeeded but an earlier has not so, in such a case this wouldn't be of
     any use.
     */
    -- last_processed_period text,
    PRIMARY KEY ((poll_id), create_es, root_opinion_id)
)
/**
  This is useful for chronological ordering
 */
            WITH CLUSTERING ORDER BY (create_es DESC);

CREATE TABLE users
(
    user_id bigint,
    PRIMARY KEY (user_id)
);

CREATE TABLE user_credentials
(
    username text,
    user_id  bigint,
    hash     text,
    PRIMARY KEY (username)
);

CREATE TABLE session
(
    session_id text,
    user_id    bigint,
    PRIMARY KEY (session_id)
);

-- insert into polls (poll_id, user_id, create_es, data)
-- values(1, 1, 1578602993, textAsBlob('hello poll!'));
--
-- insert into poll_keys (poll_id, user_id, create_es)
-- values(1, 1, 1578602993);
--
-- insert into threads (poll_id, user_id, create_es, data)
-- values(1, 1, 1578602993, textAsBlob('hello thread!'));
--
-- insert into opinions (opinion_id, poll_id, date, user_id, create_es, data, processed)
-- values(1, 1, '2020-01-09', 1, 1578602995, textAsBlob('hello ScyllaDB!'), false);
