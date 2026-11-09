-- plasma-applications.menu уходит вместе с plasma-workspace, берём меню GNOME
hl.env("XDG_MENU_PREFIX", "gnome-")

-- Один курсор везде: Hyprland, XWayland, GTK (gsettings/settings.ini), ~/.icons/default
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")
