-- plasma-applications.menu уходит вместе с plasma-workspace, берём меню GNOME
hl.env("XDG_MENU_PREFIX", "gnome-")

-- Один курсор везде: Hyprland, XWayland, GTK (gsettings/settings.ini), ~/.icons/default
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")

-- ~/.local/bin (rice-theme, rice-telegram-theme, …) — сессия gdm его в PATH не кладёт
local local_bin = os.getenv("HOME") .. "/.local/bin"
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
if not (":" .. path .. ":"):find(":" .. local_bin .. ":", 1, true) then
    hl.env("PATH", local_bin .. ":" .. path)
end
