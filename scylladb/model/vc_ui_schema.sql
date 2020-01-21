-- comment out "drop keyspace" when running for the first time
drop keyspace votecube;

create keyspace votecube WITH replication = {'class': 'SimpleStrategy', 'replication_factor' : 1};

use votecube;

-- for lookup of poll data
CREATE TABLE polls
(
    poll_id          bigint,
    theme_id         bigint,  // needed HERE because of materialized views
    location_id      int,     // needed HERE because of materialized views, and eventual sharding
    create_es        bigint,
    user_id          bigint,
    partition_period ascii,   // needed HERE because of materialized views
    data             blob,
    insert_processed tinyint, // a set of flags that are flipped progressively
    PRIMARY KEY ((poll_id), theme_id, location_id, partition_period, create_es)
);

-- for looking up all polls created by user (and daily batching)
CREATE MATERIALIZED VIEW poll_ids_by_user AS
SELECT partition_period, location_id, user_id, create_es, theme_id, poll_id
FROM polls
WHERE partition_period IS NOT NULL
  AND location_id IS NOT NULL
  AND create_es IS NOT NULL
  AND theme_id IS NOT NULL
  AND user_id IS NOT NULL
PRIMARY KEY ((partition_period, location_id), user_id, create_es, theme_id, poll_id)
        WITH CLUSTERING ORDER BY (user_id ASC, create_es DESC);

-- for displaying polls in a given partition by theme
CREATE MATERIALIZED VIEW period_poll_ids_by_theme_ob_creation AS
SELECT partition_period, location_id, theme_id, create_es, poll_id
FROM polls
WHERE partition_period IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, theme_id), location_id, create_es, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for displaying polls in a given partition by theme and location
CREATE MATERIALIZED VIEW period_poll_ids_by_theme_n_location_ob_creation AS
SELECT partition_period, location_id, theme_id, create_es, poll_id
FROM polls
WHERE partition_period IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, theme_id, location_id), create_es, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for displaying polls in a given partition by location
CREATE MATERIALIZED VIEW period_poll_ids_by_location_ob_creation AS
SELECT partition_period, location_id, create_es, poll_id
FROM polls
WHERE partition_period IS NOT NULL
  AND create_es IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, location_id), create_es, theme_id, poll_id)
        WITH CLUSTERING ORDER BY (create_es DESC);

-- for ingest by theme (secondary ingest)
CREATE MATERIALIZED VIEW period_poll_ids_ob_theme AS
SELECT partition_period, create_es, poll_id, insert_processed
FROM polls
WHERE partition_period IS NOT NULL
  AND create_es IS NOT NULL
  AND theme_id IS NOT NULL
  AND location_id IS NOT NULL
PRIMARY KEY ((partition_period), theme_id, location_id, create_es, poll_id)
        WITH CLUSTERING ORDER BY (theme_id ASC, create_es DESC);

-- for ingest by theme and location (secondary ingest)
CREATE MATERIALIZED VIEW period_poll_ids_ob_theme_n_location AS
SELECT partition_period, create_es, poll_id, insert_processed
FROM polls
WHERE partition_period IS NOT NULL
  AND create_es IS NOT NULL
  AND theme_id IS NOT NULL
  AND location_id IS NOT NULL
PRIMARY KEY ((partition_period), theme_id, location_id, create_es, poll_id)
        WITH CLUSTERING ORDER BY (theme_id ASC, location_id ASC, create_es DESC);

-- for ingest by location (secondary ingest)
CREATE MATERIALIZED VIEW period_poll_ids_ob_location AS
SELECT partition_period, create_es, poll_id, insert_processed
FROM polls
WHERE partition_period IS NOT NULL
  AND create_es IS NOT NULL
  AND theme_id IS NOT NULL
  AND location_id IS NOT NULL
PRIMARY KEY ((partition_period), location_id, theme_id, create_es, poll_id)
        WITH CLUSTERING ORDER BY (location_id ASC, create_es DESC);

-- populated on ingest, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE period_poll_id_blocks_by_theme
(
    partition_period ascii,
    theme_id         bigint,
    poll_ids         blob,
    PRIMARY KEY ((partition_period, theme_id))
);
-- populated on ingest, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE period_poll_counts_by_theme
(
    partition_period ascii,
    theme_id         bigint,
    count            blob,
    PRIMARY KEY ((partition_period), theme_id)
);

-- populated on ingest, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE period_poll_id_blocks_by_theme_n_location
(
    partition_period ascii,
    theme_id         bigint,
    location_id      int,
    poll_ids         blob,
    PRIMARY KEY ((partition_period, theme_id, location_id))
);

CREATE TABLE period_poll_counts_by_theme_n_location
(
    partition_period ascii,
    theme_id         bigint,
    location_id      int,
    counts           blob,
    PRIMARY KEY ((partition_period, theme_id), location_id)
);

-- populated on ingest, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE period_poll_id_blocks_by_location
(
    partition_period ascii,
    location_id      int,
    poll_ids         bigint,
    PRIMARY KEY ((partition_period, location_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_poll_id_blocks_by_user
(
    date     ascii,
    user_id  bigint,
    poll_ids blob,
    PRIMARY KEY ((date, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_poll_counts_by_user
(
    date    ascii,
    user_id bigint,
    count   int,
    PRIMARY KEY ((date, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_poll_id_blocks_by_user_n_theme
(
    date     ascii,
    user_id  bigint,
    theme_id bigint,
    poll_ids blob,
    PRIMARY KEY ((date, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_poll_counts_by_user_n_theme
(
    date     ascii,
    user_id  bigint,
    theme_id bigint,
    count    int,
    PRIMARY KEY ((date, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
CREATE TABLE day_poll_id_blocks_by_user_n_theme_n_location
(
    date        ascii,
    user_id     bigint,
    theme_id    bigint,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((date, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
CREATE TABLE day_poll_counts_by_user_n_theme_n_location
(
    date        ascii,
    user_id     bigint,
    theme_id    bigint,
    location_id int,
    count       int,
    PRIMARY KEY ((date, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
CREATE TABLE day_poll_id_blocks_by_user_n_location
(
    date        ascii,
    user_id     bigint,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((date, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
CREATE TABLE day_poll_counts_by_user_n_location
(
    date        ascii,
    user_id     bigint,
    location_id int,
    count       int,
    PRIMARY KEY ((date, user_id))
);

-- populated daily, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_poll_id_blocks_by_theme
(
    date     ascii,
    theme_id bigint,
    poll_ids blob,
    PRIMARY KEY ((date, theme_id))
);

-- populated daily, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_poll_counts_by_theme
(
    date     ascii,
    theme_id bigint,
    count    bigint,
    PRIMARY KEY ((date, theme_id))
);

-- populated daily, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE day_poll_id_blocks_by_theme_n_location
(
    date        ascii,
    theme_id    bigint,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((date, theme_id, location_id))
);

-- populated daily, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE day_poll_counts_by_theme_n_location
(
    date        ascii,
    theme_id    bigint,
    location_id int,
    count       bigint,
    PRIMARY KEY ((date, theme_id, location_id))
);

-- populated daily, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE day_poll_id_blocks_by_location
(
    date        ascii,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((date, location_id))
);

-- populated daily, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE day_poll_counts_by_location
(
    date        ascii,
    location_id int,
    count       bigint,
    PRIMARY KEY ((date, location_id))
);

-- populated monthly, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_poll_id_blocks_by_user
(
    month    ascii,
    user_id  bigint,
    poll_ids blob,
    PRIMARY KEY ((month, user_id))
);

-- populated monthly, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_poll_counts_by_user
(
    month   ascii,
    user_id bigint,
    count   int,
    PRIMARY KEY ((month, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_poll_id_blocks_by_user_n_theme
(
    month    ascii,
    user_id  bigint,
    theme_id bigint,
    poll_ids blob,
    PRIMARY KEY ((month, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_poll_counts_by_user_n_theme
(
    month    ascii,
    user_id  bigint,
    theme_id bigint,
    count    int,
    PRIMARY KEY ((month, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
CREATE TABLE month_poll_id_blocks_by_user_n_theme_n_location
(
    month       ascii,
    user_id     bigint,
    theme_id    bigint,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((month, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
CREATE TABLE month_poll_counts_by_user_n_theme_n_location
(
    month       ascii,
    user_id     bigint,
    theme_id    bigint,
    location_id int,
    count       int,
    PRIMARY KEY ((month, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
CREATE TABLE month_poll_id_blocks_by_user_n_location
(
    month       ascii,
    user_id     bigint,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((month, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
CREATE TABLE month_poll_counts_by_user_n_location
(
    month       ascii,
    user_id     bigint,
    location_id int,
    counts      blob,
    PRIMARY KEY ((month, user_id))
);

-- populated monthly, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_poll_id_blocks_by_theme
(
    date     ascii,
    theme_id bigint,
    poll_ids blob,
    PRIMARY KEY ((date, theme_id))
);

-- populated monthly, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_poll_counts_by_theme
(
    date     ascii,
    theme_id bigint,
    count    bigint,
    PRIMARY KEY ((date, theme_id))
);

-- populated monthly, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE month_poll_id_blocks_by_theme_n_location
(
    date        ascii,
    theme_id    bigint,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((date, theme_id, location_id))
);

-- populated monthly, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE month_poll_counts_by_theme_n_location
(
    date        ascii,
    theme_id    bigint,
    location_id int,
    count       bigint,
    PRIMARY KEY ((date, theme_id, location_id))
);

-- populated monthly, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE month_poll_id_blocks_by_location
(
    date        ascii,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((date, location_id))
);

-- populated monthly, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE month_poll_counts_by_location
(
    date        ascii,
    location_id int,
    count       bigint,
    PRIMARY KEY ((date, location_id))
);

-- populated yearly, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE year_poll_id_blocks_by_user
(
    year     ascii,
    user_id  bigint,
    poll_ids blob,
    PRIMARY KEY ((year, user_id))
);

CREATE TABLE year_poll_counts_by_user
(
    year    ascii,
    user_id bigint,
    count   bigint,
    PRIMARY KEY ((year, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE year_poll_id_blocks_by_user_n_theme
(
    year     ascii,
    user_id  bigint,
    theme_id bigint,
    poll_ids blob,
    PRIMARY KEY ((year, user_id))
);
CREATE TABLE year_poll_counts_by_user_n_theme
(
    year     ascii,
    user_id  bigint,
    theme_id bigint,
    count    bigint,
    PRIMARY KEY ((year, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
CREATE TABLE year_poll_id_blocks_by_user_n_theme_n_location
(
    year        ascii,
    user_id     bigint,
    theme_id    bigint,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((year, user_id))
);
CREATE TABLE year_poll_counts_by_user_n_theme_n_location
(
    year        ascii,
    user_id     bigint,
    theme_id    bigint,
    location_id int,
    count       bigint,
    PRIMARY KEY ((year, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
CREATE TABLE year_poll_id_blocks_by_user_n_location
(
    year        ascii,
    user_id     bigint,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((year, user_id))
);
CREATE TABLE year_poll_counts_by_user_n_location
(
    year        ascii,
    user_id     bigint,
    location_id int,
    counts      bigint,
    PRIMARY KEY ((year, user_id))
);

-- populated yearly, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE year_poll_id_blocks_by_theme
(
    year     ascii,
    theme_id bigint,
    poll_ids blob,
    PRIMARY KEY ((year, theme_id))
);
CREATE TABLE year_poll_counts_by_theme
(
    year     ascii,
    theme_id bigint,
    counts   bigint,
    PRIMARY KEY ((year, theme_id))
);

-- populated yearly, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE year_poll_id_blocks_by_theme_n_location
(
    year        ascii,
    theme_id    bigint,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((year, theme_id, location_id))
);
CREATE TABLE year_poll_counts_by_theme_n_location
(
    year        ascii,
    theme_id    bigint,
    location_id int,
    count       bigint,
    PRIMARY KEY ((year, theme_id, location_id))
);

-- populated yearly, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE year_poll_id_blocks_by_location
(
    year        ascii,
    location_id int,
    poll_ids    blob,
    PRIMARY KEY ((year, location_id))
);
CREATE TABLE year_poll_counts_by_location
(
    year        ascii,
    location_id int,
    count       bigint,
    PRIMARY KEY ((year, location_id))
);

-- for lookup of the opinion data
CREATE TABLE opinions
(
    poll_id           bigint,
    partition_period  ascii,
    opinion_id        bigint,
    version           int,
    root_opinion_id   bigint,
    parent_opinion_id bigint,
    create_es         bigint,
    user_id           bigint,
    data              blob,
    insert_processed  boolean,
    PRIMARY KEY ((poll_id, partition_period), opinion_id)
);

-- for lookup of all recent opinion ids when first displaying the thread
-- (with using partition_period = PARTITION_PERIOD)
-- its more compact than opinions and hence iterating and returning
-- a block of ids (opinion_id + version) should be faster
-- (less disk io)
CREATE MATERIALIZED VIEW opinion_ids AS
SELECT poll_id, partition_period, opinion_id, version, root_opinion_id, parent_opinion_id, create_es
FROM opinions
WHERE poll_id IS NOT NULL
  AND partition_period IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((poll_id, partition_period), opinion_id);

-- Used during ingest processing (eventually by a sequence-reader process,
-- that ingest processes will be querying for batches of ids)
CREATE MATERIALIZED VIEW period_opinion_ids AS
SELECT partition_period, poll_id, opinion_id, insert_processed
FROM opinions
WHERE poll_id IS NOT NULL
  AND partition_period IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((partition_period), poll_id, opinion_id)
    -- Order is needed to quickly serve poll based opinion id blocks
    -- at ingest time
        WITH CLUSTERING ORDER BY (poll_id DESC);

CREATE TABLE root_opinions
(
    poll_id    bigint,
    opinion_id bigint,
    version    int,
    create_es  bigint,
    data       blob,
    /*
     Shouldn't need this column.  In case of batch failures there may be an point when
     a later batch succeeded but an earlier has not so, in such a case this wouldn't be of
     any use.
     */
    -- last_processed_period text,
    PRIMARY KEY ((poll_id), opinion_id)
);

-- for lookup of historical thread record when first displaying it
-- its more compact than root_pinions and hence iterating and returning
-- a block of ids & position (root_opinion_id + version & create_es) should be faster
-- (less disk io)
-- create_es is needed to figure out when do request which opinion data over the network
CREATE MATERIALIZED VIEW root_opinion_ids AS
SELECT poll_id, opinion_id, version, create_es
FROM root_opinions
WHERE poll_id IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((poll_id), opinion_id);

-- for ingest of updates into CRDB and Vespa
CREATE TABLE opinion_updates
(
    poll_id           bigint,
    partition_period  ascii,
    opinion_id        bigint,
    version           int,
    root_opinion_id   bigint,
    parent_opinion_id bigint,
    data              blob,
    update_processed  boolean,
    PRIMARY KEY ((poll_id, partition_period), opinion_id)
);

-- For notifications in the UI as the user is looking at the thread
-- its more compact than opinion_updates and hence iterating and
-- returning a block of ids (opinion_id + create_es + version)
-- should be faster (less disk io)
CREATE MATERIALIZED VIEW opinion_update_ids AS
SELECT poll_id, partition_period, opinion_id, version
FROM opinion_updates
WHERE poll_id IS NOT NULL
  AND partition_period IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((poll_id, partition_period), opinion_id);

-- Used during ingest processing (eventually by a sequence-reader process,
-- that ingest processes will be querying for batches of ids)
CREATE MATERIALIZED VIEW period_opinion_update_ids AS
SELECT partition_period, poll_id, opinion_id, update_processed
FROM opinion_updates
WHERE partition_period IS NOT NULL
  AND poll_id IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((partition_period), poll_id, opinion_id)
    -- Order is needed to quickly serve poll based opinion id blocks
    -- at ingest time
        WITH CLUSTERING ORDER BY (poll_id DESC);

-- for lookup of all root opinion ids in which the user participated
CREATE TABLE root_opinion_ids_with_user
(
    user_id          bigint,
    partition_period ascii,
    create_es        bigint,
    opinion_id       bigint,
    version          int,
    poll_id          bigint,
    PRIMARY KEY ((user_id), partition_period, create_es, opinion_id)
)
            WITH CLUSTERING ORDER BY (partition_period DESC, create_es DESC);

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
