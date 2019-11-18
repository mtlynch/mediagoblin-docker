# Dockerized http://mediagoblin.org/

[![CircleCI](https://circleci.com/gh/mtlynch/mediagoblin-docker.svg?style=svg)](https://circleci.com/gh/mtlynch/mediagoblin-docker) [![Docker Pulls](https://img.shields.io/docker/pulls/mtlynch/mediagoblin.svg?maxAge=604800)](https://hub.docker.com/r/mtlynch/mediagoblin/) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

## Demo MediaGoblin

All data are lost when the container is stopped.

```bash
docker run \
  --tty \
  --detach \
  --publish 8080:6543 \
  --name medaigoblin \
  mtlynch/mediagoblin
```

MediaGoblin will be available at http://localhost:8080

The default user is `admin`, password `admin`.

## Run MediaGoblin with Persistent State

The data is preserved in /srv/mediagoblin.

```bash
mkdir -p persist/srv/mediagoblin

docker run \
  --tty \
  --detach \
  --publish 8080:6543 \
  --volume "${PWD}/persist/srv/mediagoblin:/var/lib/mediagoblin" \
  --name mediagoblin \
  mtlynch/mediagoblin
```

MediaGoblin will be available at http://localhost:8080

The default user is `admin`, password `admin`.

MediaGoblin will save data to `./persist/srv/mediagoblin`

## Build container from source

To rebuild this container, copy this repository locally and run:


```bash
docker build --tag mediagoblin .
```
