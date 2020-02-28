jenkins-docker-encaps
=====================

Usage
-----

Along with this image is provided a script called `encaps` (and `encaps-cleanup`) that are used to encapsulate a script execution within a container.

For instance, let's assume the following script:

    #!/bin/sh
    python setup.py bdist_egg

If you want to encapsulate such script in a containerized environment, it is (almost) as simple as replacing the shebang:

    #!/usr/bin/encaps
    python setup.py bdist_egg

Behavior of the script is defined by the following env variables:
 - `DOCKER_ENCAPS_IMG` : image used to instantiate the container
 - `DOCKER_ENCAPS_ARGS` : extra arguments that should be given to docker upon instantiation
 - `DOCKER_ENCAPS_NAME` : name used for the container, default to `BUILD_TAG` which is usually provided by Jenkins, format is `jenkins-<JOB>-<BUILD_ID>`
 - `DOCKER_ENCAPS_SHELL` : to control the actual program executing your script, default to /bin/sh
 - `DOCKER_ENCAPS_NET` : by default the container shared the host networking (--net=host). You can use this to set the hostname (--hostname=jenkins) instead, or cut the container connectivity (--network=none)
 - `DOCKER_ENCAPS_WEIGHT` : relative weight of the container (to prioritize some containers compared to others)

As it needs a running container, the script will instanciate one the first time `encaps` is run.

Once you are done with the container, you should call `encaps-cleanup` to remove it or it will stay running in the background.

In the example above, consider that you want to build your application with python 2.7.9.
Just inject the variable `DOCKER_ENCAPS_IMG=python:2.7.9` and it will use the image from https://registry.hub.docker.com/_/python/ to encapsulate your build.

Limitations
-----------

 - Do not forget that even if the docker client is running in the Jenkins container, the server is still on the host.
   Therefore, paths, etc ... should be relative/accessible from the host.
 - The workspace is considered as being a shared volume between the jenkins-slave container and the host for this reason.

