#!/bin/bash

set -o errexit

source ./common.sh

echo waiting for replication to be ready...
sleep=3; tries=10
loop1 repcheck my1c my1p.dns.podman $sleep $tries
loop1 repcheck my1c my2p.dns.podman $sleep $tries
loop1 repcheck my1c my3p.dns.podman $sleep $tries
loop1 repcheck my1c my4p.dns.podman $sleep $tries
loop1 repcheck my1c my5p.dns.podman $sleep $tries

echo ensuring we can reach mysqld
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SHOW DATABASES' | grep --quiet mysql
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my2p.dns.podman --execute 'SHOW DATABASES' | grep --quiet mysql
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my3p.dns.podman --execute 'SHOW DATABASES' | grep --quiet mysql
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my4p.dns.podman --execute 'SHOW DATABASES' | grep --quiet mysql
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my5p.dns.podman --execute 'SHOW DATABASES' | grep --quiet mysql

echo pt-table-checksum replicates percona table to all
set +o errexit
podman run --pod=my1p --env=PTDEBUG=0 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my1p.dns.podman,u=root,p=root,P=3306
set -o errexit
# podman run --pod=my2p --env=PTDEBUG=0 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my2p.dns.podman,u=root,p=root,P=3306
# podman run --pod=my3p --env=PTDEBUG=0 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my3p.dns.podman,u=root,p=root,P=3306
# podman run --pod=my4p --env=PTDEBUG=0 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my4p.dns.podman,u=root,p=root,P=3306
# podman run --pod=my5p --env=PTDEBUG=0 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my5p.dns.podman,u=root,p=root,P=3306

until grep --silent percona <<<"$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SHOW DATABASES\G')"; do sleep 5; done;
until grep --silent percona <<<"$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my2p.dns.podman --execute 'SHOW DATABASES\G')"; do sleep 5; done;
until grep --silent percona <<<"$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my3p.dns.podman --execute 'SHOW DATABASES\G')"; do sleep 5; done;
until grep --silent percona <<<"$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my4p.dns.podman --execute 'SHOW DATABASES\G')"; do sleep 5; done;
until grep --silent percona <<<"$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my5p.dns.podman --execute 'SHOW DATABASES\G')"; do sleep 5; done;

podman run --pod=my1p --env=MYSQL_PWD=root percona-toolkit pt-table-sync --sync-to-master h=my1p.dns.podman,u=root,p=root,P=3306 --databases=ptest --tables=dummy --verbose --print
podman run --pod=my1p --env=MYSQL_PWD=root percona-toolkit pt-table-sync --sync-to-master h=my2p.dns.podman,u=root,p=root,P=3306 --databases=ptest --tables=dummy --verbose --print
podman run --pod=my1p --env=MYSQL_PWD=root percona-toolkit pt-table-sync --sync-to-master h=my3p.dns.podman,u=root,p=root,P=3306 --databases=ptest --tables=dummy --verbose --print
podman run --pod=my1p --env=MYSQL_PWD=root percona-toolkit pt-table-sync --sync-to-master h=my4p.dns.podman,u=root,p=root,P=3306 --databases=ptest --tables=dummy --verbose --print
podman run --pod=my1p --env=MYSQL_PWD=root percona-toolkit pt-table-sync --sync-to-master h=my5p.dns.podman,u=root,p=root,P=3306 --databases=ptest --tables=dummy --verbose --print

echo waiting for replication to be ready...
sleep=3; tries=10
loop1 repcheck my1c my1p.dns.podman $sleep $tries
loop1 repcheck my1c my2p.dns.podman $sleep $tries
loop1 repcheck my1c my3p.dns.podman $sleep $tries
loop1 repcheck my1c my4p.dns.podman $sleep $tries
loop1 repcheck my1c my5p.dns.podman $sleep $tries

cat <<'__eot__' >reptest/extra2/20210912_1.sql
DROP DATABASE IF EXISTS ptest;
CREATE DATABASE IF NOT EXISTS ptest;
USE ptest;
CREATE TABLE dummy (id INT(11) NOT NULL auto_increment PRIMARY KEY, name CHAR(5)) engine=innodb;
INSERT INTO dummy VALUES (1, 'a'), (2, 'b');
SELECT * FROM dummy;
__eot__
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SOURCE /tmp/extra2/20210912_1.sql'

until podman exec --env=MYSQL_PWD=root my1c mysql --host=my1p --user=root --execute 'SHOW DATABASES'; do sleep 5; done;
until podman exec --env=MYSQL_PWD=root my2c mysql --host=my2p --user=root --execute 'SHOW DATABASES'; do sleep 5; done;
until podman exec --env=MYSQL_PWD=root my3c mysql --host=my3p --user=root --execute 'SHOW DATABASES'; do sleep 5; done;
until podman exec --env=MYSQL_PWD=root my4c mysql --host=my4p --user=root --execute 'SHOW DATABASES'; do sleep 5; done;
until podman exec --env=MYSQL_PWD=root my5c mysql --host=my5p --user=root --execute 'SHOW DATABASES'; do sleep 5; done;

podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --database=ptest --execute 'SELECT * FROM dummy'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --database=ptest --execute 'SELECT * FROM dummy'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --database=ptest --execute 'SELECT * FROM dummy'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --database=ptest --execute 'SELECT * FROM dummy'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --database=ptest --execute 'SELECT * FROM dummy'

set +o errexit
podman run --pod=my1p --env=PTDEBUG=0 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my1p.dns.podman,u=root,p=root,P=3306
#podman run --pod=my1p --env=PTDEBUG=1 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my2p.dns.podman,u=root,p=root,P=3306
#podman run --pod=my1p --env=PTDEBUG=1 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my3p.dns.podman,u=root,p=root,P=3306
#podman run --pod=my1p --env=PTDEBUG=1 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my4p.dns.podman,u=root,p=root,P=3306
#podman run --pod=my1p --env=PTDEBUG=1 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my5p.dns.podman,u=root,p=root,P=3306
set -o errexit

podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'STOP SLAVE'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my2p.dns.podman --execute 'STOP SLAVE'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my3p.dns.podman --execute 'STOP SLAVE'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my4p.dns.podman --execute 'STOP SLAVE'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my5p.dns.podman --execute 'STOP SLAVE'

cat <<'__eot__' >reptest/extra2/20210913_10.sql
USE ptest;
INSERT INTO dummy (id, name) VALUES (11, 'xxxxx');
-- INSERT INTO dummy (name) VALUES ('xxxxx');
SELECT * FROM dummy;
__eot__
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SOURCE /tmp/extra2/20210913_10.sql'
#podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my2p.dns.podman --execute 'SOURCE /tmp/extra2/20210913_10.sql'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my3p.dns.podman --execute 'SOURCE /tmp/extra2/20210913_10.sql'
#podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my4p.dns.podman --execute 'SOURCE /tmp/extra2/20210913_10.sql'
#podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my5p.dns.podman --execute 'SOURCE /tmp/extra2/20210913_10.sql'

cat <<'__eot__' >reptest/extra2/20210913_20.sql
USE ptest;
-- INSERT INTO dummy (id, name) VALUES (12, 'yyy'); # use this to break stuff
INSERT INTO dummy (name) VALUES ('yyy');
SELECT * FROM dummy;
__eot__
#podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SOURCE /tmp/extra2/20210913_20.sql'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my2p.dns.podman --execute 'SOURCE /tmp/extra2/20210913_20.sql'
#podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my3p.dns.podman --execute 'SOURCE /tmp/extra2/20210913_20.sql'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my4p.dns.podman --execute 'SOURCE /tmp/extra2/20210913_20.sql'
#podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my5p.dns.podman --execute 'SOURCE /tmp/extra2/20210913_20.sql'

echo starting replication
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'START SLAVE'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my2p.dns.podman --execute 'START SLAVE'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my3p.dns.podman --execute 'START SLAVE'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my4p.dns.podman --execute 'START SLAVE'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my5p.dns.podman --execute 'START SLAVE'

echo waiting for replication to be ready...
sleep=3; tries=10
loop1 repcheck my1c my1p.dns.podman $sleep $tries
loop1 repcheck my1c my2p.dns.podman $sleep $tries
loop1 repcheck my1c my3p.dns.podman $sleep $tries
loop1 repcheck my1c my4p.dns.podman $sleep $tries
loop1 repcheck my1c my5p.dns.podman $sleep $tries

set +o errexit
podman run --pod=my1p --env=PTDEBUG=0 --env=MYSQL_PWD=root percona-toolkit pt-table-checksum --replicate=percona.checksums h=my1p.dns.podman,u=root,p=root,P=3306
set -o errexit

podman run --pod=my1p --env=MYSQL_PWD=root percona-toolkit pt-table-sync --sync-to-master h=my1p.dns.podman,u=root,p=root,P=3306 --databases=ptest --tables=dummy --verbose --print

podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --database=ptest --execute 'SELECT * FROM dummy'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --database=ptest --execute 'SELECT * FROM dummy'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --database=ptest --execute 'SELECT * FROM dummy'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --database=ptest --execute 'SELECT * FROM dummy'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --database=ptest --execute 'SELECT * FROM dummy'
