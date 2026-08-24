# ISOs and hosting — platform reality

## There is no bootable ISO for Apple Silicon installs

PC-style live ISOs do not exist on this platform. Apple Silicon Macs boot
Linux only through a signed stub partition laid down by an installer running
*inside macOS* (or recoveryOS), containing the m1n1 → U-Boot chain. Writing
an ISO to a USB stick and booting it from an M-series Mac's internal storage
is not possible, regardless of distro. Asahi Linux and Fedora Asahi Remix
both ship exactly what Omnux ships:

1. a curl bootstrap script that fetches the installer payload, and
2. versioned installer tarballs on a release server.

## Omnux hosting (live today)

- Bootstrap one-liner:
  `curl -fsSL https://raw.githubusercontent.com/michaelmonetized/asahi-installer/omnux/scripts/bootstrap-omnux.sh | sh`
- Installer payloads: GitHub Releases at
  https://github.com/michaelmonetized/asahi-installer/releases
  (`/releases/latest/download/` is used by the bootstrap for stable URLs).
- `installer_data.json` currently comes from Asahi's CDN; forking it is a
  follow-up once we ship our own kernel packages.

When we get the omnux.dev domain: point it at the raw URLs above, nothing
else changes.

## What a USB image *is* good for later

Post-install, Apple Silicon Macs can boot external USB drives through
U-Boot. A rescue image (rootfs + our kernel) is worth building once
`linux-omnux` packages build cleanly in CI. That image is written with
`dd`, not booted as an installer.
