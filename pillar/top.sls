base:
  '*':
    - roles.common
  'admin.grid.mall.com':
    - roles.admin
  'ha.grid.mall.com':
    - roles.ha
  'web*.grid.mall.com':
    - roles.web
  'cache*.grid.mall.com':
    - roles.cache
  'mc*.grid.mall.com':
    - roles.mc
  'db*.grid.mall.com':
    - roles.db
  'search*.grid.mall.com':
    - roles.search
  'storage*.grid.mall.com':
    - roles.storage

  'ha1.grid.mall.com':
    - nodes.ha1
  'ha2.grid.mall.com':
    - nodes.ha2
  'mc1.grid.mall.com':
    - nodes.mc1
  'mc2.grid.mall.com':
    - nodes.mc2
  'db1.grid.mall.com':
    - nodes.db1
  'db2.grid.mall.com':
    - nodes.db2

