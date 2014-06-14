zabbix-api:
  Zabbix_URL: http://172.16.100.81/zabbix
  Zabbix_User: admin
  Zabbix_Pass: zabbix
  Monitors_DIR: /etc/zabbix/api/monitors/
  Templates_DIR: /etc/zabbix/api/templates/
 
zabbix-base-templates:
  {% if grains['os_family'] == 'RedHat' or grains['os_family'] == 'Debian' %}
  - 'Template OS Linux'
  {% endif %}

zabbix-templates:
  memcached: 'Template App Memcached'
  zabbix-server: 'Template App Zabbix Server'
  web-server: 'Template App HTTP Service'
  mysql: 'Template App MySQL'
  mysql-master: 'Template App MySQL'
  mysql-slave: 'Template App MySQL Slave'
  php-fpm: 'Template App PHP FPM'
  nginx: 'Template App Nginx'
  varnish: 'Template App Varnish'
  redis: 'Template App Redis'
