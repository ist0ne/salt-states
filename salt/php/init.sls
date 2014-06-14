include:
  - apache

php:
  pkg.installed:
    - name: php
  file.managed:
    - name: /etc/php.ini
    - source: salt://php/files/etc/php.ini
    - require:
      - pkg: php
    - watch_in:
      - service: apache
