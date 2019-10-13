#!/bin/bash

set -xe

bin/gmg dbupdate

# Ignore failure to add admin user because they may already exist.
{
  bin/gmg adduser \
    --username "$MEDIAGOBLIN_ADMIN_USER" \
    --password "$MEDIAGOBLIN_ADMIN_PASS" \
    --email "$MEDIAGOBLIN_ADMIN_EMAIL" && \
  bin/gmg makeadmin "$MEDIAGOBLIN_ADMIN_USER"
} || true

./lazyserver.sh --server-name=broadcast
