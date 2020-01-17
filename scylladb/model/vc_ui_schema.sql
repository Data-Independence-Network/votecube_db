-- comment out "drop keyspace" when running for the first time
drop keyspace votecube;

create keyspace votecube WITH replication = {'class': 'SimpleStrategy', 'replication_factor' : 1};

use votecube;

-- for lookup of poll data
CREATE TABLE polls
(
    poll_id     bigint,
    theme_id    bigint, // needed HERE because of materialized views
    location_id int,    // needed HERE because of materialized views
    user_id     bigint,
    create_date ascii,  // needed HERE because of materialized views
    create_es   bigint,
    data        blob,
    batch_id    bigint, // needed HERE because of materialized views
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

-- for ingest into CRDB and Vespa (to lookup all newly created polls, in batches
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
SELECT create_date, create_es, poll_id
FROM polls
WHERE create_date IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((create_date), create_es, location_id, theme_id, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for displaying most recent polls by location
CREATE MATERIALIZED VIEW poll_chronology_by_location AS
SELECT create_date, location_id, create_es, poll_id
FROM polls
WHERE create_date IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((create_date, location_id), create_es, theme_id, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for displaying most recent polls by location AND theme
CREATE MATERIALIZED VIEW poll_chronology_by_location_and_theme AS
SELECT create_date, location_id, theme_id, create_es, poll_id
FROM polls
WHERE create_date IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((create_date, location_id, theme_id), create_es, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for displaying most recent polls by theme
CREATE MATERIALIZED VIEW poll_chronology_by_theme AS
SELECT create_date, theme_id, create_es, poll_id
FROM polls
WHERE create_date IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((create_date, theme_id), create_es, location_id, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for lookup of the opinion data
CREATE TABLE opinions
(
    opinion_id       bigint,
    poll_id          bigint,
    position         ascii, // 13.23.1...
    parent_position  ascii,
    child_position   int,
    create_date      ascii,
    user_id          bigint,
    create_es        bigint,
    update_es        bigint,
    version          int,
    data             blob,
    insert_processed boolean,
    PRIMARY KEY ((poll_id, create_date), create_es, opinion_id)
)
            WITH CLUSTERING ORDER BY (create_es DESC);

-- for lookup of all opinions created by user
CREATE MATERIALIZED VIEW opinion_ids_by_user AS
SELECT user_id, create_es, poll_id, opinion_id
FROM opinions
WHERE user_id IS NOT NULL
  AND poll_id IS NOT NULL
  AND create_date IS NOT NULL
  AND create_es IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((user_id), create_es, poll_id, create_date, opinion_id)
WITH CLUSTERING ORDER BY (create_es desc);

-- for lookup of all recent opinion ids when first displaying the thread
-- and for notifications of newly created records once the thread is loaded
-- (with using create_es >= $DATE)
CREATE MATERIALIZED VIEW opinion_ids AS
SELECT poll_id, position, create_es, opinion_id, version
FROM opinions
WHERE poll_id IS NOT NULL
  AND create_date IS NOT NULL
  AND create_es IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((poll_id, create_date), create_es, opinion_id)
        WITH CLUSTERING ORDER BY (create_es desc);

-- For lookup at creation time (to figure out the right position)
CREATE MATERIALIZED VIEW opinion_positions AS
SELECT poll_id, parent_position, create_es, opinion_id, child_position
FROM opinions
WHERE poll_id IS NOT NULL
  AND parent_position IS NOT NULL
  AND create_es IS NOT NULL
  AND create_date IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((poll_id, parent_position), create_es, create_date, opinion_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for ingest of updates into CRDB and Vespa
CREATE TABLE opinion_updates
(
    opinion_id       bigint,
    poll_id          bigint,
    update_date      ascii,
    user_id          bigint,
    update_es        bigint,
    data             blob,
    version          int,
    update_processed boolean,
    PRIMARY KEY ((poll_id, update_date), update_es, opinion_id)
)
            WITH CLUSTERING ORDER BY (update_es DESC);

-- For notifications in the UI as the user is looking at the thread
CREATE MATERIALIZED VIEW opinion_update_lookups AS
SELECT poll_id, update_date, update_es, opinion_id, version
FROM opinion_updates
WHERE poll_id IS NOT NULL
  AND update_date IS NOT NULL
  AND update_es IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((poll_id, update_date), update_es, opinion_id)
        WITH CLUSTERING ORDER BY (update_es DESC);

CREATE TABLE threads
(
    poll_id             bigint,
    user_id             bigint,
    create_es           bigint,
    data                blob,
    last_processed_date text,
    PRIMARY KEY (poll_id)
);

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
