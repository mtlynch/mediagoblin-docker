Dockerized http://mediagoblin.org/
==================================

Demo MediaGoblin
----------------

All data are lost when the container is stopped.

    sudo docker run -p 8080:80 dachary/mediagoblin
    www-browser http://localhost:8080

The default user is admin, password admin.

Demo MediaGoblin locally
------------------------

The image is built locally, there is no dependency to the Docker registry. All data are lost when the container is stopped.

    git clone https://notabug.org/dachary/mediagoblin-docker.git
    sudo docker build -t mediagoblin-demo mediagoblin-docker
    sudo docker run -p 8080:80 mediagoblin-docker
    www-browser http://localhost:8080

The default user is admin, password admin.

Run MediaGoblin
---------------

The data is preserved in /srv/mediagoblin.

    git clone https://notabug.org/dachary/mediagoblin-docker.git
    sudo docker build -t mediagoblin-demo mediagoblin-docker
    sudo mkdir /srv/mediagoblin
    sudo docker --name mediagoblin run -p 8080:80 \
         -v /srv/mediagoblin:/var/lib/mediagoblin \
         mediagoblin-docker
    www-browser http://localhost:8080

The default user is admin, password admin.

Deploy MediaGoblin with Dokku
-----------------------------

After installing [Dokku](http://dokku.viewdocs.io/dokku/installation/), follow the [Deploying to Dokku instructions](http://dokku.viewdocs.io/dokku/application-deployment/) to create the MediaGoblin v0.8.1 app. The following example is based on Dokku installed at gmg.the.re and creates http://loic.gmg.the.re/.

     dokku apps:create loic
     mkdir /srv/loic
     dokku docker-options:add loic deploy "-v /srv/loic:/var/lib/mediagoblin"
     git clone -b v0.8.1 https://notabug.org/dachary/mediagoblin-docker.git
     cd mediagoblin-docker
     git remote add dokku dokku@gmg.the.re:loic
     git push dokku v0.8.1:master
     www-browser http://loic.gmg.the.re/

To upgrade, remove the app and create a new one after pulling the desired MediaGoblin version.

     dokku --force apps:destroy loic
     git fetch origin
     git checkout -b v0.9.0 v0.9.0
     git push dokku v0.9.0:master

Upgrade MediaGoblin
-------------------

If the data is preserved in /srv/mediagoblin as described above, upgrade by stopping the container and rebulding the image with the latest stable version.

    sudo docker stop mediagoblin
    rm -fr mediagoblin-docker
    git clone https://notabug.org/dachary/mediagoblin-docker.git
    sudo docker build -t mediagoblin-demo mediagoblin-docker
    sudo docker --name mediagoblin run -p 8080:80 \
         -v /srv/mediagoblin:/var/lib/mediagoblin \
         mediagoblin-docker
    www-browser http://localhost:8080

Maintaining the Dockerfile
==========================

The git repository has one branch per stable version. The master branch is always the latest stable, not the MediaGoblin development branch. This is to make it so PaaS like Dokku get the latest stable by
default instead of the unstable development version.

Publish to the Docker registry
------------------------------

Publish a new version:

    version=0.8.1
    git checkout -b v$version v$version
    docker login
    docker build -t dachary/mediagoblin:$version .
    docker push dachary/mediagoblin:$version

Publish the latest:

    docker build -t dachary/mediagoblin .
    docker push dachary/mediagoblin
