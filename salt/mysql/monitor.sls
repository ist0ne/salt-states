include:
  - zabbix.agent
  - mysql

my.cnf:
  file.managed:
    - name: /var/lib/zabbix/.my.cnf
    - source: salt://mysql/files/var/lib/zabbix/.my.cnf
    - template: jinja
    - watch_in:
      - service: zabbix-agent

mysql-monitor-config:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.conf.d/userparameter_mysql.conf
    - source: salt://mysql/files/etc/zabbix/zabbix_agentd.conf.d/userparameter_mysql.conf
    - template: jinja
    - require:
      - file: my.cnf
    - watch_in:
      - service: zabbix-agent
