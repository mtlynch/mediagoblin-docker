#!/bin/bash

set -uxe

# If host mounted a manually-created MediaGoblin config file, make a copy that
# the MediaGoblin user can access it.
if [[ -f mediagoblin_manual.ini ]]
then
  cp mediagoblin_manual.ini mediagoblin.ini
  chown "$MEDIAGOBLIN_USER:$MEDIAGOBLIN_GROUP" mediagoblin.ini
fi

chown \
  --no-dereference \
  --recursive \
  "${MEDIAGOBLIN_USER}:${MEDIAGOBLIN_GROUP}" "$MEDIAGOBLIN_HOME_DIR"

su "$MEDIAGOBLIN_USER" -c './user-dev-workaround.sh'
su "$MEDIAGOBLIN_USER" -c './init-mediagoblin.sh'
su "$MEDIAGOBLIN_USER" -c './lazyserver.sh --server-name=broadcast'
