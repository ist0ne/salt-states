include:
  - zabbix.agent
  - salt.minion

coreseek:
  pkg.installed:
    - name: coreseek
  service.running:
    - name: searchd
    - enable: True
    - require:
      - pkg: coreseek
    - watch:
      - pkg: coreseek
      - file: /usr/local/coreseek/etc/sphinx.conf

/usr/local/coreseek/etc/sphinx.conf:
  file.managed:
    - source: salt://coreseek/files/sphinx.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644

coreseek-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'coreseek'
    - require:
      - file: roles
      - service: coreseek
      - service: salt-minion
    - watch_in:
      - module: sync_grains
