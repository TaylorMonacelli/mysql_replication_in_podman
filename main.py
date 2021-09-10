import pathlib

import jinja2
import yaml

manifest_path = pathlib.Path(__file__).parent.resolve() / "manifest.yml"

in_file = manifest_path

with open(in_file, "r") as stream:
    try:
        manifest = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        print(exc)

tmpl_str = """#!/bin/bash
{% set global=manifest['global'] %}
{% set pods=manifest['pods'] %}

{% macro status() -%}
podman ps
podman ps --pod
podman ps -a --pod
podman network ls
podman volume ls
podman pod ls
{% endmacro -%}

set -o errexit

podman info --debug

# podman login --username mtmonacelli registry.redhat.io $REGISTRY_REDHAT_IO_PASSWORD

podman pull docker.io/perconalab/percona-toolkit:latest

{{ status() }}

{% for pod in pods %}
podman pod stop --ignore {{ pod.name }}
podman pod rm --ignore --force {{ pod.name }}
podman volume exists {{ pod.volume }} && podman volume rm --force {{ pod.volume }}
{% endfor %}

podman network exists {{ global.network}} && podman network rm --force {{ global.network }}

{{ status() }}

podman network create {{ global.network }}
{% for pod in pods %}
podman volume create {{ pod.volume }}
{%- endfor %}

rm -rf reptest/

{% for pod in pods %}
mkdir -p reptest/{{ pod.containers[0].name }}/extra
{%- endfor %}

{% for pod in pods %}
mkdir -p reptest/{{ pod.containers[0].name }}
cat <<'__eot__' >reptest/{{ pod.containers[0].name }}/my.cnf
[mysqld]
bind-address             = {{ pod.name }}.dns.podman
server_id                = {{ loop.index }}
log_bin                  = /var/log/mysql/mysql-bin.log
binlog_do_db             = db
__eot__
{% endfor %}

# pods with bridge mode networking
{%- for pod in pods %}
podman pod create --name={{ pod.name }} --publish={{ global.internal_port }}{{loop.index}}:{{ global.internal_port }} --network={{ global.network }}
{%- endfor %}

# mysqld containers
{%- for pod in pods %}
podman container create --name={{ pod.containers[0].name }} --pod={{ pod.name }} --health-start-period=80s --log-driver=journald --volume=./reptest/{{ pod.containers[0].name }}/my.cnf:/etc/my.cnf.d/100-reptest.cnf --volume=./reptest/{{ pod.containers[0].name }}/extra:/tmp/extra:Z --volume={{ pod.volume }}:/var/lib/mysql/data:Z --env=MYSQL_ROOT_PASSWORD={{ global.user_root_pass }} --env=MYSQL_USER={{ global.user_non_root }} --env=MYSQL_PASSWORD={{ global.user_non_root_pass }} --env=MYSQL_DATABASE=db registry.redhat.io/rhel8/mysql-80
{%- endfor %}

{% for pod in pods %}
podman pod start {{ pod.name }}
{%- endfor %}

{% for pod in pods %}
podman wait {{ pod.containers[0].name }} --condition=running
{%- endfor %}

{% for pod in pods %}
podman volume inspect {{ pod.volume }}
{%- endfor %}

{{ status() }}

{% for pod in pods %}
until podman exec --tty --interactive {{ pod.containers[0].name }} mysql --host={{ pod.name }} --user={{ global.user_non_root }} --password={{ global.user_non_root_pass }} --execute "SHOW DATABASES;"; do sleep 5; done;
{%- endfor %}

{% for pod in pods %}{% set ip='ip' ~ loop.index %}
podman inspect {{ pod.containers[0].name }} | grep -i ipaddr
{{ip}}=$(podman inspect {{ pod.containers[0].name }} --format '{%- raw -%} {{ {%- endraw -%}.NetworkSettings.Networks.{{ global.network }}.IPAddress{%- raw -%} }} {%- endraw -%}')
echo ${{ip}}
{%- endfor %}

{% for pod in pods %}{% set ip='ip' ~ loop.index %}
# mysqladmin --port={{ global.internal_port }} --host=${{ip}} --user={{ global.user_non_root }} --password={{ global.user_non_root_pass }} password ''
{%- endfor %}

# ip test
{% for pod in pods %}{% set ip='ip' ~ loop.index %}
mysql --port={{ global.internal_port }} --host=${{ip}} --user={{ global.user_non_root }} --password={{ global.user_non_root_pass }} --execute "SHOW DATABASES;"
{%- endfor %}

# FIXME: {% set containers = [] %}{% for pod in pods %}{{ containers.append( pod.containers[0].name ) }}{% endfor %}

# dns test
{% for container in containers %}
{% for pod in pods %}
time podman exec --tty --interactive {{ container }} mysql --user={{ global.user_root }} --password={{ global.user_root_pass }} --host={{ pod.name }}.dns.podman --execute 'SHOW DATABASES;' </dev/null
{%- endfor %}
{%- endfor %}

{{ status() }}
{% for pod in pods %}
replica_ip{{ pod.replica.number }}=$(podman inspect {{ pod.replica.container }} --format '{%- raw -%} {{ {%- endraw -%}.NetworkSettings.Networks.{{ manifest['global']['network'] }}.IPAddress{%- raw -%} }} {%- endraw -%}')
mkdir -p reptest/{{ pod.containers[0].name }}/extra
cat <<__eot__ >reptest/{{ pod.containers[0].name }}/extra/user.sql
CREATE USER '{{ global.user_replication }}'@'{{ pod.replica.fqdn }}' IDENTIFIED WITH mysql_native_password BY '{{ global.user_replication_pass }}';
GRANT REPLICATION SLAVE ON *.* TO '{{ global.user_replication }}'@'{{ pod.replica.fqdn }}';

CREATE USER '{{ global.user_replication }}'@'$replica_ip{{ pod.replica.number }}' IDENTIFIED WITH mysql_native_password BY '{{ global.user_replication_pass }}';
GRANT REPLICATION SLAVE ON *.* TO '{{ global.user_replication }}'@'$replica_ip{{ pod.replica.number }}';

-- fixme: sanity check
CREATE USER '{{ global.user_replication }}'@'%' IDENTIFIED WITH mysql_native_password BY '{{ global.user_replication_pass }}';
GRANT REPLICATION SLAVE ON *.* TO '{{ global.user_replication }}'@'%';

FLUSH PRIVILEGES;
__eot__
{% endfor %}

{%- for pod in pods %}
podman exec --tty --interactive {{ pod.containers[0].name }} mysql --user={{ global.user_root }} --password={{ global.user_root_pass }} --host={{ pod.name }}.dns.podman --execute 'SOURCE /tmp/extra/user.sql;'
{%- endfor %}

# desc mysql.user;
{%- for pod in pods %}
podman exec --tty --interactive {{ pod.containers[0].name }} mysql --user={{ global.user_root }} --password={{ global.user_root_pass }} --host={{ pod.name }}.dns.podman --execute 'SELECT User, Host from mysql.user;'
{%- endfor %}
"""

template = jinja2.Template(tmpl_str)
result = template.render(manifest=manifest)
print(result)
