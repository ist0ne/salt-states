{% set datadir = salt['pillar.get']('mysql:datadir', '/var/lib/mysql') %}
include:
  - zabbix.agent
  - salt.minion
  - mysql.monitor

mysql:
  pkg.installed:
    - pkgs:
      - MySQL-server
      - MySQL-client
      - MySQL-devel
    - require:
      - file: mysql
      - cmd: remove-mysql-libs
  service.running:
    - name: mysql
    - enable: False
    - require:
      - pkg: mysql
    - watch:
      - pkg: mysql
      - file: /etc/my.cnf
  file.managed:
    - name: /etc/yum.repos.d/mysql.repo
    - source: salt://mysql/files/etc/yum.repo.d/mysql.repo
  cmd.wait:
    - name: mkdir -p {{datadir}} && cp -r /var/lib/mysql/* {{datadir}}/ && chown -R mysql.mysql {{datadir}}
    - unless: test -d {{datadir}}
    - watch:
       - pkg: mysql

# 解决软件冲突
remove-mysql-libs:
  cmd.run:
    - name: rpm -e --nodeps mysql-libs && chkconfig --level 2345 postfix off
    - onlyif: rpm -qa |grep mysql-libs

/etc/my.cnf:
  file.managed:
    - source: salt://mysql/files/etc/{{salt['pillar.get']('mysql:conf_template', 'my.cnf')}}
    - template: jinja
    - user: root
    - group: root
    - mode: 644

mysql-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - {{salt['pillar.get']('mysql:role', 'mysql')}}
    - require:
      - file: roles
      - service: mysql
      - service: salt-minion
    - watch_in:
      - module: sync_grains
