# Docker container for HandBrake
[![Docker Image Size](https://img.shields.io/microbadger/image-size/jlesage/handbrake)](http://microbadger.com/#/images/jlesage/handbrake) [![Build Status](https://drone.le-sage.com/api/badges/jlesage/docker-handbrake/status.svg)](https://drone.le-sage.com/jlesage/docker-handbrake) [![GitHub Release](https://img.shields.io/github/release/jlesage/docker-handbrake.svg)](https://github.com/jlesage/docker-handbrake/releases/latest) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage/0usd)

This is a Docker container for [HandBrake](https://handbrake.fr/).

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on the client side) or via any VNC client.

A fully automated mode is also available: drop files into a watch folder and let HandBrake process them without any user interaction.

---

[![HandBrake logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png&w=200)](https://handbrake.fr/)[![HandBrake](https://dummyimage.com/400x110/ffffff/575757&text=HandBrake)](https://handbrake.fr/)

HandBrake is a tool for converting video from nearly any format to a selection of modern, widely supported codecs.

---

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the HandBrake docker container with the following command:
```
docker run -d \
    --name=handbrake \
    -p 5800:5800 \
    -v /docker/appdata/handbrake:/config:rw \
    -v $HOME:/storage:ro \
    -v $HOME/HandBrake/watch:/watch:rw \
    -v $HOME/HandBrake/output:/output:rw \
    jlesage/handbrake
```

Where:
  - `/docker/appdata/handbrake`: This is where the application stores its configuration, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible by the application.
  - `$HOME/HandBrake/watch`: This is where videos to be automatically converted are located.
  - `$HOME/HandBrake/output`: This is where automatically converted video files are written.

Browse to `http://your-host-ip:5800` to access the HandBrake GUI.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-handbrake.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-handbrake/issues
