base:
  '*':
    - roles.common
  'admin.grid.mall.com':
    - roles.admin
  'ha*.grid.mall.com':
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
