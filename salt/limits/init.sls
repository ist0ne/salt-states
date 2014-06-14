{% for user, limit in salt['pillar.get']('limit_users', {}).iteritems() %}
{% if user %}

limits-{{user}}-{{limit['limit_type']}}:
  file.managed:
    - source: salt://limits/files/etc/security/limits.d/limits.conf
    - template: jinja
    - defaults:
        user: {{user}}
        hard: {{limit['limit_hard']}}
        soft: {{limit['limit_soft']}}
        limit_type: {{limit['limit_type']}}
    {% if grains['os'] == 'CentOS' or grains['os'] == 'Fedora' %}
    - name: /etc/security/limits.d/{{user}}_{{limit['limit_type']}}.conf
    {% endif %}
{% endif %}
{% endfor %}
