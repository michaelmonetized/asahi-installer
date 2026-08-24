# Omnux Linux — Apple Silicon Support Matrix

Omnux is an integration-first fork of Asahi Linux for the Omarchy desktop
experience on Apple Silicon Macs. We do not claim hardware enablement that
upstream has not achieved; we ship it sooner by integrating public
work-in-progress patches the moment they exist.

Status legend:
- **Stable** — installs from the standard path, daily-drivable
- **Experimental** — installable via expert mode or `OMNUX_EXPERIMENTAL=1`;
  expect missing GPU acceleration, broken sleep, reduced battery life
- **In progress** — public code exists but is not integrated/shippable yet
- **Nothing yet** — no public enablement code exists anywhere

| Machine class | Installer | Boot (m1n1) | Display | GPU accel | Notes |
| --- | --- | --- | --- | --- | --- |
| M1 / M2 series | Stable | Stable | Stable | Stable | Asahi upstream baseline |
| M3 (T8122) | Experimental | Working | WIP (iBoot fb) | In progress (DRM driver) | CPUfreq, NVMe, WiFi, BT, audio, keyboard/trackpad working upstream |
| M3 Pro/Max/Ultra (T603x) | Experimental | Working | WIP | TBA | Same as M3 base |
| M4 base (T8132) | Not yet | Partial — NVMe/MCC/ATC in Omnux m1n1 | Nothing yet | Nothing yet | NVMe driver + devicetrees landed in Omnux kernel; needs ADT-derived DT nodes from real hardware |
| M4 Pro/Max (T604x/T8140) | Not yet | Partial — PCIe/MCC PRs merged in Omnux m1n1 | Nothing yet | Nothing yet | Skeleton DTs still RFC upstream |
| M5 series | Nothing yet | Nothing yet | Nothing yet | Nothing yet | No public reverse engineering exists |

## What the Omnux fork changes vs upstream

1. **Kernel (`linux`, branch `omnux`)**: tracks `AsahiLinux/linux#asahi` and
   integrates public-but-unmerged series immediately:
   - t8132 (M4) ANS2 NVMe binding + driver (Yureka Lilian, LKML 2026-08-11)
   - M4 MacBook Pro built-in keyboard DT, M3 PMP power management,
     DCP suspend fixes, ATC PHY pipehandler fix (upstream PRs)
2. **m1n1 (branch `omnux`)**: integrates open PR stack —
   t8132 MCC/NVMe/ATC, SART v3/v4 unification, M4 SMP reservation,
   DCP 14.8.3 ABI, USB/Type-C controller work.
3. **Installer**: Omnux branding; three-tier gating with honest messaging;
   `OMNUX_EXPERIMENTAL=1` escape hatch for M3-class machines.

## Hard blockers we will not fake

M4-class machines need device tree nodes whose register bases and interrupt
numbers can only come from a real machine's ADT (dumped under macOS via m1n1).
If you own M4/M5 hardware and want to help, see docs/BRINGUP-HOWTO.md.
