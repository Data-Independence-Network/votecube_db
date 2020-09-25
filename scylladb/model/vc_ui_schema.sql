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
  for the missing records).  Currently it appears that we can do 5 minute batches,
  delay the processing by a couple of minutes (after period end) and then do a cleanup
  round when we run repair on ScyllaDB (probably weekly).

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
    -- age_suitability  bigint,
    data             blob,
    PRIMARY KEY (poll_id)
);

CREATE TABLE poll_revisions
(
    poll_revision_id     bigint,
    poll_id              bigint,
    poll_id_mod int,
    partition_period     int,
    insert_processed     boolean, // Has the initial ingest into CockroachDb finished
    PRIMARY KEY ((partition_period, poll_id), poll_revision_id)
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
  user ids (populating batch_user_account_ids). Both are then used to distribute
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
CREATE MATERIALIZED VIEW period_poll_revision_ids_for_ingest AS
SELECT partition_period,
       poll_id_mod,
       poll_id,
       poll_revision_id,
       insert_processed
FROM poll_revisions
WHERE partition_period IS NOT NULL
  AND poll_id_mod IS NOT NULL
PRIMARY KEY ((partition_period, poll_id_mod), poll_revision_id);



------------------
-- POLL RATINGS --
------------------
CREATE TABLE poll_ratings
(
    rating_type      int,
    poll_id          bigint,
    partition_period int,
    ingest_batch_id  int,
    user_account_id  bigint,
    rating           bigint,
    PRIMARY KEY ((poll_id, partition_period), rating_type, user_account_id)
);

CREATE TABLE user_poll_ratings
(
    rating_type     int,
    poll_id         bigint,
    user_account_id bigint,
    rating          bigint,
    PRIMARY KEY ((poll_id, user_account_id), rating_type)
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

-- for lookup of the opinion data.  Also for applying updates to opinions
/**
  NOTE: older opinions cannot be deleted since they are used to verify updates
  to those opinions.  Shouldn't be too big of a deal in the long term - data
  is already compressed and disk space is relatively cheap

  NOTE: id (opinion_id only) is optimized for UI based queries for recent records.
  Batch jobs have to query each record individually as well.  This is considered
  better than having to maintain a separate Materialized View with the data
  in it (and keyed by partition_period + root_opinion_id).  The overhead of querying
  by the batch jobs should be relatively small (in comparison with the requests
  coming from the UI, since the batch job only each record once while the number of
  queries from the UI is unbounded, especially if caches miss).
 */
CREATE TABLE opinions
(
    partition_period int,
    root_opinion_id  bigint,
    opinion_id       bigint,
--     poll_id           bigint,
    version          smallint,
--     parent_opinion_id bigint,
    data             blob,
    insert_processed boolean, // Has the initial ingest into CockroachDb finished
    PRIMARY KEY ((opinion_id), root_opinion_id, partition_period)
);

/**
  Used for retrieving opinion_id and version of recently added Opinions
 */
CREATE MATERIALIZED VIEW period_opinion_ids_for_ingest AS
SELECT partition_period,
       root_opinion_id,
       opinion_id,
       version
FROM opinions
WHERE partition_period IS NOT NULL
  AND root_opinion_id IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((partition_period, root_opinion_id), opinion_id);



---------------------
-- OPINION UPDATES --
---------------------

-- for ingest of updates into CRDB
/**
  Is CRDB fast enough to process opinion updates (and opinion/poll inserts) at
  the time of the change (and not post-factum via a batch)?

  It might be but will require much more hardware to do this.  Batching all
  updates would require much less CRDB capacity.
 */
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
    partition_period int,
    root_opinion_id  bigint,
    opinion_id       bigint,
    // Version is needed for the UI query (to know which version of
    // opinion to request).
    version          smallint,
    update_processed boolean,
    PRIMARY KEY ((partition_period, root_opinion_id), opinion_id)
);



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
    opinion_id bigint, // the root opinion_id
    poll_id    bigint,
    version    int,    // this is the latest updated partition_period
    data       blob,
    // newest or oldest order)
    /*
     Shouldn't need this column.  In case of batch failures there may be an point when
     a later batch succeeded but an earlier has not so, in such a case this wouldn't be of
     any use.
     */
    -- last_processed_period text,
    PRIMARY KEY ((opinion_id), poll_id)
);


/**
  Opinions

  I. Query:

  Root opinions take care of grouping historical opinion records by at root level.  But,
  any any given point in time there may be a number of newer opinions and opinion updates
  posted (to a given poll).  Here we have two strategies (identified so far):

  A.  Load them all individually.  The positive side of this approach is that it is easier
  (just load every new and updated record).  The downside is that it can lead to a large
  number of requests from the UI (the first time around).

  B.  There will be at least one more partition period (between the current one and the
  already grouped one) that will have an already complete set of new opinions and opinion
  updates.  So it could be grouped together into a single request and send over in one shot.
  The benefit is fewer requests from the UI.  The downside is that it complicates the process
  (more UI and server logic) and requires more computational resources on read (have to
  un-compress individual opinions, put them together and re-compress them again).

  So, for now (at least), going with A.  Primary because this leads to less code and less
  complexity.

  1. Root opinion ids are loaded.
  2.
    a) Certain root opinions (determined to be on the screen or close to it)
  are loaded
    b) Ids and versions of all opinions added & updated in recent partition
  periods are loaded (via period_opinion_ids && opinion_updates).
  3. If there are additions and updates they are loaded and cached (on individual basis).

  II. Insert process:

  During insert first the period_added_to_root_opinion_ids is upserted into (
  before the a new opinion record is created).  Hence if the process fails before
  inserting an opinion the client will re-try the insert.  This can lead to
  duplicate opinion records being inserted (in rare cases, if the insert succeeded
  but network failed) so there will be a way to update opinions as duplicates (by
  either the creator or thread/theme/location admin).
  Same process happens on update with period_updated_root_opinion_ids.

  III. Core Ingest process:

  At the time of adding new opinions root_opinion_id_mod is recorded (with mod being ^2,
  probably). Same is done for opinion updates.
  Then a number of coordinator processes matching the number possibilities for
  mod (2, 4, etc.) run.  They maintain their lifecycle in CRDB with possible options
  being:
    - Not Started (no record)
    - Started
    - Finished
  The coordinators load all root_opinion_ids (for additions via
  period_added_to_root_opinion_ids and updates via period_updated_root_opinion_ids) that
  match their mod and distribute the work between Ingest Worker threads.

  Ingest Worker threads work on per root_opinion_id basis. They load all new opinions
  (for a given partition period and root_opinion_id).  They also load all opinion updates
  for same ids.  Then they update the related root_opinion record (or create a new one,
  if it didn't exist) and transactionally update CockroachDB with all additions and
  updates.  They also flip opinions.insert_processed and opinion_updates.update_processed
  flags (for eventual lookup by post-repair job).  Within the same transaction a separate
  table is updated in CRDB that keeps track of all completed (per root_opinion) ingests
  (for that partition_period).

  Once a coordinating process runs out of root_opinion_ids it runs a verification
  against CRDB to make sure that all root_opinion_ids it served out have been recorded
  in CRDB. If some have not it instructs batch worker threads to re-run those updates.
  Once they all have run successfully (and the coordinator re-queried and verified
  that) it flips the lifecycle for its run to "Finished".

  If the coordinating process itself fails, when it re-starts it first queries it's
  lifecycle record, if it's in started it re-loads all root_opinion_ids and all
  of the completion records in CRDB and proceeds from there.

  It is possible to for some records to be missed due to the eventual consistency
  nature of ScyllaDB.  So another job will run after the periodic repair process
  (that we should probably run daily).  For every partition_period it will run
  looks lookup against opinions and opinion updates (using the root_opinion_ids
  in period_added_to_root_opinion_ids and period_updated_root_opinion_ids) and
  finds any missed records, which are recorded in CRDB and then post processed
  by batch processes.  This works well for opinions but might clobber updates
  by users, so the same process also looks for subsequent updates to the same
  opinions via CRDB looks for updated_es.

  TODO: id block/counts Batch Process


  Opinion Ratings

  Same process repeats for opinion ratings
 */

/**
  For lookup of added-to root_opinion_ids during ingest run.
  Keying by root_opinion_id_mod reduces contention for the current partition.
 */
CREATE TABLE period_added_to_root_opinion_ids
(
    partition_period    int,
--     poll_id             bigint,
    root_opinion_id     bigint,
    root_opinion_id_mod int,
    PRIMARY KEY ((partition_period, root_opinion_id_mod), root_opinion_id)
);

/**
  For lookup of updated root_opinion_ids during ingest run.
  Keying by root_opinion_id_mod reduces contention for the current partition.
 */
CREATE TABLE period_updated_root_opinion_ids
(
    partition_period    int,
--     poll_id             bigint,
    root_opinion_id     bigint,
    root_opinion_id_mod int,
    PRIMARY KEY ((partition_period, root_opinion_id_mod), root_opinion_id)
);

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
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE opinion_ratings
(
    root_opinion_id   bigint,
    partition_period  int,
    opinion_rating_id bigint,
    rating_type       int,
    poll_id           bigint,
    opinion_id        bigint,
--     version           int,  since a given rating is just a uint64 it doesn't make sense
-- to retrieve it individually
--     parent_opinion_id bigint,  // can't find a need for this right now
    rating            bigint,
    insert_processed  boolean, // Has the initial ingest into CockroachDb finished
    PRIMARY KEY ((partition_period, root_opinion_id), opinion_rating_id)
);

-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
/**
  Not needed, this is embedded into root_opinion_ratings and is then adjusted
  by recent partition_period opinion_ratings and opinion_rating_updates
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
*/

-----------------------
-- OPINION RATING BLOCKS --
-----------------------
/**
  Works the same way as day_poll_id_blocks_by_user
 */
CREATE TABLE day_opinion_rating_blocks_by_user
(
    date             int,
    user_account_id  bigint,
    rating_types     blob,
    opinion_ids      blob,
    root_opinion_ids blob,
    poll_ids         blob,
    theme_ids        blob,
    location_ids     blob,
    create_dbts      blob,
    ratings          blob,
    PRIMARY KEY ((date, user_account_id))
);

/**
  Works the same way as month_poll_id_blocks_by_user
 */
CREATE TABLE month_opinion_rating_blocks_by_user
(
    month            smallint,
    user_account_id  bigint,
    rating_types     blob,
    opinion_ids      blob,
    root_opinion_ids blob,
    poll_ids         blob,
    theme_ids        blob,
    location_ids     blob,
    create_dbts      blob,
    ratings          blob,
    PRIMARY KEY ((month, user_account_id))
);


----------------------------
-- OPINION RATING UPDATES --
----------------------------

-- for ingest of updates into CRDB
/**
  Records updates to opinion ratings (in a given partition_period).  If an
  opinion rating is updated multiple times in that partition_period only
  one record is retained.

  If an opinion rating is created in the same partition_period then no
  record is created here.

  The batch process(es) updates the source opinion rating record.

  Opinion rating updates ingest can run at the same time as either
  poll or opinion insert process.  This is because the opinion
  (and poll) are already guaranteed to exist.
 */
CREATE TABLE opinion_rating_updates
(
    root_opinion_id   bigint,
    partition_period  int,
    ingest_batch_id   int,
    opinion_rating_id bigint,
    rating_type       int,
    rating            bigint,
    update_processed  boolean,
    PRIMARY KEY ((partition_period, ingest_batch_id), opinion_rating_id)
);


--------------------------
-- ROOT OPINION RATINGS --
--------------------------

/**
  Root opinions are a convenient construct to group Opinion Ratings by when displaying
  in the UI.  It groups the data of all opinion ratings under the root (top level) opinion
  of a given poll.  They allow to group a number of opinion ratings together, instead of
  having to query for each one individually.  The entire root opinion rating is retrieved
  and rendered in whatever way is most convenient.

  NOTE: root opinion ratings are populated by ingest after the initial ingest of opinion ratings
  and opinion rating updates is performed. At that point the ids of root opinions that have new
  and updated opinion ratings (in the last partition period) are known and is recorded by the
  opinion rating batch process in a separate table.  These ids are (eventually to be) used by
  root opinion rating ingest (coordinator, to distribute work between worker nodes). Then
  opinion_ratings table is used to query all opinion ratings for a given root opinion that
  have been inserted or updated in a given partition period. At that point the new copy of
  root opinion update data is created and persisted.

  When the UI requests the root opinion updates it also requests the last processed partition
  period. That's how it knows witch additional individual ratings and rating updates to request.
 */

CREATE TABLE root_opinion_ratings
(
    opinion_id bigint, // the root opinion_id
    version    int,    // this is the latest updated partition_period
    data       blob,
    /*
     Shouldn't need this column.  In case of batch failures there may be an point when
     a later batch succeeded but an earlier has not so, in such a case this wouldn't be of
     any use.
     */
    -- last_processed_period text,
    PRIMARY KEY ((opinion_id))
);

/**
  For lookup of recent opinion additions/changes to a given poll.
 */
CREATE TABLE period_rated_root_opinion_ids
(
    partition_period    int,
    root_opinion_id     bigint,
    root_opinion_id_mod int,
    PRIMARY KEY ((partition_period, root_opinion_id))
);

/**
  For lookup at ingest time
 */
CREATE MATERIALIZED VIEW period_rated_root_opinion_ids_for_ingest AS
SELECT partition_period,
       root_opinion_id_mod,
       root_opinion_id
FROM period_added_to_root_opinion_ids
WHERE partition_period IS NOT NULL
  AND root_opinion_id_mod IS NOT NULL
  AND root_opinion_id IS NOT NULL
PRIMARY KEY ((partition_period, root_opinion_id_mod), root_opinion_id);

/**
  For lookup of recent opinion additions/changes to a given poll.
 */
CREATE TABLE period_rerated_root_opinion_ids
(
    partition_period    int,
    root_opinion_id     bigint,
    root_opinion_id_mod int,
    PRIMARY KEY ((partition_period, root_opinion_id))
);

CREATE MATERIALIZED VIEW period_rerated_root_opinion_ids_for_ingest AS
SELECT partition_period,
       root_opinion_id_mod,
       root_opinion_id
FROM period_added_to_root_opinion_ids
WHERE partition_period IS NOT NULL
  AND root_opinion_id_mod IS NOT NULL
  AND root_opinion_id IS NOT NULL
PRIMARY KEY ((partition_period, root_opinion_id_mod), root_opinion_id);



------------
-- COUNTS --
------------
/*
 Counts are meant to be exposed to the general public (and hence are
 in ScyllaDB).  These are computed per day from CRDB (once it's been updated)
 */

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_counts_by_user
(
    date            int,
    age_suitability tinyint,
    user_account_id bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, user_account_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE day_counts_by_user_n_theme
(
    date            int,
    age_suitability tinyint,
    user_account_id bigint,
    theme_id        bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, user_account_id), theme_id)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
CREATE TABLE day_counts_by_user_n_theme_n_location
(
    date            int,
    age_suitability tinyint,
    user_account_id bigint,
    theme_id        bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, user_account_id), theme_id, location_id)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
CREATE TABLE day_counts_by_user_n_location
(
    date            int,
    age_suitability tinyint,
    user_account_id bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((date, age_suitability, user_account_id), location_id)
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
    user_account_id bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, user_account_id))
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
CREATE TABLE month_counts_by_user_n_theme
(
    month           smallint,
    age_suitability tinyint,
    user_account_id bigint,
    theme_id        bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, user_account_id), theme_id)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
CREATE TABLE month_counts_by_user_n_theme_n_location
(
    month           smallint,
    age_suitability tinyint,
    user_account_id bigint,
    theme_id        bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, user_account_id, theme_id), location_id)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
CREATE TABLE month_counts_by_user_n_location
(
    month           smallint,
    age_suitability tinyint,
    user_account_id bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((month, age_suitability, user_account_id), location_id)
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
    user_account_id bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, user_account_id))
);

CREATE TABLE year_counts_by_user_n_theme
(
    year            smallint,
    age_suitability tinyint,
    user_account_id bigint,
    theme_id        bigint,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, user_account_id), theme_id)
);

CREATE TABLE year_counts_by_user_n_theme_n_location
(
    year            smallint,
    age_suitability tinyint,
    user_account_id bigint,
    theme_id        bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, user_account_id, theme_id), location_id)
);

CREATE TABLE year_counts_by_user_n_location
(
    year            smallint,
    age_suitability tinyint,
    user_account_id bigint,
    location_id     int,
    poll_counts     int,
    opinion_counts  bigint,
    vote_counts     bigint,
    PRIMARY KEY ((year, age_suitability, user_account_id), location_id)
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



-------------------
-- RATING COUNTS --
-------------------
/*
 Rating counts are meant to be exposed to the general public (and hence are
 in ScyllaDB).
 */

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE day_opinion_rating_counts_by_user
(
    date            int,
    user_account_id bigint,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((date, user_account_id), rating_type)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE day_opinion_rating_counts_by_user_n_theme
(
    date            int,
    user_account_id bigint,
    theme_id        bigint,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((date, user_account_id), theme_id, rating_type)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE day_opinion_rating_counts_by_usr_n_thm_n_lctn
(
    date            int,
    user_account_id bigint,
    theme_id        bigint,
    location_id     int,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((date, user_account_id), theme_id, location_id, rating_type)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE day_opinion_rating_counts_by_user_n_location
(
    date            int,
    user_account_id bigint,
    location_id     int,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((date, user_account_id), location_id, rating_type)
);

-- populated daily, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE day_opinion_rating_counts_by_theme
(
    date        int,
    theme_id    bigint,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((date, theme_id), rating_type)
);

-- populated daily, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE day_opinion_rating_counts_by_theme_n_location
(
    date        int,
    theme_id    bigint,
    location_id int,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((date, theme_id), location_id, rating_type)
);

-- populated daily, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE day_opinion_rating_counts_by_location
(
    date        int,
    location_id int,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((date, location_id), rating_type)
);

-- populated daily, for lookup of poll data by location+theme
-- contains poll ids for actual and aggregate locations
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE day_opinion_rating_counts_by_location_n_theme
(
    date        int,
    location_id int,
    theme_id    bigint,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((date, location_id), theme_id, rating_type)
);

-- populated monthly, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE month_opinion_rating_counts_by_user
(
    month           smallint,
    user_account_id bigint,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((month, user_account_id), rating_type)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE month_opinion_rating_counts_by_user_n_theme
(
    month           smallint,
    user_account_id bigint,
    theme_id        bigint,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((month, user_account_id), theme_id, rating_type)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate themes and locations
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE month_opinion_rating_counts_by_usr_n_thm_n_lctn
(
    month           smallint,
    user_account_id bigint,
    theme_id        bigint,
    location_id     int,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((month, user_account_id, theme_id), location_id, rating_type)
);

-- populated daily, for lookup of poll data by user
-- contains poll ids for actual and aggregate locations
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE month_opinion_rating_counts_by_user_n_location
(
    month           smallint,
    user_account_id bigint,
    location_id     int,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((month, user_account_id), location_id, rating_type)
);

-- populated monthly, for lookup of poll data by theme
-- contains poll ids for actual and aggregate themes
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE month_opinion_rating_counts_by_theme
(
    month       smallint,
    theme_id    bigint,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((month, theme_id), rating_type)
);

-- populated monthly, for lookup of poll data by theme + location
-- contains poll ids for actual and aggregate themes by locations
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE month_opinion_rating_counts_by_theme_n_location
(
    month       smallint,
    theme_id    bigint,
    location_id int,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((month, theme_id), location_id, rating_type)
);

-- populated monthly, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE month_opinion_rating_counts_by_location
(
    month       smallint,
    location_id int,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((month, location_id), rating_type)
);

-- populated monthly, for lookup of poll data by location
-- contains poll ids for actual and aggregate locations
-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE month_opinion_rating_counts_by_location_n_theme
(
    month       smallint,
    location_id int,
    theme_id    bigint,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((month, location_id), theme_id, rating_type)
);

-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE year_opinion_rating_counts_by_user
(
    year            smallint,
    user_account_id bigint,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((year, user_account_id), rating_type)
);

-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE year_opinion_rating_counts_by_user_n_theme
(
    year            smallint,
    user_account_id bigint,
    theme_id        bigint,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((year, user_account_id), theme_id, rating_type)
);

-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE year_opinion_rating_counts_by_usr_n_thm_n_lctn
(
    year            smallint,
    user_account_id bigint,
    theme_id        bigint,
    location_id     int,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((year, user_account_id, theme_id), location_id, rating_type)
);

-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE year_opinion_rating_counts_by_user_n_location
(
    year            smallint,
    user_account_id bigint,
    location_id     int,
    rating_type     int,
    count           bigint,
    average         double,
    PRIMARY KEY ((year, user_account_id), location_id, rating_type)
);

-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE year_opinion_rating_counts_by_theme
(
    year        smallint,
    theme_id    bigint,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((year, theme_id), rating_type)
);

-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE year_opinion_rating_counts_by_theme_n_location
(
    year        smallint,
    theme_id    bigint,
    location_id int,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((year, theme_id), location_id, rating_type)
);

-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE year_opinion_rating_counts_by_location
(
    year        smallint,
    location_id int,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((year, location_id), rating_type)
);

-- NOTE: age_suitability is implied by rating_type and can be filtered in the UI
CREATE TABLE year_opinion_rating_counts_by_location_n_theme
(
    year        smallint,
    location_id int,
    theme_id    bigint,
    rating_type int,
    count       bigint,
    average     double,
    PRIMARY KEY ((year, location_id), theme_id, rating_type)
);



-----------------
-- TODO: OTHER --
-----------------
CREATE TABLE users
(
    user_account_id bigint,
    PRIMARY KEY (user_account_id)
);

CREATE TABLE user_lookup
(
    username        text,
    user_account_id bigint,
    password_hash   text,
    PRIMARY KEY (username)
);

CREATE TABLE user_sessions
(
    partition_period int,
    session_id       text,
    last_action_es   bigint,
    keep_signed_in   tinyint,
    user_account_id  int,
    data             blob,
    PRIMARY KEY ((partition_period, session_id))
);

CREATE TABLE user_sessions_for_timeout_batch
(
    partition_period int,
    session_id       text,
    last_action_es   bigint,
    keep_signed_in   tinyint,
    PRIMARY KEY ((partition_period), session_id)
);

/*
insert into user_sessions (partition_period,
                           session_id,
                           last_action_es,
                           keep_signed_in,
                           user_account_id,
                           data)
values (1,
        '1',
        1,
        1,
        0,
        null);
*/


-------------------
--   FEEDBACK   ---
-------------------

/*
CREATE TABLE feedback
(
    poll_id          bigint,
    poll_id_mod      int,
    partition_period int,     -- needed HERE because of materialized views
    data             blob,
    insert_processed boolean, -- Has the initial ingest into CockroachDb finished
    PRIMARY KEY ((poll_id), partition_period)
);

CREATE MATERIALIZED VIEW period_feedback_ids_for_ingest AS
SELECT partition_period,
       poll_id_mod,
       poll_id,
       insert_processed
FROM feedback
WHERE partition_period IS NOT NULL
  AND poll_id_mod IS NOT NULL
PRIMARY KEY ((partition_period, poll_id_mod), poll_id);

CREATE TABLE feedback_ratings
(
    rating_type      int,
    poll_id          bigint,
    partition_period int,
    ingest_batch_id  int,
    user_account_id          bigint,
    rating           bigint,
    PRIMARY KEY ((poll_id, partition_period), rating_type, user_account_id)
);

CREATE TABLE feedback_opinions
(
    partition_period  int,
    root_opinion_id   bigint,
    opinion_id        bigint,
--     poll_id           bigint,
    version           smallint,
--     parent_opinion_id bigint,
    data              blob,
    insert_processed  boolean, // Has the initial ingest into CockroachDb finished
    PRIMARY KEY ((opinion_id), root_opinion_id, partition_period)
);

CREATE MATERIALIZED VIEW period_feedback_opinion_ids_for_ingest AS
SELECT partition_period,
       root_opinion_id,
       opinion_id,
       version
FROM feedback_opinions
WHERE partition_period IS NOT NULL
  AND root_opinion_id IS NOT NULL
  AND opinion_id IS NOT NULL
PRIMARY KEY ((partition_period, root_opinion_id), opinion_id);

CREATE TABLE feedback_opinion_updates
(
    partition_period int,
    root_opinion_id  bigint,
    opinion_id       bigint,
    // Version is needed for the UI query (to know which version of
    // opinion to request).
    version          smallint,
    update_processed boolean,
    PRIMARY KEY ((partition_period, root_opinion_id), opinion_id)
);

CREATE TABLE feedback_root_opinions
(
    opinion_id bigint, // the root opinion_id
    poll_id    bigint,
    version    int,    // this is the latest updated partition_period
    data       blob,
    // newest or oldest order)
    PRIMARY KEY ((opinion_id), poll_id)
);

CREATE TABLE period_added_to_feedback_root_opinion_ids
(
    partition_period    int,
--     poll_id             bigint,
    root_opinion_id     bigint,
    root_opinion_id_mod int,
    PRIMARY KEY ((partition_period, root_opinion_id_mod), root_opinion_id)
);

CREATE TABLE period_updated_feedback_root_opinion_ids
(
    partition_period    int,
--     poll_id             bigint,
    root_opinion_id     bigint,
    root_opinion_id_mod int,
    PRIMARY KEY ((partition_period, root_opinion_id_mod), root_opinion_id)
);

CREATE TABLE feedback_opinion_ratings
(
    root_opinion_id   bigint,
    partition_period  int,
    opinion_rating_id bigint,
    rating_type       int,
    poll_id           bigint,
    opinion_id        bigint,
--     version           int,  since a given rating is just a uint64 it doesn't make sense
-- to retrieve it individually
--     parent_opinion_id bigint,  // can't find a need for this right now
    rating            bigint,
    insert_processed  boolean, // Has the initial ingest into CockroachDb finished
    PRIMARY KEY ((partition_period, root_opinion_id), opinion_rating_id)
);

CREATE TABLE feedback_opinion_rating_updates
(
    root_opinion_id   bigint,
    partition_period  int,
    ingest_batch_id   int,
    opinion_rating_id bigint,
    rating_type       int,
    rating            bigint,
    update_processed  boolean,
    PRIMARY KEY ((partition_period, ingest_batch_id), opinion_rating_id)
);

CREATE TABLE feedback_root_opinion_ratings
(
    opinion_id bigint, // the root opinion_id
    version    int,    // this is the latest updated partition_period
    data       blob,
     -- Shouldn't need this column.  In case of batch failures there may be an point when
     -- a later batch succeeded but an earlier has not so, in such a case this wouldn't be of
     -- any use.
    -- last_processed_period text,
    PRIMARY KEY ((opinion_id))
);

CREATE TABLE period_rated_feedback_root_opinion_ids
(
    partition_period    int,
    root_opinion_id     bigint,
    root_opinion_id_mod int,
    PRIMARY KEY ((partition_period, root_opinion_id))
);

CREATE MATERIALIZED VIEW period_rated_feedback_root_opinion_ids_for_ingest AS
SELECT partition_period,
       root_opinion_id_mod,
       root_opinion_id
FROM period_added_to_feedback_root_opinion_ids
WHERE partition_period IS NOT NULL
  AND root_opinion_id_mod IS NOT NULL
  AND root_opinion_id IS NOT NULL
PRIMARY KEY ((partition_period, root_opinion_id_mod), root_opinion_id);
*/

CREATE TABLE feedback_votes
(
    feedback_id bigint PRIMARY KEY,
    num_votes   counter
);
