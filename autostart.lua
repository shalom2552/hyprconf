-- ~/.config/hypr/autostart.conf
--===========================
-- AUTOSTART
--===========================

hl.on("hyprland.start", function ()

  -- Wayland session environment
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

  -- Wallpaper
  hl.exec_cmd("pkill -x awww-daemon; sleep 0.1; awww-daemon")
  hl.exec_cmd("bash ~/.config/hypr/scripts/set-wallpaper.sh")

  -- Notifications
  hl.exec_cmd("swaync")

  -- GTK dark mode
  hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'")

  -- System tray
  hl.exec_cmd("nm-applet")

  -- cliphist
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- OSD for volume/brightness
  hl.exec_cmd("swayosd-server")

  -- Idle daemon
  hl.exec_cmd("hypridle")

  -- Quickshell popup manager (wallpaper picker)
  hl.exec_cmd("bash ~/.config/hypr/scripts/get_monitor_offset.sh")

end)
