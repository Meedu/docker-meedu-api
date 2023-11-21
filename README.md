# MeEdu docker 一键运行方案

- [x] php7.4
- [x] 定时任务
- [x] 消费者队列

## 一、直接运行官方发行的镜像

```
docker run -d -p 80:80 --name meedu-api \
  -e DB_HOST=数据库HOST \
  -e DB_PORT=数据库端口 \
  -e DB_DATABASE=数据库名 \
  -e DB_USERNAME=数据库用户名 \
  -e DB_PASSWORD=数据库密码 \
  -e CACHE_DRIVER=redis \
  -e SESSION_DRIVER=redis \
  -e QUEUE_DRIVER=redis \
  -e REDIS_HOST=redis的HOST \
  -e REDIS_PASSWORD=null \
  -e REDIS_PORT=6379 \
  -e APP_KEY=base64:s9M5EmBWLWerXU/udZ8biH8GYGKBAEtatGNI2XnzEVM= \
  -e JWT_SECRET=26tpIiNHtYE0YsXeDge837qfIXVmlOES8l9M2u9OTrCZ9NASZcqJdYXBaOSPeLsh \
  meeduxyz/api:4.9.5
```

> 请注意替换上述命令中的配置值。为了应用安全，请将 `APP_KEY` 和 `JWT_SECRET` 的值也一并更换。

如果是第一次运行系统的话，您还需要执行下面的命令初始化系统数据：

```
# 初始化数据表
docker exec meedu-api php artisan migrate --force

# 初始化系统配置
docker exec meedu-api php artisan install config

# 初始化系统管理角色
docker exec meedu-api php artisan install role

# 初始化系统管理员
docker exec -i meedu-api php artisan install administrator
```

## 二、自行构建并运行镜像

### 第一步、克隆本仓库

```
git clone https://github.com/Meedu/docker-meedu-api.git docker-meedu-api
```

### 第二步、克隆 `meedu` API 代码

```
cd docker-meedu-api

git clone https://github.com/Qsnh/meedu.git api
```

### 第三步、生成 `.env` 配置文件

```
cd api

cp .env.example .env
```

### 第四步、打包生成镜像

```
docker build -t meedu-api:latest .
```

### 第五步、运行 `meedu-api` 服务

```
docker run -d -p 80:80 --name meedu-api \
  -e DB_HOST=数据库HOST \
  -e DB_PORT=数据库端口 \
  -e DB_DATABASE=数据库端口 \
  -e DB_USERNAME=数据库用户名 \
  -e DB_PASSWORD=数据库密码 \
  -e CACHE_DRIVER=redis \
  -e SESSION_DRIVER=redis \
  -e QUEUE_DRIVER=redis \
  -e REDIS_HOST=redis的HOST \
  -e REDIS_PASSWORD=null \
  -e REDIS_PORT=6379 \
  -e APP_KEY=base64:s9M5EmBWLWerXU/udZ8biH8GYGKBAEtatGNI2XnzEVM= \
  -e JWT_SECRET=26tpIiNHtYE0YsXeDge837qfIXVmlOES8l9M2u9OTrCZ9NASZcqJdYXBaOSPeLsh \
  meedu-api:latest
```

请按照自己的环境配置修改上述的命令。为了应用更加安全，请修改 `APP_KEY` 和 `JWT_SECRET` 的值。

## 三、镜像信息

### `Nginx`

| 配置项       | 值                          |
| ------------ | --------------------------- |
| 配置文件路径 | `/etc/nginx`                |
| `access.log` | `/var/log/nginx/access.log` |
| `error.log`  | `/var/log/nginx/error.log`  |

### `php-fpm`

| 配置项    | 值                                                              |
| --------- | --------------------------------------------------------------- |
| `php.ini` | `/usr/local/etc/php/php.ini`                                    |
| 配置文件  | `/usr/local/etc/php-fpm.conf`,`/usr/local/etc/php-fpm.d/*.conf` |
| 访问日志  | `/var/log/php/php-fpm.access.$pool.log`                         |
| 慢日志    | `/var/log/php/php-fpm.slow.$pool.log`                           |

## `php-fpm` 性能优化

在不同的配置机器中可以通过修改 `php-fpm` 的配置来达到最大的性能。你可以修改 `php/php-fpm.d/www.conf` 中的配置并重新 `build` 新的镜像使配置生效。

### 如何设置合理的 `pm` ?

- 【最大子进程数量】越大，并发能力越强，但 `pm.max_children` 最大不要超过 5000
- 【内存】每个 `PHP` 子进程需要 `20MB` 左右内存，过大的 `pm.max_children` 会导致服务器不稳定
- 【静态模式】始终维持设置的子进程数量，对内存开销较大，但并发能力较好
- 【动态模式】按设置最大空闲进程数来收回进程，内存开销小，建议小内存机器使用
- 【按需模式】根据访问需求自动创建进程，内存开销极小，但并发能力略差

得知，并发能力依次递减：静态模式 > 动态模式 > 按需模式。因为我们是容器安装，因此我们推荐直接上静态模式，按照下面要求配置即可：

```conf
pm = dynamic
pm.max_children = (容器可使用内存*0.8) / 20
```

> 上述预留了 20% 的内存。因为 PHP 涉及到图像操作的时候将会极其消耗内存。

### 原理解释

`php-fpm` 的新能主要通过下面的参数调整：

```conf
; 选择进程管理器如何控制子进程的数量。
; 可能的值：
; static - 静态模式 - 固定数量的子进程（pm.max_children）；
; dynamic - 动态模式 - 子进程的数量是根据以下指令动态设置的。使用此进程管理，将始终至少有 1 个子进程。
;   pm.max_children - 可同时存在的最大子进程数。
;   pm.start_servers - 启动时创建的子进程数。
;   pm.min_spare_servers - 处于“空闲”状态（等待处理）的最小子进程数。如果“空闲”进程数小于此数，则会创建一些子进程。
;   pm.max_spare_servers - 处于“空闲”状态（等待处理）的最大子进程数。如果“空闲”进程数大于此数，则会杀死一些子进程。
; ondemand - 按需模式 - 在启动时不创建子进程。当新请求连接时将分叉子进程。使用以下参数：
;   pm.max_children - 可同时存在的最大子进程数。
;   pm.process_idle_timeout - 空闲进程将被杀死的秒数。
; 注意：此值为必填项。
pm = static

; 当 pm 设置为“static”时创建的子进程数以及当 pm 设置为“dynamic”或“ondemand”时的最大子进程数。
; 此值设置了将同时处理的请求数的限制。相当于使用 mpm_prefork 的 ApacheMaxClients 指令。
; 相当于原始 PHP CGI 中的 PHP_FCGI_CHILDREN 环境变量。下面的默认值基于没有太多资源的服务器。不要忘记调整 pm.* 以适应您的需求。
; 注意：当 pm 设置为“static”、“dynamic”或“ondemand”时使用。
; 注意：此值为必填项。
pm.max_children = 10

; 启动时创建的子进程数。
; 注意：仅在 pm 设置为“dynamic”时使用。
; 默认值：（min_spare_servers + max_spare_servers）/ 2
pm.start_servers = 2

; 空闲服务器进程的最小数量。
; 注意：仅在 pm 设置为“dynamic”时使用。
; 注意：当 pm 设置为“dynamic”时为必填项。
pm.min_spare_servers = 1

; 空闲服务器进程的最大数量。
; 注意：仅在 pm 设置为“dynamic”时使用。
; 注意：当 pm 设置为“dynamic”时为必填项。
pm.max_spare_servers = 3
```

## 定时任务

我们可以通过 `crontab` 去配置 `MeEdu` 的定时任务，通过下面的命令打开系统的定时任务编辑器：

```
crontab -e
```

在打开的窗口最后一行另起一行，然后输入下面的配置：

```
* * * * * docker exec meedu-api php /var/www/artisan schedule:run >> /dev/null 2>&1
```

> 注意，如果您的 `MeEdu` 是分布式部署的话，那么请给定时任务单独分配一台机器用户处理。

## 消费者队列进程

如果 `MeEdu` 的 `API` 程序下的 `.env` 文件中的 `QUEUE_DRIVER` 的值不是 `sync` 的话，那么我们需要配置消费者队列进程。下面给出`Ubuntu`,`Centos`的配置教程：
  
### `Ubuntu` 配置教程

首先，安装 `Supervisor`

```
sudo apt update
sudo apt install supervisor
```

创建 `Supervisor` 的配置文件：

```
vi /etc/supervisor/conf.d/meedu-queue.conf
```

输入下面内容：

```
[program:meedu-queue]
process_name=%(program_name)s_%(process_num)02d
command=docker exec meedu-api php /var/www/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=root
numprocs=1
redirect_stderr=true
stdout_logfile=/home/ubuntu/meedu-queue-sv.log
```

让配置生效：

```
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start meedu-queue:*
```

### `Centos` 配置教程

首先，安装 `Supervisor`

```
yum install epel-release
yum install -y supervisor
```

配置 `Supervisor` 开机启动

```
systemctl enable supervisord
systemctl start supervisord 
```

创建 `Supervisor` 的配置文件：

```
vi /etc/supervisord.d/meedu-queue.ini
```

并输入下面内容：

```
[program:meedu-queue]
process_name=%(program_name)s_%(process_num)02d
command=docker exec meedu-api php /var/www/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=root
numprocs=1
redirect_stderr=true
stdout_logfile=/root/meedu-queue-sv.log
```

让配置生效：

```
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start meedu-queue:*
```

## 其它

### 我们可以指定容器可使用的最大 `CPU` 核数、内存数

```
docker run --cpus=1 --memory=512m <image_name>
```

上述案例就是限制容器只能使用 `1h,512m` 的资源。
