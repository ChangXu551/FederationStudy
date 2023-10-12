#!/bin/bash
# 导入配置
source ../wefe.cfg

echo "开始加载 serving的前后端 离线镜像"
docker load < resources/wefe_serving_website_v.2.2\.tar
docker load < resources/wefe_serving_service_v.2.2\.tar
echo "加载 serving的前后端 离线镜像完成"

docker-compose -p $WEFE_ENV -f resources/docker-compose.yml up -d