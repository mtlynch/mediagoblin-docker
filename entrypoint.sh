#!/bin/bash

set -xe

sudo nginx

bin/gmg dbupdate

# Ignore failure to add admin user because they may already exist.
{
  bin/gmg adduser \
    --username "$MEDIAGOBLIN_ADMIN_USER" \
    --password "$MEDIAGOBLIN_ADMIN_PASS" \
    --email "$MEDIAGOBLIN_ADMIN_EMAIL" && \
  bin/gmg makeadmin "$MEDIAGOBLIN_ADMIN_USER"
} || true

./lazyserver.sh \
  --server-name=fcgi \
  fcgi_host=127.0.0.1 \
  fcgi_port=26543
