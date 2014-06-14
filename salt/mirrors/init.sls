include:
  - apache

createrepo:
  pkg.installed:
   - name: createrepo

/etc/httpd/conf.d/mirrors.conf:
  file.managed:
    - source: salt://mirrors/files/etc/httpd/conf.d/mirrors.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: createrepo
      - pkg: apache
    - watch_in:
      - service: apache
  cmd.wait:
    - name: mkdir -p /data1/vhosts/mirrors
    - watch:
       - file: /etc/httpd/conf.d/mirrors.conf

/data1/vhosts/mirrors/:
  file.recurse:
    - source: salt://mirrors/files/data1/vhosts/mirrors/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - exclude_pat: '*.svn*'
    - require:
       - file: /etc/httpd/conf.d/mirrors.conf
  cmd.wait:
    - name: createrepo /data1/vhosts/mirrors/6/x86_64
    - watch:
       - file: /data1/vhosts/mirrors/
