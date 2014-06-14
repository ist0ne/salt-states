include:
  - salt.minion
  - mysql.server

zabbix-server:
  pkg.installed:
    - pkgs:
      - zabbix22-server
      - zabbix22-server-mysql
  file.managed:
    - name: /etc/zabbix_server.conf
    - source: salt://zabbix/files/etc/zabbix_server.conf
    - template: jinja
    - defaults:
        DBHost: localhost
        DBName: zabbix
        DBUser: zabbix
        DBPassword: zabbix_pass
        DBSocket: /var/lib/mysql/mysql.sock
        DBPort: 3306
    - require:
      - pkg: zabbix-server
  service.running:
    - enable: True
    - watch:
      - file: zabbix-server

zabbix-server-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'zabbix-server'
    - require:
      - file: roles
      - service: zabbix-server
      - service: salt-minion
    - watch_in:
      - module: sync_grains


zabbix_server.conf-link:
  file.symlink:
    - name: /etc/zabbix/zabbix_server.conf
    - target: /etc/zabbix_server.conf
    - require_in:
      - service: zabbix-server
    - require:
      - pkg: zabbix-server
      - file: zabbix-server

zabbix_mysql:
  pkg.installed:
    - name: MySQL-python
  mysql_database.present:
    - name: zabbix
    - require:
      - pkg: zabbix_mysql
      - service: mysql-server
  mysql_user.present:
    - name: zabbix
    - host: localhost
    - password: zabbix_pass
    - require:
      - mysql_database: zabbix_mysql
  mysql_grants.present:
    - grant: all
    - database: zabbix.*
    - user: zabbix
    - host: localhost
    - require:
      - mysql_user: zabbix_mysql
    - require_in:
      - service: zabbix-server


zabbix_mysql-init:
  cmd.run:
    - name: mysql -uroot zabbix < /usr/share/zabbix-mysql/schema.sql && mysql -uroot zabbix < /usr/share/zabbix-mysql/images.sql && mysql -uroot zabbix < /usr/share/zabbix-mysql/data.sql
    - unless: mysql -uroot -e "SELECT COUNT(*) from zabbix.users"
    - require:
      - pkg: zabbix-server
      - mysql_grants: zabbix_mysql
    - require_in:
      - file: zabbix-server
      - service: zabbix-server
