include:
  - apache
  - php
  - salt.minion

zabbix-web:
  pkg.installed:
    - pkgs:
      - zabbix22-web
      - zabbix22-web-mysql
    - watch_in:
      - service: apache 
  file.managed:
    - name: /etc/zabbix/web/zabbix.conf.php
    - source: salt://zabbix/files/etc/zabbix/web/zabbix.conf.php
    - require:
      - pkg: zabbix-web

zabbix-web-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'zabbix-web'
    - require:
      - file: roles
      - pkg: zabbix-web
      - service: salt-minion
    - watch_in:
      - module: sync_grains
