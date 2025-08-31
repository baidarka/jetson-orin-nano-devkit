# jetson-orin-nano-devkit

Flash an NVIDIA Jetson Orin Nano super devkit using commandline only.
Aimed at my personal situation and timing.

My goal is to flash the Jetson from the commandline, and straight onto an NVMe disk.
Thereby bypassing the SD card business.
Apparently that is a valid scenario.

For more generic approaches, please check:
<https://github.com/jetsonhacks>
as well as JetsonHacks on YouTube.

## Prereq

- Ubuntu 22? (with some free disk space. say 64GB ?)
- stable USB connection to Jetson Orin Nano carrier board.
`curl wget tar grep awk sed sudo lsus`

```bash
sudo apt install qemu binfmt-support qemu-user-static libxml2-utils binutils
```

## Findings

Running Ubuntu 24 from a USB stick in the end got stuck during flashing.
Possibly due to USB hiccups.

Running Ubuntu 22 seems better suited.