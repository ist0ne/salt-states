include:
  - salt.minion

mysql-server:
  pkg:
    - installed
  file.managed:
    - name: /etc/my.cnf
    - require:
      - pkg: mysql-server
  service.running:
    - name: mysqld
    - enable: True
    - require:
      - pkg: mysql-server
    - watch:
      - file: mysql-server

mysql-server-config-minion:
  file.managed:
    - name: /etc/salt/minion.d/mysql.conf
    - source: salt://mysql/files/etc/salt/minion.d/mysql.conf
    - makedirs: True
    - require:
      - service: salt-minion
     
