#!/usr/bin/env bash
# Single source of truth for Lumina bootstrap env vars. Source this from every
# Mac-side and device-side bootstrap script — do not re-hardcode JBROOT.
#
# JBROOT must stay under /mnt2/root/... or /mnt2/tmp/... (measured-writable
# paths on this Data volume). Never /mnt2/jb (new top-level dirs on Data allow
# mkdir but reject file creates) and never classic /var/jb (that path does not
# exist on the ICH ramdisk — /mnt2 is Data, not /var).
export JBROOT="${JBROOT:-/mnt2/root/jb}"
export STAGE="${STAGE:-/mnt2/tmp/lumina-bootstrap}"
