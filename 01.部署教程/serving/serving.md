
#ǰ�˴��
```shell
npm run dev
npm run build
npm run build -- dev // dev ��Ӧ�� .env �е�����
```
#ǰ�˾��񹹽�
```shell
FROM nginx:1.19.2

WORKDIR /opt/website

COPY html /opt/website/

RUN chmod +x /opt/website

```
#ǰ�˾��񱣴�
```sh
sudo docker build -t wefe_serving_website:$WEFE_VERSION .
sudo docker save -o wefe_serving_website_$WEFE_VERSION.tar wefe_serving_website:$WEFE_VERSION
```




#�����Ŀ�������
#��ʼ�����ݿ�
ִ��SQl�ű���serving-init.sql
```shell
mvn clean install -Dmaven.test.skip=true -am -pl serving/serving-service
```
SDK ʹ�÷���
���� sdk

```shell
 <dependencies>
    <dependency>
         <groupId>com.welab.wefe</groupId>
          <artifactId>serving-sdk-java</artifactId>
          <version>1.0.0</version>
      </dependency>
</dependencies>
```
#���Dockerfile
```shell
FROM wefe_java_base

WORKDIR /opt/service

COPY serving-service.jar /opt/service/serving-service.jar

COPY start.sh /opt/service/start.sh

# RUN chmod +x /opt/service/start.sh

CMD ["sh", "/opt/service/start.sh"]

````

#�����ű�start.sh
```shell
java -jar serving-service.jar
```
#��˾��񱣴�
```dockerfile
sudo docker build -t wefe_serving_service:$WEFE_VERSION .
sudo docker save -o wefe_serving_service_$WEFE_VERSION.tar wefe_serving_service:$WEFE_VERSION
```

#docker-compose

���Խ������application.properties���ص�������jar��ͬһλ�ã�������Ч
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
#�����ű�
```shell
#!/bin/bash

# ��������
source ../wefe.cfg

echo "��ʼ���� serving��ǰ��� ���߾���"
docker load < resources/wefe_serving_website_v2.2\.tar
docker load < resources/wefe_serving_servicev2.2\.tar
echo "���� serving��ǰ��� ���߾������"

docker-compose -p $WEFE_ENV -f resources/docker-compose.yml up -d

```

#ֹͣ�ű�
```shell
docker-compose -p wefe -f resources/docker-compose.yml down
```


���𷽿��Բ���Ӳ��Ҫ��sql��ʽ��ȡ��
��������ѧϰ����Ԥ�������ʱ��˫����û��������ģ�ͣ���ֻ�з���ͨ������Э�������ܽ���������Ԥ�⣨�˲����߼�����ײ㴦����Э�����ǲ��ܽ���Ԥ��ģ�
Э���������������Ϊ�˱�֤�����������ĵ��õ������� 
�������õ����ȼ�һ����Э����->���𷽡�


#�ڲ��� debug,provider�ӿ�
Э����ģ�����ߣ�������ǰdebugԤ��У�����ݿ⡣���ｨ��ĳ� select feature1,feature2 from table where id = ?������ģ���һ��ռλ�����Ὣ���������a���������sql
�������� {{baseUr}}/serving-service/predict/provider/��ָ��Э����
http://10.10.178.147:9000/serving-service/predict/provider/
http://124.71.228.136:9000/serving-service/predict/provider/
http://123.249.9.220:9000/serving-service/predict/provider/

�������Ԥ��

#�ⲿ�� promter�ӿ�
����ģ������
���˵�������ڲ�ϵͳ�Լ����õĻ�����ͨ���˽ӿ�{{baseUr}}/serving-service/predict/promter/���ã�����ӿڻ�ͨ���㵱ʱ��ʼ���ṩ��board��Կ������ǩ�ġ�  
������ṩ���ⲿ���ã������Ҫ�ٰ�װһ�㣬���յ��Է���������Լ��ټ�һ��ǩ����Ȼ����������ӿڡ�


#˽Կǩ������Կ��ǩ
AbstractAlgorithm.setFederatedPredictBody
Launcher.apiPermissionPolicy