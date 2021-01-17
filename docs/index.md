# Introduction

This GitHub page introduces an approach to build an environment for Django + Vue.js.

The page consists of two parts:
1. The former part describes how to build a development environment.
2. The latter part describes how to deploy an implemented application on AWS Fargate.

## Repositories

- Docker : [https://github.com/hajime-f/octave_docker](https://github.com/hajime-f/octave_docker)
- Backend : [https://github.com/hajime-f/octave_backend](https://github.com/hajime-f/octave_backend)
- Frontend : [https://github.com/hajime-f/octave_frontend](https://github.com/hajime-f/octave_frontend)

## Versions

The versions of operating environments and packages are shown below:

- Operating environments
  - macOS Big Sur ver.11.1
  - VirtualBox 6.1.16
  - Ubuntu Server 20.04 LTS
- Packages
  - Docker 20.10.2
  - docker-compose 1.24.1
  - Django 3.1.4
  - Vue CLI 4.5.10
  - nginx 1.17
  - MySQL 5.7

## Notes

1. I am making a web application called “octave”, which can manage activities of orchestras. Please replace it to your application name in the explanation below.
2. I am not responsible for any disadvantage caused by referring to this page.

# Development environment

## Directory

The directory structure is shown below:

```
octave
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

Nine files have to be edited:
1. docker-compose.dev.yml
2. Dockerfile (python)
3. requirements.txt
4. Dockerfile (mysql)
5. init.sql
6. Dockerfile (vue)
7. app-nginx.conf
8. uwsgi_params
9. Makefile

Although docker-compose.prod.yml exists in the directory, we do not have to edit it this part (see the next part).
