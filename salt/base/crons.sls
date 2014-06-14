include:
  - ntp

'/usr/sbin/ntpdate 1.cn.pool.ntp.org 1.asia.pool.ntp.org':
  cron.present:
    - user: root
    - minute: 0
    - hour: 2
