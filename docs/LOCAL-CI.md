# Local CI policy

Omnux does not use hosted CI. Builds and releases run on maintainer hardware:

    ./scripts/build-local.sh [version]

Produces `releases/installer-<ver>.tar.gz`, `latest`, and `SHA256SUMS`,
including the cross-compiled m1n1 integration binary from ../m1n1.

Publishing is a manual `gh release create` against
michaelmonetized/asahi-installer. The curl bootstrap resolves
`/releases/latest/download/` automatically.

Requirements are listed in the script header (Arch package names).
