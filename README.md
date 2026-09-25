# deck-awake

`deck-awake` is a small Steam Deck command that temporarily prevents automatic
suspend during long-running downloads, transfers, builds, backups, or remote
sessions.

It is designed for SteamOS Gaming Mode:

- The screen may dim or turn off normally.
- The inhibitor survives an SSH disconnect.
- A timer automatically restores normal suspend behavior.
- Pressing the physical power button releases the inhibitor and suspends the
  Deck normally.
- Nothing is enabled at boot, and no permanent system service is installed.

## Why the power-button watcher exists

A normal `systemd-inhibit --what=sleep` lock also blocks manual suspend. In
Gaming Mode, pressing the power button while such a lock is active can leave
the screen black even though the Deck is still awake.

`deck-awake` avoids that failure by watching the Deck's readable ACPI
power-button devices with `evtest`. When it sees `KEY_POWER`, it stops its own
transient inhibitor before Steam submits the suspend request:

```text
Power button -> release inhibitor -> Steam suspends normally
```

The command refuses to start if it cannot find a readable power-button device.

## Requirements

- Steam Deck running SteamOS
- Bash
- systemd user services and `systemd-inhibit`
- `evtest`, `coreutils`, and `grep` (included with SteamOS)
- A terminal or SSH access for installation and use

Tested on a Steam Deck running SteamOS build `20260922.1`. Other SteamOS builds
may work, but power-button device permissions or Gaming Mode behavior can
change.

## Install

Clone or copy this directory onto the Deck, then run:

```bash
cd deck-awake
./install.sh
```

This installs one executable at `~/.local/bin/deck-awake`. It does not require
root access or modify Steam's configuration.

If `~/.local/bin` is not in your shell's `PATH`, use the full path shown in the
examples below or add that directory to `PATH`.

## Usage

```bash
~/.local/bin/deck-awake          # prevent suspend for 2 hours
~/.local/bin/deck-awake 45m      # prevent suspend for 45 minutes
~/.local/bin/deck-awake 3h       # prevent suspend for 3 hours
~/.local/bin/deck-awake on       # prevent suspend until stopped
~/.local/bin/deck-awake status   # show the transient service
~/.local/bin/deck-awake off      # restore normal suspend immediately
```

Durations accept a number with an optional `s`, `m`, `h`, or `d` suffix.
Starting a new timer replaces the existing one.

Internally, the command creates a transient user unit named
`deck-awake.service`. It disappears when the timer expires, when `off` is run,
when the power button is pressed, or when the Deck reboots.

## Wake-on-LAN and remote access

Wake-on-LAN is not required to use `deck-awake`. It becomes important when the
Deck is administered remotely: after the timer expires or the power button is
pressed, the Deck suspends and SSH, Steam Remote Play, and Tailscale become
unreachable.

Before relying on remote wake:

1. Keep physical access to the Deck while testing. If WoL fails, the physical
   power button is the recovery path.
2. Prefer wired Ethernet through a powered dock. On the Deck used to develop
   this project, the Wi-Fi adapter advertised magic-packet Wake-on-WLAN support,
   but Wake-on-Wi-Fi did not work in testing. Wired WoL through the dock did.
   Wake-on-Wi-Fi depends on the radio, access point, firmware, and driver, so
   results may differ on other hardware and networks.
3. Ensure the dock and Ethernet cable remain connected and powered during
   suspend.
4. Send the magic packet from the same physical LAN, or from an always-on device
   on that LAN such as a router, NAS, Raspberry Pi, or Home Assistant host.

The sleeping Deck cannot receive a wake request through its own Tailscale
client because that client is suspended too. Magic packets are normally local
broadcast traffic and are not routed across the internet. Remote wake therefore
requires an awake relay inside the physical network or router support for WoL.

### Tailscale access

For an update-resistant Tailscale installation on SteamOS, see
[`tailscale-dev/deck-tailscale`](https://github.com/tailscale-dev/deck-tailscale).
That is the installer used on the Deck where this project was developed. It
installs Tailscale under `/opt/tailscale`, configures its systemd service, and
can enable Tailscale SSH.

Tailscale provides convenient remote access while the Deck is awake, but it
does not replace WoL. Once the Deck suspends, its Tailscale daemon and network
stack are suspended as well. To wake it remotely, an awake device on the
Deck's physical LAN must send the wired magic packet.

### Battery charge limit

Because `deck-awake` may leave the Deck running on external power for extended
periods, the Deck used to develop this project has its battery charge limit set
to 80% as a precaution. This was configured through Gaming Mode under
**Settings → Power → Battery Charge Limit**.

The charge limit is optional and is managed by SteamOS. `deck-awake` does not
read or change battery-charging settings.

### Enable wired Wake-on-LAN

Find the active wired connection and its MAC address:

```bash
nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status
nmcli -f GENERAL.DEVICE,GENERAL.CONNECTION,GENERAL.HWADDR device show
```

Enable magic-packet wake, replacing the connection name as needed:

```bash
sudo nmcli connection modify "Wired connection 1" \
  802-3-ethernet.wake-on-lan magic
sudo nmcli device reapply YOUR_ETHERNET_INTERFACE
```

Verify the saved profile:

```bash
nmcli -g 802-3-ethernet.wake-on-lan \
  connection show "Wired connection 1"
```

It should print `magic`.

### Send a magic packet from Windows

Replace `AA:BB:CC:DD:EE:FF` with the dock Ethernet MAC and replace
`192.168.1.255` with the broadcast address for the Deck's physical LAN:

```powershell
$mac = "AA:BB:CC:DD:EE:FF".Split(":") |
  ForEach-Object { [byte]("0x$_") }
$packet = [byte[]]((,0xFF * 6) + ($mac * 16))
$udp = [System.Net.Sockets.UdpClient]::new()
$udp.EnableBroadcast = $true
[void]$udp.Send($packet, $packet.Length, "192.168.1.255", 9)
$udp.Close()
```

Test WoL before leaving the Deck unattended: suspend it, wait at least ten
seconds, send the packet, and confirm that the wired interface and SSH return.

## Troubleshooting

Check the helper:

```bash
~/.local/bin/deck-awake status
systemd-inhibit --list
journalctl --user -u deck-awake.service --no-pager
```

If the display is black but SSH still works, release the inhibitor:

```bash
~/.local/bin/deck-awake off
```

Then complete a real suspend/resume cycle:

```bash
sudo systemctl suspend
```

Wake the Deck with its physical power button. Do not place a Deck that may
still be awake into a case or bag; verify that it actually suspended first.

## Uninstall

From the repository directory:

```bash
./uninstall.sh
```

## Scope

This project intentionally does not permanently disable Steam's idle timeout,
install a boot service, configure battery charging limits, or enable WoL
automatically. Those policies are machine- and network-specific; the README
documents WoL so remote users can configure and test it deliberately.

## License

[MIT](LICENSE)
