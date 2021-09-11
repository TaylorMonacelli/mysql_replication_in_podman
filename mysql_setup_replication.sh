#!/bin/bash

set -o errexit

podman info --debug

# podman login --username mtmonacelli registry.redhat.io $REGISTRY_REDHAT_IO_PASSWORD

podman pull docker.io/perconalab/percona-toolkit:latest

podman ps
podman ps --pod
podman ps -a --pod
podman network ls
podman volume ls
podman pod ls



podman pod stop --ignore my1p
podman pod rm --ignore --force my1p
podman volume exists my1dbdata && podman volume rm --force my1dbdata

podman pod stop --ignore my2p
podman pod rm --ignore --force my2p
podman volume exists my2dbdata && podman volume rm --force my2dbdata

podman pod stop --ignore my3p
podman pod rm --ignore --force my3p
podman volume exists my3dbdata && podman volume rm --force my3dbdata

podman pod stop --ignore my4p
podman pod rm --ignore --force my4p
podman volume exists my4dbdata && podman volume rm --force my4dbdata

podman pod stop --ignore my5p
podman pod rm --ignore --force my5p
podman volume exists my5dbdata && podman volume rm --force my5dbdata


podman network exists replication && podman network rm --force replication

podman ps
podman ps --pod
podman ps -a --pod
podman network ls
podman volume ls
podman pod ls


podman network create replication

podman volume create my1dbdata
podman volume create my2dbdata
podman volume create my3dbdata
podman volume create my4dbdata
podman volume create my5dbdata

rm -rf reptest/


mkdir -p reptest/my1c/extra
mkdir -p reptest/my2c/extra
mkdir -p reptest/my3c/extra
mkdir -p reptest/my4c/extra
mkdir -p reptest/my5c/extra


mkdir -p reptest/my1c
cat <<'__eot__' >reptest/my1c/my.cnf
[mysqld]
bind-address             = my1p.dns.podman
server_id                = 1
log_bin                  = /var/log/mysql/mysql-bin.log
binlog_do_db             = db
__eot__

mkdir -p reptest/my2c
cat <<'__eot__' >reptest/my2c/my.cnf
[mysqld]
bind-address             = my2p.dns.podman
server_id                = 2
log_bin                  = /var/log/mysql/mysql-bin.log
binlog_do_db             = db
__eot__

mkdir -p reptest/my3c
cat <<'__eot__' >reptest/my3c/my.cnf
[mysqld]
bind-address             = my3p.dns.podman
server_id                = 3
log_bin                  = /var/log/mysql/mysql-bin.log
binlog_do_db             = db
__eot__

mkdir -p reptest/my4c
cat <<'__eot__' >reptest/my4c/my.cnf
[mysqld]
bind-address             = my4p.dns.podman
server_id                = 4
log_bin                  = /var/log/mysql/mysql-bin.log
binlog_do_db             = db
__eot__

mkdir -p reptest/my5c
cat <<'__eot__' >reptest/my5c/my.cnf
[mysqld]
bind-address             = my5p.dns.podman
server_id                = 5
log_bin                  = /var/log/mysql/mysql-bin.log
binlog_do_db             = db
__eot__


# pods with bridge mode networking
podman pod create --name=my1p --publish=33061:3306 --network=replication
podman pod create --name=my2p --publish=33062:3306 --network=replication
podman pod create --name=my3p --publish=33063:3306 --network=replication
podman pod create --name=my4p --publish=33064:3306 --network=replication
podman pod create --name=my5p --publish=33065:3306 --network=replication

# mysqld containers
podman container create --name=my1c --pod=my1p --health-start-period=80s --log-driver=journald --volume=./reptest/my1c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my1c/extra:/tmp/extra:Z --volume=my1dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
podman container create --name=my2c --pod=my2p --health-start-period=80s --log-driver=journald --volume=./reptest/my2c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my2c/extra:/tmp/extra:Z --volume=my2dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
podman container create --name=my3c --pod=my3p --health-start-period=80s --log-driver=journald --volume=./reptest/my3c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my3c/extra:/tmp/extra:Z --volume=my3dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
podman container create --name=my4c --pod=my4p --health-start-period=80s --log-driver=journald --volume=./reptest/my4c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my4c/extra:/tmp/extra:Z --volume=my4dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
podman container create --name=my5c --pod=my5p --health-start-period=80s --log-driver=journald --volume=./reptest/my5c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my5c/extra:/tmp/extra:Z --volume=my5dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80


podman pod start my1p
podman pod start my2p
podman pod start my3p
podman pod start my4p
podman pod start my5p


podman wait my1c --condition=running
podman wait my2c --condition=running
podman wait my3c --condition=running
podman wait my4c --condition=running
podman wait my5c --condition=running


podman volume inspect my1dbdata
podman volume inspect my2dbdata
podman volume inspect my3dbdata
podman volume inspect my4dbdata
podman volume inspect my5dbdata

podman ps
podman ps --pod
podman ps -a --pod
podman network ls
podman volume ls
podman pod ls



until podman exec --tty --interactive my1c mysql --host=my1p --user=joe --password=joe --execute "SHOW DATABASES;"; do sleep 5; done;
until podman exec --tty --interactive my2c mysql --host=my2p --user=joe --password=joe --execute "SHOW DATABASES;"; do sleep 5; done;
until podman exec --tty --interactive my3c mysql --host=my3p --user=joe --password=joe --execute "SHOW DATABASES;"; do sleep 5; done;
until podman exec --tty --interactive my4c mysql --host=my4p --user=joe --password=joe --execute "SHOW DATABASES;"; do sleep 5; done;
until podman exec --tty --interactive my5c mysql --host=my5p --user=joe --password=joe --execute "SHOW DATABASES;"; do sleep 5; done;


podman inspect my1c | grep -i ipaddr
ip1=$(podman inspect my1c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
echo $ip1
podman inspect my2c | grep -i ipaddr
ip2=$(podman inspect my2c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
echo $ip2
podman inspect my3c | grep -i ipaddr
ip3=$(podman inspect my3c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
echo $ip3
podman inspect my4c | grep -i ipaddr
ip4=$(podman inspect my4c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
echo $ip4
podman inspect my5c | grep -i ipaddr
ip5=$(podman inspect my5c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
echo $ip5


# mysqladmin --port=3306 --host=$ip1 --user=joe --password=joe password ''
# mysqladmin --port=3306 --host=$ip2 --user=joe --password=joe password ''
# mysqladmin --port=3306 --host=$ip3 --user=joe --password=joe password ''
# mysqladmin --port=3306 --host=$ip4 --user=joe --password=joe password ''
# mysqladmin --port=3306 --host=$ip5 --user=joe --password=joe password ''

# ip test

mysql --port=3306 --host=$ip1 --user=joe --password=joe --execute "SHOW DATABASES;"
mysql --port=3306 --host=$ip2 --user=joe --password=joe --execute "SHOW DATABASES;"
mysql --port=3306 --host=$ip3 --user=joe --password=joe --execute "SHOW DATABASES;"
mysql --port=3306 --host=$ip4 --user=joe --password=joe --execute "SHOW DATABASES;"
mysql --port=3306 --host=$ip5 --user=joe --password=joe --execute "SHOW DATABASES;"

# FIXME: NoneNoneNoneNoneNone

# dns test


time podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my1c mysql --user=root --password=root --host=my2p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my1c mysql --user=root --password=root --host=my3p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my1c mysql --user=root --password=root --host=my4p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my1c mysql --user=root --password=root --host=my5p.dns.podman --execute 'SHOW DATABASES;' </dev/null

time podman exec --tty --interactive my2c mysql --user=root --password=root --host=my1p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my2c mysql --user=root --password=root --host=my3p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my2c mysql --user=root --password=root --host=my4p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my2c mysql --user=root --password=root --host=my5p.dns.podman --execute 'SHOW DATABASES;' </dev/null

time podman exec --tty --interactive my3c mysql --user=root --password=root --host=my1p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my3c mysql --user=root --password=root --host=my2p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my3c mysql --user=root --password=root --host=my4p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my3c mysql --user=root --password=root --host=my5p.dns.podman --execute 'SHOW DATABASES;' </dev/null

time podman exec --tty --interactive my4c mysql --user=root --password=root --host=my1p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my4c mysql --user=root --password=root --host=my2p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my4c mysql --user=root --password=root --host=my3p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my4c mysql --user=root --password=root --host=my5p.dns.podman --execute 'SHOW DATABASES;' </dev/null

time podman exec --tty --interactive my5c mysql --user=root --password=root --host=my1p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my5c mysql --user=root --password=root --host=my2p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my5c mysql --user=root --password=root --host=my3p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my5c mysql --user=root --password=root --host=my4p.dns.podman --execute 'SHOW DATABASES;' </dev/null
time podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p.dns.podman --execute 'SHOW DATABASES;' </dev/null

podman ps
podman ps --pod
podman ps -a --pod
podman network ls
podman volume ls
podman pod ls

replica_ip=$(podman inspect my2c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
# 'repl'@'$replica_ip' on my1c:
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "CREATE USER 'repl'@'$replica_ip' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'$replica_ip';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'my2p.dns.podname' on my1c:
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "CREATE USER 'repl'@'my2p.dns.podname' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my2p.dns.podname';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'my2p' on my1c:
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "CREATE USER 'repl'@'my2p' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my2p';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'%' on my1c:
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "FLUSH PRIVILEGES;" </dev/null

replica_ip=$(podman inspect my3c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
# 'repl'@'$replica_ip' on my2c:
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "CREATE USER 'repl'@'$replica_ip' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'$replica_ip';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'my3p.dns.podname' on my2c:
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "CREATE USER 'repl'@'my3p.dns.podname' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my3p.dns.podname';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'my3p' on my2c:
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "CREATE USER 'repl'@'my3p' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my3p';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'%' on my2c:
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "FLUSH PRIVILEGES;" </dev/null

replica_ip=$(podman inspect my4c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
# 'repl'@'$replica_ip' on my3c:
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "CREATE USER 'repl'@'$replica_ip' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'$replica_ip';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'my4p.dns.podname' on my3c:
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "CREATE USER 'repl'@'my4p.dns.podname' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my4p.dns.podname';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'my4p' on my3c:
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "CREATE USER 'repl'@'my4p' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my4p';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'%' on my3c:
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "FLUSH PRIVILEGES;" </dev/null

replica_ip=$(podman inspect my5c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
# 'repl'@'$replica_ip' on my4c:
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "CREATE USER 'repl'@'$replica_ip' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'$replica_ip';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'my5p.dns.podname' on my4c:
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "CREATE USER 'repl'@'my5p.dns.podname' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my5p.dns.podname';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'my5p' on my4c:
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "CREATE USER 'repl'@'my5p' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my5p';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'%' on my4c:
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "FLUSH PRIVILEGES;" </dev/null

replica_ip=$(podman inspect my1c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
# 'repl'@'$replica_ip' on my5c:
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "CREATE USER 'repl'@'$replica_ip' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'$replica_ip';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'my1p.dns.podname' on my5c:
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "CREATE USER 'repl'@'my1p.dns.podname' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my1p.dns.podname';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'my1p' on my5c:
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "CREATE USER 'repl'@'my1p' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my1p';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "FLUSH PRIVILEGES;" </dev/null
# 'repl'@'%' on my5c:
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "FLUSH PRIVILEGES;" </dev/null


: <<'END_COMMENT'
replica_ip=$(podman inspect my2c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "DROP USER 'repl'@'$replica_ip';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "DROP USER 'repl'@'my2p.dns.podname';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "DROP USER 'repl'@'my2p';" </dev/null
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p --execute "DROP USER 'repl'@'%';" </dev/null

replica_ip=$(podman inspect my3c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "DROP USER 'repl'@'$replica_ip';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "DROP USER 'repl'@'my3p.dns.podname';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "DROP USER 'repl'@'my3p';" </dev/null
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p --execute "DROP USER 'repl'@'%';" </dev/null

replica_ip=$(podman inspect my4c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "DROP USER 'repl'@'$replica_ip';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "DROP USER 'repl'@'my4p.dns.podname';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "DROP USER 'repl'@'my4p';" </dev/null
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p --execute "DROP USER 'repl'@'%';" </dev/null

replica_ip=$(podman inspect my5c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "DROP USER 'repl'@'$replica_ip';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "DROP USER 'repl'@'my5p.dns.podname';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "DROP USER 'repl'@'my5p';" </dev/null
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p --execute "DROP USER 'repl'@'%';" </dev/null

replica_ip=$(podman inspect my1c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "DROP USER 'repl'@'$replica_ip';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "DROP USER 'repl'@'my1p.dns.podname';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "DROP USER 'repl'@'my1p';" </dev/null
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p --execute "DROP USER 'repl'@'%';" </dev/null

END_COMMENT
mkdir -p reptest/my1c/extra
replica_ip=$(podman inspect my2c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
cat <<__eot__ >reptest/my1c/extra/user.sql
__eot__
cat reptest/my1c/extra/user.sql

mkdir -p reptest/my2c/extra
replica_ip=$(podman inspect my3c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
cat <<__eot__ >reptest/my2c/extra/user.sql
__eot__
cat reptest/my2c/extra/user.sql

mkdir -p reptest/my3c/extra
replica_ip=$(podman inspect my4c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
cat <<__eot__ >reptest/my3c/extra/user.sql
__eot__
cat reptest/my3c/extra/user.sql

mkdir -p reptest/my4c/extra
replica_ip=$(podman inspect my5c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
cat <<__eot__ >reptest/my4c/extra/user.sql
__eot__
cat reptest/my4c/extra/user.sql

mkdir -p reptest/my5c/extra
replica_ip=$(podman inspect my1c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
cat <<__eot__ >reptest/my5c/extra/user.sql
__eot__
cat reptest/my5c/extra/user.sql

podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p.dns.podman --execute 'SOURCE /tmp/extra/user.sql;'
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p.dns.podman --execute 'SOURCE /tmp/extra/user.sql;'
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p.dns.podman --execute 'SOURCE /tmp/extra/user.sql;'
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p.dns.podman --execute 'SOURCE /tmp/extra/user.sql;'
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p.dns.podman --execute 'SOURCE /tmp/extra/user.sql;'

# desc mysql.user;
podman exec --tty --interactive my1c mysql --user=root --password=root --host=my1p.dns.podman --execute 'SELECT User, Host from mysql.user ORDER BY user;'
podman exec --tty --interactive my2c mysql --user=root --password=root --host=my2p.dns.podman --execute 'SELECT User, Host from mysql.user ORDER BY user;'
podman exec --tty --interactive my3c mysql --user=root --password=root --host=my3p.dns.podman --execute 'SELECT User, Host from mysql.user ORDER BY user;'
podman exec --tty --interactive my4c mysql --user=root --password=root --host=my4p.dns.podman --execute 'SELECT User, Host from mysql.user ORDER BY user;'
podman exec --tty --interactive my5c mysql --user=root --password=root --host=my5p.dns.podman --execute 'SELECT User, Host from mysql.user ORDER BY user;'
