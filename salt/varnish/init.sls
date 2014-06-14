include:
  - zabbix.agent
  - salt.minion
  - varnish.monitor

varnish:
  pkg.installed:
    - name: varnish
  service.running:
    - name: varnish
    - enable: True
    - require:
      - pkg: varnish
    - watch:
      - pkg: varnish
      - file: varnish
      - file: /etc/varnish/default.vcl
  file.managed:
    - name: /etc/sysconfig/varnish
    - source: salt://varnish/files/etc/sysconfig/varnish
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: varnish
  cmd.run:
    - name: mkdir -p /data1/varnish
    - unless: test -d /data1/varnish

/etc/varnish/default.vcl:
  file.managed:
    - source: salt://varnish/files/etc/varnish/default.vcl
    - template: jinja
    - user: root
    - group: root
    - mode: 644

varnish-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'varnish'
    - require:
      - file: roles
      - service: varnish
      - service: salt-minion
    - watch_in:
      - module: sync_grains
