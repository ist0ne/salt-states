include:
  - salt.minion

salt-master:
  pkg.installed:
    - name: salt-master
  file.managed:
    - name: /etc/salt/master
    - require:
      - pkg: salt-master
  service.running:
    - enable: True
    - watch:
      - pkg: salt-master
      - file: salt-master
      - file: /etc/salt/master.d/

/etc/salt/master.d/:
  file.recurse:
    - source: salt://salt/files/etc/salt/master.d/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644

salt-master-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'salt-master'
    - require:
      - file: roles
      - service: salt-master
      - service: salt-minion
    - watch_in:
      - module: sync_grains
