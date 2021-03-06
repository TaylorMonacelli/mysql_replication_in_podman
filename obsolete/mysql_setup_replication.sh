#!/bin/bash

set -o errexit

podman info --debug
mysql --version

# destroy everything except for podman network for sanity check
: <<'END_COMMENT'
podman pod stop --ignore --all; podman container stop --ignore --all; podman system prune --all --force; podman pod rm --all --force; podman container rm --all --force; podman volume rm --all --force; for network in $(podman network ls --format json | jq -r '.[].Name'); do if [[ "$network" !=  "podman" ]]; then podman network exists $network && podman network rm $network; fi; done; podman ps; podman ps --pod; podman ps -a --pod; podman network ls; podman volume ls; podman pod ls  #destroyall
END_COMMENT

# FIXME: reminder: i'm using appveyor secrets to decrypt this from ./auth.json.enc, thats obscure
# podman login --authfile $HOME/.config/containers/auth.json registry.redhat.io

podman pull docker.io/perconalab/percona-toolkit:latest

podman ps
podman ps --pod
podman ps -a --pod
podman network ls
podman volume ls
podman pod ls

if ! command -v bats &>/dev/null; then
    git clone --depth 1 https://github.com/sstephenson/bats.git /usr/local/src/bats
    pushd /usr/local/src/bats
    ./install.sh /usr/local
    popd
fi

podman container stop --ignore my1c
podman container stop --ignore my2c
podman container stop --ignore my3c
podman container stop --ignore my4c
podman container stop --ignore my5c

podman pod stop --ignore my1p
podman pod rm --ignore --force my1p

podman pod stop --ignore my2p
podman pod rm --ignore --force my2p

podman pod stop --ignore my3p
podman pod rm --ignore --force my3p

podman pod stop --ignore my4p
podman pod rm --ignore --force my4p

podman pod stop --ignore my5p
podman pod rm --ignore --force my5p

podman volume exists my1dbdata && podman volume rm --force my1dbdata
podman volume exists my2dbdata && podman volume rm --force my2dbdata
podman volume exists my3dbdata && podman volume rm --force my3dbdata
podman volume exists my4dbdata && podman volume rm --force my4dbdata
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

# start clean
[[ -d 'reptest' ]] && mv reptest reptest.$(date +%s)

mkdir -p reptest/extra2
mkdir -p reptest/my1c/extra
mkdir -p reptest/my2c/extra
mkdir -p reptest/my3c/extra
mkdir -p reptest/my4c/extra
mkdir -p reptest/my5c/extra

mkdir -p reptest/my1c
cat <<'__eot__' >reptest/my1c/my.cnf
[mysqld]
bind-address                   = my1p.dns.podman
server_id                      = 1
auto_increment_offset          = 1
auto_increment_increment       = 5
# log_bin                      = /var/log/mysql/mysql-bin.log
datadir                        = /var/log/mysql
log_bin                        = mysql-bin.log
#binlog_format                  = ROW
#binlog_format                  = MIXED
binlog_format                  = STATEMENT
log_slave_updates              = ON
skip_name_resolve              = FALSE

; ignore duplicate key errors
; slave-skip-errors              = 1062
; slave-skip-errors                = 1050,1062,1032
sql_mode                       =
innodb_flush_log_at_trx_commit = 1
sync_binlog                    = 1
__eot__
cat reptest/my1c/my.cnf

mkdir -p reptest/my2c
cat <<'__eot__' >reptest/my2c/my.cnf
[mysqld]
bind-address                   = my2p.dns.podman
server_id                      = 2
auto_increment_offset          = 2
auto_increment_increment       = 5
# log_bin                      = /var/log/mysql/mysql-bin.log
datadir                        = /var/log/mysql
log_bin                        = mysql-bin.log
#binlog_format                  = ROW
#binlog_format                  = MIXED
binlog_format                  = STATEMENT
log_slave_updates              = ON
skip_name_resolve              = FALSE

; ignore duplicate key errors
; slave-skip-errors              = 1062
; slave-skip-errors                = 1050,1062,1032
sql_mode                       =
innodb_flush_log_at_trx_commit = 1
sync_binlog                    = 1
__eot__
cat reptest/my2c/my.cnf

mkdir -p reptest/my3c
cat <<'__eot__' >reptest/my3c/my.cnf
[mysqld]
bind-address                   = my3p.dns.podman
server_id                      = 3
auto_increment_offset          = 3
auto_increment_increment       = 5
# log_bin                      = /var/log/mysql/mysql-bin.log
datadir                        = /var/log/mysql
log_bin                        = mysql-bin.log
#binlog_format                  = ROW
#binlog_format                  = MIXED
binlog_format                  = STATEMENT
log_slave_updates              = ON
skip_name_resolve              = FALSE

; ignore duplicate key errors
; slave-skip-errors              = 1062
; slave-skip-errors                = 1050,1062,1032
sql_mode                       =
innodb_flush_log_at_trx_commit = 1
sync_binlog                    = 1
__eot__
cat reptest/my3c/my.cnf

mkdir -p reptest/my4c
cat <<'__eot__' >reptest/my4c/my.cnf
[mysqld]
bind-address                   = my4p.dns.podman
server_id                      = 4
auto_increment_offset          = 4
auto_increment_increment       = 5
# log_bin                      = /var/log/mysql/mysql-bin.log
datadir                        = /var/log/mysql
log_bin                        = mysql-bin.log
#binlog_format                  = ROW
#binlog_format                  = MIXED
binlog_format                  = STATEMENT
log_slave_updates              = ON
skip_name_resolve              = FALSE

; ignore duplicate key errors
; slave-skip-errors              = 1062
; slave-skip-errors                = 1050,1062,1032
sql_mode                       =
innodb_flush_log_at_trx_commit = 1
sync_binlog                    = 1
__eot__
cat reptest/my4c/my.cnf

mkdir -p reptest/my5c
cat <<'__eot__' >reptest/my5c/my.cnf
[mysqld]
bind-address                   = my5p.dns.podman
server_id                      = 5
auto_increment_offset          = 5
auto_increment_increment       = 5
# log_bin                      = /var/log/mysql/mysql-bin.log
datadir                        = /var/log/mysql
log_bin                        = mysql-bin.log
#binlog_format                  = ROW
#binlog_format                  = MIXED
binlog_format                  = STATEMENT
log_slave_updates              = ON
skip_name_resolve              = FALSE

; ignore duplicate key errors
; slave-skip-errors              = 1062
; slave-skip-errors                = 1050,1062,1032
sql_mode                       =
innodb_flush_log_at_trx_commit = 1
sync_binlog                    = 1
__eot__
cat reptest/my5c/my.cnf

# pods with bridge mode networking
podman pod create --name=my1p --publish=33061:3306 --network=replication
podman pod create --name=my2p --publish=33062:3306 --network=replication
podman pod create --name=my3p --publish=33063:3306 --network=replication
podman pod create --name=my4p --publish=33064:3306 --network=replication
podman pod create --name=my5p --publish=33065:3306 --network=replication

# mysqld containers
#podman container create --name=my1c --pod=my1p --health-start-period=80s --log-driver=journald --healthcheck-interval=0 --health-retries=10 --health-timeout=30s --healthcheck-command 'CMD-SHELL mysqladmin ping -h localhost || exit 1' --healthcheck-command 'mysql --user=root --password="root" --host=my1p --execute "USE mysql" || exit 1' --volume=./reptest/my1c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my1c/extra:/tmp/extra:Z --volume=./reptest/extra2:/tmp/extra2:Z --volume=my1dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
podman container create --name=my1c --pod=my1p --health-start-period=80s --log-driver=journald --healthcheck-interval=0 --health-retries=10 --health-timeout=30s --healthcheck-command 'CMD-SHELL mysqladmin ping -h localhost || exit 1' --healthcheck-command 'mysql --user=root --password="root" --host=my1p --execute "USE mysql" || exit 1' --volume=./reptest/my1c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my1c/extra:/tmp/extra:Z --volume=./reptest/extra2:/tmp/extra2:Z --volume=my1dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
#podman container create --name=my2c --pod=my2p --health-start-period=80s --log-driver=journald --healthcheck-interval=0 --health-retries=10 --health-timeout=30s --healthcheck-command 'CMD-SHELL mysqladmin ping -h localhost || exit 1' --healthcheck-command 'mysql --user=root --password="root" --host=my2p --execute "USE mysql" || exit 1' --volume=./reptest/my2c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my2c/extra:/tmp/extra:Z --volume=./reptest/extra2:/tmp/extra2:Z --volume=my2dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
podman container create --name=my2c --pod=my2p --health-start-period=80s --log-driver=journald --healthcheck-interval=0 --health-retries=10 --health-timeout=30s --healthcheck-command 'CMD-SHELL mysqladmin ping -h localhost || exit 1' --healthcheck-command 'mysql --user=root --password="root" --host=my2p --execute "USE mysql" || exit 1' --volume=./reptest/my2c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my2c/extra:/tmp/extra:Z --volume=./reptest/extra2:/tmp/extra2:Z --volume=my2dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
#podman container create --name=my3c --pod=my3p --health-start-period=80s --log-driver=journald --healthcheck-interval=0 --health-retries=10 --health-timeout=30s --healthcheck-command 'CMD-SHELL mysqladmin ping -h localhost || exit 1' --healthcheck-command 'mysql --user=root --password="root" --host=my3p --execute "USE mysql" || exit 1' --volume=./reptest/my3c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my3c/extra:/tmp/extra:Z --volume=./reptest/extra2:/tmp/extra2:Z --volume=my3dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
podman container create --name=my3c --pod=my3p --health-start-period=80s --log-driver=journald --healthcheck-interval=0 --health-retries=10 --health-timeout=30s --healthcheck-command 'CMD-SHELL mysqladmin ping -h localhost || exit 1' --healthcheck-command 'mysql --user=root --password="root" --host=my3p --execute "USE mysql" || exit 1' --volume=./reptest/my3c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my3c/extra:/tmp/extra:Z --volume=./reptest/extra2:/tmp/extra2:Z --volume=my3dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
#podman container create --name=my4c --pod=my4p --health-start-period=80s --log-driver=journald --healthcheck-interval=0 --health-retries=10 --health-timeout=30s --healthcheck-command 'CMD-SHELL mysqladmin ping -h localhost || exit 1' --healthcheck-command 'mysql --user=root --password="root" --host=my4p --execute "USE mysql" || exit 1' --volume=./reptest/my4c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my4c/extra:/tmp/extra:Z --volume=./reptest/extra2:/tmp/extra2:Z --volume=my4dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
podman container create --name=my4c --pod=my4p --health-start-period=80s --log-driver=journald --healthcheck-interval=0 --health-retries=10 --health-timeout=30s --healthcheck-command 'CMD-SHELL mysqladmin ping -h localhost || exit 1' --healthcheck-command 'mysql --user=root --password="root" --host=my4p --execute "USE mysql" || exit 1' --volume=./reptest/my4c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my4c/extra:/tmp/extra:Z --volume=./reptest/extra2:/tmp/extra2:Z --volume=my4dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
#podman container create --name=my5c --pod=my5p --health-start-period=80s --log-driver=journald --healthcheck-interval=0 --health-retries=10 --health-timeout=30s --healthcheck-command 'CMD-SHELL mysqladmin ping -h localhost || exit 1' --healthcheck-command 'mysql --user=root --password="root" --host=my5p --execute "USE mysql" || exit 1' --volume=./reptest/my5c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my5c/extra:/tmp/extra:Z --volume=./reptest/extra2:/tmp/extra2:Z --volume=my5dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
podman container create --name=my5c --pod=my5p --health-start-period=80s --log-driver=journald --healthcheck-interval=0 --health-retries=10 --health-timeout=30s --healthcheck-command 'CMD-SHELL mysqladmin ping -h localhost || exit 1' --healthcheck-command 'mysql --user=root --password="root" --host=my5p --execute "USE mysql" || exit 1' --volume=./reptest/my5c/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/my5c/extra:/tmp/extra:Z --volume=./reptest/extra2:/tmp/extra2:Z --volume=my5dbdata:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD=root --env=MYSQL_USER=joe --env=MYSQL_PASSWORD=joe --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80

podman pod start my1p
podman pod start my2p
podman pod start my3p
podman pod start my4p
podman pod start my5p

until podman healthcheck run my1c </dev/null; do sleep 5; done
until podman healthcheck run my2c </dev/null; do sleep 5; done
until podman healthcheck run my3c </dev/null; do sleep 5; done
until podman healthcheck run my4c </dev/null; do sleep 5; done
until podman healthcheck run my5c </dev/null; do sleep 5; done

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

until podman exec --env=MYSQL_PWD=joe my1c mysql --host=my1p --user=joe --execute 'SHOW DATABASES'; do sleep 5; done
until podman exec --env=MYSQL_PWD=joe my2c mysql --host=my2p --user=joe --execute 'SHOW DATABASES'; do sleep 5; done
until podman exec --env=MYSQL_PWD=joe my3c mysql --host=my3p --user=joe --execute 'SHOW DATABASES'; do sleep 5; done
until podman exec --env=MYSQL_PWD=joe my4c mysql --host=my4p --user=joe --execute 'SHOW DATABASES'; do sleep 5; done
until podman exec --env=MYSQL_PWD=joe my5c mysql --host=my5p --user=joe --execute 'SHOW DATABASES'; do sleep 5; done

until podman exec --env=MYSQL_PWD=root my1c mysql --host=my1p --user=root --execute 'SHOW DATABASES'; do sleep 5; done
until podman exec --env=MYSQL_PWD=root my2c mysql --host=my2p --user=root --execute 'SHOW DATABASES'; do sleep 5; done
until podman exec --env=MYSQL_PWD=root my3c mysql --host=my3p --user=root --execute 'SHOW DATABASES'; do sleep 5; done
until podman exec --env=MYSQL_PWD=root my4c mysql --host=my4p --user=root --execute 'SHOW DATABASES'; do sleep 5; done
until podman exec --env=MYSQL_PWD=root my5c mysql --host=my5p --user=root --execute 'SHOW DATABASES'; do sleep 5; done

ip1=$(podman inspect my1c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
echo $ip1
ip2=$(podman inspect my2c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
echo $ip2
ip3=$(podman inspect my3c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
echo $ip3
ip4=$(podman inspect my4c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
echo $ip4
ip5=$(podman inspect my5c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
echo $ip5

# mysqladmin --port=3306 --host=$ip1 --user=joe --password=joe password ''
# mysqladmin --port=3306 --host=$ip2 --user=joe --password=joe password ''
# mysqladmin --port=3306 --host=$ip3 --user=joe --password=joe password ''
# mysqladmin --port=3306 --host=$ip4 --user=joe --password=joe password ''
# mysqladmin --port=3306 --host=$ip5 --user=joe --password=joe password ''

# ip test

MYSQL_PWD=joe mysql --port=3306 --host=$ip1 --user=joe --execute 'SHOW DATABASES' </dev/null
MYSQL_PWD=joe mysql --port=3306 --host=$ip2 --user=joe --execute 'SHOW DATABASES' </dev/null
MYSQL_PWD=joe mysql --port=3306 --host=$ip3 --user=joe --execute 'SHOW DATABASES' </dev/null
MYSQL_PWD=joe mysql --port=3306 --host=$ip4 --user=joe --execute 'SHOW DATABASES' </dev/null
MYSQL_PWD=joe mysql --port=3306 --host=$ip5 --user=joe --execute 'SHOW DATABASES' </dev/null

# FIXME: NoneNoneNoneNoneNone

# dns test

time podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my2p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my3p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my4p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my5p.dns.podman --execute 'SHOW DATABASES'

time podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my1p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my3p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my4p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my5p.dns.podman --execute 'SHOW DATABASES'

time podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my1p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my2p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my4p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my5p.dns.podman --execute 'SHOW DATABASES'

time podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my1p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my2p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my3p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my5p.dns.podman --execute 'SHOW DATABASES'

time podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my1p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my2p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my3p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my4p.dns.podman --execute 'SHOW DATABASES'
time podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'SHOW DATABASES'

podman ps
podman ps --pod
podman ps -a --pod
podman network ls
podman volume ls
podman pod ls

replica_ip=$(podman inspect my2c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
# 'repl'@'$replica_ip' on my1c:
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "CREATE USER 'repl'@'$replica_ip' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'FLUSH PRIVILEGES'
# 'repl'@'my2p.dns.podname' on my1c:
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "CREATE USER 'repl'@'my2p.dns.podname' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my2p.dns.podname'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'FLUSH PRIVILEGES'
# 'repl'@'my2p' on my1c:
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "CREATE USER 'repl'@'my2p' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my2p'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'FLUSH PRIVILEGES'
# 'repl'@'%' on my1c:
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'FLUSH PRIVILEGES'

replica_ip=$(podman inspect my3c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
# 'repl'@'$replica_ip' on my2c:
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "CREATE USER 'repl'@'$replica_ip' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'FLUSH PRIVILEGES'
# 'repl'@'my3p.dns.podname' on my2c:
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "CREATE USER 'repl'@'my3p.dns.podname' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my3p.dns.podname'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'FLUSH PRIVILEGES'
# 'repl'@'my3p' on my2c:
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "CREATE USER 'repl'@'my3p' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my3p'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'FLUSH PRIVILEGES'
# 'repl'@'%' on my2c:
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'FLUSH PRIVILEGES'

replica_ip=$(podman inspect my4c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
# 'repl'@'$replica_ip' on my3c:
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "CREATE USER 'repl'@'$replica_ip' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'FLUSH PRIVILEGES'
# 'repl'@'my4p.dns.podname' on my3c:
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "CREATE USER 'repl'@'my4p.dns.podname' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my4p.dns.podname'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'FLUSH PRIVILEGES'
# 'repl'@'my4p' on my3c:
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "CREATE USER 'repl'@'my4p' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my4p'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'FLUSH PRIVILEGES'
# 'repl'@'%' on my3c:
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'FLUSH PRIVILEGES'

replica_ip=$(podman inspect my5c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
# 'repl'@'$replica_ip' on my4c:
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "CREATE USER 'repl'@'$replica_ip' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'FLUSH PRIVILEGES'
# 'repl'@'my5p.dns.podname' on my4c:
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "CREATE USER 'repl'@'my5p.dns.podname' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my5p.dns.podname'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'FLUSH PRIVILEGES'
# 'repl'@'my5p' on my4c:
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "CREATE USER 'repl'@'my5p' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my5p'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'FLUSH PRIVILEGES'
# 'repl'@'%' on my4c:
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'FLUSH PRIVILEGES'

replica_ip=$(podman inspect my1c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
# 'repl'@'$replica_ip' on my5c:
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "CREATE USER 'repl'@'$replica_ip' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'FLUSH PRIVILEGES'
# 'repl'@'my1p.dns.podname' on my5c:
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "CREATE USER 'repl'@'my1p.dns.podname' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my1p.dns.podname'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'FLUSH PRIVILEGES'
# 'repl'@'my1p' on my5c:
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "CREATE USER 'repl'@'my1p' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'my1p'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'FLUSH PRIVILEGES'
# 'repl'@'%' on my5c:
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'FLUSH PRIVILEGES'

podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'FLUSH TABLES WITH READ LOCK'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'FLUSH TABLES WITH READ LOCK'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'FLUSH TABLES WITH READ LOCK'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'FLUSH TABLES WITH READ LOCK'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'FLUSH TABLES WITH READ LOCK'

podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'UNLOCK TABLES'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'UNLOCK TABLES'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'UNLOCK TABLES'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'UNLOCK TABLES'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'UNLOCK TABLES'

podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'CREATE DATABASE IF NOT EXISTS dummy'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'CREATE DATABASE IF NOT EXISTS dummy'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'CREATE DATABASE IF NOT EXISTS dummy'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'CREATE DATABASE IF NOT EXISTS dummy'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'CREATE DATABASE IF NOT EXISTS dummy'

: <<'END_COMMENT'
# workaround for mysql 5.6: GRANT USAGE ON *.* TO...
replica_ip=$(podman inspect my2c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "GRANT USAGE ON *.* TO 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "DROP USER 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "GRANT USAGE ON *.* TO 'repl'@'my2p.dns.podname'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "DROP USER 'repl'@'my2p.dns.podname'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "GRANT USAGE ON *.* TO 'repl'@'my2p'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "DROP USER 'repl'@'my2p'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "GRANT USAGE ON *.* TO 'repl'@'%'"
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute "DROP USER 'repl'@'%'"

replica_ip=$(podman inspect my3c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "GRANT USAGE ON *.* TO 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "DROP USER 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "GRANT USAGE ON *.* TO 'repl'@'my3p.dns.podname'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "DROP USER 'repl'@'my3p.dns.podname'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "GRANT USAGE ON *.* TO 'repl'@'my3p'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "DROP USER 'repl'@'my3p'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "GRANT USAGE ON *.* TO 'repl'@'%'"
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute "DROP USER 'repl'@'%'"

replica_ip=$(podman inspect my4c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "GRANT USAGE ON *.* TO 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "DROP USER 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "GRANT USAGE ON *.* TO 'repl'@'my4p.dns.podname'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "DROP USER 'repl'@'my4p.dns.podname'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "GRANT USAGE ON *.* TO 'repl'@'my4p'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "DROP USER 'repl'@'my4p'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "GRANT USAGE ON *.* TO 'repl'@'%'"
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute "DROP USER 'repl'@'%'"

replica_ip=$(podman inspect my5c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "GRANT USAGE ON *.* TO 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "DROP USER 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "GRANT USAGE ON *.* TO 'repl'@'my5p.dns.podname'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "DROP USER 'repl'@'my5p.dns.podname'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "GRANT USAGE ON *.* TO 'repl'@'my5p'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "DROP USER 'repl'@'my5p'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "GRANT USAGE ON *.* TO 'repl'@'%'"
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute "DROP USER 'repl'@'%'"

replica_ip=$(podman inspect my1c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "GRANT USAGE ON *.* TO 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "DROP USER 'repl'@'$replica_ip'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "GRANT USAGE ON *.* TO 'repl'@'my1p.dns.podname'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "DROP USER 'repl'@'my1p.dns.podname'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "GRANT USAGE ON *.* TO 'repl'@'my1p'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "DROP USER 'repl'@'my1p'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "GRANT USAGE ON *.* TO 'repl'@'%'"
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute "DROP USER 'repl'@'%'"

END_COMMENT

cat <<'__eot__' >reptest/extra2/extra2.sql
CREATE DATABASE IF NOT EXISTS sales;
USE sales;
CREATE TABLE IF NOT EXISTS user
   (
   user_id int,
   fn varchar(30),
   ln varchar(30),
   age int
   );
INSERT INTO user (fn, ln, age) VALUES ('tom', 'mccormick', 40);
__eot__

# podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SOURCE /tmp/extra2/extra2.sql'
# podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'SOURCE /tmp/extra2/extra2.sql'
# podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'SOURCE /tmp/extra2/extra2.sql'
# podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'SOURCE /tmp/extra2/extra2.sql'
# podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'SOURCE /tmp/extra2/extra2.sql'

mkdir -p reptest/my1c/extra
replica_ip=$(podman inspect my2c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
cat <<'__eot__' >reptest/my1c/extra/extra.sql
-- placeholder
__eot__
# cat reptest/my1c/extra/extra.sql
mkdir -p reptest/my2c/extra
replica_ip=$(podman inspect my3c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
cat <<'__eot__' >reptest/my2c/extra/extra.sql
-- placeholder
__eot__
# cat reptest/my2c/extra/extra.sql
mkdir -p reptest/my3c/extra
replica_ip=$(podman inspect my4c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
cat <<'__eot__' >reptest/my3c/extra/extra.sql
-- placeholder
__eot__
# cat reptest/my3c/extra/extra.sql
mkdir -p reptest/my4c/extra
replica_ip=$(podman inspect my5c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
cat <<'__eot__' >reptest/my4c/extra/extra.sql
-- placeholder
__eot__
# cat reptest/my4c/extra/extra.sql
mkdir -p reptest/my5c/extra
replica_ip=$(podman inspect my1c --format '{{.NetworkSettings.Networks.replication.IPAddress}}')
cat <<'__eot__' >reptest/my5c/extra/extra.sql
-- placeholder
__eot__
# cat reptest/my5c/extra/extra.sql

podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SOURCE /tmp/extra/extra.sql'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'SOURCE /tmp/extra/extra.sql'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'SOURCE /tmp/extra/extra.sql'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'SOURCE /tmp/extra/extra.sql'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'SOURCE /tmp/extra/extra.sql'

# podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SOURCE /tmp/extra/extra.sql'
# podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'SOURCE /tmp/extra/extra.sql'
# podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'SOURCE /tmp/extra/extra.sql'
# podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'SOURCE /tmp/extra/extra.sql'
# podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'SOURCE /tmp/extra/extra.sql'

podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SELECT User, Host from mysql.user ORDER BY user'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'SELECT User, Host from mysql.user ORDER BY user'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'SELECT User, Host from mysql.user ORDER BY user'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'SELECT User, Host from mysql.user ORDER BY user'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'SELECT User, Host from mysql.user ORDER BY user'
position=$(podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'SHOW MASTER STATUS\G' | sed -e '/^ *Position:/!d' -e 's/[^0-9]*//g')
echo target:my1c source:my5c position:$position
podman exec --env=MYSQL_PWD=root my1c mysql --host=my1p --user=root --execute "CHANGE MASTER TO MASTER_HOST='my5p.dns.podman',MASTER_USER='repl',MASTER_PASSWORD='repl',MASTER_LOG_FILE='mysql-bin.000003',MASTER_LOG_POS=$position"
position=$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'SHOW MASTER STATUS\G' | sed -e '/^ *Position:/!d' -e 's/[^0-9]*//g')
echo target:my2c source:my1c position:$position
podman exec --env=MYSQL_PWD=root my2c mysql --host=my2p --user=root --execute "CHANGE MASTER TO MASTER_HOST='my1p.dns.podman',MASTER_USER='repl',MASTER_PASSWORD='repl',MASTER_LOG_FILE='mysql-bin.000003',MASTER_LOG_POS=$position"
position=$(podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'SHOW MASTER STATUS\G' | sed -e '/^ *Position:/!d' -e 's/[^0-9]*//g')
echo target:my3c source:my2c position:$position
podman exec --env=MYSQL_PWD=root my3c mysql --host=my3p --user=root --execute "CHANGE MASTER TO MASTER_HOST='my2p.dns.podman',MASTER_USER='repl',MASTER_PASSWORD='repl',MASTER_LOG_FILE='mysql-bin.000003',MASTER_LOG_POS=$position"
position=$(podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'SHOW MASTER STATUS\G' | sed -e '/^ *Position:/!d' -e 's/[^0-9]*//g')
echo target:my4c source:my3c position:$position
podman exec --env=MYSQL_PWD=root my4c mysql --host=my4p --user=root --execute "CHANGE MASTER TO MASTER_HOST='my3p.dns.podman',MASTER_USER='repl',MASTER_PASSWORD='repl',MASTER_LOG_FILE='mysql-bin.000003',MASTER_LOG_POS=$position"
position=$(podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'SHOW MASTER STATUS\G' | sed -e '/^ *Position:/!d' -e 's/[^0-9]*//g')
echo target:my5c source:my4c position:$position
podman exec --env=MYSQL_PWD=root my5c mysql --host=my5p --user=root --execute "CHANGE MASTER TO MASTER_HOST='my4p.dns.podman',MASTER_USER='repl',MASTER_PASSWORD='repl',MASTER_LOG_FILE='mysql-bin.000003',MASTER_LOG_POS=$position"

podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'

podman exec --env=MYSQL_PWD=root my1c bash -c "mysql --user=root --host=my1p.dns.podman --execute 'SHOW SLAVE STATUS\G' |grep -iE 'Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master'"
podman exec --env=MYSQL_PWD=root my2c bash -c "mysql --user=root --host=my2p.dns.podman --execute 'SHOW SLAVE STATUS\G' |grep -iE 'Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master'"
podman exec --env=MYSQL_PWD=root my3c bash -c "mysql --user=root --host=my3p.dns.podman --execute 'SHOW SLAVE STATUS\G' |grep -iE 'Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master'"
podman exec --env=MYSQL_PWD=root my4c bash -c "mysql --user=root --host=my4p.dns.podman --execute 'SHOW SLAVE STATUS\G' |grep -iE 'Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master'"
podman exec --env=MYSQL_PWD=root my5c bash -c "mysql --user=root --host=my5p.dns.podman --execute 'SHOW SLAVE STATUS\G' |grep -iE 'Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master'"

: <<'END_COMMENT'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'STOP SLAVE'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'STOP SLAVE'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'STOP SLAVE'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'STOP SLAVE'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'STOP SLAVE'
END_COMMENT

# testing replication
: <<'END_COMMENT'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'SHOW DATABASES'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'DROP DATABASE IF EXISTS dummy'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'SHOW DATABASES'

podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'SHOW DATABASES'
podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'DROP DATABASE IF EXISTS dummy'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'SHOW DATABASES'

podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'SHOW DATABASES'
podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'DROP DATABASE IF EXISTS dummy'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'SHOW DATABASES'

podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'SHOW DATABASES'
podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'DROP DATABASE IF EXISTS dummy'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'SHOW DATABASES'

podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'SHOW DATABASES'
podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'DROP DATABASE IF EXISTS dummy'
podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'SHOW DATABASES'

END_COMMENT

cat <<'__eot__' >test_replication_is_running.bats
@test 'ensure replication is running' {
  sleep 5
  podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
  podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
  podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
  podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'

  sleep 5
  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'CREATE DATABASE IF NOT EXISTS dummy'
  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'USE dummy'
  podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'USE dummy'
  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'DROP DATABASE IF EXISTS dummy'
  run podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'USE dummy'
  sleep 5
  [ "$status" -eq 1 ]
}
__eot__
sudo bats test_replication_is_running.bats

cat <<'__eot__' >test_replication_is_stopped.bats
@test 'stop replication and ensure its not running' {
  skip
  sleep 5
  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'CREATE DATABASE IF NOT EXISTS dummy'
  podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'STOP SLAVE'
  podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'STOP SLAVE'
  podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'STOP SLAVE'
  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'STOP SLAVE'
  podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'STOP SLAVE'

  sleep 5
  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'USE dummy'
  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'DROP DATABASE IF EXISTS dummy'

  sleep 5
  run podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'USE dummy'
  [ "$status" -eq 1 ]

  sleep 5
  run podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'USE dummy'
  [ "$status" -eq 0 ]

  # make sure replication is running again for next test...managing state like this will get dirty, i promise
  podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
  podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
  podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
  podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'START SLAVE USER="repl" PASSWORD="repl"'
}
__eot__
sudo bats test_replication_is_stopped.bats

# i guess positions have increased, yes?
position=$(podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --execute 'SHOW MASTER STATUS\G' | sed -e '/^ *Position:/!d' -e 's/[^0-9]*//g')
echo target:my1c source:my5c position:$position
position=$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --execute 'SHOW MASTER STATUS\G' | sed -e '/^ *Position:/!d' -e 's/[^0-9]*//g')
echo target:my2c source:my1c position:$position
position=$(podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --execute 'SHOW MASTER STATUS\G' | sed -e '/^ *Position:/!d' -e 's/[^0-9]*//g')
echo target:my3c source:my2c position:$position
position=$(podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --execute 'SHOW MASTER STATUS\G' | sed -e '/^ *Position:/!d' -e 's/[^0-9]*//g')
echo target:my4c source:my3c position:$position
position=$(podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'SHOW MASTER STATUS\G' | sed -e '/^ *Position:/!d' -e 's/[^0-9]*//g')
echo target:my5c source:my4c position:$position

until grep --silent 'Slave_IO_Running: Yes' <<<"$(podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my1p.dns.podman --execute 'SHOW SLAVE STATUS\G')"; do sleep 5; done
until grep --silent 'Slave_SQL_Running: Yes' <<<"$(podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my1p.dns.podman --execute 'SHOW SLAVE STATUS\G')"; do sleep 5; done
until grep --silent 'Slave_IO_Running: Yes' <<<"$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my2p.dns.podman --execute 'SHOW SLAVE STATUS\G')"; do sleep 5; done
until grep --silent 'Slave_SQL_Running: Yes' <<<"$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my2p.dns.podman --execute 'SHOW SLAVE STATUS\G')"; do sleep 5; done
until grep --silent 'Slave_IO_Running: Yes' <<<"$(podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my3p.dns.podman --execute 'SHOW SLAVE STATUS\G')"; do sleep 5; done
until grep --silent 'Slave_SQL_Running: Yes' <<<"$(podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my3p.dns.podman --execute 'SHOW SLAVE STATUS\G')"; do sleep 5; done
until grep --silent 'Slave_IO_Running: Yes' <<<"$(podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my4p.dns.podman --execute 'SHOW SLAVE STATUS\G')"; do sleep 5; done
until grep --silent 'Slave_SQL_Running: Yes' <<<"$(podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my4p.dns.podman --execute 'SHOW SLAVE STATUS\G')"; do sleep 5; done
until grep --silent 'Slave_IO_Running: Yes' <<<"$(podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my5p.dns.podman --execute 'SHOW SLAVE STATUS\G')"; do sleep 5; done
until grep --silent 'Slave_SQL_Running: Yes' <<<"$(podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my5p.dns.podman --execute 'SHOW SLAVE STATUS\G')"; do sleep 5; done

cat <<'__eot__' >replication_ok.bats
@test 'user table replicated ok' {
  skip
  podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SOURCE /tmp/extra2/extra2.sql'

  result1="$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result1" -eq 1 ] 

  result2="$(podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result2" -eq 1 ] 

  result3="$(podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result3" -eq 1 ] 

  result4="$(podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result4" -eq 1 ] 

  result5="$(podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result5" -eq 1 ] 

  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --database=sales --execute 'DELETE FROM user WHERE ln="mccormick"'

  result1="$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result1" -eq 0 ] 

  result2="$(podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result2" -eq 0 ] 

  result3="$(podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result3" -eq 0 ] 

  result4="$(podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result4" -eq 0 ] 

  result5="$(podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result5" -eq 0 ] 

  podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'SOURCE /tmp/extra2/extra2.sql'
  podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SOURCE /tmp/extra2/extra2.sql'

  result5="$(podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result5" -eq 2 ] 

  r=$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SHOW DATABASES'| grep -c sales || true)
  [ "$r" -eq 1 ] 

  podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p --execute 'DROP DATABASE IF EXISTS sales'

  r=$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SHOW DATABASES'| grep -c sales || true)
  [ "$r" -eq 0 ] 

  r=$(podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p.dns.podman --execute 'SHOW DATABASES'| grep -c sales || true)
  [ "$r" -eq 0 ] 

  r=$(podman exec --env=MYSQL_PWD=root my3c mysql --user=root --host=my3p.dns.podman --execute 'SHOW DATABASES'| grep -c sales || true)
  [ "$r" -eq 0 ] 

  r=$(podman exec --env=MYSQL_PWD=root my4c mysql --user=root --host=my4p.dns.podman --execute 'SHOW DATABASES'| grep -c sales || true)
  [ "$r" -eq 0 ] 

  r=$(podman exec --env=MYSQL_PWD=root my5c mysql --user=root --host=my5p.dns.podman --execute 'SHOW DATABASES' | grep -c sales || true)
  [ "$r" -eq 0 ] 
}
__eot__
sudo bats replication_ok.bats

cat <<'__eot__' >test_replication_stop_start.bats
@test 'stop replication, observe' {
  skip
  podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'STOP SLAVE'
  podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p.dns.podman --execute 'SOURCE /tmp/extra2/extra2.sql'
  result1="$(podman exec --env=MYSQL_PWD=root my1c mysql --user=root --host=my1p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result1" -eq 0 ] 

  result2="$(podman exec --env=MYSQL_PWD=root my2c mysql --user=root --host=my2p --database=sales --execute 'SELECT * FROM user' | grep -c mccormick || true)"
  [ "$result2" -eq 0 ] 
}
__eot__
sudo bats replication_ok.bats
