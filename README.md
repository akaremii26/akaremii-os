# akaremii-os &nbsp; [![bluebuild build badge](https://github.com/akaremii26/akaremii-os/actions/workflows/build.yml/badge.svg)](https://github.com/akaremii26/akaremii-os/actions/workflows/build.yml)

See the [BlueBuild docs](https://blue-build.org/how-to/setup/) if you want to make your own image.

## Installation

To rebase an existing atomic Fedora installation to the latest build:

- Rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/akaremii26/akaremii-os:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.
