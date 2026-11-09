#!/usr/bin/env sh
set -eu
systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
systemctl --user start quickshell.service
