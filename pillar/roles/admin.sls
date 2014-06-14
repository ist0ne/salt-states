include:
  - svn
  - zabbix.api

hostgroup: admin
limit_users:
  root:
    limit_hard: 65535
    limit_soft: 65535
    limit_type: nofile
apache:
  Listen: 80
