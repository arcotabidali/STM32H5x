# Picocom (bundled)

This repo includes a prebuilt `picocom` binary at `tools/picocom/picocom`, so you can use it without installing `picocom` from your OS.

## Quick start

```bash
# List likely serial devices
ls -l /dev/ttyACM* /dev/ttyUSB* 2>/dev/null || true

# Connect (example: 115200 8N1)
./tools/picocom/picocom -b 115200 /dev/ttyACM0
```

## Key commands

- Exit: `Ctrl-a` then `Ctrl-x`
- Help: `Ctrl-a` then `Ctrl-h`

## Permissions (Linux)

If you get "Permission denied" opening the device:

```bash
sudo usermod -aG dialout "$USER"
newgrp dialout
```

## Licenses

- Picocom license: `tools/picocom/LICENSE.txt`
- Linenoise license: `tools/picocom/THIRD_PARTY_LICENSES/linenoise-LICENSE`
