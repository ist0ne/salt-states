hostgroup: storage
exports:
  /data1/share: '172.16.100.*(rw,async,all_squash,anonuid=65534,anongid=65534) *.grid.mall.com(rw,async,all_squash,anonuid=65534,anongid=65534)'
