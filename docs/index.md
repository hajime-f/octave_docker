## Overview

This GitHub page introduces an approach to build an environment for Django + Vue.js.

The page consists of two parts:
1. The former part describes how to build a development environment.
2. The latter part describes how to deploy an implemented application on AWS Fargate.

The author of the page is [Hajime Fujita](https://www.linkedin.com/in/fujitahajime/). 

I am making a web application called “octave”, which can manage activities of orchestras. Please replace "octave" to your application name in the description below and note that I am not responsible for any disadvantage caused by referring to this page.

## Repositories

- Infra (Docker) : [https://github.com/hajime-f/octave_docker](https://github.com/hajime-f/octave_docker)
- Backend (Django) : [https://github.com/hajime-f/octave_backend](https://github.com/hajime-f/octave_backend)
- Frontend (Vue) : [https://github.com/hajime-f/octave_frontend](https://github.com/hajime-f/octave_frontend)

## Versions

The versions of operating environments and packages are shown below:

- Operating environments
  - macOS Big Sur 11.1 (Host)
  - VirtualBox 6.1.16
  - Ubuntu Server 20.04 LTS (Guest)
- Packages
  - Docker 20.10.2
  - docker-compose 1.24.1
  - Django 3.1.4
  - Vue CLI 4.5.10
  - nginx 1.17
  - MySQL 5.7
  - Make 4.2.1

# How to build a development environment

## Directory

The directory structure is shown below:

```
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
      MYSQL_ROOT_PASSWORD: ${OCTAVE_DB_PASSWORD:-default}
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

### 3. requirements.txt

### 4. Dockerfile (mysql)

### 5. init.sql

### 6. Dockerfile (vue)

### 7. app-nginx.conf

### 8. uwsgi_params

### 9. Makefile

### 10. .env


# How to deploy an implemented application on AWS Fargate


