#!/bin/bash

nginx
chown -hR mediagoblin:www-data /var/lib/mediagoblin
cd /srv/mediagoblin.example.org/mediagoblin/
sudo -u mediagoblin bin/gmg dbupdate
sudo -u mediagoblin bin/gmg adduser --username admin --password admin --email some@where.com
sudo -u mediagoblin bin/gmg makeadmin admin
sudo -u mediagoblin ./lazyserver.sh --server-name=fcgi fcgi_host=127.0.0.1 fcgi_port=26543
