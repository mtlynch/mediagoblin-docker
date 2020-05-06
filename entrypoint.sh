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

# Create a default mediagoblin.ini if none has been specified.
if [[ ! -f mediagoblin.ini ]]
then
  echo '[[mediagoblin.media_types.audio]]' >> mediagoblin.ini
  echo '[[mediagoblin.media_types.video]]' >> mediagoblin.ini
fi

./lazyserver.sh --server-name=broadcast
