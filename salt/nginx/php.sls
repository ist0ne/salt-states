php-fpm:
  pkg:
    - name: php-fpm
    - pkgs:
      - php-fpm
      - php-common
      - php-cli
      - php-devel
      - php-pecl-memcache
      - php-pecl-memcached
      - php-gd
      - php-pear
      - php-mbstring
      - php-mysql
      - php-xml
      - php-bcmath
      - php-pdo
    - installed
  service:
    - running
    - require:
      - pkg: php-fpm
    - watch:
      - pkg: php-fpm
      - file: /etc/php.ini
      - file: /etc/php.d/
      - file: /etc/php-fpm.conf
      - file: /etc/php-fpm.d/

/etc/php.ini:
  file.managed:
    - source: salt://nginx/files/etc/php.ini
    - user: root
    - group: root
    - mode: 644

/etc/php.d/:
  file.recurse:
    - source: salt://nginx/files/etc/php.d/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644

/etc/php-fpm.conf:
  file.managed:
    - source: salt://nginx/files/etc/php-fpm.conf
    - user: root
    - group: root
    - mode: 644

/etc/php-fpm.d/:
  file.recurse:
    - source: salt://nginx/files/etc/php-fpm.d/
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644

php-fpm-role:
  file.append:
    - name: /etc/salt/roles
    - text:
      - 'php-fpm'
    - require:
      - file: roles
      - service: php-fpm
      - service: salt-minion
    - watch_in:
      - module: sync_grains
