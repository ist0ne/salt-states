include:
  - zabbix.agent
  - memcached.install

memcached-monitor-script:
  file.managed:
    - name: /etc/zabbix/ExternalScripts/zabbix_memcached_check.sh
    - source: salt://memcached/files/etc/zabbix/ExternalScripts/zabbix_memcached_check.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - service: memcached
      - cmd: memcached-monitor-scrip
  cmd.run:
    - name: mkdir -p /etc/zabbix/ExternalScripts
    - unless: test -d /etc/zabbix/ExternalScripts

memcached-monitor-config:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.conf.d/memcached.conf
    - source: salt://memcached/files/etc/zabbix/zabbix_agentd.conf.d/memcached.conf
    - require:
      - file: memcached-monitor-script
    - watch_in:
      - service: zabbix-agent
