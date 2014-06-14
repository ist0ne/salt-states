/etc/yum.repos.d/mall.repo:
  file.managed:
    - source: salt://base/files/mall.repo
    - user: root
    - group: root
    - mode: 644
    - order: 1
  cmd.wait:
    - name: yum clean all
    - watch:
       - file: /etc/yum.repos.d/mall.repo
