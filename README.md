本文以一个小的电商网站（www.mall.com）为例，讲述Saltstack在真实场景中的应用。主要介绍如何使用salt对电商网站各种服务进行管理、基于角色对应用进行自动化监控、基于Saltstack runner的代码部署系统等，主要包括以下主题：

* [网站架构介绍](http://yoyolive.com/saltstack/2014/05/27/saltstack-example-introduction.html)
* [Saltstack安装](http://yoyolive.com/saltstack/2014/05/28/saltstack-install.html)
* [基础服务部署](http://yoyolive.com/saltstack/2014/05/29/saltstack-base-service.html)
* [服务部署](http://yoyolive.com/saltstack/2014/06/14/saltstack-service.html)
* [代码部署系统搭建](http://yoyolive.com/saltstack/2014/06/15/saltstack-publish.html)
* [自动化监控](http://yoyolive.com/saltstack/2014/06/16/saltstack-pzabbix_monitor.html)
* [Salt模块的扩展](http://yoyolive.com/saltstack/2014/06/17/saltstack-expand.html)

## 网站架构介绍

### 网络架构

1. 使用Haproxy做负载均衡，一主一备，当主服务器宕机后备服务器自动接替主服务器角色对外提供服务。
2. WEB前端采用Nginx+PHP提供动态页面的访问；所有前端服务器通过NFS协议挂载共享存储，商品展示图片上传至存储中，图片访问时通过Varnish进行缓存加速。
3. 使用memcached做缓冲层来提高访问速度和减轻数据库的压力；使用Redis做队列服务。
4. 数据持久层使用MySQL，MySQL采用主从模式，通过主从分离提高访问速度。
5. 使用Salt对整个系统进行配置管理；使用Zabbix进行系统监控；所有服务器通过跳板机进行登录。
6. 使用SVN统一管理代码和配置信息。

![网络架构](http://yoyolive.com/assets/images/14-05-27/net.png)
说明:上面网络架构未按实际服务器数量画出，具体服务器见角色划分部分。

### 系统架构

1. 统一管理：整个系统通过Salt进行配置管理，所有配置文件统一存储到SVN中，通过SVN版本控制能够在系统故障时轻松回退到上一个正常版本。
2. 代码部署：通过命令行部署工具从SVN中检出代码并部署到WEB前端，做到简单轻松部署。
3. 应用架构：采用经典的三层架构--代码解析层、缓冲层、数据持久化层。缓冲层对用户数据进行缓存，不必每次都去数据库提取数据，减轻数据库压力；数据库采用主从架构，读写分离，减轻主库负载，提高了用户的访问速度。
4. 动静态分离：图片、CSS、JS与动态程序分离，通过Varnish进行加速，提升用户体验。
5. Zabbix监控：基于角色的自动监控机制，通过Zabbix对系统状态、应用状态进行自动监控。

![系统架构](http://yoyolive.com/assets/images/14-05-27/sys.png)

### 角色划分（主机名、IP地址分配）

说明：所有服务器配置内、外双网卡，eth0为内网，eth1为外网。操作系统统一部署CentOS 6.5 64位。

#### 负载均衡（ha）

需要两台服务器作为负载均衡器使用，两台服务器配置为主备模式，当主服务器宕机后从服务器自动接管服务。

* ha1.grid.mall.com 60.60.60.11 172.16.100.11
* ha2.grid.mall.com 60.60.60.12 172.16.100.12

#### Web前端（web）

需要三台服务器作为Web前端服务器，对外提供Web服务，Web服务通过负载均衡供用户访问。

* web1.grid.mall.com 60.60.60.21 172.16.100.21
* web2.grid.mall.com 60.60.60.22 172.16.100.22
* web3.grid.mall.com 60.60.60.23 172.16.100.23

#### 图片缓存（cache）

需要两台服务器作为商品图片的缓存服务器，缓存服务器通过负载均衡供用户访问。

* cache1.grid.mall.com 60.60.60.31 172.16.100.31
* cache2.grid.mall.com 60.60.60.32 172.16.100.32

#### 缓存服务和队列服务（mc）

需要两台服务器提供缓冲服务器和队列服务。

* mc1.grid.mall.com 60.60.60.41 172.16.100.41
* mc2.grid.mall.com 60.60.60.42 172.16.100.42

#### 数据库（db）

需要两台服务器提供数据库服务，两台服务器通过主从复制同步数据。

* db1.grid.mall.com 60.60.60.51 172.16.100.51
* db2.grid.mall.com 60.60.60.52 172.16.100.52

#### 搜索（search）

需要两台服务器提供搜索服务。

* search1.grid.mall.com 60.60.60.61 172.16.100.61
* search2.grid.mall.com 60.60.60.62 172.16.100.62

#### 共享存储（storage）

需要一台服务器提供存储服务。

* storage1.grid.mall.com 60.60.60.71 172.16.100.71

#### 管理机（admin）

需要一台管理机，上面部署Salt master，zabbix，svn等管理服务。

* admin.grid.mall.com 60.60.60.81 172.16.100.81

## Saltstack安装

Saltstack源码地址：https://github.com/saltstack/salt，最新版本为v2014.1.4。
需要自己[打rpm包](http://yoyolive.com/%E5%85%B6%E4%BB%96/2014/05/22/rpm-pkg.html)，salt描述文件：https://github.com/saltstack/salt/blob/develop/pkg/rpm/salt.spec，另外最新版本的salt需要python-libcloud，也需要提前打好包。如果是在CentOS 5.x 上安装salt，需要升级zeromq到3.x版。将所有打好的rpm包放入yum仓库，开始安装。

### Salt Master安装

注意：安装前确保主机名已按角色划分部分进行配置。

安装salt-master：

>\# yum install -y salt-master

修改配置文件：/etc/salt/master，使salt监听在内网网卡上。

>interface: 172.16.100.81

启动Salt Master：

>\# /etc/init.d/salt-master start

查看启动情况，4505端口处于监听状态：

>\# netstat -tunlp |grep 4505

### Salt Minion安装

注意：安装前确保主机名已按角色划分部分进行配置。

安装salt-minion：

>\# yum install -y salt-minion

修改配置文件：/etc/salt/minion，使其连接到master。

>master: 172.16.100.81

启动Salt Minion：

>\# /etc/init.d/salt-minion start

查看启动情况，4506端口处于监听状态：

>\# netstat -tunlp |grep 4506

### 在Salt Master上为Salt Minion授权

查看Salt Minion是否已经向Salt Master请求授权：

>\# salt-key -L  
Accepted Keys:  
Unaccepted Keys:  
admin.grid.mall.com  


为Salt Minion授权：

>\# salt-key -a admin.grid.mall.com

## 基础服务部署

对基础服务的管理包括配置管理系统、用户账号管理、yum配置管理、hosts文件管理、时间同步管理、DNS配置管理。

### 配置管理系统

配置管理系统使用模块化设计，每个服务一个模块，将多个模块组织到一起形成角色（/srv/salt/roles/）。所有模块放置到：/srv/salt下，入口配置文件为：/srv/salt/top.sls。模块使用的变量放置到：/srv/pillar，入口配置文件：/srv/pillar/top.sls。针对变量的作用域不同，将变量分为三级级，一级应用于模块（/srv/pillar/模块名），一级应用于角色（/srv/pillar/roles/），一级应用于主机节点（/srv/pillar/nodes）。具体配置在此不一一列出，具体参见salt配置文件。

入口配置/srv/salt/top.sls，直接引用各种角色：

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
      'storage*'.grid.mall.com':  
        - roles.storage  

变量入口配置文件/srv/pillar/top.sls：

    base:  
      '*':  
        - roles.common  
      # 引用角色级变量  
      # 模块级变量在角色级变量中引用  
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
      'storage*'.grid.mall.com':  
        - roles.storage  
      # 引用节点级变量
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

### 用户账号管理

用户管理模块：/srv/salt/users  

此模块用到pillar，pillar和grains都可以用来获取变量，但是grains偏向于获取客户端相关信息，比如硬件架构、cpu核数、操作系统版本等信息，相当于puppet的facter；pillar用于定义用户变量，通过pillar变量的传递，使salt state模块易于重用，相当于puppet的hiera。使用pillar变量之前需要执行salt '*' saltutil.refresh_pillar命令使定义生效。使用命令salt 'admin.grid.mall.com' pillar.item users获取users变量：

    # salt 'admin.grid.mall.com' pillar.item users  
    admin.grid.mall.com:  
        ----------  
        users:  
            ----------  
            dongliang:  
                ----------  
                fullname:  
                    Shi Dongliang  
                gid:  
                    1000  
                group:  
                    dongliang  
                password:  
                    $6$BZpX5dWZ$./TKqv8ZL3eLNAAmuiGWeT0SvwvpPtk5Nhgf8.xeyFd5XVMJ0QRh8HmiJOpJi7qPCo.  mfXIIrbQSGdAJVmZxW.  
                shell:  
                    /bin/bash  
                ssh_auth:  
                    ----------  
                    comment:  
                        dongliang@leju.com  
                    key:  
                        AAAAB3NzaC1yc2EAAAABIwAAAQEAmCqNHfK6VACeXsAnRfzq3AiSN+U561pSF8qoLOh5Ez38UqtsFLBaFdC/pTTxGQBYhwO2KkgWL9TtWOEp+LxYLskXUeG24pIe8y8r+edHC8fhmHGXWXQVmZwRERl+ygTdFt3ojhDu1FYA0WmKU07KgAqUrvJW1zwJsa/DaXExfwSzALAgm2jwx68hP9CO1msTAhtElUJWeLTlQTZr0ZGWvmlKzcwqxDX58HpA69qgccaOzO5n5qsQYXx8JmnCV18XW9bkxMvn5q8Y9o/to+BQ1440hKcsm9rNpJlIrnQaIbMZs/Sy2QnT+bVx9JyucDvaVJmsfJ+qZlfnhdRkm6eosw==  
                sudo:  
                    True  
                uid:  
                    1000  

获取admin.grid.mall.com上面定义的所有pillar变量： 

>\# salt 'admin.grid.mall.com' pillar.items

添加用户： 

/srv/salt/users/user.sls用于管理用户

{% highlight ruby %}
include:
  - users.sudo

{% for user, args in pillar['users'].iteritems() %}
{{user}}:
  group.present:
    - gid: {{args['gid']}}
  user.present:
    - home: /home/{{user}}
    - shell: {{args['shell']}}
    - uid: {{args['uid']}}
    - gid: {{args['gid']}}
    - fullname: {{args['fullname']}}
    {% if 'password' in args %}
    - password: {{args['password']}}
    {% endif %}
    - require:
      - group: {{user}}

{% if 'sudo' in args %}
{% if args['sudo'] %}
sudoer-{{user}}:
  file.append:
    - name: /etc/sudoers
    - text:
      - '{{user}}  ALL=(ALL)       NOPASSWD: ALL'
    - require:
      - file: sudoers
      - user: {{user}}
{% endif %}
{% endif %}

{% if 'ssh_auth' in args %}
/home/{{user}}/.ssh:
  file.directory:
    - user: {{user}}
    - group: {{args['group']}}
    - mode: 700
    - require:
      - user: {{user}}

/home/{{user}}/.ssh/authorized_keys:
  file.managed:
    - user: {{user}}
    - group: {{args['group']}}
    - mode: 600
    - require:
      - file: /home/{{user}}/.ssh

{{ args['ssh_auth']['key'] }}:
  ssh_auth.present:
    - user: {{user}}
    - comment: {{args['ssh_auth']['comment']}}
    - require:
      - file: /home/{{user}}/.ssh/authorized_keys
{% endif %}
{% endfor %}
{% endhighlight %}

sudo.sls为用户添加sudo权限：

    sudoers:  
      file.managed:  
        - name: /etc/sudoers  

/srv/salt/users/user.sls读取/srv/pillar/users/init.sls中的users变量。

    users:  
      dongliang:  # 定义用户名  
        group: dongliang  # 用户所在组  
        uid: 1000  # 用户uid  
        gid: 1000  # 用户gid  
        fullname: Shi Dongliang  
        password:   $6$BZpX5dWZ$./TKqv8ZL3eLNAAmuiGWeT0SvwvpPtk5Nhgf8.xeyFd5XVMJ0QRh8HmiJOpJi7qPCo.  mfXIIrbQSGdAJVmZxW.  # 密码，注意是hash后的密码  
        shell: /bin/bash  # 用户shell  
        sudo: true  # 是否给sudo权限  
        ssh_auth:  # 无密码登录，可选项  
          key: AAAAB3NzaC1yc2EAAAABIwAAAQEAmCqNHfK6VACeXsAnRfzq3AiSN+U561pSF8qoLOh5Ez38UqtsFLBaFdC/pTTxGQBYhwO2KkgWL9TtWOEp+LxYLskXUeG24pIe8y8r+edHC8fhmHGXWXQVmZwRERl+ygTdFt3ojhDu1FYA0WmKU07KgAqUrvJW1zwJsa/DaXExfwSzALAgm2jwx68hP9CO1msTAhtElUJWeLTlQTZr0ZGWvmlKzcwqxDX58HpA69qgccaOzO5n5qsQYXx8JmnCV18XW9bkxMvn5q8Y9o/to+BQ1440hKcsm9rNpJlIrnQaIbMZs/Sy2QnT+bVx9JyucDvaVJmsfJ+qZlfnhdRkm6eosw==  
          comment: dongliang@mall.com 

在salt-master上执行下面命令使配置生效  
> \# salt '*' saltutil.refresh_pillar  
> \# salt '*' state.highstate


### yum配置管理

yum配置管理：/srv/salt/base/repo.sls  
配置文件：/srv/salt/base/files/mall.repo  \# 此配置文件可以通过salt协议下发到客户端

/srv/salt/base/repo.sls定义，管理mall.repo文件，当文件改变后执行yum clean all清理缓存，是配置生效。

    /etc/yum.repos.d/mall.repo:  
      file.managed:  
        - source: salt://base/files/mall.repo  
        - user: root  
        - group: root  
        - mode: 644  
        - order: 1  
      cmd.wait:  
        - name: yum clean all  
        - watch:  
           - file: /etc/yum.repos.d/mall.repo  


### hosts文件管理

hosts文件管理：/srv/salt/base/hosts.sls  

/srv/salt/base/hosts.sls 定义了每个主机名和IP的对应关系。如下：

    admin.grid.mall.com:  
      host.present:  
        - ip: 172.16.100.81  
        - order: 1  
        - names:  
          - admin.grid.mall.com  

### 时间同步管理

时间同步作为一个cron，定义文件为：/srv/salt/base/crons.sls

    # 引用ntp模块  
    include:  
      - ntp  
       
    '/usr/sbin/ntpdate 1.cn.pool.ntp.org 1.asia.pool.ntp.org':  
      cron.present:  
        - user: root  
        - minute: 0  
        - hour: 2  

ntp模块：ntp/init.sls

    # 安装ntpdate软件包  
    ntpdate:  
      pkg.installed:  
        - name: ntpdate  

### DNS配置管理

配置DNS服务器定义在resolv.sls，控制/etc/resolv.conf配置文件:

    /etc/resolv.conf:  
      file.managed:  
        - source: salt://base/files/resolv.conf  
        - user: root  
        - group: root  
        - mode: 644  
        - template: jinja  

## 服务部署

本节以web服务器为例介绍salt服务的部署。把不同的服务组织成不同的角色，然后将角色应用到不同的节点上。通过角色的划分能够清晰的对不同的服务模块进行组织，所有角色的配置放到/srv/salt/roles下，角色用到的相关变量放到/srv/pillar/roles和/srv/pillar/nodes下，其中/srv/pillar/nodes下放置与具体节点相关的变量。

### 角色与配置文件

/srv/salt/roles/web.sls配置如下，包括nginx模块、rsync模块、limits模块和nfs.client：

    include:  
      - nginx  
      - rsync  
      - limits 
      - nfs.client  

变量/srv/pillar/roles/web.sls如下，没有单独应用到节点的变量:

    hostgroup: web  # 定义zabbix分组，具体见后文的自动化监控一节  
    vhostsdir: /data1/vhosts  # 代码发布目录  
    vhostscachedir: /data1/cache  # 程序临时目录  
    logdir: /data1/logs  # nginx日志目录  
    vhosts:  # 虚拟主机名，用于创建对用的代码发布目录  
      - www.mall.com  
      - static.mall.com  
    limit_users:  # 对用户打开文件数做设置  
      nginx:  
        limit_hard: 65535  
        limit_soft: 65535  
        limit_type: nofile  
    mounts: # nfs共享存储挂载相关配置  
      /data1/vhosts/static.mall.com/htdocs:  
        device: 172.16.100.71:/data1/share  
        fstype: nfs  
        mkmnt: True  
        opts: async,noatime,noexec,nosuid,soft,timeo=3,retrans=3,intr,retry=3,rsize=16384,wsize=16384  

### Nginx+PHP配置

管理模块：/srv/salt/nginx/  
nginx配置文件：/srv/salt/nginx/files/etc/nginx/，其中包括主配置文件、虚拟主机配置文件、和环境变量配置文件。  
php配置文件：主配置文件：/srv/salt/nginx/files/etc/php.ini 模块配置文件：/srv/salt/nginx/files/etc/php.d/  
php-fpm配置文件：主配置文件：/srv/salt/nginx/files/etc/php-fpm.conf 其他配置文件：/srv/salt/nginx/files/etc/php-fpm.d/  
角色配置：/srv/pillar/roles/web.sls  

#### 详细说明

/srv/salt/nginx/init.sls用于组织整个nginx模块：
 
    include:
      - nginx.server  # 包含nginx相关配置
      - nginx.php  # 包含php相关配置
      - nginx.monitor # 包含监控相关配置

/srv/salt/nginx/server.sls用于配置nginx服务：

定义nginx相关配置，主要包括安装nginx软件包配置相关配置文件，并启动nginx服务。  
![nginx server 1](http://yoyolive.com/assets/images/14-06-14/nginx_server_1.png)

创建日志目录、代码发布目录、代码缓存目录。并配置服务角色，角色也用于对服务的监控，详见后文自动化监控。  
![nginx server 2](http://yoyolive.com/assets/images/14-06-14/nginx_server_2.png)


/srv/salt/nginx/php.sls用于配置php服务：

定义php相关配置，主要包括安装php软件包配置相关配置文件，启动php-fpm服务，并配置服务角色。

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
  
    php-fpm-role:  # 定义php-fpm角色  
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

/srv/salt/nginx/monitor.sls用于配置对服务的监控：

    include:  
      - zabbix.agent  
      - nginx  
  
    nginx-monitor:  
      pkg.installed:  # 安装脚本依赖的软件包  
        - name: perl-libwww-perl  
  
    php-fpm-monitor-script:  # 管理监控脚本，如果脚本存放目录不存在自动创建  
      file.managed:  
        - name: /etc/zabbix/ExternalScripts/php-fpm_status.pl  
        - source: salt://nginx/files/etc/zabbix/ExternalScripts/php-fpm_status.pl  
        - user: root  
        - group: root  
        - mode: 755  
        - require:  
          - service: php-fpm  
          - pkg: nginx-monitor  
          - cmd: php-fpm-monitor-script  
      cmd.run:  
        - name: mkdir -p /etc/zabbix/ExternalScripts  
        - unless: test -d /etc/zabbix/ExternalScripts  
  
    php-fpm-monitor-config:  # 定义zabbix客户端用户配置文件  
      file.managed:  
        - name: /etc/zabbix/zabbix_agentd.conf.d/php_fpm.conf  
        - source: salt://nginx/files/etc/zabbix/zabbix_agentd.conf.d/php_fpm.conf  
        - require:  
          - file: php-fpm-monitor-script  
          - service: php-fpm  
        - watch_in:  
          - service: zabbix-agent  
  
    nginx-monitor-config:  # 定义zabbix客户端用户配置文件  
      file.managed:  
        - name: /etc/zabbix/zabbix_agentd.conf.d/nginx.conf  
        - source: salt://nginx/files/etc/zabbix/zabbix_agentd.conf.d/nginx.conf  
        - template: jinja  
        - require:  
          - service: nginx  
        - watch_in:  
          - service: zabbix-agent  

其他角色的部署跟web相似，不一一列出。


## 基于Saltstack部署系统搭建

部署系统基于Salt Runner编写，Salt Runner使用salt-run命令执行的命令行工具，可以通过调用Salt API很轻松构建。Salt Runner与Salt的执行模块很像，但是在Salt Master上运行而非Salt Minion上。

### 配置Salt Master

配置文件（/etc/salt/master.d/publish.conf）如下：

    svn:  
      username: 'publish'  # 定义svn用户名，用于检出代码  
      password: '#1qaz@WSX#ht'  # svn密码  
  
    publish:  
        master: 'admin.grid.mall.com'  # salt master主机名  
        cwd: '/data1/vhosts'  # 代码检出目录  

    projects:  
      www.mall.com:  # 定义项目名  
        remote: 'svn://172.16.100.81/www.mall.com' # svn存放路径  
        target:  # 定义代码部署列表 ip::rsync模块  
          - '172.16.100.21::www_mall_com'  
          - '172.16.100.22::www_mall_com'  
          - '172.16.100.23::www_mall_com'  

另外还要配置runner的放置目录：runner_dirs: [/srv/salt/_runners]，配置完成后要重启Puppet master。

### Web前端部署rsync服务

rsync服务由/srv/salt/rsync模块进行管理，rsync配置文件(etc/rsyncd.conf)如下：

    # File Managed by Salt  
  
    uid = nobody  
    gid = nobody  
    use chroot = yes  
    max connections = 150  
    pid file = /var/run/rsyncd.pid  
    log file = /var/log/rsyncd.log  
    transfer logging = yes  
    log format = %t %a %m %f %b  
    syslog facility = local3  
    timeout = 300  
    incoming chmod = Du=rwx,Dog=rx,Fu=rw,Fgo=r  
    hosts allow=172.16.100.0/24  
  
    [www_mall_com]  
    path=/data1/vhosts/www.mall.com/htdocs/  
    read only=no  

### 编写runner脚本

部署系统在Salt Master上把代码从SVN中检出，通过rsync命令部署到web前端。runner脚本(/srv/salt/_runners/publish.py)如下：

{% highlight python %}
# -*- coding: utf-8 -*-
'''
Functions to publish code on the master
'''

# Import salt libs
import salt.client
import salt.output


def push(project, output=True):
    '''
    publish code to web server.

    CLI Example:

    .. code-block:: bash

        salt-run publish.push project
    '''

    client = salt.client.LocalClient(__opts__['conf_file'])
    ret = client.cmd(__opts__['publish']['master'],
                      'svn.checkout',
                       [
                         __opts__['publish']['cwd'],
                         __opts__['projects'][project]['remote']
                       ],
                       {
                         'username': __opts__['svn']['username'],
                         'password':__opts__['svn']['password']
                       }
                    )

    msg = 'URL: %s\n%s' %(__opts__['projects'][project]['remote'], ret[__opts__['publish']['master']])
    ret = {'Check out code': msg}
    if output:
        salt.output.display_output(ret, '', __opts__)

    for target in __opts__['projects'][project]['target']:
        cmd = '/usr/bin/rsync -avz --exclude=".svn" %s/%s/trunk/* %s/' %(__opts__['publish']['cwd'], project, target)
        ret[target] = client.cmd(__opts__['publish']['master'],
                           'cmd.run',
                           [
                             cmd,
                           ],
                         )

        title = '\nSending file to %s' %target.split(':')[0]
        ret = {title: ret[target][__opts__['publish']['master']]}
        if output:
            salt.output.display_output(ret, '', __opts__)

    return ret
{% endhighlight %}

注意，一个项目（svn://172.16.100.81/www.mall.com ）通常会建立三个SVN子目录：trunk、branches、tags，上面脚本推送时只会将trunk目录下的代码部署到web前端。

### 代码部署

    # salt-run publish.push www.mall.com

publish为上文runner脚本名，push为此脚本中定义的推送函数，www.mall.com为salt master中定义的项目名。

参考：  
[Salt Runners](http://docs.saltstack.com/en/latest/ref/runners/)  
[Python client API](http://docs.saltstack.com/en/latest/ref/clients/index.html)  



## 自动化监控

本节参考了[绿肥](http://pengyao.org/)的《记saltstack和zabbix的一次联姻》，对zabbix添加监控脚本（add_monitors.py）进行部分修改而成，此脚本基于@超大杯摩卡星冰乐 同学的zapi进行更高级别的封装而成，在此表示感谢。

整自动化监控的过程如下：  
1. 通过Saltstack部署Zabbix server、Zabbix web、Zabbix api；  
2. 完成安装后需要手动导入Zabbix监控模板；  
3. 通过Saltstack部署服务及Zabbix agent；  
4. Saltstack在安装完服务后通过Salt Mine将服务角色汇报给Salt Master；  
5. Zabbix api拿到各服务角色后添加相应监控到Zabbix server。  

[Salt Mine](http://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.mine.html)用于将Salt Minion的信息存储到Salt Master，供其他Salt Minion使用。

下面以对nginx模块的监控为例讲述整个监控过程，其中Zabbix服务（Zabbix server、Zabbix web、Zabbix api）安装使用/srv/salt/zabbix进行管理，服务器部署在admin.grid.mall.com上。Zabbix agent使用/srv/salt/zabbix进行管理。nginx使用/srv/salt/nginx模块进行管理。

安装完nginx和php后定义相应地角色：

    nginx-role:  
      file.append:  
        - name: /etc/salt/roles  
        - text:  
          - 'nginx'  
        - require:  
          - file: roles  
          - service: nginx  
          - service: salt-minion  
        - watch_in:  
          - module: sync_grains  

    php-fpm-role:  # 定义php-fpm角色  
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

/srv/salt/nginx/monitor.sls用于配置zabbix agent和监控脚本：

    include:  
      - zabbix.agent  
      - nginx  
  
    nginx-monitor:  
      pkg.installed:  # 安装脚本依赖的软件包  
        - name: perl-libwww-perl  
  
    php-fpm-monitor-script:  # 管理监控脚本，如果脚本存放目录不存在自动创建  
      file.managed:  
        - name: /etc/zabbix/ExternalScripts/php-fpm_status.pl  
        - source: salt://nginx/files/etc/zabbix/ExternalScripts/php-fpm_status.pl  
        - user: root  
        - group: root  
        - mode: 755  
        - require:  
          - service: php-fpm  
          - pkg: nginx-monitor  
          - cmd: php-fpm-monitor-script  
      cmd.run:  
        - name: mkdir -p /etc/zabbix/ExternalScripts  
        - unless: test -d /etc/zabbix/ExternalScripts  
  
    php-fpm-monitor-config:  # 定义zabbix客户端用户配置文件  
      file.managed:  
        - name: /etc/zabbix/zabbix_agentd.conf.d/php_fpm.conf  
        - source: salt://nginx/files/etc/zabbix/zabbix_agentd.conf.d/php_fpm.conf  
        - require:  
          - file: php-fpm-monitor-script  
          - service: php-fpm  
        - watch_in:  
          - service: zabbix-agent  
  
    nginx-monitor-config:  # 定义zabbix客户端用户配置文件  
      file.managed:  
        - name: /etc/zabbix/zabbix_agentd.conf.d/nginx.conf  
        - source: salt://nginx/files/etc/zabbix/zabbix_agentd.conf.d/nginx.conf  
        - template: jinja  
        - require:  
          - service: nginx  
        - watch_in:  
          - service: zabbix-agent  

Salt Minion收集各个角色到/etc/salt/roles中，并生成grains，Salt Mine通过grains roles获取角色信息，当roles改变后通知Salt Mine更新。

    roles:  
      file.managed:  
        - name: /etc/salt/roles  

    sync_grains:  
      module.wait:  
        - name: saltutil.sync_grains  

    mine_update:  
      module.run:  
        - name: mine.update  
        - require:  
          - module: sync_grains  

/srv/pillar/salt/minion.sls 定义Salt Mine functions：

    mine_functions:
      test.ping: []
      grains.item: [id, hostgroup, roles, ipv4]

grains类似puppet facer，用于收集客户端相关的信息。本文grains脚本（/srv/salt/_grains/roles.py）通过读取/etc/salt/roles文件生成grains roles:

{% highlight python %}
import os.path

def roles():
    '''define host roles'''

    roles_file = "/etc/salt/roles"
    roles_list = []
  
    if os.path.isfile(roles_file):
        roles_fd = open(roles_file, "r")
        for eachroles in roles_fd:
            roles_list.append(eachroles[:-1])
    return {'roles': roles_list}


if __name__ == "__main__":
    print roles()
{% endhighlight %}

Zabbix api的配置通过/srv/salt/zabbix/api.sls进行管理，主要完成对zapi的安装、Zabbix api角色的添加、Zabbix api配置文件的管理、添加监控脚本的管理以及更新监控配置并添加监控。此配置未实现zabbix模板的自动导入，所以需要手动导入模板(/srv/salt/zabbix/files/etc/zabbix/api/templates/zbx_export_templates.xml)。

![zabbix api 1](http://yoyolive.com/assets/images/14-06-16/zabbix_api_1.png)  
![zabbix api 2](http://yoyolive.com/assets/images/14-06-16/zabbix_api_2.png)  


上面配置读取/srv/pillar/zabbix/api.sls配置文件：

![zabbix api pillar](http://yoyolive.com/assets/images/14-06-16/zabbix_api_pillar.png)  

zabbix-api中定义zabbix url、用户名、密码以及监控配置目录和模板目录等。zabbix-base-templates定义基本监控模板，基本监控模板是需要加到所有机器上的。zabbix-templates定义角色与模板的对应关系。


添加监控脚本（/srv/salt/zabbix/files/etc/zabbix/api/add_monitors.py ）如下：

{% highlight python %}
#!/bin/env python
#coding=utf8

##########################################################
# Add Monitor To Zabbix
##########################################################

import sys, os.path
import yaml

from zabbix.zapi import *

def _config(config_file):
    '''get config'''
    
    config_fd = open(config_file)
    config = yaml.load(config_fd)

    return config

def _get_templates(api_obj, templates_list):
    '''get templates ids'''

    templates_id = {}
    templates_result = api_obj.Template.getobjects({"host": templates_list})
    
    for each_template in templates_result:
        template_name = each_template['name']
        template_id = each_template['templateid']
        templates_id[template_name] = template_id

    return templates_id

def _get_host_templates(api_obj, hostid):
    '''get the host has linked templates'''

    templates_id = []
    templates_result = api_obj.Template.get({'hostids': hostid})
      
    for each_template in templates_result:
        template_id = each_template['templateid']
        templates_id.append(template_id)

    return templates_id


def _create_hostgroup(api_obj, group_name):
    '''create hostgroup'''

    ##check hostgroup exists
    hostgroup_status = api_obj.Hostgroup.exists({"name": "%s" %(group_name)}) 
    if hostgroup_status:
        print "Hostgroup(%s) is already exists" %(group_name)
        group_id = api_obj.Hostgroup.getobjects({"name": "%s" %(group_name)})[0]["groupid"]
    else:
        hostgroup_status = api_obj.Hostgroup.create({"name": "%s" %(group_name)})
        if hostgroup_status:
            print "Hostgroup(%s) create success" %(group_name)
            group_id = hostgroup_status["groupids"][0]
        else:
            sys.stderr.write("Hostgroup(%s) create failed, please connect administrator\n" %(group_name))
            exit(2)

    return group_id

def _create_host(api_obj, hostname, hostip, group_ids):
    '''create host'''

    ##check host exists
    host_status = api_obj.Host.exists({"name": "%s" %(hostname)})
    if host_status:
        print "Host(%s) is already exists" %(hostname)
        hostid = api_obj.Host.getobjects({"name": "%s" %(hostname)})[0]["hostid"]
        ##update host groups
        groupids = [group['groupid'] for group in api_obj.Host.get({"output": ["hostid"], "selectGroups": "extend", "filter": {"host": ["%s" %(hostname)]}})[0]['groups']]
        is_hostgroup_update = 0
        for groupid in group_ids:
            if groupid not in groupids:
                is_hostgroup_update = 1
                groupids.append(groupid)
        if is_hostgroup_update == 1:
            groups = []
            for groupid in groupids:
                groups.append({"groupid": "%s" %(groupid)})
            host_status = api_obj.Host.update({"hostid": "%s" %(hostid), "groups": groups})
            if host_status:
                print "Host(%s) group update success" %(hostname)
            else:
                sys.stderr.write("Host(%s) group update failed, please connect administrator\n" %(hostname))
                exit(3)
    else:
        groups = []
        for groupid in group_ids:
            groups.append({"groupid": "%s" %(groupid)})
        host_status = api_obj.Host.create({"host": "%s" %(hostname), "interfaces": [{"type": 1, "main": 1, "useip": 1, "ip": "%s" %(hostip), "dns": "", "port": "10050"}], "groups": groups})
        if host_status:
            print "Host(%s) create success" %(hostname)
            hostid = host_status["hostids"][0] 
        else:
            sys.stderr.write("Host(%s) create failed, please connect administrator\n" %(hostname))
            exit(3)

    return hostid

def _create_host_usermacro(api_obj, hostname, usermacro):
    '''create host usermacro'''

    for macro in usermacro.keys():
        value = usermacro[macro]

    ##check host exists
    host_status = api_obj.Host.exists({"name": "%s" %(hostname)})
    if host_status:
        hostid = api_obj.Host.getobjects({"name": "%s" %(hostname)})[0]["hostid"]
        ##check usermacro exists
        usermacros = api_obj.Usermacro.get({"output": "extend", "hostids": "%s" %(hostid)})
        is_macro_exists = 0
        if usermacros:
            for usermacro in usermacros:
                if usermacro["macro"] == macro:
                    is_macro_exists = 1
                    if usermacro["value"] == str(value):
                        print "Host(%s) usermacro(%s) is already exists" %(hostname, macro)
                        hostmacroid = usermacro["hostmacroid"]
                    else:
                        ##usermacro exists, but value is not the same, update
                        usermacro_status = api_obj.Usermacro.update({"hostmacroid": usermacro["hostmacroid"], "value": "%s" %(value)})
                        if usermacro_status:
                            print "Host(%s) usermacro(%s) update success" %(hostname, macro)
                            hostmacroid = usermacro_status["hostmacroids"][0]
                        else:
                            sys.stderr.write("Host(%s) usermacro(%s) update failed, please connect administrator\n" %(hostname, macro))
                            exit(3)
                    break
        if is_macro_exists == 0:
            usermacro_status = api_obj.Usermacro.create({"hostid": "%s" %(hostid), "macro": "%s" %(macro), "value": "%s" %(value)})
            if usermacro_status:
                print "Host(%s) usermacro(%s) create success" %(hostname, macro)
                hostmacroid = usermacro_status["hostmacroids"][0]
            else:
                sys.stderr.write("Host(%s) usermacro(%s) create failed, please connect administrator\n" %(hostname, macro))
                exit(3)
    else:
        sys.stderr.write("Host(%s) is not exists" %(hostname))
        exit(3)

    return hostmacroid

def _link_templates(api_obj, hostname, hostid, templates_list, donot_unlink_templates):
    '''link templates'''

    all_templates = []
    clear_templates = []
    ##get templates id
    if donot_unlink_templates is None:
        donot_unlink_templates_id = {}
    else:
        donot_unlink_templates_id = _get_templates(api_obj, donot_unlink_templates)
    templates_id = _get_templates(api_obj, templates_list) 
    ##get the host currently linked tempaltes
    curr_linked_templates = _get_host_templates(api_obj, hostid)
    
    for each_template in templates_id:
        if templates_id[each_template] in curr_linked_templates:
            print "Host(%s) is already linked %s" %(hostname, each_template)
        else:
            print "Host(%s) will link %s" %(hostname, each_template)
        all_templates.append(templates_id[each_template])
    
    ##merge templates list
    for each_template in curr_linked_templates:
        if each_template not in all_templates:
            if each_template in donot_unlink_templates_id.values():
                all_templates.append(each_template)
            else:
                clear_templates.append(each_template)


    ##convert to zabbix api style
    templates_list = []
    clear_templates_list = []
    for each_template in all_templates:
        templates_list.append({"templateid": each_template})
    for each_template in clear_templates:
        clear_templates_list.append({"templateid": each_template})


    ##update host to link templates
    update_status = api_obj.Host.update({"hostid": hostid, "templates": templates_list})

    if update_status:
        print "Host(%s) link templates success" %(hostname)
    else:
        print "Host(%s) link templates failed, please contact administrator" %(hostname)

    ##host unlink templates
    if clear_templates_list != []:
        clear_status = api_obj.Host.update({"hostid": hostid, "templates_clear": clear_templates_list})
        if clear_status:
            print "Host(%s) unlink templates success" %(hostname)
        else:
            print "Host(%s) unlink templates failed, please contact administrator" %(hostname)


def _main():
    '''main function'''
  
    hosts = [] 
    if len(sys.argv) > 1:
        hosts = sys.argv[1:]
    
    config_dir = os.path.dirname(sys.argv[0])
    if config_dir:
        config_file = config_dir+"/"+"config.yaml"
    else:
        config_file = "config.yaml"

    ###get config options
    config = _config(config_file)
    Monitor_DIR = config["Monitors_DIR"]
    Zabbix_URL = config["Zabbix_URL"]
    Zabbix_User = config["Zabbix_User"]
    Zabbix_Pass = config["Zabbix_Pass"]
    Zabbix_Donot_Unlink_Template = config["Zabbix_Donot_Unlink_Template"]

    if not hosts:
        hosts = os.listdir(Monitor_DIR)

    ###Login Zabbix 
    zapi = ZabbixAPI(url=Zabbix_URL, user=Zabbix_User, password=Zabbix_Pass)
    zapi.login()

    for each_host in hosts:
        each_config_fd = open(Monitor_DIR+"/"+each_host) 
        each_config = yaml.load(each_config_fd)
     
        ##Get config options
        each_ip = each_config["IP"]
        hostgroups = each_config["Hostgroup"]
        each_templates = each_config["Templates"]
        each_usermacros = each_config["Usermacros"]

        ###Create Hostgroup
        groupids = []
        for each_hostgroup in hostgroups:
            group_id = _create_hostgroup(zapi, each_hostgroup)
            groupids.append(group_id)

        ##Create Host
        hostid = _create_host(zapi, each_host, each_ip, groupids)

        if each_usermacros:
            ##Create Host Usermacros
            for usermacro in each_usermacros:
                if usermacro:
                    usermacrosid = _create_host_usermacro(zapi, each_host, usermacro)
    
        if each_templates:
            ##Link tempaltes
            _link_templates(zapi, each_host, hostid, each_templates, Zabbix_Donot_Unlink_Template)
           

if __name__ == "__main__":
    _main()
{% endhighlight %}

参考：[zabbix api](https://www.zabbix.com/documentation/2.2/manual/api)

此脚本读取的配置文件（/srv/salt/zabbix/files/etc/zabbix/api/config.yaml）:

    Monitors_DIR: {{Monitors_DIR}}  
    Templates_DIR: {{Templates_DIR}}  
    Zabbix_URL: {{Zabbix_URL}}  
    Zabbix_User: {{Zabbix_User}}  
    Zabbix_Pass: {{Zabbix_Pass}}  
    Zabbix_Donot_Unlink_Template:  # zabbix自动维护连接的模板，手动连接到主机上的模板需要在此处列出
      - 'Template OS Linux'  


## Salt模块的扩展

对Salt进行模块化设计就是为了扩展，另外将变量抽象出来放到pillar中也是为了模块可以重用。当你需要配置两个web平台，而这两个平台又有些许不同时你该怎么办？需要重新再写个nginx模块适配新的平台吗？

对于上面问题的回答是否定的，我们无需再重新写一个nginx模块，我们只需要对新的平台传递新的配置文件或者使用同一个模板传递不同的参数。

#### 使用不同的配置文件

当两个平台配置相差比较大时可能传递一个不同的配置文件会更合适，如下：

    /etc/rsyncd.conf:  
      file.managed:  
        - source: salt://rsync/files/etc/{{salt['pillar.get']('rsync_template', 'rsyncd.conf')}}  
        - template: jinja  
        - user: root  
        - group: root  
        - mode: 644  

为不同的节点在pillar中配置不同的rsync_template变量即可。

#### 使用同一个模板传递不同的参数

    /etc/keepalived/keepalived.conf:  
      file.managed:  
        - source: salt://keepalived/files/etc/keepalived/keepalived.conf  
        - template: jinja  
        - user: root  
        - group: root  
        - mode: 644  

对于主服务器(/srv/salt/pillar/nodes/ha1.sls )使用如下pillar变量：

    keepalived:  
      notification_email: 'dongliang@mall.com'  
      notification_email_from: 'haproxy@mall.com'  
      smtp_server: 127.0.0.1  
      state: MASTER  
      priority: 100  
      auth_type: PASS  
      auth_pass: mall  
      virtual_ipaddress_internal: 172.16.100.100  
      virtual_ipaddress_external: 60.60.60.100  

对于从服务器(/srv/salt/pillar/nodes/ha2.sls )使用如下pillar变量：

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


