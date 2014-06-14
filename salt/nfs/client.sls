include:
  - rpcbind

nfs-client:
  pkg.installed:
    - name: nfs-utils

{% for dir, args in salt['pillar.get']('mounts', {}).iteritems() %}
{{dir}}:
  mount.mounted:
    - device: {{args['device']}}
    - fstype: {{args['fstype']}}
    - mkmnt: {{args['mkmnt']}}
    - opts: {{args['opts']}}
    - require:
      - pkg: nfs-utils
      - service: rpcbind
{% endfor %}
