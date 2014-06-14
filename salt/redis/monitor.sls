include:
  - zabbix.agent
  - redis

redis-monitor-config:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.conf.d/redis.conf
    - source: salt://redis/files/etc/zabbix/zabbix_agentd.conf.d/redis.conf
    - template: jinja
    - require:
      - service: redis
    - watch_in:
      - service: zabbix-agent
