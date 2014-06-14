include:
  - salt.minion

python-zabbix-zapi:
  file.recurse:
    - name: /usr/lib/python2.6/site-packages/zabbix
    - source: salt://zabbix/files/usr/lib/python2.6/site-packages/zabbix
    - include_empty: True


zabbix-api-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'zabbix-api'
    - require:
      - file: roles
      - service: salt-minion
      - file: python-zabbix-zapi
    - watch_in:
      - module: sync_grains 

zabbix-api-config:
  file.managed:
    - name: /etc/zabbix/api/config.yaml
    - source: salt://zabbix/files/etc/zabbix/api/config.yaml
    - makedirs: True
    - template: jinja
    - defaults:
        Monitors_DIR: {{pillar['zabbix-api']['Monitors_DIR']}}
        Templates_DIR: {{pillar['zabbix-api']['Templates_DIR']}}
        Zabbix_User: {{pillar['zabbix-api']['Zabbix_User']}}
        Zabbix_Pass: {{pillar['zabbix-api']['Zabbix_Pass']}}
        Zabbix_URL: {{pillar['zabbix-api']['Zabbix_URL']}}

zabbix-templates:
  file.recurse:
    - name: {{pillar['zabbix-api']['Templates_DIR']}}
    - source: salt://zabbix/files/etc/zabbix/api/templates
    - require:
      - file: python-zabbix-zapi
      - file: zabbix-api-config

zabbix-add-monitors-script:
  file.managed:
    - name: /etc/zabbix/api/add_monitors.py
    - source: salt://zabbix/files/etc/zabbix/api/add_monitors.py
    - makedirs: True
    - mode: 755
    - require:
      - file: python-zabbix-zapi
      - file: zabbix-api-config 

{% for each_minion, each_mine in salt['mine.get']('*', 'grains.item').iteritems() %}
monitor-{{each_minion}}:
  file.managed:
    - name: {{pillar['zabbix-api']['Monitors_DIR']}}/{{each_minion}}
    - source: salt://zabbix/files/etc/zabbix/api/monitors/minion
    - makedirs: True
    - template: jinja
    - defaults:
        IP: {{each_mine.ipv4[0]}}
        Hostgroup: {{each_mine.hostgroup}}
        Roles: {{each_mine.roles}}
        Templates: {{pillar['zabbix-templates']}}
    - order: last
    - require:
      - module: mine_update
  cmd.wait:
    - name: python /etc/zabbix/api/add_monitors.py {{each_minion}}
    - require:
      - file: zabbix-add-monitors-script
    - watch:
       - file: monitor-{{each_minion}}
{% endfor %}
