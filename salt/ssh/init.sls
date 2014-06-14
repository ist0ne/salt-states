openssh:
  pkg:
    - installed

sshd:
  service:
    - running
    - watch:
      - file: /etc/ssh/sshd_config
  require:
    - pkg: openssh

/etc/ssh/sshd_config:
  file.managed:
    - source: salt://ssh/files/etc/ssh/sshd_config
    - template: jinja
