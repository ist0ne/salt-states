rpcbind:
  pkg.installed:
    - name: rpcbind
  service.running:
    - name: rpcbind
    - enable: True
    - require:
      - pkg: rpcbind
    - watch:
      - pkg: rpcbind
