------------------------
-- ВВОД (мой слой поверх end-4)
-- Живёт в custom/, поэтому переживает обновления end-4.
------------------------
hl.config({
    input = {
        -- Первая раскладка задаёт раскладку БИНДОВ, поэтому ставим us первой:
        -- так латинские шорткаты (SUPER+Q, SUPER+E и т.д.) срабатывают в любой раскладке.
        kb_layout  = "us,ru",
        kb_options = "grp:alt_shift_toggle", -- Alt+Shift переключает раскладку
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll          = true,
            tap_to_click            = true,
            tap_and_drag            = true,
            drag_lock               = 1,    -- продолжать перетаскивание после отрыва пальца
            disable_while_typing    = true,
            middle_button_emulation = true, -- тап тремя пальцами = средняя кнопка
            clickfinger_behavior    = false,
            scroll_factor           = 0.8,  -- на ноутбуке скролл плавнее
        },
    },
})

-- Основная клавиатура: по умолчанию русская раскладка для ввода.
-- Раскладку БИНДОВ это не меняет (она берётся из глобального kb_layout = us,ru),
-- поэтому шорткаты продолжают работать в обеих раскладках.
hl.device({
    name      = "at-translated-set-2-keyboard",
    kb_layout = "ru,us",
})

------------------------
-- RICE: рамки, тени, отступы, анимации (мой слой поверх end-4)
------------------------
-- Цвета берём из палитры matugen (её генерирует ii из обоев),
-- чтобы при смене обоев рамка перекрашивалась вместе со всем остальным.
local function matugen_color(name, fallback)
    local f = io.open(HOME .. "/.local/state/quickshell/user/generated/colors.json", "r")
    if not f then return fallback end
    local json = f:read("*a")
    f:close()
    return json:match('"' .. name .. '"%s*:%s*"#(%x%x%x%x%x%x)"') or fallback
end

local primary  = matugen_color("primary", "e7bdb9")
local accent2  = matugen_color("outline", "919191")

hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 14,
        border_size = 2,
        col = {
            -- статичный градиент: вращающийся (borderangle loop) зря грузит iGPU
            active_border   = { colors = { "rgba(" .. primary .. "ee)", "rgba(" .. accent2 .. "ee)" }, angle = 45 },
            inactive_border = "rgba(00000000)",
        },
        snap = { window_gap = 6, monitor_gap = 14 },
    },
    decoration = {
        blur = {
            size   = 7,
            passes = 2,
        },
        shadow = {
            -- «двойная рамка» как в lilith: внутри градиентный бордер, снаружи
            -- плотное тёмное кольцо вместо мягкой тени (range 30 давал ореол)
            range          = 4,
            render_power   = 3,
            offset         = { 0, 0 },
            color          = "rgba(000000aa)",
            color_inactive = "rgba(00000066)",
        },
        dim_strength = 0.12,
    },
})

-- Лёгкий «пружинящий» вылет окон на кривых, которые end-4 объявил, но не использует
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4,   bezier = "expressiveDefaultSpatial", style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "expressiveDefaultSpatial", style = "slide" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,   bezier = "expressiveDefaultSpatial", style = "slidefade 20%" })

------------------------
-- HYPRExpo: обзор рабочих столов (плагин собирается через hyprexpo-rebuild)
------------------------
local hyprexpo_so = HOME .. "/.local/lib/hyprland-plugins/hyprexpo.so"
if is_file_exists(hyprexpo_so) then
    -- pcall: после обновления Hyprland старый .so может не загрузиться, конфиг при этом ломаться не должен
    pcall(hl.plugin.load, hyprexpo_so)
end
if hl.plugin.hyprexpo then
    local c = function(role, fb) return "rgb(" .. matugen_color(role, fb) .. ")" end
    hl.config({ plugin = { hyprexpo = {
        columns          = 3,
        gaps_in          = 10,
        gaps_out         = 24,
        bg_col           = c("surface", "131313"),
        workspace_method = "center current",
        -- рамки плиток в цветах палитры: текущий стол, фокус клавиатуры, под мышью
        border_width         = 2,
        border_color_current = c("primary", "ffffff"),
        border_color_focus   = c("outline", "919191"),
        border_color_hover   = c("outline_variant", "474747"),
        -- номера столов в углу плитки
        label_enable        = 1,
        label_text_mode     = "index",
        label_position      = "top-left",
        label_font_size     = 14,
        label_color_current = c("on_primary", "1b1b1b"),
        label_color_focus   = c("on_surface", "e2e2e2"),
        label_color_hover   = c("on_surface", "e2e2e2"),
        label_bg_enable     = 1,
        label_bg_shape      = "circle",
    } } })
    hl.bind("SUPER + grave", function() hl.plugin.hyprexpo.expo("toggle") end, { description = "Hyprexpo: toggle overview" })
    -- щипок 4 пальцами (3 пальца-щипок у end-4 уже fullscreen, свайпы 3/4 заняты)
    hl.plugin.hyprexpo.gesture({ fingers = 4, direction = "pinch", action = "expo" })
end
