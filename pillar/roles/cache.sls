hostgroup: cache
varnish_static_01: 172.16.100.21
varnish_static_02: 172.16.100.22
varnish_static_03: 172.16.100.23
limit_users:
  varnish:
    limit_hard: 65535
    limit_soft: 65535
    limit_type: nofile
