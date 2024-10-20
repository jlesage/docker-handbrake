# Docker container for HandBrake
[![Release](https://img.shields.io/github/release/jlesage/docker-handbrake.svg?logo=github&style=for-the-badge)](https://github.com/jlesage/docker-handbrake/releases/latest)
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/handbrake/latest?logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/handbrake/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/jlesage/handbrake?label=Pulls&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/handbrake)
[![Docker Stars](https://img.shields.io/docker/stars/jlesage/handbrake?label=Stars&logo=docker&style=for-the-badge)](https://hub.docker.com/r/jlesage/handbrake)
[![Build Status](https://img.shields.io/github/actions/workflow/status/jlesage/docker-handbrake/build-image.yml?logo=github&branch=master&style=for-the-badge)](https://github.com/jlesage/docker-handbrake/actions/workflows/build-image.yml)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg?style=for-the-badge)](https://paypal.me/JocelynLeSage)

This project implements a Docker container for [HandBrake](https://handbrake.fr).

The GUI of the application is accessed through a modern web browser (no
installation or configuration needed on the client side) or via any VNC client.

A fully automated mode is also available: drop files into a watch folder and let
HandBrake process them without any user interaction.

---

[![HandBrake logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/handbrake-icon.png&w=110)](https://handbrake.fr)[![HandBrake](https://images.placeholders.dev/?width=288&height=110&fontFamily=monospace&fontWeight=400&fontSize=52&text=HandBrake&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://handbrake.fr)

HandBrake is a tool for converting video from nearly any format to a selection
of modern, widely supported codecs.

---

## Table of Content

   * [Quick Start](#quick-start)
   * [Usage](#usage)
      * [Environment Variables](#environment-variables)
         * [Deployment Considerations](#deployment-considerations)
      * [Data Volumes](#data-volumes)
      * [Ports](#ports)
      * [Changing Parameters of a Running Container](#changing-parameters-of-a-running-container)
   * [Docker Compose File](#docker-compose-file)
   * [Docker Image Versioning](#docker-image-versioning)
   * [Docker Image Update](#docker-image-update)
      * [Synology](#synology)
      * [unRAID](#unraid)
   * [User/Group IDs](#usergroup-ids)
   * [Accessing the GUI](#accessing-the-gui)
   * [Security](#security)
      * [SSVNC](#ssvnc)
      * [Certificates](#certificates)
      * [VNC Password](#vnc-password)
      * [Web Authentication](#web-authentication)
         * [Configuring Users Credentials](#configuring-users-credentials)
   * [Reverse Proxy](#reverse-proxy)
      * [Routing Based on Hostname](#routing-based-on-hostname)
      * [Routing Based on URL Path](#routing-based-on-url-path)
   * [Shell Access](#shell-access)
   * [Access to Optical Drive(s)](#access-to-optical-drives)
   * [Automatic Video Conversion](#automatic-video-conversion)
      * [Multiple Watch Folders](#multiple-watch-folders)
      * [Video Discs](#video-discs)
      * [Hooks](#hooks)
      * [Temporary Conversion Directory](#temporary-conversion-directory)
   * [Intel Quick Sync Video](#intel-quick-sync-video)
      * [unRAID](#unraid-1)
   * [Nightly Builds](#nightly-builds)
   * [Debug Builds](#debug-builds)
      * [unRAID](#unraid-2)
   * [Support or Contact](#support-or-contact)

## Quick Start

> [!IMPORTANT]
> The Docker command provided in this quick start is given as an example and
> parameters should be adjusted to your need.

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

  - `/docker/appdata/handbrake`: This is where the application stores its configuration, states, log and any files needing persistency.
  - `/home/user`: This location contains files from your host that need to be accessible to the application.
  - `/home/user/HandBrake/watch`: This is where videos to be automatically converted are located
  - `/home/user/HandBrake/output`: This is where automatically converted video files are written.

Browse to `http://your-host-ip:5800` to access the HandBrake GUI.
Files from the host appear under the `/storage` folder in the container.

## Usage

```shell
docker run [-d] \
    --name=handbrake \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    jlesage/handbrake
```

| Parameter | Description |
|-----------|-------------|
| -d        | Run the container in the background. If not set, the container runs in the foreground. |
| -e        | Pass an environment variable to the container. See the [Environment Variables](#environment-variables) section for more details. |
| -v        | Set a volume mapping (allows to share a folder/file between the host and the container). See the [Data Volumes](#data-volumes) section for more details. |
| -p        | Set a network port mapping (exposes an internal container port to the host). See the [Ports](#ports) section for more details. |

### Environment Variables

To customize some properties of the container, the following environment
variables can be passed via the `-e` parameter (one for each variable). Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`USER_ID`| ID of the user the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`GROUP_ID`| ID of the group the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`SUP_GROUP_IDS`| Comma-separated list of supplementary group IDs of the application. | (no value) |
|`UMASK`| Mask that controls how permissions are set for newly created files and folders.  The value of the mask is in octal notation.  By default, the default umask value is `0022`, meaning that newly created files and folders are readable by everyone, but only writable by the owner.  See the online umask calculator at http://wintelguy.com/umask-calc.pl. | `0022` |
|`LANG`| Set the [locale](https://en.wikipedia.org/wiki/Locale_(computer_software)), which defines the application's language, **if supported**.  Format of the locale is `language[_territory][.codeset]`, where language is an [ISO 639 language code](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes), territory is an [ISO 3166 country code](https://en.wikipedia.org/wiki/ISO_3166-1#Current_codes) and codeset is a character set, like `UTF-8`.  For example, Australian English using the UTF-8 encoding is `en_AU.UTF-8`. | `en_US.UTF-8` |
|`TZ`| [TimeZone](http://en.wikipedia.org/wiki/List_of_tz_database_time_zones) used by the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`KEEP_APP_RUNNING`| When set to `1`, the application will be automatically restarted when it crashes or terminates. | `0` |
|`APP_NICENESS`| Priority at which the application should run.  A niceness value of -20 is the highest priority and 19 is the lowest priority.  The default niceness value is 0.  **NOTE**: A negative niceness (priority increase) requires additional permissions.  In this case, the container should be run with the docker option `--cap-add=SYS_NICE`. | `0` |
|`INSTALL_PACKAGES`| Space-separated list of packages to install during the startup of the container.  List of available packages can be found at https://pkgs.alpinelinux.org.  **ATTENTION**: Container functionality can be affected when installing a package that overrides existing container files (e.g. binaries). | (no value) |
|`PACKAGES_MIRROR`| Mirror of the repository to use when installing packages. List of mirrors is available at https://mirrors.alpinelinux.org. | (no value) |
|`CONTAINER_DEBUG`| Set to `1` to enable debug logging. | `0` |
|`DISPLAY_WIDTH`| Width (in pixels) of the application's window. | `1920` |
|`DISPLAY_HEIGHT`| Height (in pixels) of the application's window. | `1080` |
|`DARK_MODE`| When set to `1`, dark mode is enabled for the application. | `0` |
|`WEB_AUDIO`| When set to `1`, audio support is enabled, meaning that any audio produced by the application is played through the browser. Note that audio is not supported for VNC clients. | `0` |
|`WEB_AUTHENTICATION`| When set to `1`, the application' GUI is protected via a login page when accessed via a web browser.  Access is allowed only when providing valid credentials.  **NOTE**: This feature requires secure connection (`SECURE_CONNECTION` environment variable) to be enabled. | `0` |
|`WEB_AUTHENTICATION_USERNAME`| Optional username to configure for the web authentication.  This is a quick and easy way to configure credentials for a single user.  To configure credentials in a more secure way, or to add more users, see the [Web Authentication](#web-authentication) section. | (no value) |
|`WEB_AUTHENTICATION_PASSWORD`| Optional password to configure for the web authentication.  This is a quick and easy way to configure credentials for a single user.  To configure credentials in a more secure way, or to add more users, see the [Web Authentication](#web-authentication) section. | (no value) |
|`SECURE_CONNECTION`| When set to `1`, an encrypted connection is used to access the application's GUI (either via a web browser or VNC client).  See the [Security](#security) section for more details. | `0` |
|`SECURE_CONNECTION_VNC_METHOD`| Method used to perform the secure VNC connection.  Possible values are `SSL` or `TLS`.  See the [Security](#security) section for more details. | `SSL` |
|`SECURE_CONNECTION_CERTS_CHECK_INTERVAL`| Interval, in seconds, at which the system verifies if web or VNC certificates have changed.  When a change is detected, the affected services are automatically restarted.  A value of `0` disables the check. | `60` |
|`WEB_LISTENING_PORT`| Port used by the web server to serve the UI of the application.  This port is used internally by the container and it is usually not required to be changed.  By default, a container is created with the default bridge network, meaning that, to be accessible, each internal container port must be mapped to an external port (using the `-p` or `--publish` argument).  However, if the container is created with another network type, changing the port used by the container might be useful to prevent conflict with other services/containers.  **NOTE**: a value of `-1` disables listening, meaning that the application's UI won't be accessible over HTTP/HTTPs. | `5800` |
|`VNC_LISTENING_PORT`| Port used by the VNC server to serve the UI of the application.  This port is used internally by the container and it is usually not required to be changed.  By default, a container is created with the default bridge network, meaning that, to be accessible, each internal container port must be mapped to an external port (using the `-p` or `--publish` argument).  However, if the container is created with another network type, changing the port used by the container might be useful to prevent conflict with other services/containers.  **NOTE**: a value of `-1` disables listening, meaning that the application's UI won't be accessible over VNC. | `5900` |
|`VNC_PASSWORD`| Password needed to connect to the application's GUI.  See the [VNC Password](#vnc-password) section for more details. | (no value) |
|`ENABLE_CJK_FONT`| When set to `1`, open-source computer font `WenQuanYi Zen Hei` is installed.  This font contains a large range of Chinese/Japanese/Korean characters. | `0` |
|`HANDBRAKE_DEBUG`| Setting this to `1` enables HandBrake debug logging for both the GUI and the automatic video converter.  For the latter, the increased verbosity is reflected in `/config/log/hb/conversion.log` (container path).  For the GUI, log messages are sent to `/config/log/hb/handbrake.debug.log` (container path).  **NOTE**: When enabled, a lot of information is generated and the log file will grow quickly.  Make sure to enable this temporarily and only when needed. | `0` |
|`HANDBRAKE_GUI`| Setting this to `1` enables the HandBrake GUI, `0` disables it. | `1` |
|`HANDBRAKE_GUI_QUEUE_STARTUP_ACTION`| Action to be taken on the queue of HandBrake (GUI) when it starts. When set to `PROCESS`, HandBrake automatically starts encoding elements present in the queue. When set to `CLEAR`, the content of the queue is cleared. With any other value, no action is taken on the queue. | `NONE` |
|`AUTOMATED_CONVERSION`| Setting this to `1` enables the automatic video converter, `0` disables it. | `1` |
|`AUTOMATED_CONVERSION_PRESET`| HandBrake preset used by the automatic video converter.  Identification of a preset must follow the format `<CATEGORY>/<PRESET NAME>`.  See the [Automatic Video Conversion](#automatic-video-conversion) section for more details. | `General/Very Fast 1080p30` |
|`AUTOMATED_CONVERSION_FORMAT`| Video container format used by the automatic video converter for output files.  This is typically the video filename extension.  See the [Automatic Video Conversion](#automatic-video-conversion) section for more details. | `mp4` |
|`AUTOMATED_CONVERSION_KEEP_SOURCE`| When set to `0`, a video that has been successfully converted is removed from the watch folder. | `1` |
|`AUTOMATED_CONVERSION_VIDEO_FILE_EXTENSIONS`| Space-separated list of file extensions to be considered as video files. By default, this list is empty, meaning that the automatic video converter will let HandBrake automatically detects if a file, no matter its extension, is a video or not (note that extensions defined by the `AUTOMATED_CONVERSION_NON_VIDEO_FILE_EXTENSIONS` environment variable are always considered as non-video files).  Normally, this variable doesn't need to be set.  Usage of this variable is useful when only specific video files need to converted. | (no value) |
|`AUTOMATED_CONVERSION_NON_VIDEO_FILE_ACTION`| When set to `ignore`, a non-video file found in the watch folder is ignored.  If set to `copy`, a non-video file is copied as-is to the output folder. | `ignore` |
|`AUTOMATED_CONVERSION_NON_VIDEO_FILE_EXTENSIONS`| Space-separated list of file extensions to be considered as not being videos.  Most non-video files are properly rejected by HandBrake. However, some files, like images, are convertible by HandBrake even if they are not video files. | `jpg jpeg bmp png gif txt nfo` |
|`AUTOMATED_CONVERSION_OUTPUT_DIR`| Root directory, inside the container, where converted videos should be written.  **NOTE**: Make sure a volume mapping for this directory is defined when creating the container. | `/output` |
|`AUTOMATED_CONVERSION_OUTPUT_SUBDIR`| Subdirectory of the output folder into which converted videos should be written.  By default, this variable is not set, meaning that videos are saved directly into `/output/`.  If `Home/Movies` is set, converted videos will be written to `/output/Home/Movies`.  Use the special value `SAME_AS_SRC` to use the same subfolder as the source.  For example, if the video source file is `/watch/Movies/mymovie.mkv`, the converted video will be written to `/output/Movies/`. | (no value) |
|`AUTOMATED_CONVERSION_OVERWRITE_OUTPUT`| Setting this to `1` allows the final destination file to be overwritten if it already exists. | `0` |
|`AUTOMATED_CONVERSION_SOURCE_STABLE_TIME`| Time (in seconds) during which properties (e.g. size, time, etc) of a video file in the watch folder need to remain the same.  This is to avoid processing a file that is being copied. | `5` |
|`AUTOMATED_CONVERSION_SOURCE_MIN_DURATION`| Minimum title duration (in seconds).  Shorter titles will be ignored.  This applies only to video disc sources (ISO file, `VIDEO_TS` folder or `BDMV` folder). | `10` |
|`AUTOMATED_CONVERSION_SOURCE_MAIN_TITLE_DETECTION`| Setting this to `1` enables HandBrake main feature title detection to try to guess and select the main title. | `0` |
|`AUTOMATED_CONVERSION_CHECK_INTERVAL`| Interval (in seconds) at which the automatic video converter checks for new files. | `5` |
|`AUTOMATED_CONVERSION_MAX_WATCH_FOLDERS`| Maximum number of watch folders handled by the automatic video converter. | `5` |
|`AUTOMATED_CONVERSION_NO_GUI_PROGRESS`| When set to `1`, progress of videos converted by the automatic video converter is not shown in the HandBrake GUI. | `0` |
|`AUTOMATED_CONVERSION_HANDBRAKE_CUSTOM_ARGS`| Custom arguments to pass to HandBrake when performing a conversion. | (no value) |
|`AUTOMATED_CONVERSION_INSTALL_PKGS`| Space-separated list of Alpine Linux packages to install.  This is useful when the automatic video converter's hooks require tools not available in the container image.  See https://pkgs.alpinelinux.org for the list of available Alpine Linux packages. | (no value) |
|`AUTOMATED_CONVERSION_USE_TRASH`| When set to `1`, the automatic video converter uses the trash directory. So when the automatic video converter is configured to *not* keep sources, it will move them to the trash directory (`/trash` inside the container) instead of deleting them. | `0` |

#### Deployment Considerations

Many tools used to manage Docker containers extract environment variables
defined by the Docker image and use them to create/deploy the container. For
example, this is done by:
  - The Docker application on Synology NAS
  - The Container Station on QNAP NAS
  - Portainer
  - etc.

While this can be useful for the user to adjust the value of environment
variables to fit its needs, it can also be confusing and dangerous to keep all
of them.

A good practice is to set/keep only the variables that are needed for the
container to behave as desired in a specific setup. If the value of variable is
kept to its default value, it means that it can be removed. Keep in mind that
all variables are optional, meaning that none of them is required for the
container to start.

Removing environment variables that are not needed provides some advantages:

  - Prevents keeping variables that are no longer used by the container. Over
    time, with image updates, some variables might be removed.
  - Allows the Docker image to change/fix a default value. Again, with image
    updates, the default value of a variable might be changed to fix an issue,
    or to better support a new feature.
  - Prevents changes to a variable that might affect the correct function of
    the container. Some undocumented variables, like `PATH` or `ENV`, are
    required to be exposed, but are not meant to be changed by users. However,
    container management tools still show these variables to users.
  - There is a bug with the Container Station on QNAP and the Docker application
    on Synology, where an environment variable without value might not be
    allowed. This behavior is wrong: it's absolutely fine to have a variable
    without value. In fact, this container does have variables without value by
    default. Thus, removing unneeded variables is a good way to prevent
    deployment issue on these devices.

### Data Volumes

The following table describes data volumes used by the container. The mappings
are set via the `-v` parameter. Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/config`| rw | This is where the application stores its configuration, states, log and any files needing persistency. |
|`/storage`| ro | This location contains files from your host that need to be accessible to the application. |
|`/watch`| rw | This is where videos to be automatically converted are located |
|`/output`| rw | This is where automatically converted video files are written. |
|`/trash`| rw | When trash usage is enabled, this is where the automatic video converter moves converted files instead of deleting them. |

### Ports

Here is the list of ports used by the container.

When using the default bridge network, ports can be mapped to the host via the
`-p` parameter (one per port mapping). Each mapping is defined with the
following format: `<HOST_PORT>:<CONTAINER_PORT>`. The port number used inside
the container might not be changeable, but you are free to use any port on the
host side.

See the [Docker Container Networking](https://docs.docker.com/config/containers/container-networking)
documentation for more details.

| Port | Protocol | Mapping to host | Description |
|------|----------|-----------------|-------------|
| 5800 | TCP | Optional | Port to access the application's GUI via the web interface.  Mapping to the host is optional if access through the web interface is not wanted.  For a container not using the default bridge network, the port can be changed with the `WEB_LISTENING_PORT` environment variable. |
| 5900 | TCP | Optional | Port to access the application's GUI via the VNC protocol.  Mapping to the host is optional if access through the VNC protocol is not wanted.  For a container not using the default bridge network, the port can be changed with the `VNC_LISTENING_PORT` environment variable. |

### Changing Parameters of a Running Container

As can be seen, environment variables, volume and port mappings are all specified
while creating the container.

The following steps describe the method used to add, remove or update
parameter(s) of an existing container. The general idea is to destroy and
re-create the container:

  1. Stop the container (if it is running):
```shell
docker stop handbrake
```

  2. Remove the container:
```shell
docker rm handbrake
```

  3. Create/start the container using the `docker run` command, by adjusting
     parameters as needed.

> [!NOTE]
> Since all application's data is saved under the `/config` container folder,
> destroying and re-creating a container is not a problem: nothing is lost and
> the application comes back with the same state (as long as the mapping of the
> `/config` folder remains the same).

## Docker Compose File

Here is an example of a `docker-compose.yml` file that can be used with
[Docker Compose](https://docs.docker.com/compose/overview/).

Make sure to adjust according to your needs. Note that only mandatory network
ports are part of the example.

```yaml
version: '3'
services:
  handbrake:
    image: jlesage/handbrake
    ports:
      - "5800:5800"
    volumes:
      - "/docker/appdata/handbrake:/config:rw"
      - "/home/user:/storage:ro"
      - "/home/user/HandBrake/watch:/watch:rw"
      - "/home/user/HandBrake/output:/output:rw"
```

## Docker Image Versioning

Each release of a Docker image is versioned. Prior to october 2022, the
[semantic versioning](https://semver.org) was used as the versioning scheme.

Since then, versioning scheme changed to
[calendar versioning](https://calver.org). The format used is `YY.MM.SEQUENCE`,
where:
  - `YY` is the zero-padded year (relative to year 2000).
  - `MM` is the zero-padded month.
  - `SEQUENCE` is the incremental release number within the month (first release
    is 1, second is 2, etc).

## Docker Image Update

Because features are added, issues are fixed, or simply because a new version
of the containerized application is integrated, the Docker image is regularly
updated. Different methods can be used to update the Docker image.

The system used to run the container may have a built-in way to update
containers. If so, this could be your primary way to update Docker images.

An other way is to have the image be automatically updated with [Watchtower].
Watchtower is a container-based solution for automating Docker image updates.
This is a "set and forget" type of solution: once a new image is available,
Watchtower will seamlessly perform the necessary steps to update the container.

Finally, the Docker image can be manually updated with these steps:

  1. Fetch the latest image:
```shell
docker pull jlesage/handbrake
```

  2. Stop the container:
```shell
docker stop handbrake
```

  3. Remove the container:
```shell
docker rm handbrake
```

  4. Create and start the container using the `docker run` command, with the
the same parameters that were used when it was deployed initially.

[Watchtower]: https://github.com/containrrr/watchtower

### Synology

For owners of a Synology NAS, the following steps can be used to update a
container image.

  1.  Open the *Docker* application.
  2.  Click on *Registry* in the left pane.
  3.  In the search bar, type the name of the container (`jlesage/handbrake`).
  4.  Select the image, click *Download* and then choose the `latest` tag.
  5.  Wait for the download to complete. A notification will appear once done.
  6.  Click on *Container* in the left pane.
  7.  Select your HandBrake container.
  8.  Stop it by clicking *Action*->*Stop*.
  9.  Clear the container by clicking *Action*->*Reset* (or *Action*->*Clear* if
      you don't have the latest *Docker* application). This removes the
      container while keeping its configuration.
  10. Start the container again by clicking *Action*->*Start*. **NOTE**:  The
      container may temporarily disappear from the list while it is re-created.

### unRAID

For unRAID, a container image can be updated by following these steps:

  1. Select the *Docker* tab.
  2. Click the *Check for Updates* button at the bottom of the page.
  3. Click the *update ready* link of the container to be updated.

## User/Group IDs

When using data volumes (`-v` flags), permissions issues can occur between the
host and the container. For example, the user within the container may not
exist on the host. This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`USER_ID` and `GROUP_ID` environment variables.

To find the right IDs to use, issue the following command on the host, with the
user owning the data volume on the host:

    id <username>

Which gives an output like this one:
```text
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),4(adm),24(cdrom),27(sudo),46(plugdev),113(lpadmin)
```

The value of `uid` (user ID) and `gid` (group ID) are the ones that you should
be given the container.

## Accessing the GUI

Assuming that container's ports are mapped to the same host's ports, the
graphical interface of the application can be accessed via:

  * A web browser:

```text
http://<HOST IP ADDR>:5800
```

  * Any VNC client:

```text
<HOST IP ADDR>:5900
```

## Security

By default, access to the application's GUI is done over an unencrypted
connection (HTTP or VNC).

Secure connection can be enabled via the `SECURE_CONNECTION` environment
variable. See the [Environment Variables](#environment-variables) section for
more details on how to set an environment variable.

When enabled, application's GUI is performed over an HTTPs connection when
accessed with a browser. All HTTP accesses are automatically redirected to
HTTPs.

When using a VNC client, the VNC connection is performed over SSL. Note that
few VNC clients support this method. [SSVNC] is one of them.

[SSVNC]: http://www.karlrunge.com/x11vnc/ssvnc.html

### SSVNC

[SSVNC] is a VNC viewer that adds encryption security to VNC connections.

While the Linux version of [SSVNC] works well, the Windows version has some
issues. At the time of writing, the latest version `1.0.30` is not functional,
as a connection fails with the following error:
```text
ReadExact: Socket error while reading
```
However, for your convenience, an unofficial and working version is provided
here:

https://github.com/jlesage/docker-baseimage-gui/raw/master/tools/ssvnc_windows_only-1.0.30-r1.zip

The only difference with the official package is that the bundled version of
`stunnel` has been upgraded to version `5.49`, which fixes the connection
problems.

### Certificates

Here are the certificate files needed by the container. By default, when they
are missing, self-signed certificates are generated and used. All files have
PEM encoded, x509 certificates.

| Container Path                  | Purpose                    | Content |
|---------------------------------|----------------------------|---------|
|`/config/certs/vnc-server.pem`   |VNC connection encryption.  |VNC server's private key and certificate, bundled with any root and intermediate certificates.|
|`/config/certs/web-privkey.pem`  |HTTPs connection encryption.|Web server's private key.|
|`/config/certs/web-fullchain.pem`|HTTPs connection encryption.|Web server's certificate, bundled with any root and intermediate certificates.|

> [!TIP]
> To prevent any certificate validity warnings/errors from the browser or VNC
> client, make sure to supply your own valid certificates.

> [!NOTE]
> Certificate files are monitored and relevant daemons are automatically
> restarted when changes are detected.

### VNC Password

To restrict access to your application, a password can be specified. This can
be done via two methods:
  * By using the `VNC_PASSWORD` environment variable.
  * By creating a `.vncpass_clear` file at the root of the `/config` volume.
    This file should contain the password in clear-text.  During the container
    startup, content of the file is obfuscated and moved to `.vncpass`.

The level of security provided by the VNC password depends on two things:
  * The type of communication channel (encrypted/unencrypted).
  * How secure the access to the host is.

When using a VNC password, it is highly desirable to enable the secure
connection to prevent sending the password in clear over an unencrypted channel.

> [!CAUTION]
> Password is limited to 8 characters. This limitation comes from the Remote
> Framebuffer Protocol [RFC](https://tools.ietf.org/html/rfc6143) (see section
> [7.2.2](https://tools.ietf.org/html/rfc6143#section-7.2.2)). Any characters
> beyond the limit are ignored.

### Web Authentication

Access to the application's GUI via a web browser can be protected with a login
page. When web authentication is enabled, users have to provide valid
credentials, otherwise access is denied.

Web authentication can be enabled by setting the `WEB_AUTHENTICATION`
environment variable to `1`.

See the [Environment Variables](#environment-variables) section for more details
on how to set an environment variable.

> [!IMPORTANT]
> Secure connection must also be enabled to use web authentication.
> See the [Security](#security) section for more details.

#### Configuring Users Credentials

Two methods can be used to configure users credentials:

  1. Via container environment variables.
  2. Via password database.

Containers environment variables can be used to quickly and easily configure
a single user. Username and pasword are defined via the following environment
variables:
  - `WEB_AUTHENTICATION_USERNAME`
  - `WEB_AUTHENTICATION_PASSWORD`

See the [Environment Variables](#environment-variables) section for more details
on how to set an environment variable.

The second method is more secure and allows multiple users to be configured.
The usernames and password hashes are saved into a password database, located at
`/config/webauth-htpasswd` inside the container. This database file has the
same format as htpasswd files of the Apache HTTP server. Note that password
themselves are not saved into the database, but only their hash. The bcrypt
password hashing function is used to generate hashes.

Users are managed via the `webauth-user` tool included in the container:
  - To add a user password: `docker exec -ti <container name or id> webauth-user add <username>`.
  - To update a user password: `docker exec -ti <container name or id> webauth-user update <username>`.
  - To remove a user: `docker exec <container name or id> webauth-user del <username>`.
  - To list users: `docker exec <container name or id> webauth-user user`.

## Reverse Proxy

The following sections contain NGINX configurations that need to be added in
order to reverse proxy to this container.

A reverse proxy server can route HTTP requests based on the hostname or the URL
path.

### Routing Based on Hostname

In this scenario, each hostname is routed to a different application/container.

For example, let's say the reverse proxy server is running on the same machine
as this container. The server would proxy all HTTP requests sent to
`handbrake.domain.tld` to the container at `127.0.0.1:5800`.

Here are the relevant configuration elements that would be added to the NGINX
configuration:

```nginx
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

upstream docker-handbrake {
	# If the reverse proxy server is not running on the same machine as the
	# Docker container, use the IP of the Docker host here.
	# Make sure to adjust the port according to how port 5800 of the
	# container has been mapped on the host.
	server 127.0.0.1:5800;
}

server {
	[...]

	server_name handbrake.domain.tld;

	location / {
	        proxy_pass http://docker-handbrake;
	}

	location /websockify {
		proxy_pass http://docker-handbrake;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection $connection_upgrade;
		proxy_read_timeout 86400;
	}
}

```

### Routing Based on URL Path

In this scenario, the hostname is the same, but different URL paths are used to
route to different applications/containers.

For example, let's say the reverse proxy server is running on the same machine
as this container. The server would proxy all HTTP requests for
`server.domain.tld/handbrake` to the container at `127.0.0.1:5800`.

Here are the relevant configuration elements that would be added to the NGINX
configuration:

```nginx
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

upstream docker-handbrake {
	# If the reverse proxy server is not running on the same machine as the
	# Docker container, use the IP of the Docker host here.
	# Make sure to adjust the port according to how port 5800 of the
	# container has been mapped on the host.
	server 127.0.0.1:5800;
}

server {
	[...]

	location = /handbrake {return 301 $scheme://$http_host/handbrake/;}
	location /handbrake/ {
		proxy_pass http://docker-handbrake/;
		# Uncomment the following line if your Nginx server runs on a port that
		# differs from the one seen by external clients.
		#port_in_redirect off;
		location /handbrake/websockify {
			proxy_pass http://docker-handbrake/websockify/;
			proxy_http_version 1.1;
			proxy_set_header Upgrade $http_upgrade;
			proxy_set_header Connection $connection_upgrade;
			proxy_read_timeout 86400;
		}
	}
}

```
## Shell Access

To get shell access to the running container, execute the following command:

```shell
docker exec -ti CONTAINER sh
```

Where `CONTAINER` is the ID or the name of the container used during its
creation.

## Access to Optical Drive(s)

By default, a Docker container doesn't have access to host's devices.  However,
access to one or more device can be granted with the `--device DEV` parameter.

Optical drives usually have `/dev/srX` as device.  For example, the first drive
is `/dev/sr0`, the second `/dev/sr1`, and so on.  To allow HandBrake to access
the first drive, this parameter is needed:
```
--device /dev/sr0
```

To easily find devices of optical drives, start the container and look at its
log for messages similar to these ones:
```
...
[cont-init.d] 54-check-optical-drive.sh: executing...
[cont-init.d] 54-check-optical-drive.sh: looking for usable optical drives...
[cont-init.d] 54-check-optical-drive.sh: found optical drive /dev/sr0, but it is not usable because is not exposed to the container.
[cont-init.d] 54-check-optical-drive.sh: no usable optical drive found.
[cont-init.d] 54-check-optical-drive.sh: exited 0.
...
```

Since HandBrake can decrypt DVD video discs, their conversion can be performed
directly from the optical device.  From the graphical interface, click the
`Open Source` button and browse through the file system to find your optical
drive device (e.g. `/dev/sr0`).

## Automatic Video Conversion

This container has an automatic video converter built-in.  This is useful to
batch-convert videos without user interaction.

Basically, files copied to the `/watch` container folder are automatically
converted by HandBrake to a pre-defined video format according to a pre-defined
preset.

All configuration parameters of the automatic video converter are
defined via environment variables.  See the
[Environment Variables](#environment-variables) section for the list of
available variables.  The ones having their name starting with
`AUTOMATED_CONVERSION_` apply to the automatic video converter.

**NOTE**: A preset is identified by its category and its name.

**NOTE**: All default presets, along with personalized/custom ones, can be seen
and edited with the HandBrake GUI.

**NOTE**: Converted videos are stored, by default, to the `/output` folder of
the container.

**NOTE**: The status and progression of conversions performed by the automatic
video converter can be seen from both the GUI and the container's log.
Container's log can be obtained by executing the command
`docker logs handbrake`, where `handbrake` is the name of the container.  Also,
full details about the conversion are stored in `/config/log/hb/conversion.log`
(container path).

### Multiple Watch Folders

If needed, additionnal watch folders can be used:
  - `/watch2`
  - `/watch3`
  - `/watch4`
  - `/watch5`
  - etc.

This is useful for scenarios where videos need to be converted by different
presets.  For example, one could use a watch folder for movies and another watch
folder for TV shows, both having different encoding quality requirements.

By default, additional watch folders inherits the same settings has the main one
(`/watch`).  A setting for a particular watch folder can be overriden by adding
its index to the corresponding environment variable name.

For example, to set the HandBrake preset used to convert videos in `/watch2`,
the environment variable `AUTOMATED_CONVERSION_PRESET_2` is used.
`AUTOMATED_CONVERSION_PRESET_3` is used for `/watch3`, and so on.

All settings related to the automatic video converter (environment variables
with name prefixed with `AUTOMATED_CONVERSION_`) can be overriden for each
additional watch folder.

The maximum number of watch folders handled by the automatic video converter
is defined by the `AUTOMATED_CONVERSION_MAX_WATCH_FOLDERS` environment variable.

**NOTE**: Each additional watch folder must be mapped to a folder on the host by
adding a volume mapping during the creation of the container.

**NOTE**: Each output folder defined via the `AUTOMATED_CONVERSION_OUTPUT_DIR`
environment variable must be mapped to a folder on the host by adding a volume
mapping during the creation of the container.

### Video Discs

The automatic video converter supports video discs, in the following format:
  - ISO image file.
  - DVD video disc folder containing the `VIDEO_TS` folder.
  - Blu-ray video disc folder containing the `BDMV` folder.

Note that folder names are case sensitive.  For example, `video_ts`, `Video_Ts`
or `Bdmv` won't be treated as discs, but as normal directories.

When the source is a disc folder, the name of the converted video file will
match to one of its folder.  For example, `/watch/MyMovie/VIDEO_TS` will produce
a video file with name `MyMovie.mp4`.

Video discs can have multiple titles (the main movie, previews, extras, etc).
In a such case, each title is converted to its own file.  These files have the
suffix `.title-XX`, where `XX` is the title number. For example, if the file
`MyMovie.iso` has 2 titles, the following files would be generated:
  - `MyMovie.title-1.mp4`
  - `MyMovie.title-2.mp4`

It is possible to ignore titles shorted than a specific amount of time.  By
default, only titles longer than 10 seconds are processed.  This duration can be
adjusted via the `AUTOMATED_CONVERSION_SOURCE_MIN_DURATION` environment
variable.  See the [Environment Variables](#environment-variables) section for
details about setting environment variables.

### Hooks

Custom actions can be performed using hooks.  Hooks are shell scripts executed
by the automatic video converter.

**NOTE**: Hooks are always invoked via `/bin/sh`, ignoring any shebang the
script may have.

Hooks are optional and by default, no one is defined.  A hook is defined and
executed when the script is found at a specific location.

The following table describe available hooks:

| Container location | Description | Parameter(s) |
|--------------------|-------------|--------------|
| `/config/hooks/pre_conversion.sh` | Hook executed before the beginning of a video conversion. | The first argument is the path of the converted video.  The second argument is the path to the source file.  Finally, the third argument is the name of the Handbrake preset that will be used to convert the video. |
| `/config/hooks/post_conversion.sh` | Hook executed when the conversion of a video file is terminated. | The first parameter is the status of the conversion.  A value of `0` indicates that the conversion terminated successfuly.  Any other value represent a failure.  The second argument is the path to the converted video (the output).  The third argument is the path to the source file.  Finally, the fourth argument is the name of the Handbrake preset used to convert the video. |
| `/config/hooks/post_watch_folder_processing.sh` | Hook executed after all videos in the watch folder have been processed. | The path of the watch folder. |

During the first start of the container, example hooks are installed in
`/config/hooks/`.  Example scripts have the suffix `.example`.  For example,
you can use `/config/hooks/post_conversion.sh.example` as a starting point.

**NOTE**: Keep in mind that this container has the minimal set of packages
required to run HandBrake.  This may limit actions that can be performed in
hooks.

### Temporary Conversion Directory

A video being converted is written in a hidden, temporary directory under the
root of the output directory (`/output` by default).  Once a conversion
successfully terminates, the video file is moved to its final location.

This feature can be useful for scenarios where the output folder is monitored
by another application: with proper configuration, one can make sure this
application only "sees" the final, converted video file and not the transient
versions.

If the monitoring application ignores hidden directories, then nothing special
is required and the application should always see the final file.

However, if the monitoring application handles hidden directories, the automatic
video converter should be configured with the
`AUTOMATED_CONVERSION_OUTPUT_SUBDIR` environment variable sets to a
subdirectory.  The application can then be configured to monitor this
subdirectory.  For example, if `AUTOMATED_CONVERSION_OUTPUT_SUBDIR` is set to
`TV Shows` and `/output` is mapped to `/home/user/appvolumes/HandBrake` on the
host, `/home/user/appvolumes/HandBrake/TV Shows` should be monitored by the
application.

## Intel Quick Sync Video

Intel Quick Sync Video is Intel's brand for its dedicated video encoding and
decoding hardware core.  It is a technology that is capable of offloading video
decoding and encoding task to the integrated GPU, thus saving the CPU usage to
do other tasks.  As a specialized hardware core on the processor die, Quick Sync
offers a much more power efficient video processing which is much superior to
video encoding on a CPU.

For HandBrake to be able to use hardware-accelerated encoding, the following are
required:

  - Have a compatible Intel processor.  To determine if your CPU has the Quick
    Sync Video hardware, consult this [list] from the [Intel Ark] website.  The
    model name of your processor is printed to the container's log during its
    startup.  Look for a message like this:
    ```
    [cont-init.d] 95-check-qsv.sh: Processor: Intel(R) Core(TM) i7-2600 CPU @ 3.40GHz
    ```
  - The Intel i915 graphic driver must be loaded on the **host**.
  - The `/dev/dri` device must be exposed to the container.  This is done by
    adding the `--device /dev/dri` parameter to the `docker run` command.

When Intel Quick Sync Video is properly enabled, HandBrake offers the following
video encoder:
```
H.264 (Intel QSV)
```

If this encoder is not part of the list, something is wrong and looking at the
container's log can give more details about the issue.

**NOTE**: In most cases, HandBrake can successfully access the `/dev/dri` device
without changing anything on the host side.  This is possible because the user
under which the container is running is automatically added to the group owning
the `/dev/dri` device.  However, this method doesn't work if the device is owned
by the group `root`.  The problem can be fixed using one of the following
methods:
  - Running the container as root (`USER_ID=0`).
  - Adding, on the host, read/write permissions for all to the `/dev/dri`
    device:
    ```
    sudo chmod a+wr /dev/dri/*
    ```
  - Changing, on the host, the group owning the `/dev/dri` device.  For example,
    to change the group to `video`:
    ```
    sudo chown root:video /dev/dri/*
    ```

[list]: https://ark.intel.com/Search/FeatureFilter?productType=873&0_QuickSyncVideo=True
[Intel Ark]: https://ark.intel.com

### unRAID

With recent versions of unRAID, the Intel i915 driver is already included in the
distribution and is automatically loaded.

With older versions, the following lines might need to be added to
`/boot/config/go` for the driver to be loaded during the startup of unRAID:
```
# Load the i915 driver.
modprobe i915
```

## Nightly Builds

Nightly builds are based on the latest HandBrake development code.
This means that they may have bugs, crashes and instabilities.

Nightly builds are available through Docker image tags.  These tags have the
following format:
```
nightly-<COMMIT_DATE>-<COMMIT_HASH>
```

Where:
  - `COMMIT_DATE` is the date (in `YYMMDDHHMMSS` format) of the latest commit
    from the HandBrake [Git repository].
  - `COMMIT_HASH` is the short hash of the latest commit from the HandBrake
    [Git repository].

The latest nightly build is available through the `nightly-latest` Docker image
tag.  The list of available tags are available on [Docker Hub].

To use a Docker image tag, it has to be appended to the name of the Docker image
during the creation of the container.  Here is an example:
```
docker run [OPTIONS..] jlesage/handbrake:nightly-latest
```

[Git repository]: https://github.com/HandBrake/HandBrake
[Docker Hub]: https://hub.docker.com/r/jlesage/handbrake/tags/

## Debug Builds

Debug builds can be used to better investigate problems that can occur with
HandBrake.  These builds have HandBrake
compiled in debug mode and all symbols are kept.

The main use case of debug builds is debugging a crash.  To do this, a core dump
needs to be generated when HandBrake crashes.  To make sure
this core dump is properly generated, two things are required:

  1. Core dumps must be enabled.  This is done by setting the maximum size of
     cores via the `--ulimit core=-1` parameter of the `docker run` command.
     A value of `-1` mean "unlimited".
  2. Location of the cores must be set.  This can be done by executing the
     following command on the **host**:
     ```
     echo 'CORE_PATTERN' | sudo tee /proc/sys/kernel/core_pattern
     ```
     Where `CORE_PATTERN` is the template that defines the naming of core dump
     files.  For example, to set the files in the configuration volume of the
     container (for easy retrieval from the host), use the pattern
     `/config/core.%e.%t`.

     **NOTE**: Because a core file contains the complete memory layout of an
     application, it is created with restrictive permissions.  If another user
     other than the one used to run HandBrake needs to access
     the core file, permissions must be changed by executing
     `chmod a+r CORE`, where `CORE` is the path to the core file.

     **NOTE**: Since the core dump files pattern is shared between the host and
     the container, you may want to revert to the original pattern once
     done.

     **NOTE**: The current value of the pattern can be obtained by executing
     `cat /proc/sys/kernel/core_pattern`.

Debug builds are available by using Docker image tags with the `debug` suffix.
Make sure to look at available [tags on Docker Hub].

When creating the container, the tag needs to be appended to the name of the
Docker image, like this:
```
docker run [OPTIONS..] jlesage/handbrake:v1.14.3-debug
```

[tags on Docker Hub]: https://hub.docker.com/r/jlesage/handbrake/tags/

### unRAID

On systems running unRAID, the `--ulimit core=-1` parameter can be added to the
`Extra Parameters` field of the container settings.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-handbrake/issues
