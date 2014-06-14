include:
  - zabbix.agent
  - salt.minion
  - rpcbind

nfs:
  pkg.installed:
    - name: nfs-utils
  service.running:
    - name: nfs
    - enable: True
    - require:
      - pkg: nfs-utils
    - watch:
      - pkg: nfs-utils
      - service: rpcbind

{% for dir, right in salt['pillar.get']('exports', {}).iteritems() %}
{{dir}}:
  cmd.run:
    - name: mkdir -p {{dir}} && chown -R nfsnobody.nfsnobody {{dir}}
    - unless: test -d {{dir}}
    - require:
      - pkg: nfs-utils
{% endfor %}

/etc/exports:
  file.managed:
    - source: salt://nfs/files/etc/exports
    - template: jinja
    - user: root
    - group: root
    - mode: 644
  cmd.wait:
    - name: /usr/sbin/exportfs -rv
    - watch:
       - file: /etc/exports

nfs-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'nfs'
    - require:
      - file: roles
      - service: nfs
      - service: salt-minion
    - watch_in:
      - module: sync_grains
