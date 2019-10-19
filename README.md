# Dockerized http://mediagoblin.org/

[![CircleCI](https://circleci.com/gh/mtlynch/mediagoblin-docker.svg?style=svg)](https://circleci.com/gh/mtlynch/mediagoblin-docker) [![Docker Pulls](https://img.shields.io/docker/pulls/mtlynch/mediagoblin.svg?maxAge=604800)](https://hub.docker.com/r/mtlynch/mediagoblin/) [![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

## Branch information

This is the `mtlynch-custom` branch of the mediagoblin-docker repository. It creates a more customized MediaGoblin docker image specialized for mtlynch's needs.

In particular, it:

* Uses the [`mtlynch-custom`](https://github.com/mtlynch/mediagoblin/tree/mtlynch-custom) branch of the core MediaGoblin repo.
  * This just replaces MediaGoblin's custom media player with a HTML5 default media player and customizes minor UI elements.
* Uses nginx to manage static resources
  * nginx assumes that all media files are located in a public Google Cloud Storage bucket that the user specifies at container build time.
* It allows the image builder to customize MediaGoblin's HTML title as a build parameter
* It protects the MediaGoblin app using HTTP basic authentication.
* It adds the [basicsearch](https://github.com/ayleph/mediagoblin-basicsearch) plugin to MediaGoblin.
* It downloads a pre-populated mediagoblin.db database from a URL specified at container build time.
  * Note that uploading new files to this MediaGoblin instance will not work.
* It skips video transcoding for video and audio codecs that modern browsers already support natively.
