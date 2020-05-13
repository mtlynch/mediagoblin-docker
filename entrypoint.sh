#!/bin/bash

set -uxe

# For some reason, heroku fails when you try to run "su mediagoblin -c ..." so
# we'll run everything as root.

./init-mediagoblin.sh

envsubst '${PORT},${DOMAIN},${APP_ROOT},${GCS_BUCKET}' \
  < "$NGINX_CONFIG_TEMPLATE" \
  > /etc/nginx/sites-enabled/default

echo "Turning on nginx for port $PORT"
nginx

./lazyserver.sh --server-name=broadcast
