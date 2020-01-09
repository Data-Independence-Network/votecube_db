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
    create_es  bigint,
    data       blob,
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

-- insert into opinions (opinion_id, poll_id, date, user_id, create_es, data)
-- values(1, 1, '2020-01-09', 1, 1578602993, textAsBlob('hello ScyllaDB!'));
--
-- insert into threads (poll_id, user_id, create_es, data)
-- values(1, 1, 1578602995, textAsBlob('hello thread!'));

-- select * from threads;
