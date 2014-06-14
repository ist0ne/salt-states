include:
  - zabbix.agent
  - salt.minion

nginx:
  pkg:
    - name: nginx
    - installed
  service:
    - name: nginx
    - running
    - require:
      - pkg: nginx
    - watch:
      - pkg: nginx
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/conf.d/

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://nginx/files/etc/nginx/nginx.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - backup: minion

/etc/nginx/conf.d/:
  file.recurse:
    - source: salt://nginx/files/etc/nginx/conf.d/
    - template: jinja
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644

{% set logdir = salt['pillar.get']('logdir', '/var/log/nginx') %}
{{logdir}}:
  cmd.run:
    - name: mkdir -p {{logdir}}
    - unless: test -d {{logdir}}
    - require:
      - pkg: nginx

{% if salt['pillar.get']('vhosts', false) %}
{% set dir = salt['pillar.get']('vhostsdir', '/var/www/html') %}
{% set cachedir = salt['pillar.get']('vhostscachedir', '/var/www/cache') %}
{% for vhost in pillar['vhosts'] %}
{{dir}}/{{vhost}}/htdocs:
  cmd.run:
    - name: mkdir -p {{dir}}/{{vhost}}/htdocs && chown -R nobody.nobody {{dir}}/{{vhost}}/htdocs
    - unless: test -d {{dir}}/{{vhost}}/htdocs
    - require:
      - pkg: nginx
{{cachedir}}/{{vhost}}:
  cmd.run:
    - name: mkdir -p {{cachedir}}/{{vhost}} && chown -R nginx.nginx {{cachedir}}/{{vhost}}
    - unless: test -d {{cachedir}}/{{vhost}}
    - require:
      - pkg: nginx
{% endfor %}
{% endif %}

nginx-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'nginx'
    - require:
      - file: roles
      - service: nginx
      - service: salt-minion
    - watch_in:
      - module: sync_grains
