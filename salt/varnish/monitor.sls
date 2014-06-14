include:
  - zabbix.agent
  - varnish

varnish-monitor-config:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.conf.d/varnish.conf
    - source: salt://varnish/files/etc/zabbix/zabbix_agentd.conf.d/varnish.conf
    - require:
      - service: varnish
    - watch_in:
      - service: zabbix-agent
