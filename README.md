# MeEdu docker 一键运行方案

## 构建方法

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