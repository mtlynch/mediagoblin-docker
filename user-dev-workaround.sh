#!/bin/bash

set -uxe

# Workaround because MediaGoblin doesn't fully respect data_basedir in the
# mediagoblin.ini.
#
# When data_basedir is defined in mediagoblin.ini, MediaGoblin writes uploaded
# files to that location, but when it tries to serve files, it still looks for
# them in ./user_dev/media/public.
#
# As a workaround, create a symlink from the incorrect path to the correct
# path.

CORRECT_SERVING_DIR="${MEDIAGOBLIN_HOME_DIR}/media/public"
INCORRECT_SERVING_DIR="./user_dev/media/public"

mkdir --parents "$CORRECT_SERVING_DIR"
mkdir --parents $(dirname "$INCORRECT_SERVING_DIR")
ln -s "$CORRECT_SERVING_DIR" "$INCORRECT_SERVING_DIR"