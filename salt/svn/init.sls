{% set repodir = salt['pillar.get']('repodir', '/var/svn') %}
svnserve:
  pkg:
    - name: subversion
    - installed
  service:
    - running
    - require:
      - pkg: subversion
    - watch:
      - pkg: subversion
      - file: /etc/sysconfig/svnserve
      - file: {{repodir}}/conf/
  cmd.wait:
    - name: mkdir -p {{repodir}} && /usr/bin/svnadmin create {{repodir}}
    - watch:
       - pkg: subversion

/etc/sysconfig/svnserve:
  file.managed:
    - source: salt://svn/files/etc/sysconfig/svnserve
    - template: jinja
    - user: root
    - group: root
    - mode: 644

{{repodir}}/conf/:
  file.recurse:
    - source: salt://svn/files/conf/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
