include:
  - zabbix.agent
  - nginx

nginx-monitor:
  pkg.installed:
    - name: perl-libwww-perl

php-fpm-monitor-script:
  file.managed:
    - name: /etc/zabbix/ExternalScripts/php-fpm_status.pl
    - source: salt://nginx/files/etc/zabbix/ExternalScripts/php-fpm_status.pl
    - user: root
    - group: root
    - mode: 755
    - require:
      - service: php-fpm
      - pkg: nginx-monitor
      - cmd: php-fpm-monitor-script
  cmd.run:
    - name: mkdir -p /etc/zabbix/ExternalScripts
    - unless: test -d /etc/zabbix/ExternalScripts

php-fpm-monitor-config:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.conf.d/php_fpm.conf
    - source: salt://nginx/files/etc/zabbix/zabbix_agentd.conf.d/php_fpm.conf
    - require:
      - file: php-fpm-monitor-script
      - service: php-fpm
    - watch_in:
      - service: zabbix-agent

nginx-monitor-config:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.conf.d/nginx.conf
    - source: salt://nginx/files/etc/zabbix/zabbix_agentd.conf.d/nginx.conf
    - template: jinja
    - require:
      - service: nginx
    - watch_in:
      - service: zabbix-agent
