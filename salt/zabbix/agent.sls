include:
  - salt.minion

zabbix-agent:
  pkg.installed:
    - name: zabbix22-agent
  file.managed:
    - name: /etc/zabbix_agentd.conf
    - source: salt://zabbix/files/etc/zabbix_agentd.conf
    - template: jinja
    - defaults:
        zabbix_server: {{ pillar['zabbix-agent']['Zabbix_Server'] }}
    - require:
      - pkg: zabbix-agent
  service.running:
    - enable: True
    - watch:
      - pkg: zabbix-agent
      - file: zabbix-agent

zabbix-agent-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'zabbix-agent'
    - require:
      - file: roles
      - service: zabbix-agent
      - service: salt-minion
    - watch_in:
      - module: sync_grains
  

zabbix_agentd_conf-link:
  file.symlink:
    - name: /etc/zabbix/zabbix_agentd.conf
    - target: /etc/zabbix_agentd.conf
    - require_in:
      - service: zabbix-agent
    - require:
      - pkg: zabbix-agent 
      - file: zabbix-agent
    
zabbix_agentd.conf.d:
  file.directory:
    - name: /etc/zabbix/zabbix_agentd.conf.d
    - watch_in:
      - service: zabbix-agent
    - require:
      - pkg: zabbix-agent
      - file: zabbix-agent

