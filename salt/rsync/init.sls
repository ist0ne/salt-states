include:
  - zabbix.agent
  - salt.minion

rsync:
  pkg.installed:
    - name: rsync
    - pkgs:
      - xinetd
      - rsync
  service.running:
    - name: xinetd
    - enable: True
    - require:
      - pkg: rsync
    - watch:
      - pkg: rsync
      - file: /etc/xinetd.d/rsync

/etc/xinetd.d/rsync:
  file.managed:
    - source: salt://rsync/files/etc/xinetd.d/rsync
    - template: jinja
    - user: root
    - group: root
    - mode: 644

/etc/rsyncd.conf:
  file.managed:
    - source: salt://rsync/files/etc/rsyncd.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
