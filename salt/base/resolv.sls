/etc/resolv.conf:
  file.managed:
    - source: salt://base/files/resolv.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
