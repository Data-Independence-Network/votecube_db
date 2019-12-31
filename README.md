# votecube_db
store data base related files


# ScyllaDB

Start development node

docker stop scylla
docker rm scylla
docker run -p 9042:9042 --name scylla -d scylladb/scylla

username: cassandra
password: cassandra

# CockroachDB

docker stop cockroach
docker rm cockroach
docker run -d --name=cockroach -p 26257:26257 -p 8080:8080 cockroachdb/cockroach:v19.2.2 start --insecure

username: root
no password
