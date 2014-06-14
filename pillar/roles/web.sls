hostgroup: web
vhostsdir: /data1/vhosts
vhostscachedir: /data1/cache
logdir: /data1/logs
vhosts:
  - www.mall.com
  - static.mall.com
limit_users:
  nginx:
    limit_hard: 65535
    limit_soft: 65535
    limit_type: nofile
mounts:
  /data1/vhosts/static.mall.com/htdocs:
    device: 172.16.100.71:/data1/share
    fstype: nfs
    mkmnt: True
    opts: async,noatime,noexec,nosuid,soft,timeo=3,retrans=3,intr,retry=3,rsize=16384,wsize=16384
