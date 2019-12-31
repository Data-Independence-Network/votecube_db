-- comment out "drop keyspace" when running for the first time
drop keyspace votecube;

create keyspace votecube WITH replication = {'class': 'SimpleStrategy', 'replication_factor' : 1};

use votecube;

CREATE TABLE opinions
(
    opinion_id bigint,
    poll_id    bigint,
    date       text,
    user_id    bigint,
    create_dt  timestamp,
    data       blob,
    PRIMARY KEY ((poll_id, date), opinion_id)
);

CREATE TABLE threads
(
    thread_id bigint,
    poll_id    bigint,
    date       text,
    user_id    bigint,
    create_dt  timestamp,
    data       blob,
    PRIMARY KEY ((poll_id, date), thread_id)
);

-- insert into opinions (opinion_id, poll_id, date, user_id, create_dt, data)
-- values(1, 1, '2019-12-31', 1, toTimestamp(now()), textAsBlob('hello ScyllaDB!'));
--
-- insert into threads (thread_id, poll_id, date, user_id, create_dt, data)
-- values(2, 1, '2019-12-31', 1, toTimestamp(now()), textAsBlob('hello thread!'));

-- select * from threads;
