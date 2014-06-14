include:
  - salt.minion

apache:
  pkg.installed:
    - name: httpd
  file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://apache/files/etc/httpd/conf/httpd.conf
    - template: jinja
    - require: 
      - pkg: apache
  service.running:
    - name: httpd
    - enable: True
    - watch:
      - pkg: apache
      - file: apache

httpd-conf.d:
  file.directory:
    - name: /etc/httpd/conf.d/
    - watch_in:
      - service: apache

web-server-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'web-server'
    - require:
      - file: roles
      - service: apache
      - service: salt-minion
    - watch_in:
      - module: sync_grains

