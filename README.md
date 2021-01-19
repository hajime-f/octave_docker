# How to build an environment for Django + Vue.js with Docker

## Overview

This GitHub page introduces an approach to build an environment for Django + Vue.js.

The page consists of two parts:
1. [The former part describes how to build a development environment](https://github.com/hajime-f/octave_docker#how-to-build-a-development-environment).
2. The latter part describes how to deploy an implemented application on AWS Fargate.

I am making a web application called “octave”, which can manage activities of orchestras. Please replace "octave" to your application name in the description below.

## Versions

The versions of operating environments and packages are shown below:

- Operating environments
  - macOS Big Sur 11.1 (Host)
  - VirtualBox 6.1.16
  - Ubuntu Server 20.04 LTS (Guest)
- Packages
  - Docker 20.10.2
  - docker-compose 1.24.1
  - Python 3.9
  - Django 3.1.4
  - Node 15.5
  - Vue CLI 4.5.10
  - nginx 1.17
  - MySQL 5.7
  - Make 4.2.1

# How to build a development environment

## Directory

The directory structure is shown below:

```bash
octave
├── .env
├── docker-compose.dev.yml
├── docker-compose.prod.yml
├── Makefile
├── mysql
│   ├── Dockerfile
│   └── init.d
│       └── init.sql
├── nginx
│   ├── conf
│   │   └── app_nginx.conf
│   └── uwsgi_params
├── vue
│   └── Dockerfile
└── python
    ├── Dockerfile
    └── requirements.txt
```

## Setting files

Ten files have to be edited:
1. docker-compose.dev.yml
2. Dockerfile (python)
3. requirements.txt
4. Dockerfile (mysql)
5. init.sql
6. Dockerfile (vue)
7. app_nginx.conf
8. uwsgi_params
9. Makefile
10. .env

### 1. docker-compose.dev.yml

```yaml:docker-compose.yml
version: '3.7'

services:
  python:
    build:
      context: ./python
      dockerfile: Dockerfile
    command: uwsgi --socket :8001 --module octave.wsgi --py-autoreload 1 --logto /tmp/uwsgi.log
    restart: unless-stopped
    container_name: Django
    networks:
      - django_net
    volumes:
      - ./src:/code
      - ./static:/static
      - ./template:/template
    expose:
      - "8001"
    depends_on:
      - db

  vue:
    build:
      context: ./vue
      dockerfile: Dockerfile
    restart: unless-stopped
    container_name: Vue
    networks:
      - django_net
    volumes:
      - ./src/frontend:/code
      - ./static:/static
      - ./template:/template
    expose:
      - "3000"
    depends_on:
      - python
  
  db:
    build:
      context: ./mysql
      dockerfile: Dockerfile
    restart: unless-stopped
    container_name: MySQL
    networks:
      - django_net
    ports:
      - "3306:3306"
    environment:
      MYSQL_DATABASE: octave_db
      MYSQL_USER: octave_user
      MYSQL_PASSWORD: ${OCTAVE_DB_PASSWORD:-default}
      MYSQL_ROOT_PASSWORD: ${OCTAVE_DB_ROOT_PASSWORD:-default}
      TZ: "Asia/Tokyo"
    volumes:
      - octave.db.volume:/var/lib/mysql
      - ./mysql/init.d:/docker-entrypont-initdb.d

  nginx:
    image: nginx:1.17
    restart: unless-stopped
    container_name: nginx
    networks:
      - django_net
    ports:
      - "80:80"
    volumes:
      - ./nginx/conf:/etc/nginx/conf.d
      - ./nginx/uwsgi_params:/etc/nginx/uwsgi_params
      - ./static:/static
      - ./src/frontend:/frontend
    depends_on:
      - python

networks:
  django_net:
    driver: bridge

volumes:
  octave.db.volume:
    name: octave.db.volume
```

### 2. Dockerfile (python)

```docker:./python/Dockerfile
FROM python:3.9
WORKDIR /code
ADD requirements.txt /code/
RUN pip install --upgrade pip && pip install -r requirements.txt
ADD . /code/
```

### 3. requirements.txt

```:./python/requirements.txt
Django==3.1.4
uwsgi==2.0.18
mysqlclient==1.4.6
```

### 4. Dockerfile (mysql)

```docker:./mysql/Dockerfile
FROM mysql:5.7
COPY init.d/* /docker-entrypoint-initdb.d/
```

### 5. init.sql

```mysql:./mysql/init.d/init.sql
GRANT ALL PRIVILEGES ON octave_db.* TO 'octave_user'@'%';
FLUSH PRIVILEGES;
```

### 6. Dockerfile (vue)

```docker:./vue/Dockerfile
FROM node:15.5
WORKDIR /code
RUN npm install -g @vue/cli axios bootstrap-vue vuex vue-router && npm install -g @vue/cli-service-global
ADD . /code/
```

### 7. app_nginx.conf

```conf:./nginx/conf/app_nginx.conf
upstream django {
  ip_hash;
  server python:8001;
  server vue:3000;
}

server {
  listen      80;
  server_name 127.0.0.1;
  charset     utf-8;

  location /static {
    alias /static;
  }

  location /template {
    alias /template;
  }

  client_max_body_size 75M;

  location / {
    root /frontend/dist;
  }
  
  location /apiv1/ {
    uwsgi_pass  django;
    include     /etc/nginx/uwsgi_params;
  }

  location /admin/ {
    uwsgi_pass  django;
    include     /etc/nginx/uwsgi_params;
  }
  
  location /docs/ {
    uwsgi_pass  django;
    include     /etc/nginx/uwsgi_params;
  }
}

server_tokens off;
```

### 8. uwsgi_params

```:./nginx/uwsgi_params
uwsgi_param  QUERY_STRING       $query_string;
uwsgi_param  REQUEST_METHOD     $request_method;
uwsgi_param  CONTENT_TYPE       $content_type;
uwsgi_param  CONTENT_LENGTH     $content_length;

uwsgi_param  REQUEST_URI        $request_uri;
uwsgi_param  PATH_INFO          $document_uri;
uwsgi_param  DOCUMENT_ROOT      $document_root;
uwsgi_param  SERVER_PROTOCOL    $server_protocol;
uwsgi_param  REQUEST_SCHEME     $scheme;
uwsgi_param  HTTPS              $https if_not_empty;

uwsgi_param  REMOTE_ADDR        $remote_addr;
uwsgi_param  REMOTE_PORT        $remote_port;
uwsgi_param  SERVER_PORT        $server_port;
uwsgi_param  SERVER_NAME        $server_name;
```

### 9. Makefile

```makefile:./Makefile
main:
	docker tag octave_python:latest $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/octave_python:latest
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/octave_python:latest
dev:
	docker-compose -f docker-compose.dev.yml build
prod:
	docker-compose -f docker-compose.prod.yml build
up:
	docker-compose -f docker-compose.dev.yml up -d
down:
	docker-compose -f docker-compose.dev.yml down
stop:
	docker-compose -f docker-compose.dev.yml stop
login:
	aws ecr get-login-password --region ap-northeast-1 --profile fujita | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com
clean:
	docker-compose -f docker-compose.dev.yml rm
	docker-compose -f docker-compose.prod.yml rm
app:
	docker-compose -f docker-compose.dev.yml run python ./manage.py startapp $(APP_NAME)
migrate:
	docker-compose -f docker-compose.dev.yml run python ./manage.py makemigrations
	docker-compose -f docker-compose.dev.yml run python ./manage.py migrate
all_clear:
	docker-compose -f docker-compose.dev.yml down
	docker volume rm octave.db.volume
	find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
	find . -path "*/migrations/*.pyc" -delete
commit:
	@echo "Running git on octave_docker"
	git add -A .
	git commit -m $(COMMENT)
	git push origin master
	cd "$(PWD)/src" && make commit $(COMMENT)
```

### 10. .env

```
AWS_ACCOUNT_ID=***********
OCTAVE_DB_PASSWORD='******'
```

# How to deploy an implemented application on AWS Fargate


