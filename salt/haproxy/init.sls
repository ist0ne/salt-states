include:
  - zabbix.agent
  - salt.minion

haproxy:
  pkg.installed:
    - name: haproxy
  service.running:
    - name: haproxy
    - enable: True
    - require:
      - pkg: haproxy
    - watch:
      - pkg: haproxy
      - file: /etc/haproxy/haproxy.cfg

/etc/haproxy/haproxy.cfg:
  file.managed:
    - source: salt://haproxy/files/etc/haproxy/haproxy.cfg
    - template: jinja
    - user: root
    - group: root
    - mode: 644

haproxy-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'haproxy'
    - require:
      - file: roles
      - service: haproxy
      - service: salt-minion
    - watch_in:
      - module: sync_grains
