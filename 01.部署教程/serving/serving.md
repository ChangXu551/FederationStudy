
#前端打包
```shell
npm run dev
npm run build
npm run build -- dev // dev 对应了 .env 中的配置
```
#前端镜像构建
```shell
FROM nginx:1.19.2

WORKDIR /opt/website

COPY html /opt/website/

RUN chmod +x /opt/website

```
#前端镜像保存
```sh
sudo docker build -t wefe_serving_website:$WEFE_VERSION .
sudo docker save -o wefe_serving_website_$WEFE_VERSION.tar wefe_serving_website:$WEFE_VERSION
```




#后端项目打包方法
#初始化数据库
执行SQl脚本：serving-init.sql
```shell
mvn clean install -Dmaven.test.skip=true -am -pl serving/serving-service
```
SDK 使用方法
导入 sdk

```shell
 <dependencies>
    <dependency>
         <groupId>com.welab.wefe</groupId>
          <artifactId>serving-sdk-java</artifactId>
          <version>1.0.0</version>
      </dependency>
</dependencies>
```
#后端Dockerfile
```shell
FROM wefe_java_base

WORKDIR /opt/service

COPY serving-service.jar /opt/service/serving-service.jar

COPY start.sh /opt/service/start.sh

# RUN chmod +x /opt/service/start.sh

CMD ["sh", "/opt/service/start.sh"]

````

#启动脚本start.sh
```shell
java -jar serving-service.jar
```
#后端镜像保存
```dockerfile
sudo docker build -t wefe_serving_service:$WEFE_VERSION .
sudo docker save -o wefe_serving_service_$WEFE_VERSION.tar wefe_serving_service:$WEFE_VERSION
```

#docker-compose

可以将外面的application.properties挂载到容器内jar包同一位置，即可生效
```shell
version: "3"
services:

  wefe_serving_website:
    image: wefe_serving_website:v.2.2 # wefe_version
    ports:
      - 3310:80 # website_port
    restart: always
    privileged: true
    networks:
      - network
    volumes:
      - "./mount/default.conf:/etc/nginx/conf.d/default.conf"
  wefe_serving_service:
    image: wefe_serving_service:v.2.2 # wefe_version
    ports:
      - 9000:9000 # website_port
    restart: always
    privileged: true
    networks:
      - network
    volumes:
      - "/root/docker-compose/logs/service:/data/logs/wefe-serving-service" # service_logs
      - "./mount/start.sh:/opt/service/start.sh"
      - "./mount/serving-service.jar:/opt/service/serving-service.jar"
      - "./mount/application.properties:/opt/service/application.properties"

networks:
  network:
    driver: bridge
```

#nginx,default.conf
```shell
server {

    listen  80;
    server_name  10.10.178.147;

    client_max_body_size 100m;


    location / {
         root  /opt/website/serving-website;
    }
    
    location /serving-service/ {
    	add_header Access-Control-Allow-Origin *;
    	add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
    	add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization';

    	if ($request_method = 'OPTIONS') {
    		return 204;
		}

		proxy_pass http://10.10.178.147:9000/serving-service/;
		proxy_read_timeout 1800;
    }

}

```
#启动脚本
```shell
#!/bin/bash

# 导入配置
source ../wefe.cfg

echo "开始加载 serving的前后端 离线镜像"
docker load < resources/wefe_serving_website_v2.2\.tar
docker load < resources/wefe_serving_servicev2.2\.tar
echo "加载 serving的前后端 离线镜像完成"

docker-compose -p $WEFE_ENV -f resources/docker-compose.yml up -d

```

#停止脚本
```shell
docker-compose -p wefe -f resources/docker-compose.yml down
```


发起方可以不用硬性要求sql方式获取。
纵向联邦学习进行预测推理的时候，双方都没有完整的模型，且只有发起方通过调用协作方才能进行完整的预测（此部分逻辑代码底层处理），协作方是不能进行预测的，
协作方这里的配置是为了保证发起方能正常的调用到己方。 
所以配置的优先级一般是协作方->发起方。


#内部玩 debug,provider接口
协作方模型上线，并且提前debug预测校验数据库。这里建议改成 select feature1,feature2 from table where id = ?。这里的？是一个占位符，会将你下面填的a填充进来组成sql
发起方配置 {{baseUr}}/serving-service/predict/provider/，指向协作方
http://10.10.178.147:9000/serving-service/predict/provider/
http://124.71.228.136:9000/serving-service/predict/provider/
http://123.249.9.220:9000/serving-service/predict/provider/

发起方最后预测

#外部玩 promter接口
发起方模型上线
如果说是你们内部系统自己调用的话可以通过此接口{{baseUr}}/serving-service/predict/promter/调用，这个接口会通过你当时初始化提供的board公钥进行验签的。  
如果是提供给外部调用，你就需要再包装一层，接收到对方的请求后自己再加一次签名，然后调用上述接口。


#私钥签名，公钥验签
AbstractAlgorithm.setFederatedPredictBody
Launcher.apiPermissionPolicy