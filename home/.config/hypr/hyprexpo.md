# Hyprexpo — обзор рабочих столов

Шпаргалка по локально собранному плагину. Конфиг: `~/.config/hypr/hyprland.lua`
(секция «ПЛАГИНЫ» + секция «HYPRExpo» в конце файла).

## Что установлено

| что | где |
| --- | --- |
| плагин | `~/.local/lib/hyprland-plugins/hyprexpo.so` (v0.56.2) |
| пересборка | `hyprexpo-rebuild` → `~/.local/bin/hyprexpo-rebuild` |
| кэш сборки | `~/.cache/hyprexpo` (sysroot с заголовками + исходники, ~336 МБ) |
| исходник | форк `sandwichfarm/hyprexpo`, коммит-пин `5891014c…` (для Hyprland 0.56.2) |

Официальный `hyprexpo` из `hyprwm/hyprland-plugins` удалён 12.05.2026 как
неподдерживаемый, поэтому установлен поддерживаемый форк. `hyprpm` на этой
системе не используется: его состояние лежит в root-каталоге `/var/cache/hyprpm`,
а у сборки Hyprland из Fedora-RPM «unknown commit», из-за чего hyprpm не может
подобрать заголовки.

## Использование

* **Super + G** — открыть/закрыть обзор.
* Мышь: клик по плитке — перейти в воркспейс; перетаскивание окна на плитку —
  переместить окно в тот воркспейс.
* Внутри обзора: `←↑↓→` или `h j k l` — фокус, `Enter` — выбрать, `Esc` — отмена,
  `1`…`9`, `0` — сразу перейти на воркспейс с таким номером.
* Обзор на всех мониторах: `hl.plugin.hyprexpo.expo("toggle all")`.

Текущий конфиг плагина (в конце `hyprland.lua`):

```lua
plugin = { hyprexpo = {
    columns = 4, gaps_in = 5,
    bg_col = "rgb(1e1e2e)",
    workspace_method = "center current",
} }
```

## Настройки (внутри `plugin = { hyprexpo = { … } }`)

Сетка и поведение:

| опция | по умолч. | смысл |
| --- | --- | --- |
| `columns` | 3 | плиток в ряду, 1–7 |
| `rows` | 0 | 0 — рядов столько же, сколько колонок; иначе 1–7 |
| `gaps_in` / `gaps_out` | 5 / 0 | отступы между плитками / по краю |
| `bg_col` | `0xFF111111` | фон сетки |
| `workspace_method` | `center current` | раскладка воркспейсов, либо `first <N>` |
| `skip_empty` | 0 | 1 — не показывать пустые воркспейсы |
| `max_workspace` | 0 | ограничить число плиток номером воркспейса |
| `show_cursor` | 1 | 0 — прятать курсор в обзоре |
| `show_pinned_windows` | 0 | 1 — показывать pin/PiP в превью |
| `drag_drop_enable` | 1 | 0 — выключить перетаскивание окон на плитки |
| `cancel_key` | `escape` | клавиши отмены (`none`/`off` — выключить) |

Вид плиток и подписи:

| опция | по умолч. | смысл |
| --- | --- | --- |
| `tile_rounding` | 0 | радиус углов превью |
| `border_width` | 2 | толщина рамки |
| `border_color_current` | `rgb(66ccff)` | рамка активного воркспейса |
| `border_color_focus` | `rgb(ffcc66)` | рамка плитки под фокусом клавиатуры |
| `border_color_hover` | `rgb(aabbcc)` | рамка под курсором |
| `label_enable` | 1 | подписи воркспейсов |
| `label_text_mode` | `token` | `token`, `index` или `id` |
| `label_token_map` | — | токены по порядку плиток, напр. `1,2,3,4,5,6,7,8,9,0` |
| `label_position` | `center` | `top-left`, `top-right`, `bottom-*`, `center` |
| `label_font_size` | 16 | размер шрифта подписи |
| `label_color_current/_focus/_hover` | — | цвета подписей |
| `label_bg_enable` / `label_bg_shape` | 1 / `circle` | подложка под подписью |

Клавиатура:

| опция | по умолч. | смысл |
| --- | --- | --- |
| `keynav_enable` | 1 | навигация и submap `hyprexpo` |
| `number_key_mode` | `workspace` | `workspace` — цифра = номер воркспейса, `index` — позиция плитки, `passthrough` — цифры отдаются своим биндам |
| `keynav_wrap_h` / `_v` | 1 / 1 | зацикливание фокуса по краям |
| `keynav_reading_order` | 0 | 1 — движение построчно |

Жест тачпада: `gesture_fingers = 0` (выключен), `gesture_direction = up`,
`gesture_distance = 200`. Внимание: у тебя уже заняты все свайпы в 3 и 4 пальца
(`hl.gesture` в конфиге), поэтому выбранная комбинация «пальцы + направление» не
должна совпадать с ними. Через Lua можно и отмену вешать на жест:

```lua
hl.plugin.hyprexpo.gesture({ fingers = 4, direction = "pinch", action = "expo" })
```

Второй («scrolling») режим показывает отдельные окна на воркспейсах с нативной
раскладкой `scrolling`; настройка `scrolling_thumbnail_budget` (по умолч. 4)
ограничивает память под превью. Остальное — в доке: <https://hyprexpo.lol/docs/>
(локальная копия: `~/.cache/hyprexpo/src-5891014c…/docs/`).

## Диспетчеры

`hyprexpo:expo` c аргументами `toggle`, `on`/`enable`, `off`/`disable`,
`cancel`, `select` (выбрать плитку под курсором), `bring` (забрать окно из
воркспейса под курсором в текущий), `1`…`9`. Суффикс `all` — на все мониторы.
Навигация: `hyprexpo:kb_focus left|right|up|down`, `hyprexpo:kb_confirm`,
`hyprexpo:kb_selecti <индекс>`, `hyprexpo:kb_selectn <воркспейс>`,
`hyprexpo:kb_select <токен>`, `hyprexpo:move_window <из> <в>`.

Из Lua — через `hl.plugin.hyprexpo.*`, например:

```lua
hl.bind("SUPER + G", function() hl.plugin.hyprexpo.expo("toggle") end)
```

## Обслуживание

```bash
hyprexpo-rebuild              # пересобрать под текущий Hyprland и подменить
hyprexpo-rebuild --clean      # удалить кэш сборки (освободит ~336 МБ)
hyprctl plugin list           # загружен ли плагин
hyprctl configerrors          # ошибки конфига (должно быть пусто)
hyprctl plugin unload ~/.local/lib/hyprland-plugins/hyprexpo.so
```

* После `sudo dnf upgrade hyprland` обязательно запусти `hyprexpo-rebuild`:
  плагин должен быть собран против той же ревизии и ABI, что и композитор.
  Скрипт сам берёт нужный коммит из `hyprpm.toml` форка; если для новой версии
  пина ещё нет — он сообщит об этом.
* Не копируй `.so` поверх загруженного файла вручную (можно повредить память
  Hyprland) — скрипт выгружает плагин, копирует и загружает обратно.
* Перед правками конфига сделан бэкап `~/.config/hypr/hyprland.lua.bak-hyprexpo-*`.

### Удаление

1. Убрать/закомментировать строку `hl.plugin.load("…/hyprexpo.so")`.
2. `rm -rf ~/.local/lib/hyprland-plugins ~/.local/bin/hyprexpo-rebuild`
3. `hyprexpo-rebuild --clean` (если нужен кэш) — либо просто `rm -rf ~/.cache/hyprexpo`.

Секция «HYPRExpo» в конце конфига написана с проверкой
`hl.get_loaded_plugins()`, поэтому без плагина конфиг продолжит работать.
