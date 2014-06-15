include:
  - apache

createrepo:
  pkg.installed:
   - name: createrepo

/etc/httpd/conf.d/mirrors.mall.com.conf:
  file.managed:
    - source: salt://mirrors/files/etc/httpd/conf.d/mirrors.mall.com.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: createrepo
      - pkg: apache
    - watch_in:
      - service: apache
  cmd.wait:
    - name: mkdir -p /data1/vhosts/mirrors.mall.com
    - watch:
       - file: /etc/httpd/conf.d/mirrors.mall.com.conf

/data1/vhosts/mirrors.mall.com/:
  file.recurse:
    - source: salt://mirrors/files/data1/vhosts/mirrors.mall.com/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - exclude_pat: '*.svn*'
    - require:
       - file: /etc/httpd/conf.d/mirrors.mall.com.conf
  cmd.wait:
    - name: createrepo /data1/vhosts/mirrors.mall.com/mall/6/x86_64 && createrepo /data1/vhosts/mirrors.mall.com/mysql/6/x86_64
    - watch:
       - file: /data1/vhosts/mirrors.mall.com/
