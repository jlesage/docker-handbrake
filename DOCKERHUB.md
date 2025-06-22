# Docker container for HandBrake
[![Release](https://img.shields.io/github/release/jlesage/docker-handbrake.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-handbrake/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/handbrake/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/handbrake/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/handbrake?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/handbrake)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/handbrake?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/handbrake)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-handbrake/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-handbrake/actions/workflows/build-image.yml)
[![Source](https://img.shields.io/badge/Source-GitHub-blue?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-handbrake)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This is a Docker container for [HandBrake](https://handbrake.fr).

The graphical user interface (GUI) of the application can be accessed through a
modern web browser, requiring no installation or configuration on the client

A fully automated mode is also available: drop files into a watch folder and let
HandBrake process them without any user interaction.

---

[![HandBrake logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png&w=110)](https://handbrake.fr)[![HandBrake](https://images.placeholders.dev/?width=288&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=HandBrake&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://handbrake.fr)

HandBrake is a tool for converting video from nearly any format to a selection
of modern, widely supported codecs.

---

## Quick Start

**NOTE**:
    The Docker command provided in this quick start is an example, and parameters
    should be adjusted to suit your needs.

Launch the HandBrake docker container with the following command:
```shell
docker run -d \
    --name=handbrake \
    -p 5800:5800 \
    -v /docker/appdata/handbrake:/config:rw \
    -v /home/user:/storage:ro \
    -v /home/user/HandBrake/watch:/watch:rw \
    -v /home/user/HandBrake/output:/output:rw \
    jlesage/handbrake
```

Where:

  - `/docker/appdata/handbrake`: Stores the application's configuration, state, logs, and any files requiring persistency.
  - `/home/user`: Contains files from the host that need to be accessible to the application.
  - `/home/user/HandBrake/watch`: The location for videos to be automatically converted.
  - `/home/user/HandBrake/output`: The destination for converted video files.

Access the HandBrake GUI by browsing to `http://your-host-ip:5800`.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-handbrake.

## Support or Contact

Having troubles with the container or have questions? Please
[create a new issue](https://github.com/jlesage/docker-handbrake/issues).

For other Dockerized applications, visit https://jlesage.github.io/docker-apps.
