-- comment out "drop keyspace" when running for the first time
drop keyspace votecube;

create keyspace votecube
            WITH replication = {'class': 'SimpleStrategy', 'replication_factor' : 1};

use votecube;


----------
-- META --
----------
/**
  Below schema supports standard loading of data when the page is requested by
  the user.  It will facilitate delaying of loading for polls, opinions and
  rankings until the relevant display is scrolled into the view (by the user).
  It does not attempt to do any real-time updating of the view, such as keeping
  track of users typing responses, when new rankings are added to an opinion
  or ranking and when new opinions are posted to a poll thread.  That functionality
  can be added on via in-memory only infrastructure (since there is no additional
  data that needs to be persisted, just a stream of events).

  The in-memory infrastructure could scale in a following way:

  3 total tiers - Front load balancing, Connection management servers and Thread
  management servers

  1) Front Load balancing servers simply forward TCP packets between the Client
  and the Connection management servers.  They can either:
  a) keep sticky sessions and act as a complete pass-though for a TCP connection.
  This will probably be the default and easiest to implement but requires session
  management on both the Load balancers and Connection management servers.
  b) or, assuming that CloudFlare will handle sticky sessions, TCP sessions could
  terminate on the Load balancers.  They would then make completely stateless
  requests to Connection managers
  c) or, we could hack the TCP protocol stack and make Load balancers fake out TCP
  sessions while keeping the requests to Connection managers sessionless

  2) Connection managers keep an array (indexed by poll id) of Thread management server
  indexes (or even final addresses).  So, they act as lookup gateways between the
  client and the Thread managers that keep track of what happens on a given Thread.
  They would also batch up requests on per Thread management server and periodically
  send these to those servers (while keeping a connection open and sending ping requests
  of no data actually requested).  This could be done on a reasonable time cadence (maybe
  every 3 seconds).

  So, to begin with, we can support 1B threads with 256 Thread management servers we would
  only need 1GB of RAM for the lookup.  This scales pretty well to the limits of modern
  hardware (with 2TB RAM being able to support 1T threads with 64K Thread management
  servers).  And the number of Connection managers can be increased or decreased at any
  time.  They are only "mildly stateful", when a new one comes up it simply needs to
  populate its cache of Thread to Thread Manager array and the addresses of Thread managers.
  The cache population requests can be distributed between all of the rest of the Connection
  managers (with each returning a chunk of the cache) and Thread manager addresses should
  be compact enough.

  Though, overall it is better to use 2 layers of Connection managers.  First layer can mod
  the thread number and lookup a Layer 2 Service address to forward a given request to.
  The layer 2 service would then have a much smaller map of threads (just for the right
  block).  It also allows to favor new Threads and run with more instances of layer 2
  servers for them (then some very old and very stable threads).  Hence the amount of
  RAM needed to serve the total number of requests can be reduced drastically.  And
  scaling will also become faster (standing up new Layer 2 service is quicker and
  cheaper) and is no longer limited at about 1T threads (becoming virtually unlimited).

  3) Thread managers are also "mildly stateful", they only need to keep track of what happened
  in the last 3 seconds for a given thread.  Eventually they might become more stateful
  and keep track all modifications for a given thread for a longer period of time and
  then attempt state repair (return more data to clients) if they find inconsistencies
  in what they have sent and what is the actual state of the database.  This will require
  quite a bit more thought though (to make sure that we don't negatively impact database
  performance by doing this periodic state repair).

  Thread managers can also scale (you can run multiple instances for the state of the
  same thread) but that becomes a bit more tricky, since when you stand up a new Thread
  manager you need to notify it of which Threads it needs to now keep track of.  And the
  Layer 2 Connection managers will also have to be notified of a new Thread manager (for
  a given thread).

  Ultimately it should be possible to support in-memory infrastructure, even for the
  most hot threads (say if 100M people are watching a thread because of a time sensitive
  event).  As a design goal, the amount of required hardware should be determined the
  total number of devices watching, not the number of devices watching a given thread.

  NOTE: In UI websockets are the best option for such communication, since the user
  is actively watching a thead and not only expects notifications back but also might
  be typing an opinion (and we'll be notifying other users watching the same thread) that
  this is happening) or has just submitted a ranking.
 */

/**
  A separate use case is notifying users on events (new threads, new opinions, new ratings,
  for a given theme, location, thread) while they are not actively watching it.  This
  is more of a batch job-like task, since the user might want these notifications even if
  they have their device locked and aren't even looking at the browser.  Though the same
  infrastructure as above might be used (if Thread managers become more stateful) with fewer
  notifications (for example, users won't be notified if someone is in process of writing
  a response, or might opt out of being notified if a ranking is posted and only care for
  new opinions/threads).  In that case such notifications might be requested by the client
  with less frequency (say one per minute).

  NOTE: In UI server-side push (service worker friendly) is the way to go for this.  The
  Load balancers or Layer 1 of Connection managers, would then be smart enough to maintain
  a different channel for that.
 */

/**
  Voting should probably be funnelled though this infrastructure as well.  It will have to
  be properly persisted but that can be done in batches (and might have to be given higher
  potential for usage spikes towards the end of the voting period) by the Thread servers.
  If a given batch is successfully persisted then the client is notified. If it isn't then the
  client knows that it must re-try to submit the vote (automatically).

  Thread servers would record new votes in batch records, query those records (for recent
  partition periods), and return newly computed totals to the clients.

  Top votes infrastructure might have to be adjusted as well, since we now will have the means
  to know which votes have been recently added.  It should be possible to setup up a set of
  intermediate servers that spit up all actively running threads and store their votes counts in
  order. Then a separate layer can combine this data and come up with final sorted lists (taking
  into account totals from other, recently closed votes).  Then a separate layer can record
  vote totals (in order and individually) on periodic basis.  Ex: (Polls with most votes in a
  given theme at a given location in a given month).
 */

/**
  ScyllaDB supports GEO partitioning for all of the data (meaning all of the data
  may be stored id different data centers) but does not provide a way to split up
  data by a geo-paritioning key (though maybe things will change in the future).
  If we are ever forced to store EU data in EU and Chinese data in China then
  we'll have to do such partitioning in software.  With such a setup all queries
  for certain locations will go specific regions.  Since Scylla does not support
  SQL style queries this isn't that big of a deal (and pretty simple to implement
  when we need it).

  For relational data we'll be using CockroachDB, which does support Geographical
  partitioning based on a key (location_id in our case).
 */


-----------
-- POLLS --
-----------

/**
  VC ScyllaDB model uses a partitioning period.  This is a period with a certain number
  of minutes in it, say 5 or 15.  Once the partition period is filled the data from it
  is ingested into CockroachDB and Vespa and internal id grouping and counts tables
  are populated as well.

  We don't want the partition period to be too big since that would greatly increase
  the lag between when the data is entered into the system and when it is processed
  for analysis (and added to full text search).  At the same time we don't want it to
  be too short either, since that would lead to smaller id batches (and counts batches)
  and increase the total number of requests made to the server.  Also we want to give
  ScyllaDB enough time to get the level of consistency to 100% for ingested partition
  so that we don't have to re-ingest the records later (and redo id blocks and counts
  for the missing records).  So 15 minute batches appear to be best at this point
  (with maybe a 5 minute lag between end of the period and start of ingest, to give
  ScyllaDB room to ensure consistency, if there are any sudden,short-term usage
  spikes).
  For development purposes these batches can be configured to be smaller (say 5
  minutes).

  The partition period has the following format:

  2020-01-02T03:04  and always represents UTC time.

  In ASCII this takes 16 bytes (for every high traffic record), so it makes sense
  to encode it further to a 32 bit (4 byte) integer with:

  12 bits for the year, 4 bits for month, 5 bits for day, 5 bits for hour, 6 bits for
  minute.  This limits the year storage 4 millennia (and we can start counting with
  2020).  If the system lasts that long it is bound to be refactored by then (note
  that support for the sign bit isn't planned at this point so really its 2
  + 2 millennia).

  Note that there should never be manual manipulation of these anyway and when
  necessary it is easy to write converters.
 */


-- for lookup of poll data
CREATE TABLE polls
(
    poll_id          bigint,
    theme_id         bigint,  // needed HERE because of materialized views
    location_id      int,     // needed HERE because of materialized views, and eventual sharding
    ingest_batch_id  int,
    create_es        bigint,
    user_id          bigint,
    partition_period int,     // needed HERE because of materialized views
    /**
      Age suitability reserves 4 bits for general ratings. All other bits are reserved for
      "culture specific" 2 bit blocks.  For example faithful parents (with cultural variations in
      what is allowed) may not want their children to see certain content until a later age. 2
      Bits allow up to 3 age group delay, so for example a Muslim child may be protected from
      certain content up to 7, 13 or 17 years, even if that content is generally accepted to be
      0+ rating.  This allows for up to 30 general cultures to be supported - should be enough
      planetarily.

      NOTE: age shift does not have any effect on adults.  The idea is to better protect
      children, and not to prevent information from reaching responsible adults. Though it would
      be possible for countries like China to always set the "Chinese" flag up to level 3 (but
      probably not force the age of all their citizens to be < 17 :).  Seems reasonable enough -
      if a country doesn't want it's children to see some content until they are a bit older -
      that's probably something that needs to be sorted out by that country.

      Counts of polls/opinions are computed on the general numbers.  So 0+ counts won't currently
      be re-computed on per-culture basis.  Cultures aren't currently scheduled for
      implementation.
     */
    age_suitability  bigint,
    data             blob,
    insert_processed boolean, // Has the initial ingest into CockroachDb finished
    PRIMARY KEY ((poll_id), theme_id, location_id, partition_period)
);

/**
    Used by Primary Poll Ingest to CockroachDB and Vespa.

  1) The poll ids are retrieved here, on per batch basis.
  2) The poll records are individually retrieved from the polls table
  3) All polls from a particular batch are inserted in one transaction.
  In the same transaction a record is inserted into batch_executions.
  4) After that records in the batch are inserted into Vespa and
  batch_executions is updated.

  TODO: After all batches have been processed a check is run to make sure
  that no batches failed.  If any failed they are re-tried until
  completion.

  Batch executions also keep track of locations and themes that where
  inserted for this partition period.  After Primary Poll Ingest is
  done. batch_themes_n_locations table is populated.  Same is done for
  user ids (populating batch_user_ids). Both are then used to distribute
  work for the internal maintenance ingests (adding to id
  grouping/counts tables in Scylla) is done in a separate processes.

  TODO: A good chunk of time after a given batch (say a couple of hours,
  to make sure that the data has been FOR SURE propagated to all view
  copies on all nodes) run another check that spins though all of the
  batches for that period and makes sure that none of the records were
  left behind. If they were ingest them and update all relevant id
  blocks and counts.

  Q: Should the data be replicated here?
  A: No need since it would be along term store and is only needed
  once.  Reading the source record once is OK - ingest doesn't have
  to be super fast since it can be distributed (using ingest_batch_id).
  Q: Why not split data by location/theme or both?
  A: The best of my current understanding that requires a separate table
  would have to keep track of which locations & themes were inserted
  into in a give partition_period.  Maintaining that is extra work
  that either has to be done on every insert (very expensive) or
  done as a pre-requisite step of the ingest (thus slowing it down).
  Also ingest_batch_id gives a more even distribution of work and can
  help maintain certain batch sizes (which can now be reasonably well
  controlled, with some monitoring).  Write servers can then be
  notified with the max batch size for the following ingest cycle.
 */
CREATE MATERIALIZED VIEW period_poll_ids_by_batch AS
SELECT partition_period,
       ingest_batch_id,
       create_es,
--        theme_id,
--        location_id,
       poll_id,
       insert_processed
FROM polls
WHERE partition_period IS NOT NULL
  AND ingest_batch_id IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, ingest_batch_id), poll_id, theme_id, location_id);


/**
  For looking up all poll ids created by user in either current or any
  of the previous partition periods for which batched id records aren't yet
  available.

  Note that it is needed even with very small partition_periods because
  it itself is used create per user, per partition period id batches and
  counts.

  Note that create_es is missing from the key since it's not needed in the UI,
  which can post sort the opinions in the right order AND is not needed by
  the ingest because it can correctly order the records itself.  The end effect
  is a bit of CPU, Memory Storage savings by the database, which probably adds
  up overtime to more benefit than the cost of sorting by the batch and UI.

  TODO: make sure that UI sorts period records and batch sorts all of the
  records by create_es
 */
CREATE MATERIALIZED VIEW period_poll_ids_by_user AS
SELECT partition_period,
       user_id,
       age_suitability,
       poll_id,
--        location_id,
--        theme_id,
       create_es
FROM polls
WHERE partition_period IS NOT NULL
  AND user_id IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, user_id), poll_id, theme_id, location_id);

/**
  For displaying polls in a given (recent) partition by theme.
  Also used for ingesting by theme id blocks and counts into appropriate
  tables in ScyllaDB
 */
CREATE MATERIALIZED VIEW period_poll_ids_by_theme AS
SELECT partition_period,
       age_suitability,
       poll_id,
--        theme_id,
--        location_id,
       create_es
FROM polls
WHERE partition_period IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, theme_id), poll_id, location_id);
// NOTE: not ordering by location_id or create_es, done in memory by batch job & UI

/**
  For displaying polls in a given (recent) partition by theme 1st and location 2nd.
  Also used for ingesting by theme id blocks and counts into appropriate
  tables in ScyllaDB
 */
/*
Appears to be somewhat redundant, same thing can be served by theme view, removing for now

CREATE MATERIALIZED VIEW period_poll_ids_by_theme_n_location AS
SELECT partition_period,
      age_suitability,
--        theme_id,
--        location_id,
      poll_id,
      create_es
FROM polls
WHERE partition_period IS NOT NULL
 AND theme_id IS NOT NULL
 AND location_id IS NOT NULL
PRIMARY KEY ((partition_period, theme_id, location_id), poll_id);
*/
/**
  For displaying polls in a given (recent) partition by location.
  Also used for ingesting by theme id blocks and counts into appropriate
  tables in ScyllaDB.
  To save maintenance of another view (by location 1st and theme 2nd) this same
  view is used for ingesting location+theme id blocks and counts.
 */
CREATE MATERIALIZED VIEW period_poll_ids_by_location AS
SELECT partition_period,
       age_suitability,
--        location_id,
       poll_id,
--        theme_id,
       create_es
FROM polls
WHERE partition_period IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, location_id), poll_id, theme_id);
// NOTE: not ordering by theme_id or create_es, done in memory by batch job & UI


--------------------
-- POLL ID BLOCKS --
--------------------

/**
  Access is provided for the user to lookup their own recent polls.
  We also keep them historically so the user can go back and see
  what were they writing at some period of time in the past.

  Also access to latest polls is provided by Theme, Theme+Location,
  Location & Location+Theme.  And a historical record of these is
  kept as well (which is easy to do, just takes a bit more space).
  Hence a user can drill down into any Year, Month, Day or period
  and find out the counts for at at any Location, for any Theme
  or a combination of the two.
 */

-- per period blocks

-- NOTE: in blocks and counts only core age_sutability value is stored
-- In future any culturally blocked polls will be filtered in the UI
-- thus not preventing data retrieval by id only

-- populated every partition period, for lookup of poll data by user
-- also stores corresponding location and theme ids
-- contains  ids for actual (not aggregate) themes and locations
CREATE TABLE period_poll_id_blocks_by_user
(
    partition_period int,
    age_suitability  tinyint,
    user_id          bigint,
    theme_ids        blob,
    location_ids     blob,
    poll_ids         blob,
    PRIMARY KEY ((partition_period, age_suitability, user_id))
);

-- populated every partition period, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE period_poll_id_blocks_by_theme
(
    partition_period int,
    age_suitability  tinyint,
    theme_id         bigint,
    poll_ids         blob,
    PRIMARY KEY ((partition_period, age_suitability, theme_id))
);

-- populated every partition period, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE period_poll_id_blocks_by_theme_n_location
(
    partition_period int,
    age_suitability  tinyint,
    theme_id         bigint,
    location_id      int,
    poll_ids         blob,
    PRIMARY KEY ((partition_period, age_suitability, theme_id, location_id))
);

-- populated every partition period, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE period_poll_id_blocks_by_location
(
    partition_period int,
    age_suitability  tinyint,
    location_id      int,
    poll_ids         bigint,
    PRIMARY KEY ((partition_period, age_suitability, location_id))
);

-- populated every partition period, for lookup of poll data by location + theme
-- contains poll ids for actual and aggregate locations and themes
CREATE TABLE period_poll_id_blocks_by_location_n_theme
(
    partition_period int,
    age_suitability  tinyint,
    location_id      int,
    theme_id         bigint,
    poll_ids         bigint,
    PRIMARY KEY ((partition_period, age_suitability, location_id, theme_id))
);

-- per day blocks

-- populated daily, for lookup of poll data by user
CREATE TABLE day_poll_id_blocks_by_user
(
    date            int,
    age_suitability tinyint,
    user_id         bigint,
    theme_ids       blob,
    location_ids    blob,
    poll_ids        blob,
    PRIMARY KEY ((date, age_suitability, user_id))
);

-- populated daily, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_poll_id_blocks_by_theme
(
    date            int,
    age_suitability tinyint,
    theme_id        bigint,
    poll_ids        blob,
    PRIMARY KEY ((date, age_suitability, theme_id))
);

-- populated daily, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE day_poll_id_blocks_by_theme_n_location
(
    date            int,
    age_suitability tinyint,
    theme_id        bigint,
    location_id     int,
    poll_ids        blob,
    PRIMARY KEY ((date, age_suitability, theme_id, location_id))
);

-- populated daily, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE day_poll_id_blocks_by_location
(
    date            int,
    age_suitability tinyint,
    location_id     int,
    poll_ids        blob,
    PRIMARY KEY ((date, age_suitability, location_id))
);

-- populated daily, for lookup of poll data by location + theme
-- contains poll ids for actual and aggregate locations and themes
CREATE TABLE day_poll_id_blocks_by_location_n_theme
(
    date            int,
    age_suitability tinyint,
    location_id     int,
    theme_id        bigint,
    poll_ids        blob,
    PRIMARY KEY ((date, age_suitability, location_id, theme_id))
);

-- per month blocks

-- populated monthly, for lookup of poll data by user
CREATE TABLE month_poll_id_blocks_by_user
(
    month           smallint,
    age_suitability tinyint,
    user_id         bigint,
    theme_ids       blob,
    location_ids    blob,
    poll_ids        blob,
    PRIMARY KEY ((month, age_suitability, user_id))
);

-- populated monthly, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_poll_id_blocks_by_theme
(
    month           smallint,
    age_suitability tinyint,
    theme_id        bigint,
    poll_ids        blob,
    PRIMARY KEY ((month, age_suitability, theme_id))
);

-- populated monthly, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE month_poll_id_blocks_by_theme_n_location
(
    month           smallint,
    age_suitability tinyint,
    theme_id        bigint,
    location_id     int,
    poll_ids        blob,
    PRIMARY KEY ((month, age_suitability, theme_id, location_id))
);

-- populated monthly, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE month_poll_id_blocks_by_location
(
    month           smallint,
    age_suitability tinyint,
    location_id     int,
    poll_ids        blob,
    PRIMARY KEY ((month, age_suitability, location_id))
);

-- populated monthly, for lookup of poll data by location + theme
-- contains poll ids for actual and aggregate locations and themes
CREATE TABLE month_poll_id_blocks_by_location_n_theme
(
    month           smallint,
    age_suitability tinyint,
    location_id     int,
    theme_id        bigint,
    poll_ids        blob,
    PRIMARY KEY ((month, age_suitability, location_id, theme_id))
);

-- per year blocks

-- populated yearly, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE year_poll_id_blocks_by_user
(
    year            smallint,
    age_suitability tinyint,
    user_id         bigint,
    theme_ids       blob,
    location_ids    blob,
    poll_ids        blob,
    PRIMARY KEY ((year, age_suitability, user_id))
);

-- populated yearly, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE year_poll_id_blocks_by_theme
(
    year            smallint,
    age_suitability tinyint,
    theme_id        bigint,
    poll_ids        blob,
    PRIMARY KEY ((year, age_suitability, theme_id))
);

-- populated yearly, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE year_poll_id_blocks_by_theme_n_location
(
    year            smallint,
    age_suitability tinyint,
    theme_id        bigint,
    location_id     int,
    poll_ids        blob,
    PRIMARY KEY ((year, age_suitability, theme_id, location_id))
);

-- populated yearly, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE year_poll_id_blocks_by_location
(
    year            smallint,
    age_suitability tinyint,
    location_id     int,
    poll_ids        blob,
    PRIMARY KEY ((year, age_suitability, location_id))
);

-- populated yearly, for lookup of poll data by location + theme
-- contains poll ids for actual and aggregate locations and themes
CREATE TABLE year_poll_id_blocks_by_location_n_theme
(
    year            smallint,
    age_suitability tinyint,
    location_id     int,
    theme_id        bigint,
    poll_ids        blob,
    PRIMARY KEY ((year, age_suitability, location_id, theme_id))
);



------------------
-- POLL RATINGS --
------------------
CREATE TABLE poll_ratings
(
    rating_type      int,
    poll_id          bigint,
    partition_period int,
    ingest_batch_id  int,
    user_id          bigint,
    rating           bigint,
    PRIMARY KEY ((poll_id, partition_period), rating_type, user_id)
);

CREATE TABLE user_poll_ratings
(
    rating_type int,
    poll_id     bigint,
    user_id     bigint,
    rating      bigint,
    PRIMARY KEY ((poll_id, user_id), rating_type)
);

CREATE TABLE period_poll_rating_averages
(
    rating_type      int,
    poll_id          bigint,
    partition_period bigint,
    count            bigint,
    average          float,
    rating           bigint,
    PRIMARY KEY ((poll_id, partition_period), rating_type)
);



--------------
-- OPINIONS --
--------------

-- for lookup of the opinion data
CREATE TABLE opinions
(
    poll_id           bigint,
    partition_period  int,
    age_suitability   bigint,  // The effective age suitability
    opinion_id        bigint,
    theme_id          bigint,  // Needed to compute counts by theme and theme+location
    location_id       int,     // Needed to compute counts by location and location + theme
    ingest_batch_id   int,
    version           int,
    root_opinion_id   bigint,
    parent_opinion_id bigint,
    create_es         bigint,
    user_id           bigint,
    data              blob,
    insert_processed  boolean, // Has the initial ingest into CockroachDb finished
    PRIMARY KEY ((poll_id, partition_period), opinion_id, theme_id, location_id)
);


-- for lookup of all recent opinion ids when first displaying the thread
-- (with using partition_period = PARTITION_PERIOD)
-- its more compact than opinions and hence iterating and returning
-- a block of ids (opinion_id + version) should be faster
-- (less disk io)
CREATE MATERIALIZED VIEW period_opinion_ids AS
SELECT poll_id,
       partition_period,
       age_suitability,
       opinion_id,
--        theme_id,
--        location_id,
       version,
       root_opinion_id,  // Needed to determine if and when to load the opinion data record
       parent_opinion_id // Needed to determine if and when to load the opinion data record
--        create_es
FROM opinions
WHERE poll_id IS NOT NULL
  AND partition_period IS NOT NULL
  AND opinion_id IS NOT NULL
  AND theme_id IS NOT NULL
  AND location_id IS NOT NULL
PRIMARY KEY ((poll_id, partition_period), opinion_id, theme_id, location_id);

/**
  Works the same way as period_poll_ids_by_batch
 */
CREATE MATERIALIZED VIEW period_opinion_ids_by_batch AS
SELECT partition_period,
       ingest_batch_id,
--        theme_id,
--        location_id,
       opinion_id,
       insert_processed
FROM opinions
WHERE partition_period IS NOT NULL
  AND ingest_batch_id IS NOT NULL
  AND opinion_id IS NOT NULL
  AND theme_id IS NOT NULL
  AND location_id IS NOT NULL
  AND poll_id IS NOT NULL
PRIMARY KEY ((partition_period, ingest_batch_id), opinion_id, theme_id, location_id, poll_id);

/**
  Works the same way as period_poll_ids_by_user

  Note that create_es is missing from the key since it's not needed in the UI,
  which can post sort the opinions in the right order AND is not needed by
  the ingest because it can correctly order the records itself.  The end effect
  is a bit of CPU, Memory Storage savings by the database, which probably adds
  up overtime to more benefit than the cost of sorting by the batch and UI.

  TODO: make sure that UI sorts period records and batch sorts all of the
  records by create_es
 */
CREATE MATERIALIZED VIEW period_opinion_ids_by_user AS
SELECT partition_period,
       user_id,
       age_suitability,
       opinion_id,
       root_opinion_id,
       poll_id,
--        location_id,opo
--        theme_id,
       create_es // Needed for sorting by UI & batch job
FROM opinions
WHERE partition_period IS NOT NULL
  AND user_id IS NOT NULL
  AND opinion_id IS NOT NULL
  AND poll_id IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, user_id), opinion_id, poll_id, theme_id, location_id);

/**
  Works the same way as period_poll_ids_by_theme.  Most recent opinions are not
  shown but these views are needed, to support opinion counts by theme/theme+location
  /location/location+theme.  In case of opinions the ingest process computes only
  the counts (for a given partition_period) and not id blocks.

  Currently by_theme does double duty of also counting by theme + location.
  The argument is that it is fewer records it is easier for ScyllaDB to
  */
CREATE MATERIALIZED VIEW period_opinion_ids_by_theme AS
SELECT partition_period,
       age_suitability,
       opinion_id,
       poll_id
--        theme_id,
--        location_id,
FROM opinions
WHERE partition_period IS NOT NULL
  AND theme_id IS NOT NULL
  AND opinion_id IS NOT NULL
  AND poll_id IS NOT NULL
  AND location_id IS NOT NULL
PRIMARY KEY ((partition_period, theme_id), opinion_id, poll_id, location_id);
// NOTE: not ordering by location_id, done in memory by batch job & UI

/**
  Works the same way as period_poll_ids_by_location
  Currently by_location does double duty of also counting by location + theme
 */
CREATE MATERIALIZED VIEW period_opinion_ids_by_location AS
SELECT partition_period,
       age_suitability,
--        location_id,
       opinion_id,
       poll_id
--        theme_id,
FROM opinions
WHERE partition_period IS NOT NULL
  AND location_id IS NOT NULL
  AND opinion_id IS NOT NULL
  AND poll_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, location_id), opinion_id, poll_id, theme_id);
// NOTE: not ordering by theme_id, done in memory by batch job & UI


-----------------------
-- OPINION ID BLOCKS --
-----------------------
/**
  Access is provided for the user to lookup their own recent opinions.
  We also keep them historically so the user can go back and see
  what were they writing at some period of time in the past.
 */

/**
  Works the same way as period_poll_id_blocks_by_user
 */
CREATE TABLE period_opinion_id_blocks_by_user
(
    partition_period int,
    age_suitability  tinyint,
    user_id          bigint,
    theme_ids        blob,
    location_ids     blob,
    opinion_ids      blob,
    root_opinion_ids blob,
    PRIMARY KEY ((partition_period, age_suitability, user_id))
);

/**
  Works the same way as day_poll_id_blocks_by_user
 */
CREATE TABLE day_opinion_id_blocks_by_user
(
    date             int,
    age_suitability  tinyint,
    user_id          bigint,
    theme_ids        blob,
    location_ids     blob,
    opinion_ids      blob,
    root_opinion_ids blob,
    PRIMARY KEY ((date, age_suitability, user_id))
);

/**
  Works the same way as month_poll_id_blocks_by_user
 */
CREATE TABLE month_opinion_id_blocks_by_user
(
    month            smallint,
    age_suitability  tinyint,
    user_id          bigint,
    theme_ids        blob,
    location_ids     blob,
    opinion_ids      blob,
    root_opinion_ids blob,
    PRIMARY KEY ((month, age_suitability, user_id))
);

/**
  ?Year blocks should not be needed?
  Works the same way as year_poll_id_blocks_by_user
CREATE TABLE year_opinion_id_blocks_by_user
(
    year             smallint,
    age_suitability  tinyint,
    user_id          bigint,
    theme_ids        blob,
    location_ids     blob,
    opinion_ids      blob,
    root_opinion_ids blob,
    PRIMARY KEY ((year, age_suitability, user_id))
);
 */


---------------------
-- OPINION UPDATES --
---------------------

-- for ingest of updates into CRDB and Vespa
/**
  Records updates to opinions (in a given partition_period).  If an opinion is
  updated multiple times in that partition_period only one record is retained.

  If an opinion is created in the same partition_period then no
  record is created here.

  Data is not stored in the update record, since it's found in the opinion
  record itself and there does not appear to be any value in keeping older
  versions of opinions.  The batch process(es) reads the opinion record (which
  itself is updated).

  Opinion updates ingest can run at the same time as either poll or opinion
  insert process.  This is because the opinion (and poll) are already
  guaranteed to exist.
 */
CREATE TABLE opinion_updates
(
    poll_id          bigint,
    partition_period int,
    ingest_batch_id  int,
    opinion_id       bigint,
    // Version is needed for the UI query (to know which version of
    // opinion to request).
    version          int,
    /**
      Root and parent opinion ids do not appear to be needed here.  The
      opinion record itself is read during ingest and it contains the
      necessary information.

      It is also not needed at UI query time, since the update isn't
      going to be retrieved unless the opinion itself is rendered.
     */
    // root_opinion_id   bigint,
    /**
      Same with parent ids it does not appear to be needed (for the same
      reason as stated above).
     */
    // parent_opinion_id bigint,
    update_processed boolean,
    PRIMARY KEY ((partition_period, ingest_batch_id), opinion_id)
);

-- For initial thread load to get the updates that happened in the
-- current (or possibly recent) partition period.
-- its more compact than opinion_updates and hence iterating and
-- returning a block of ids (opinion_id + create_es + version)
-- should be faster (less disk io)
CREATE MATERIALIZED VIEW opinion_update_ids AS
SELECT poll_id,
       partition_period,
       opinion_id,
       ingest_batch_id,
       version
FROM opinion_updates
WHERE poll_id IS NOT NULL
  AND partition_period IS NOT NULL
  AND opinion_id IS NOT NULL
  AND ingest_batch_id IS NOT NULL
PRIMARY KEY ((poll_id, partition_period), opinion_id, ingest_batch_id);



-------------------
-- ROOT OPINIONS --
-------------------

/**
  Root opinions are a convenient construct to group Opinions by when displaying in the UI.
  It groups the data of all opinions under the root (top level) opinion of a given poll.
  They allow to group a number of opinions together, instead of having to query for each
  one individually.  They also allow for different opinion sorting/ranking.  Along with
  opinion id it's root opinion id is retrieved.  Then the entire root opinion is retrieved
  and rendered in whatever way is most convenient.

  These should work well up to mid-scale. Eventually we'll want to add support for users to
  drill down into a particular sub-opinion and watch only what happens there.  This could
  become very useful in very large polls where multiple conversations are being contributed
  to at the same time.  This can be easily controlled by detecting what the user is looking
  at at a given time and only watching that The relevant sub-thread.  One way to do this is
  to cut off root thread recording at a particular depth and record sub content in separate
  sub threads.

  Visually we might want to support nesting of trees and lists so that the user gets a clue
  for what was happening previously.  Internally everything can be stored as a tree.  However
  if opinions a very close to each other in time then some sub-trees are better collapsed
  into lists.

  NOTE: root opinions are populated by ingest after the initial ingest of opinions and
  opinion updates is performed. At that point the ids of polls that have new and updated opinions
  (in the last partition period) are known and is recorded by the poll batch process in a
  separate table. Also recorded are the ids of modified the root opinions.  These two ids are
  (eventually to be) used by root opinion ingest (coordinator, to distribute work between worker
  nodes). Then opinions table is used to query all opinions for a given poll that have been
  inserted or updated in a given partition period. At that point the new copy of root opinion
  data is created and persisted.

  When the UI requests the root opinions it also requests the last processed partition period.
  That's how it knows witch additional individual poll and poll update ids to request.
 */

CREATE TABLE root_opinions
(
    poll_id    bigint,
    opinion_id bigint,
    version    int, // this is the latest updated partition_period
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
-- its more compact than root_opinions and hence iterating and returning
-- a block of ids & position (root_opinion_id + version & create_es) should be faster
-- (less disk io)
CREATE MATERIALIZED VIEW root_opinion_ids AS
SELECT poll_id, opinion_id, version
FROM root_opinions
WHERE poll_id IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((poll_id), opinion_id);

-- for lookup of all root opinion ids in which the user participated
/**
  NOTE: not needed - root_opinion_ids are incuded in *_opinon_ids_by_user tables
CREATE TABLE root_opinion_ids_with_user
(
    user_id          bigint,
    partition_period int,
    create_es        bigint,
    opinion_id       bigint,
    version          int,
    poll_id          bigint,
    PRIMARY KEY ((user_id), partition_period, create_es, opinion_id)
)
            WITH CLUSTERING ORDER BY (partition_period DESC, create_es DESC);
*/


---------------------
-- OPINION RATINGS --
---------------------

/**
  Ratings are different in nature than polls and opinions.  They don't have variable data
  assigned to them and hence aren't as good of candidates for caching individually as are
  polls and opinions.  So, it makes sense to cache them in batches (all ratings for a poll
  & root opinion) and retrieve the remainder in one (non-cached) shot.

  Process or retrieving a thread:

  1) Retrieve all root opinion ids.  Along with it retrieve last finished batch period
  (or batch periods if/once they are different for polls and opinions, etc.) NOTE: very
  operation returns it.

  2)
  a. Retrieve all shown root opinions (that are expected to be rendered on the screen)
  b. Retrieve all shown root opinion ratings (for the same root opinions)
  c. Retrieve all recent opinion ids (since last batch period)
  d. Retrieve all recent opinion update ids (since last batch period)
  e. Retrieve all recent ratings for all shown root opinions

  3)
  a. (If in recent opinions there are shown root opinions) retrieve recent opinion
  ratings for the new root opinions

  Then continuously as the user scrolls down step 2 is repeated.
 */
CREATE TABLE opinion_ratings
(
    root_opinion_id   bigint,
    partition_period  int,
    opinion_rating_id bigint,
    rating_type       int,
    poll_id           bigint,
    opinion_id        bigint,
    theme_id          bigint,  // Needed to compute counts by theme and theme+location
    location_id       int,     // Needed to compute counts by location and location + theme
    ingest_batch_id   int,
--     version           int,  since a given rating is just a uint64 it doesn't make sense
-- to retrieve it individually
--     parent_opinion_id bigint,  // can't find a need for this right now
    create_es         bigint,
    user_id           bigint,
    rating            bigint,
    insert_processed  boolean, // Has the initial ingest into CockroachDb finished
    PRIMARY KEY ((root_opinion_id, partition_period), opinion_rating_id, theme_id, location_id)
);

/**
  Works the same way as period_poll_ids_by_batch
 */
CREATE MATERIALIZED VIEW period_opinion_ratings_by_batch AS
SELECT partition_period,
       ingest_batch_id,
       opinion_rating_id,
--        theme_id,
--        location_id,
       rating_type,
       opinion_id,
       ingest_batch_id,
       create_es,
       user_id,
       rating,
       insert_processed
FROM opinion_ratings
WHERE partition_period IS NOT NULL
  AND ingest_batch_id IS NOT NULL
  AND opinion_rating_id IS NOT NULL
  AND root_opinion_id IS NOT NULL
  AND theme_id IS NOT NULL
  AND location_id IS NOT NULL
PRIMARY KEY ((partition_period, ingest_batch_id), opinion_rating_id, root_opinion_id, theme_id, location_id);

/**
  Works the same way as period_poll_ids_by_user

  Note that create_es is missing from the key since it's not needed in the UI,
  which can post sort the opinions in the right order AND is not needed by
  the ingest because it can correctly order the records itself.  The end effect
  is a bit of CPU, Memory Storage savings by the database, which probably adds
  up overtime to more benefit than the cost of sorting by the batch and UI.

  TODO: make sure that UI sorts period records and batch sorts all of the
  records by create_es
 */
CREATE MATERIALIZED VIEW period_opinion_ratings_by_user AS
SELECT partition_period,
       user_id,
       opinion_rating_id,
       root_opinion_id, // needed for ability to navigate to the correct part of the thread
       opinion_id,
       poll_id,
       rating_type,
       rating,
--        location_id,
--        theme_id,
       create_es        // Needed for sorting by UI & batch job
FROM opinion_ratings
WHERE partition_period IS NOT NULL
  AND user_id IS NOT NULL
  AND opinion_rating_id IS NOT NULL
  AND root_opinion_id IS NOT NULL
  AND location_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, user_id), opinion_rating_id, root_opinion_id, theme_id, location_id);

/**
  Works the same way as period_poll_ids_by_theme.  Most recent opinion ratings are not
  shown but these views are needed, to support opinion counts by theme/theme+location
  /location/location+theme.  In case of opinion ratings the ingest process computes
  only the counts (for a given partition_period) and not id blocks.

  Currently by_theme does double duty of also counting by theme + location.
  The argument is that it is fewer records it is easier for ScyllaDB to
  */
CREATE MATERIALIZED VIEW period_opinion_ratings_by_theme AS
SELECT partition_period,
--        theme_id,
       opinion_rating_id,
--        root_opinion_id,
       poll_id,
--        location_id,
       rating_type,
       rating
FROM opinion_ratings
WHERE partition_period IS NOT NULL
  AND theme_id IS NOT NULL
  AND opinion_rating_id IS NOT NULL
  AND root_opinion_id IS NOT NULL
  AND location_id IS NOT NULL
PRIMARY KEY ((partition_period, theme_id), opinion_rating_id, root_opinion_id, location_id);
// NOTE: not ordering by location_id, done in memory by batch job & UI

/**
  Works the same way as period_poll_ids_by_location
  Currently by_location does double duty of also counting by location + theme
 */
CREATE MATERIALIZED VIEW period_opinion_ratings_by_location AS
SELECT partition_period,
--        location_id,
       opinion_rating_id,
--        root_opinion_id,
       poll_id,
--        theme_id,
       rating_type,
       rating
FROM opinion_ratings
WHERE partition_period IS NOT NULL
  AND location_id IS NOT NULL
  AND opinion_rating_id IS NOT NULL
  AND root_opinion_id IS NOT NULL
  AND theme_id IS NOT NULL
PRIMARY KEY ((partition_period, location_id), opinion_rating_id, root_opinion_id, theme_id);
// NOTE: not ordering by theme_id, done in memory by batch job & UI


CREATE TABLE opinion_rating_averages
(
    rating_type      int,
    poll_id          bigint,
    partition_period bigint,
    opinion_id       bigint,
    count            bigint,
    average          double,
    rating           bigint,
    PRIMARY KEY ((poll_id, partition_period), opinion_id, rating_type)
);



------------
-- COUNTS --
------------
/*
 Counts are meant to be exposed to the general public (and hence are
 in ScyllaDB).  Since we already process all of the records in batches
 and compute id blocks, counts is a natural extension of this process.
 It takes very little extra effort to record the counts (once Id
 blocks are computed).
 */

/*
Period count breakdowns by user are not done - just not enough data
is expected on per user/per period basis.  They are done daily.
 */

CREATE TABLE period_counts_by_theme
(
    partition_period int,
    age_suitability  tinyint,
    theme_id         bigint,
    poll_counts      int,
    opinion_counts   bigint,
    vote_counts      bigint,
    PRIMARY KEY ((partition_period, age_suitability, theme_id))
);

CREATE TABLE period_counts_by_theme_n_location
(
    partition_period int,
    age_suitability  tinyint,
    theme_id         bigint,
    location_id      int,
    poll_counts      int,
    opinion_counts   bigint,
    vote_counts      bigint,
    PRIMARY KEY ((partition_period, age_suitability, theme_id), location_id)
);

CREATE TABLE period_counts_by_location
(
    partition_period int,
    age_suitability  tinyint,
    theme_id         bigint,
    location_id      int,
    poll_counts      int,
    opinion_counts   bigint,
    vote_counts      bigint,
    PRIMARY KEY ((partition_period, age_suitability, location_id))
);

CREATE TABLE period_counts_by_location_n_theme
(
    partition_period int,
    age_suitability  tinyint,
    theme_id         bigint,
    location_id      int,
    poll_counts      int,
    opinion_counts   bigint,
    vote_counts      bigint,
    PRIMARY KEY ((partition_period, age_suitability, location_id), theme_id)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_counts_by_user
(
    date            int,
    age_suitability tinyint,
    user_id         bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_counts_by_user_n_theme
(
    date            int,
    age_suitability tinyint,
    user_id         bigint,
    theme_id        bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, user_id), theme_id)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
CREATE TABLE day_counts_by_user_n_theme_n_location
(
    date            int,
    age_suitability tinyint,
    user_id         bigint,
    theme_id        bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, user_id), theme_id, location_id)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
CREATE TABLE day_counts_by_user_n_location
(
    date            int,
    age_suitability tinyint,
    user_id         bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, user_id), location_id)
);

-- populated daily, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_counts_by_theme
(
    date            int,
    age_suitability tinyint,
    theme_id        bigint,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, theme_id))
);

-- populated daily, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE day_counts_by_theme_n_location
(
    date            int,
    age_suitability tinyint,
    theme_id        bigint,
    location_id     int,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, theme_id), location_id)
);

-- populated daily, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE day_counts_by_location
(
    date            int,
    age_suitability tinyint,
    location_id     int,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, location_id))
);

-- populated daily, for lookup of poll data by location+theme
-- contains poll ids for actual and aggregate locations
CREATE TABLE day_counts_by_location_n_theme
(
    date            int,
    age_suitability tinyint,
    location_id     int,
    theme_id        bigint,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, location_id), theme_id)
);

-- populated monthly, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_counts_by_user
(
    month           smallint,
    age_suitability tinyint,
    user_id         bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, user_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_counts_by_user_n_theme
(
    month           smallint,
    age_suitability tinyint,
    user_id         bigint,
    theme_id        bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, user_id), theme_id)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
CREATE TABLE month_counts_by_user_n_theme_n_location
(
    month           smallint,
    age_suitability tinyint,
    user_id         bigint,
    theme_id        bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, user_id, theme_id), location_id)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
CREATE TABLE month_counts_by_user_n_location
(
    month           smallint,
    age_suitability tinyint,
    user_id         bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, user_id), location_id)
);

-- populated monthly, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_counts_by_theme
(
    month           smallint,
    age_suitability tinyint,
    theme_id        bigint,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, theme_id))
);

-- populated monthly, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
CREATE TABLE month_counts_by_theme_n_location
(
    month           smallint,
    age_suitability tinyint,
    theme_id        bigint,
    location_id     int,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, theme_id), location_id)
);

-- populated monthly, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE month_counts_by_location
(
    month           smallint,
    age_suitability tinyint,
    location_id     int,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, location_id))
);

-- populated monthly, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
CREATE TABLE month_counts_by_location_n_theme
(
    month           smallint,
    age_suitability tinyint,
    location_id     int,
    theme_id        bigint,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, location_id), theme_id)
);

CREATE TABLE year_counts_by_user
(
    year            smallint,
    age_suitability tinyint,
    user_id         bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, user_id))
);

CREATE TABLE year_counts_by_user_n_theme
(
    year            smallint,
    age_suitability tinyint,
    user_id         bigint,
    theme_id        bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, user_id), theme_id)
);

CREATE TABLE year_counts_by_user_n_theme_n_location
(
    year            smallint,
    age_suitability tinyint,
    user_id         bigint,
    theme_id        bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, user_id, theme_id), location_id)
);

CREATE TABLE year_counts_by_user_n_location
(
    year            smallint,
    age_suitability tinyint,
    user_id         bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, user_id), location_id)
);

CREATE TABLE year_counts_by_theme
(
    year            smallint,
    age_suitability tinyint,
    theme_id        bigint,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, theme_id))
);

CREATE TABLE year_counts_by_theme_n_location
(
    year            smallint,
    age_suitability tinyint,
    theme_id        bigint,
    location_id     int,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, theme_id), location_id)
);

CREATE TABLE year_counts_by_location
(
    year            smallint,
    age_suitability tinyint,
    location_id     int,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, location_id))
);

CREATE TABLE year_counts_by_location_n_theme
(
    year            smallint,
    age_suitability tinyint,
    location_id     int,
    theme_id        bigint,
    poll_counts     bigint,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, location_id), theme_id)
);



-----------------
-- TODO: OTHER --
-----------------
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
