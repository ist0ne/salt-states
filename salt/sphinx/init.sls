include:
  - zabbix.agent
  - salt.minion

sphinx:
  pkg.installed:
    - name: sphinx
  service.running:
    - name: searchd
    - enable: True
    - require:
      - pkg: sphinx
    - watch:
      - pkg: sphinx
      - file: /etc/sphinx/sphinx.conf

/etc/sphinx/sphinx.conf:
  file.managed:
    - source: salt://sphinx/files/etc/sphinx/sphinx.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644

sphinx-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'sphinx'
    - require:
      - file: roles
      - service: sphinx
      - service: salt-minion
    - watch_in:
      - module: sync_grains
