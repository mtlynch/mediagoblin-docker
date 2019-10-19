#!/bin/bash

set -xe

su "$MEDIAGOBLIN_USER" -c './init-mediagoblin.sh'

envsubst '${PORT},${DOMAIN},${APP_ROOT},${GCS_BUCKET}' \
  < "$NGINX_CONFIG_TEMPLATE" \
  > /etc/nginx/sites-enabled/default

echo "Turning on nginx for port $PORT"
nginx

su "$MEDIAGOBLIN_USER" -c './lazyserver.sh --server-name=broadcast'
