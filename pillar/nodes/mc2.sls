redis:
  port: 6379
  bind: 172.16.100.42
  timeout: 300
  loglevel: warning
  dir: /data1/redis
  master: 172.16.100.41
  master_port: 6379
  maxclients: 3000
  maxmemory: 128MB
