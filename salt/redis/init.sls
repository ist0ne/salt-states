include:
  - redis.monitor

{% set dbdir = salt['pillar.get']('redis:dir', '/var/lib/redis/') %}
redis:
  pkg:
    - installed
  file.managed:
    - name: /etc/redis.conf
    - source: salt://redis/files/etc/redis.conf
    - template: jinja
    - defaults:
        bind: 127.0.0.1
        port: 6379
    - require:
      - pkg: redis
  service.running:
    - enable: True
    - watch:
      - file: redis
  cmd.wait:
    - name: mkdir -p {{dbdir}} && chown -R redis.redis {{dbdir}}
    - watch:
       - pkg: redis

/etc/sysctl.d/redis.conf:
  file.managed:
    - source: salt://redis/files/etc/sysctl.d/redis.conf

redis-sysctl:
  cmd.wait:
    - name: /sbin/sysctl -q -p /etc/sysctl.d/redis.conf
    - watch:
      - file: /etc/sysctl.d/redis.conf

/etc/rc.d/rc.local:
  file.managed:
    - name: /etc/rc.d/rc.local
    - text:
      - '/sbin/sysctl -q -p /etc/sysctl.d/redis.conf'
    - require:
      - file: /etc/sysctl.d/redis.conf
      - service: redis

redis-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'redis'
    - require:
      - file: roles
      - service: redis
      - service: salt-minion
    - watch_in:
      - module: sync_grains
