# Omnux Apple Silicon bring-up guide

Goal: turn "In progress" rows in SUPPORT.md into installable ones, then into
Stable. This is reverse-engineering work; it happens on real hardware,
against macOS firmware, using upstream tooling.

## Prerequisites

- The target Mac (M4/M5 class) running macOS with a free disk container
- A second machine or this Mac's macOS side to run tooling
- Upstream docs: https://github.com/AsahiLinux/docs and the m1n1
  documentation (src/docs in the m1n1 repo)

## Step 1: dump the ADT

Boot the stock (or Omnux) m1n1 on the target Mac from USB by holding long
power-on, then use `m1n1.adt` from a proxyclient session to dump the ADT:

    python3 -m pip install --user pyserial construct
    python3 proxyclient/tools/dump_adt.py > adt.dump

The ADT contains every MMIO range, IRQ number and power domain the DTs need.
This step requires physical access to the machine — it cannot be done
remotely or from documentation.

## Step 2: write devicetrees

Port nodes block-by-block from the closest supported SoC (t8122 for M4 base),
substituting ADT values:

- `nvme` node: reg = nvmmu/nvme/ans ranges per binding schema
- `sart`, `ans_mbox`, PCIe ports + PHYs, AIC IRQ numbers, pmgr domains

Validate with `make dtbs_check` (kernel tree) before committing.

## Step 3: iterate over m1n1

Use `m1n1/proxyclient` experiments (`linux.py` boot harness) to boot the
Omnux kernel with earlycon. Bring-up order used successfully for M3:
NVMe -> UART/debug -> AIC -> PCIe -> DCP/framebuffer -> keyboard/touchpad.

## Step 4: report upstream

Omnux policy: everything we get working goes upstream first as patches;
our branches only carry what has not merged yet.
