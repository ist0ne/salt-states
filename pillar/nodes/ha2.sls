keepalived:
  notification_email: 'dongliang@mall.com'
  notification_email_from: 'haproxy@mall.com'
  smtp_server: 127.0.0.1
  state: BACKUP
  priority: 99
  auth_type: PASS
  auth_pass: mall
  virtual_ipaddress_internal: 172.16.100.100
  virtual_ipaddress_external: 60.60.60.100
