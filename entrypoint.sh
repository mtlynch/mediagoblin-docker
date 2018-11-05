#!/bin/bash

set -xe

sudo nginx

# Mount GCS bucket.
gcsfuse \
  -o nonempty \
  -o allow_other \
  "$GCS_BUCKET" "$GCS_MOUNT_ROOT"

# Link MediaGoblin's media serving folder to GCS.
if [ ! -d "$MEDIAGOBLIN_PUBLIC_DIR" ]; then
  mkdir --parents "$MEDIAGOBLIN_MEDIA_DIR"
  ln --symbolic "$GCS_MOUNT_ROOT" "$MEDIAGOBLIN_PUBLIC_DIR";
fi

# Pull an existing database from GCS if one is available.
if [ ! -f "$MEDIAGOBLIN_DB_PATH" ] && [ -f "$GCS_DB_PATH" ]; then
  cp "$GCS_DB_PATH" "$MEDIAGOBLIN_DB_PATH";
fi

bin/gmg dbupdate

# Ignore failure to add admin user because they may already exist.
{
  bin/gmg adduser \
    --username "$MEDIAGOBLIN_ADMIN_USER" \
    --password "$MEDIAGOBLIN_ADMIN_PASS" \
    --email "$MEDIAGOBLIN_ADMIN_EMAIL" && \
  bin/gmg makeadmin "$MEDIAGOBLIN_ADMIN_USER"
} || true

# Watch the DB file on the local filesystem and mirror any changes to the GCS
# bucket.
echo "$MEDIAGOBLIN_DB_PATH" | \
  entr -n rsync "$MEDIAGOBLIN_DB_PATH" "$GCS_DB_PATH" &

./lazyserver.sh \
  --server-name=fcgi \
  fcgi_host=127.0.0.1 \
  fcgi_port=26543
