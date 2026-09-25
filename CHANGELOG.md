# Changelog

All notable changes to this project will be documented in this file.

This project uses [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-09-25

Initial public release.

- Temporarily prevent automatic suspend for a specified duration or until
  explicitly stopped.
- Allow the display to dim or turn off normally.
- Keep the inhibitor active after an SSH session disconnects.
- Release the inhibitor when the physical power button is pressed so Gaming
  Mode can suspend normally.
- Provide install, status, stop, and uninstall commands.
- Document wired Wake-on-LAN, remote-access limitations, Tailscale, and the
  optional SteamOS battery charge limit.

[0.1.0]: https://github.com/mcnearcj/deck-awake/tree/v0.1.0
