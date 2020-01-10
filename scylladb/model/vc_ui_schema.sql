-- comment out "drop keyspace" when running for the first time
drop keyspace votecube;

create keyspace votecube WITH replication = {'class': 'SimpleStrategy', 'replication_factor' : 1};

use votecube;

CREATE TABLE polls
(
    poll_id   bigint,
    user_id   bigint,
    create_es bigint,
    data      blob,
    PRIMARY KEY (poll_id)
);

CREATE TABLE poll_keys
(
    poll_id   bigint,
    user_id   bigint,
    create_es bigint,
    batch_id  bigint,
    PRIMARY KEY ((poll_id), batch_id)
);

CREATE TABLE opinions
(
    opinion_id bigint,
    poll_id    bigint,
    date       text,
    user_id    bigint,
    create_es  bigint,
    data       blob,
    processed  boolean,
    PRIMARY KEY ((poll_id, date), create_es, opinion_id)
)
            WITH CLUSTERING ORDER BY (create_es DESC);

CREATE TABLE threads
(
    poll_id   bigint,
    user_id   bigint,
    create_es bigint,
    data      blob,
    PRIMARY KEY (poll_id)
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
