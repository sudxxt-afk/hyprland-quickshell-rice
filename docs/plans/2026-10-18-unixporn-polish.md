# Полировка риса в духе unixporn — план реализации

> **Для агентов-исполнителей:** ОБЯЗАТЕЛЬНЫЙ СУБ-НАВЫК: используйте `executing-plans` для реализации плана по задачам. Шаги отмечены чекбоксами (`- [ ]`).

**Цель:** довести рабочий стол до «постового» вида: структурные обои под живое стекло, одна палитра во всей системе (включая приложения), уведомления и OSD внутри Wayle, выровненная и живая сцена виджетов.

**Архитектура:** три слоя рисования остаются прежними — Hyprland (обои, стекло, границы), Wayle 0.7.0 (бар, дропдауны, уведомления, OSD), Quickshell 0.3.2 (карточка плеера, док, эквалайзер). Над ними появляется четвёртый слой — `theme/`: `palette.toml` как единственный источник цвета и `render.py`, который раскладывает его по конфигам между маркерами. Стекло настраивается замером FPS с оверлеем Hyprland, а не на глаз.

**Стек:** Fedora 44, Hyprland 0.56.2, Wayle 0.7.0, Quickshell 0.3.2, Python 3.14 (numpy 2.5, pillow 12, tomllib — тесты через `python3 -m unittest`), kitty (CozetteVector), wofi, hyprpaper, hyprlock, btop, cava, starship, fastfetch.

**Спека:** `docs/specs/2026-10-18-unixporn-polish-design.md` — план аргументирует от неё, исполнителю нужно читать обе.

## Global Constraints

- Палитра — **только Catppuccin Mocha**, значения берутся из `theme/palette.toml`; литеральных хексов в конфигах и компонентах быть не должно. Токены: `base #1e1e2e`, `mantle #181825`, `crust #11111b`, `surface0 #313244`, `surface1 #45475a`, `surface2 #585b70`, `overlay0 #6c7086`, `overlay1 #7f849c`, `subtext0 #a6adc8`, `subtext1 #bac2de`, `text #cdd6f4`, `lavender #b4befe`, `blue #89b4fa`, `sapphire #74c7ec`, `sky #89dceb`, `teal #94e2d5`, `green #a6e3a1`, `yellow #f9e2af`, `peach #fab387`, `maroon #eba0ac`, `red #f38ba8`, `mauve #cba6f7`, `pink #f5c2e7`, `flamingo #f2cdcd`, `rosewater #f5e0dc`; акцент — `mauve`.
- Стекло (verbatim): `blur.size = 6`, `passes = 2`, `noise = 0.015`, `contrast = 1.05`, `brightness = 0.92`, `vibrancy = 0.12`, `vibrancy_darkness = 0.03` — стартовые значения; итог выбирается замером по критерию **≥ 55 FPS** на 1920×1080 (Task 8). `popups = true`, `special = false`, `new_optimizations = true`.
- Непрозрачности: бар `background-opacity = 78`, окна `inactive_opacity = 0.94`, стекло виджетов `rgba(24,24,37,0.62)` (QML `#9e181825`), рамка `rgba(205,214,244,0.20)` (`#33cdd6f4`).
- Геометрия виджетов: отступ от краёв экрана `16`, радиус `16`, низ всех трёх на линии `y = 1080 − 16`; высоты — карточка `96`, док `68`, эквалайзер `68`; по X: карточка `16`, док по центру (`x = (1920 − ширина) / 2`), эквалайзер `1920 − 16 − ширина`.
- Namespace слоёв: виджеты `qs-widgets`, бар `wayle-bar.*` (уведомления и OSD Wayle — своими namespace, точные имена фиксируются в Task 9).
- Бар Wayle: `inset-edge = 0.5` em (8 px), `inset-ends = 0.75` em (12 px), `rounding = "lg"`, `module-gap = 0.25`, блоки без внутренних зазоров, каждый блок со своим скруглением `button-group-rounding = "sm"`. Раскладка блоков не меняется.
- Шрифты: интерфейс и бар/виджеты — `JetBrains Mono` / `JetBrainsMono Nerd Font`, терминал — `CozetteVector 13`, размер интерфейса `11`.
- Тема приложений: GTK3/GTK4 — `catppuccin-mocha-mauve-standard+default`, иконки — `Papirus-Dark`, курсор — `catppuccin-mocha-mauve-cursors` (в `hl.env` уже прописан), `gsettings` синхронизируется с этими же значениями.
- Обвязка: уведомления и OSD рисует **Wayle**; `mako` и `swayosd` вне автозапуска, но **не удаляются**: откат — вернуть строки `hl.exec_cmd` и привязки.
- Медиа-клавиши (verbatim): `wayle audio output-volume +5` / `-5` (знак процента не принимается), `wayle audio output-mute`, `wayle audio input-mute`, `wayle media next|previous|play-pause`, яркость — `brightnessctl set 5%+` / `5%-`.
- Обои: генератор детерминирован по seed; размер ровно `1920x1080`; для локскрина — тёмный вариант той же картинки; структура есть по всей площади, нижняя полоса (y 880–1080) не пустая.
- Бюджеты: Quickshell `RSS < 250 МБ`; Wayle без регрессии; целевой FPS ≥ 55.
- Инъекции ввода у агента нет (нет `ydotool`-сокета, `wlrctl`, доступа к `/dev/uinput`) — нажатия клавиш проверяет пользователь; команды из привязок агент выполняет вручную.
- Один монитор: `eDP-1`, 1920×1080, scale 1. Обои и снимки — всегда под этот размер.
- Тихий сигнал для проверок звука, карточки и эквалайзера: `/tmp/opencode/tone.wav`, громкость потока `3 %` (`pactl set-sink-input-volume <idx> 3%`). Если файла нет — создать командой из Task 10, Step 3. Проверки со звуком всегда заканчиваются остановкой источника и восстановлением выхода по умолчанию.
- **Перед каждой правкой живого конфига — бэкап** в `/tmp/opencode/` (`<имя>.bak-<задача>`). Проверка любой правки Hyprland: `hyprctl reload` + `hyprctl configerrors` (должно быть пусто).
- Коммит после каждой задачи; сообщения — conventional commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`).
- Вне области: тема загрузки и экрана входа, многомониториность, вычисление палитры из обоев (matugen/wallust/pywal не используются), новые виджеты, замена бара.

## Review Focus

Наиболее вероятные «болячки», которые проверки должны пришпилить к своим задачам (спека — документ о намерении, её молчание не разрешает падать):

1. **Маркера в конфиге нет** (файл переписали вручную, маркер затёрли) → `render.py` должен упасть с понятной ошибкой и ничего не записать, а не затереть файл или промолчать (Task 1).
2. **Залипший MPRIS без звука / плеера нет** → карточка не должна оставлять пустую рамку и не должна ломаться от `null`-плеера; поведение «нет звука — нет карточки» сохраняется (Task 13).
3. **Провал плана по FPS на UHD 620** → стекло не должно ставить систему на колени: при недостижении 55 FPS берётся более дешёвый набор, и это фиксируется в отчёте (Task 8).
4. **Wayle не получил шину уведомлений** (её держит mako) → уведомления не должны исчезнуть: `notify-send` доходит до экрана, откат — строка автозапуска (Task 9).
5. **Посторонний цвет или след Tokyo Night возвращается при правке** → `theme/check.sh` ловит и падает (Task 1, Task 5).
6. **OSD не реагирует на яркость из `brightnessctl`** → честно фиксируется результат, а не подразумевается работа (Task 9).

---

## File Structure

```
~/rice/
  theme/
    palette.toml                 # Task 1 — единственный источник цвета
    render.py                    # Task 1 — рендерер (маркеры, --check, --dry-run)
    check.sh                     # Task 1 — сторож дрейфа палитры
    templates/fastfetch.jsonc.in # Task 3 — шаблон fastfetch
  tests/
    test_render.py               # Task 1 (unittest)
    test_check.py                # Task 1
    test_wallpaper.py            # Task 6
  hypr/
    hyprland.lua                 # Task 5 (блок цветов), Task 7 (хоткей), Task 9 (привязки), Task 17
    hyprpaper.conf               # Task 7
    hyprlock.conf                # Task 15
    scripts/gen-wallpaper.py     # Task 6
    scripts/set-wallpaper.sh     # Task 7
  quickshell/widgets/
    Theme.qml                    # Task 4 (блок палитры), Task 11 (геометрия)
    Cards/PlayerCard.qml         # Task 13
    Dock/Dock.qml, Dock/DockItem.qml   # Task 12
    Cava/CavaBar.qml             # Task 14
  install.sh                     # Task 18
  uninstall.sh                   # Task 18
  README.md                      # Task 18
  docs/plans/2026-10-18-unixporn-polish.md   # этот файл
```

Живые конфиги (правятся рендерером или задачей напрямую): `~/.config/kitty/theme.conf`, `~/.config/wofi/style.css`, `~/.config/btop/{btop.conf,themes/catppuccin-mocha.theme}`, `~/.config/cava/config`, `~/.config/starship.toml`, `~/.config/fastfetch/config.jsonc`, `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini`, `~/.config/wayle/config.toml`.

---

### Task 1: Палитра и рендерер

**Files:**
- Create: `theme/palette.toml`, `theme/render.py`, `theme/check.sh`
- Test: `tests/test_render.py`, `tests/test_check.py`

**Interfaces:**
- Produces:
  - `render.load_palette(path: Path) -> Palette` — `Palette` (frozen dataclass) с полями `colors: dict[str, str]` (имя → `#rrggbb`), `fonts: dict[str, str]`, `geometry: dict[str, int]`; ошибка `PaletteError` при неизвестном токене.
  - `render.apply_block(text: str, begin: str, end: str, body: str) -> str` — заменяет всё между строками-маркерами `begin`/`end` (маркеры сохраняются), `MarkerError` если маркер не найден ровно один раз.
  - `render.apply_template(template: str, palette: Palette) -> str` — подстановка `{{ token }}` (имя токена) → цвет/шрифт/число.
  - `render.Target` (dataclass: `path: Path`, `kind: Literal["block","template"]`, `markers: tuple[str,str]`, `body: Callable[[Palette], str]`), `render.TARGETS: list[Target]`.
  - `render.main(argv: list[str]) -> int` — флаги `--dry-run`, `--check`, `--palette PATH`; код возврата 0 при успехе, 1 при ошибке маркеров, 2 при расхождении в `--check`; при ошибке маркеров **ничего не пишется**.
  - `check.sh` — `theme/render.py --check` + поиск посторонних hex и токенов Tokyo Night (`7aa2f7 bb9af7 1a1b26 24283b 1f2335 394b70 565f89 414868 c0caf5 e0af68 f7768e`); выход 1 при находке.

- [ ] **Step 1: Написать падающие тесты**

`tests/test_render.py` (`python3 -m unittest`):

```python
def test_replaces_marked_block():        # маркеры сохраняются, тело заменено
def test_preserves_text_outside_markers(): # текст вне маркеров байт-в-байт
def test_missing_marker_raises():        # MarkerError, файл не тронут
def test_double_marker_raises():         # два блока с одним маркером → MarkerError
def test_idempotent():                   # второй прогон → те же байты
def test_unknown_token_raises():         # PaletteError
def test_template_substitution():        # {{ mauve }} → #cba6f7
def test_check_reports_drift():          # --check на разъехавшемся файле → 2
```
`tests/test_check.py`: на временном файле с `#7aa2f7` → `check.sh` выходит 1; с цветами только из палитры → 0.

- [ ] **Step 2: Убедиться, что тесты падают**

Run: `cd ~/rice && python3 -m unittest discover -s tests -p 'test_*.py' -v`
Expected: FAIL — `ModuleNotFoundError: theme.render` / файла `check.sh` нет.

- [ ] **Step 3: Написать `theme/palette.toml`**

Секции `[palette]` (все токены из Global Constraints), `[fonts]` (`ui = "JetBrains Mono"`, `ui_size = 11`, `mono = "JetBrains Mono"`, `terminal = "CozetteVector"`, `terminal_size = 13`), `[geometry]` (`margin = 16`, `radius = 16`, `dock_height = 68`, `cava_height = 68`, `card_height = 96`, `screen_w = 1920`, `screen_h = 1080`).

- [ ] **Step 4: Реализовать `theme/render.py`**

Функции из блока Interfaces. Подстановка блока — по строкам, поиск `begin`/`end` как подстрок; запись атомарная (временный файл + `os.replace`), чтобы при ошибке не осталось половинчатого файла. `TARGETS` на этом шаге — пустой список (наполняется в Task 2–4).

- [ ] **Step 5: Прогнать тесты**

Run: `cd ~/rice && python3 -m unittest discover -s tests -p 'test_*.py' -v`
Expected: PASS (10 тестов).

- [ ] **Step 6: Написать `theme/check.sh`**

`set -euo pipefail`; сначала `render.py --check`, затем `grep -rIn` по списку живых конфигов и `quickshell/widgets/Theme.qml`; исключения — сам `theme/`, `docs/`, бэкапы `*.bak-*`, `wayle/schema.json`.

- [ ] **Step 7: Убедиться, что чекер ловит токийскую ночь**

Run: `cd ~/rice && ./theme/check.sh; echo "код: $?"`
Expected: код 1, в выводе — `starship.toml` и `fastfetch/config.jsonc` (они ещё не переведены — это Task 3).

- [ ] **Step 8: Коммит**

```bash
git add theme tests/test_render.py tests/test_check.py
git commit -m "feat(theme): палитра как источник и рендерер с маркерами"
```

---

### Task 2: Файлы, которыми рис владеет целиком

**Files:**
- Modify: `theme/render.py` (наполнить `TARGETS`), `~/.config/kitty/kitty.conf` (строка `include`), `~/.config/wofi/style.css`, `~/.config/btop/btop.conf`, `~/.config/cava/config`
- Test: `tests/test_render.py` (дополнить)

**Interfaces:**
- Consumes: `render.apply_block`, `render.Target`, `Palette` из Task 1.
- Produces: цели `kitty-theme` (template, `~/.config/kitty/theme.conf`), `wofi-style` (block, `~/.config/wofi/style.css`, маркеры `/* palette:begin */` / `/* palette:end */`), `btop-conf` (block, ключ `color_theme`), `btop-theme` (template, `~/.config/btop/themes/catppuccin-mocha.theme`), `cava-conf` (block).

- [ ] **Step 1: Добавить падающий тест на полноту целей**

```python
def test_targets_have_unique_paths():   # нет двух целей с одним путём
def test_block_targets_declare_markers():  # kind == "block" → markers заданы
```

- [ ] **Step 2: Прогнать тест, убедиться в падении**

Run: `python3 -m unittest tests.test_render -v` → FAIL (пустой `TARGETS`).

- [ ] **Step 3: Наполнить `TARGETS` и подготовить живые файлы**

a) `kitty.conf` — строка `include theme.conf` **в конце** файла; b) `wofi/style.css` — цвета переписать на маркерный блок; c) `cava/config` — блок `[color]` между маркерами; d) `btop.conf` — `color_theme` + создать `~/.config/btop/themes/`. Перед правкой каждого файла — бэкап в `/tmp/opencode/`.

- [ ] **Step 4: Прогнать рендерер**

Run: `cd ~/rice && python3 theme/render.py --dry-run && python3 theme/render.py`
Expected: список целей, затем запись без ошибок.

- [ ] **Step 5: Проверить видами, а не словами**

- `kitty` — открыть окно терминала, снять `grim`, сверить фон/текст/курсор с палитрой;
- `wofi --show drun` — запустить, снять, закрыть (`pkill -x wofi`);
- `btop` — запустить в kitty, снять схему, выйти;
- `cava` в терминале — запустить на 5 с, увидеть цвет столбиков, закрыть.

Run: `grim -o eDP-1 /tmp/opencode/rice-kitty.png` (и аналогично для остальных)
Expected: в снимках цвета палитры; фон kitty не чёрный и не tokio-night.

- [ ] **Step 6: Прогнать тесты и чекер**

Run: `python3 -m unittest discover -s tests -p 'test_*.py' -v && ./theme/check.sh; echo "код: $?"`
Expected: тесты PASS; чекер всё ещё ругается только на starship/fastfetch (Task 3).

- [ ] **Step 7: Коммит**

```bash
git add theme tests/test_render.py
git commit -m "feat(theme): kitty, wofi, btop и cava получают цвета из палитры"
```

---

### Task 3: starship, fastfetch, GTK и gsettings

**Files:**
- Create: `theme/templates/fastfetch.jsonc.in`
- Modify: `theme/render.py` (+3 цели), `~/.config/starship.toml`, `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini`
- Test: `tests/test_render.py`, `tests/test_check.py`

**Interfaces:**
- Produces: цели `starship-palette` (block, секция `[palettes.mocha]`), `fastfetch` (template, `~/.config/fastfetch/config.jsonc`), `gtk3-settings` / `gtk4-settings` (block), плюс `render.gsettings_commands(palette) -> list[list[str]]` для синхронизации `gsettings` (тема GTK, иконки, курсор, шрифт).

- [ ] **Step 1: Падающий тест на gsettings**

```python
def test_gsettings_commands_cover_theme_icons_cursor_font():  # 4 ключа, значения из палитры
```

- [ ] **Step 2: Прогнать, убедиться в падении** → `FAIL: функции нет`.

- [ ] **Step 3: Реализовать**

a) starship: модули переписать с hex на именованные цвета (`[palettes.mocha]` + `palette = "mocha"`), hex в модулях не остаётся; b) `templates/fastfetch.jsonc.in` — текущий конфиг с цветами через `{{ }}` и логотипом `~/.config/fastfetch/fastfetch.png`; c) GTK `settings.ini` — блок между маркерами; d) `gsettings_commands` возвращает `gsettings set org.gnome.desktop.interface ...` для `gtk-theme`, `icon-theme`, `cursor-theme`, `font-name`; e) `main()` выполняет их, если не `--dry-run`/`--check`.

- [ ] **Step 4: Применить и проверить**

Run: `cd ~/rice && python3 theme/render.py && ./theme/check.sh; echo "код: $?"`
Expected: чекер выходит 0 — посторонних цветов и следов Tokyo Night нет.

Run: `gsettings get org.gnome.desktop.interface gtk-theme` (и `icon-theme`, `cursor-theme`, `font-name`)
Expected: `catppuccin-mocha-mauve-standard+default`, `Papirus-Dark`, `catppuccin-mocha-mauve-cursors`, `JetBrains Mono 11`.

Run: `starship prompt >/dev/null; fastfetch | head -20; nautilus &` + `grim /tmp/opencode/rice-apps.png`
Expected: prompt и fastfetch в палитре, Nautilus — Catppuccin, иконки Papirus, моно-шрифт.

- [ ] **Step 5: Тесты и коммит**

```bash
python3 -m unittest discover -s tests -p 'test_*.py' -v
git add theme tests && git commit -m "feat(theme): starship, fastfetch и GTK-темы из палитры"
```

---

### Task 4: Wayle и Theme.qml получают палитру

**Files:**
- Modify: `theme/render.py` (+2 цели), `~/.config/wayle/config.toml`, `quickshell/widgets/Theme.qml`
- Test: `tests/test_render.py`

**Interfaces:**
- Produces: цели `wayle-config` (block: `[styling.palette]` + `font-sans`/`font-mono`) и `qml-theme` (block: блок `// palette:begin` / `// palette:end` в `Theme.qml` с `readonly property color …`). Имена токенов в QML — как в палитре (`base`, `mantle`, `crust`, `surface0`, `surface1`, `overlay0`, `subtext0`, `text`, `mauve`, `blue`, `red`, `green`, `yellow`, `teal`, `peach`, …).

- [ ] **Step 1: Падающий тест**

```python
def test_qml_block_uses_property_color_syntax():   # каждая строка блока — readonly property color
def test_wayle_block_has_all_palette_keys():       # bg surface elevated fg fg-muted primary red yellow green blue
```

- [ ] **Step 2: Прогнать, убедиться в падении** → FAIL.

- [ ] **Step 3: Реализовать цели и вставить маркеры**

`Theme.qml`: палитра заворачивается в блок маркеров; `wayle/config.toml`: `[styling]` + `[styling.palette]` заворачиваются, `font-sans`/`font-mono` — тоже (в `[general]`). Бэкапы обязательны. В комментариях оставить пометку, что блок рендерится из `theme/palette.toml`.

- [ ] **Step 4: Применить и проверить**

Run: `cd ~/rice && python3 theme/render.py && wayle panel restart && sleep 3 && hyprctl layers | grep -E 'wayle-bar|qs-widgets'`
Expected: бар и три поверхности виджетов живы, цвета не изменились визуально (палитра та же).

Run: `grim -o eDP-1 /tmp/opencode/rice-bar-after-palette.png`
Expected: неотличимо от дореформенного вида (палитра та же, изменился только источник).

- [ ] **Step 5: Коммит**

```bash
git add theme quickshell/widgets/Theme.qml
git commit -m "feat(theme): Wayle и виджеты берут палитру из общего источника"
```

---

### Task 5: Палитра в hyprland.lua

**Files:**
- Modify: `theme/render.py` (+1 цель), `~/.config/hypr/hyprland.lua`, `hypr/hyprland.lua`
- Test: `tests/test_render.py`

**Interfaces:**
- Produces: цель `hyprland-palette` (block в начале файла: `local pal = { mauve = "#cba6f7", … }` + `local col = function(hex, a) … end`); остальной конфиг ссылается на `pal.*` для границ и тени.

- [ ] **Step 1: Добавить падающий тест**

```python
def test_lua_block_is_valid_local_table():  # содержит "local pal = {" и закрывающую "}"
def test_lua_has_no_raw_hex_outside_block(): # ни одного #rrggbb вне блока маркеров
```

- [ ] **Step 2: Прогнать, убедиться в падении** → FAIL.

- [ ] **Step 3: Реализовать**

Бэкап `hyprland.lua` → вставить блок маркеров с `pal` в начало → заменить хексы границ (`active_border`, `inactive_border`), тени и цвета слоёв на `pal.mauve`, `pal.blue` и т.д. → синхронизировать копию в репозитории.

- [ ] **Step 4: Проверить синтаксис и живой конфиг**

Run: `luajit -bl ~/.config/hypr/hyprland.lua >/dev/null && hyprctl reload && hyprctl configerrors`
Expected: синтаксис ок, `configerrors` пуст.

Run: `grim -o eDP-1 /tmp/opencode/rice-border.png` (с открытым окном)
Expected: градиент границ mauve→blue на месте.

- [ ] **Step 5: Чекер и тесты**

Run: `cd ~/rice && ./theme/check.sh && python3 -m unittest discover -s tests -p 'test_*.py' -v`
Expected: 0 и PASS.

- [ ] **Step 6: Коммит**

```bash
git add theme hypr/hyprland.lua && git commit -m "feat(theme): цвета композитора из палитры"
```

---

### Task 6: Генератор обоев

**Files:**
- Modify: `hypr/scripts/gen-wallpaper.py` (переписать)
- Test: `tests/test_wallpaper.py`

**Interfaces:**
- Produces: `gen-wallpaper.render(variant: str, seed: int, size: tuple[int,int], lock: bool) -> numpy.ndarray` (H×W×3, `uint8`) и `gen-wallpaper.main(argv)` с флагами `--variant mauve|blue|teal|rose|mix`, `--seed N`, `--size WxH`, `--out PATH`, `--lock`. Слои: база, пятна, аврора, структура, зерно, виньетка. Для `--lock` — та же картинка, затемнённая и обесцвеченная на 35 %, зерно на месте.

- [ ] **Step 1: Падающие тесты**

```python
def test_seed_determinism():       # одинаковый seed → одинаковый sha256
def test_variants_differ():        # mix и teal → разные хеши
def test_size_is_exact():          # shape == (1080, 1920, 3)
def test_bottom_band_has_structure():  # std яркости в y 880:1080 ≥ 0.6 × std в y 400:600
def test_lock_is_darker():         # средняя яркость lock < средней яркости стола
def test_no_banding_on_flat_area():    # локальный градиент без ступеней: число уникальных значений в фрагменте > 64
```

- [ ] **Step 2: Прогнать, убедиться в падении** → FAIL (`ImportError`).

- [ ] **Step 3: Реализовать слои**

Каждый слой — отдельная функция (`_base`, `_blooms`, `_aurora`, `_structure`, `_grain`, `_vignette`), композиция — в `render`. Пятна и аврора — по сидовому генератору (`numpy.random.default_rng(seed)`). Структура — многооктавный шум (3 октавы) с амплитудой ±3–4 % яркости. Зерно — ±2 %. Виньетка — радиальное затемнение + усиление затемнения в нижней полосе.

- [ ] **Step 4: Прогнать тесты** → PASS.

- [ ] **Step 5: Сгенерировать варианты и посмотреть глазами**

Run: `python3 hypr/scripts/gen-wallpaper.py --variant mix --out /tmp/opencode/wp-mix.png --lock && …` для `mauve`, `blue`, `teal`, `rose`
Expected: 5 файлов + lock-варианты; открыть каждый и убедиться, что структура видна по всей площади, низ не пустой.

- [ ] **Step 6: Применить выбранный вариант**

Run: `hyprctl hyprpaper reload ,/tmp/opencode/wp-mix.png` затем `grim -o eDP-1 /tmp/opencode/rice-wp.png`
Expected: обои сменились, низ под виджетами структурный.

- [ ] **Step 7: Коммит**

```bash
git add hypr/scripts/gen-wallpaper.py tests/test_wallpaper.py
git commit -m "feat(wallpaper): слоистый генератор обоев под стекло"
```

---

### Task 7: Обои в системе (hyprpaper, локскрин, хоткей)

**Files:**
- Create: `hypr/scripts/set-wallpaper.sh`
- Modify: `hypr/hyprpaper.conf`, `~/.config/hypr/hyprpaper.conf`, `~/.config/hypr/hyprlock.conf`, `~/.config/hypr/hyprland.lua`, `hypr/hyprland.lua`

**Interfaces:**
- Consumes: `gen-wallpaper.py` из Task 6.
- Produces: `set-wallpaper.sh [next|set <variant>|lock]` — генерирует вариант в `~/Pictures/Wallpapers/catppuccin-<variant>.png`, тёмный вариант в `…-lock.png`, перезагружает hyprpaper (`hyprctl hyprpaper reload ,<path>`), подставляет путь в `hyprlock.conf`, сохраняет выбор в `~/.cache/rice/wallpaper`. Хоткей `SUPER + SHIFT + W` → `set-wallpaper.sh next`.

- [ ] **Step 1: Написать скрипт и синхронизировать конфиги**

Тёмный вариант считается один раз при смене обоев (не на каждый запуск локскрина).
`[wallpaper] engine-enabled = false` в Wayle остаётся: обоями владеет hyprpaper, два движка спорить не должны.

- [ ] **Step 2: Проверить переключение**

Run: `hypr/scripts/set-wallpaper.sh next && hyprctl hyprpaper listloaded && grep -m1 path ~/.config/hypr/hyprlock.conf`
Expected: загружен новый файл; в `hyprlock.conf` — путь `…-lock.png`.

Run: `hypr/scripts/set-wallpaper.sh next && grim -o eDP-1 /tmp/opencode/rice-wp-2.png`
Expected: картинка сменилась, виджеты читаются на новом фоне.

- [ ] **Step 3: Проверить хоткей и конфиг**

Run: `hyprctl binds | grep -i 'SHIFT, W' && hyprctl reload && hyprctl configerrors`
Expected: привязка есть, ошибок нет.

- [ ] **Step 4: Коммит**

```bash
git add hypr/scripts/set-wallpaper.sh hypr/hyprpaper.conf hypr/hyprland.lua
git commit -m "feat(wallpaper): смена обоев скриптом и хоткеем, локскрин на том же кадре"
```

---

### Task 8: Стекло замером

**Files:**
- Modify: `~/.config/hypr/hyprland.lua`, `hypr/hyprland.lua`

**Interfaces:**
- Consumes: обои из Task 7.

- [ ] **Step 1: Включить оверлей FPS и поставить нагрузку**

Run: `hyprctl keyword debug:overlay true; hyprctl dispatch exec "[workspace 9] kitty --class fpsprobe -e cava"; sleep 4; hyprctl dispatch workspace 9; hyprctl dispatch fullscreen 1; hyprctl clients -j | jq -r '.[] | select(.class=="fpsprobe") | .address'`
Expected: окно-нагрузка открыто на воркспейсе 9 во весь экран, адрес записан, в углу видно счётчик FPS.

- [ ] **Step 2: Снять текущий набор (4/1)**

Run: 5× `grim -o eDP-1 /tmp/opencode/fps-4-1-<n>.png` с интервалом 2 с
Expected: прочитать FPS на снимках, записать в таблицу отчёта.

- [ ] **Step 3: Прогнать наборы 6/2 и 8/3**

Run: `hyprctl keyword decoration:blur:size 6; hyprctl keyword decoration:blur:passes 2; …` затем те же снимки
Expected: таблица «набор → FPS» из трёх строк.

- [ ] **Step 4: Выбрать набор и закрепить в конфиге**

Правило: самый «стеклянный» набор с FPS ≥ 55. Если 6/2 не держит — взять 4/2 + `vibrancy 0.12`, записать это в отчёт как результат. Внести набор в `hyprland.lua` (`decoration.blur`), включить блюр бара:

```lua
hl.layer_rule({ match = { namespace = "wayle-bar.*" }, blur = true, ignore_alpha = 0.25 })
```

и `background-opacity = 78` в `~/.config/wayle/config.toml`.

- [ ] **Step 5: Проверить вид и метрику структуры обоев**

Run: `hyprctl reload && hyprctl configerrors && grim -o eDP-1 /tmp/opencode/rice-glass.png`
Expected: `configerrors` пусто; на снимке бар и виджеты читаются, стекло видно; метрика структуры обоев из Task 6 — в отчёте.

- [ ] **Step 6: Выключить оверлей и закрыть нагрузку**

Run: `hyprctl keyword debug:overlay false; ADDR=$(hyprctl clients -j | jq -r '.[] | select(.class=="fpsprobe") | .address'); hyprctl dispatch closewindow address:$ADDR; sleep 1; hyprctl clients -j | jq '[.[] | select(.class=="fpsprobe")] | length'`
Expected: `0` — закрыто именно окно-нагрузка; чужие окна kitty не тронуты (проверить `hyprctl clients -j | jq '[.[] | select(.class=="kitty")] | length'` до и после).

- [ ] **Step 7: Коммит**

```bash
git add hypr/hyprland.lua && git commit -m "feat(glass): блюр и тени по замеру FPS"
```

---

### Task 9: Уведомления и OSD внутри Wayle

**Files:**
- Modify: `~/.config/wayle/config.toml` (через `theme/render.py` — блок палитры уже есть; новые секции правятся руками), `~/.config/hypr/hyprland.lua`, `hypr/hyprland.lua`

**Interfaces:**
- Produces: модуль `notifications` в правой группе бара, `[osd] enabled = true`, блок-лист Telegram; `mako` и `swayosd-server` убраны из автозапуска (строки сохранены в комментарии рядом для отката). Точные namespace слоёв Wayle для уведомлений и OSD фиксируются здесь и вносятся в `hl.layer_rule` (blueprint: `wayle-notifications`, `wayle-osd` — уточнить по `hyprctl layers` в момент показа).

- [ ] **Step 1: Настроить Wayle**

В `[bar.layout]` правая группа получает `notifications`; `[modules.notifications]` — `popup-position = "top-right"`, `popup-duration = 5000`, `popup-margin-x = 8`, `popup-margin-y = 8`, `popup-shadow = true`, `popup-urgency-bar = "low"`, `blocklist = ["*Telegram*"]`; `[osd] enabled = true`, `position = "bottom"`, `margin = 150`, `border = true`; в `[modules.hyprland-workspaces]` — `app-icons-show = true`, `app-icons-dedupe = true` (иконки приложений в воркспейсах; если на скриншоте (Step 5) выглядит шумно — вернуть `false` и записать решение в отчёт).

- [ ] **Step 2: Остановить mako и swayosd, убрать из автозапуска**

Run: `systemctl --user stop mako 2>/dev/null; pkill -x mako; pkill -x swayosd-server; wayle panel restart; sleep 2; busctl --user list | grep -i Notifications`
Expected: владелец `org.freedesktop.Notifications` — процесс Wayle.

- [ ] **Step 3: Проверить уведомления**

Run: `notify-send "Проверка" "Обычное уведомление"; notify-send -u critical "Критическое" "Должно держаться"; grim -o eDP-1 /tmp/opencode/rice-notify.png`
Expected: на снимке попап Wayle в палитре и стекле; критические не улетают через 5 с.

Run: `wayle notify status && wayle notify list && wayle notify dnd`
Expected: DND включается/выключается, список живёт.

- [ ] **Step 4: Проверить блок-лист и OSD**

Run: `notify-send -a "Telegram Desktop" "Спам" "не должно быть видно"` + `grim` → попапа нет (или он в истории, но не на экране).
Run: `wayle audio output-volume +5 && grim -o eDP-1 /tmp/opencode/rice-osd.png`
Expected: OSD появляется в палитре; если OSD есть только у Wayle-команд — зафиксировать это в отчёте.
Run: `brightnessctl set 5%+` → есть ли OSD (результат — обязательно в отчёт, положительный или отрицательный).

- [ ] **Step 5: Зафиксировать namespace слоёв**

Run: `hyprctl layers | grep -i wayle` (в момент показа уведомления и OSD)
Expected: имена namespace записаны в отчёт и добавлены `hl.layer_rule` с `blur = true` для непрозрачных оверлеев (если требуется).

- [ ] **Step 6: Конфиг и коммит**

Run: `hyprctl reload && hyprctl configerrors`
```bash
git add hypr/hyprland.lua && git commit -m "feat(wayle): уведомления и OSD внутри бара, mako и swayosd выведены"
```

---

### Task 10: Медиа-клавиши на Wayle

**Files:**
- Modify: `~/.config/hypr/hyprland.lua`, `hypr/hyprland.lua`

**Interfaces:**
- Consumes: команды Wayle из Task 9.

- [ ] **Step 1: Заменить привязки**

Громкость, mute выхода и микрофона — `wayle audio …`; яркость — `brightnessctl`; next/prev/play-pause — `wayle media …`; строки `swayosd-client` и `playerctl` закомментированы рядом с пометкой об откате.

- [ ] **Step 2: Проверить команды вручную**

Run: `hyprctl binds | grep -E 'XF86Audio|XF86MonBrightness'` → привязки на месте.
Run: `wayle audio output-volume +5 && wayle audio output-volume -5 && wayle audio output-mute && wayle audio output-mute && brightnessctl set 5%+ && brightnessctl set 5%-`
Expected: громкость растёт/падает, mute переключается, яркость меняется; OSD (если он у Wayle) показывается.

- [ ] **Step 3: Проверить медиа-команды**

Run: `[ -f /tmp/opencode/tone.wav ] || python3 -c "import wave,struct,math;w=wave.open('/tmp/opencode/tone.wav','w');w.setnchannels(1);w.setsampwidth(2);w.setframerate(44100);w.writeframes(b''.join(struct.pack('<h',int(2000*math.sin(2*math.pi*220*t/44100))) for t in range(44100*30)));w.close()"`
Run: `setsid vlc -I dummy --loop --no-video --no-one-instance /tmp/opencode/tone.wav >/dev/null 2>&1 & sleep 6; pactl set-sink-input-volume "$(pactl -f json list sink-inputs | jq -r '.[0].index')" 3%`, затем `wayle media list`, `wayle media play-pause`, `wayle media next`
Expected: состояние плеера меняется; после проверки — `pkill -x vlc` (по имени процесса, не по шаблону строки).

- [ ] **Step 4: Конфиг и коммит**

```bash
hyprctl reload && hyprctl configerrors   # пусто
git add hypr/hyprland.lua && git commit -m "feat(wayle): медиа-клавиши через wayle audio и media"
```

---

### Task 11: Сцена виджетов — одна линия и одно стекло

**Files:**
- Modify: `quickshell/widgets/Theme.qml`, `quickshell/widgets/shell.qml`, `Dock/Dock.qml`, `Cava/CavaBar.qml`, `Cards/PlayerCard.qml`

**Interfaces:**
- Consumes: блок палитры в `Theme.qml` (Task 4).
- Produces: токены `glass` (значение `rgba(24,24,37,0.62)` → QML `#9e181825`, было `#a6181825`), `glassEdge` (`#33cdd6f4`, было `#2ecdd6f4`), `margin = 16`, `radius = 16`, высоты `dockHeight = 68`, `cavaHeight = 68`, `cardHeight = 96`; позиции в `shell.qml`: карточка `(16, 1080 − 16 − 96)`, док `((1920 − w) / 2, 1080 − 16 − 68)`, эквалайзер `(1920 − 16 − w, 1080 − 16 − 68)`. Имена существующих токенов не меняются — меняются значения и добавляются высоты.

- [ ] **Step 1: Внести токены и геометрию**

Высоты виджетов берутся из `Theme`, а не из литералов; стекло всех трёх — из `Theme.glassBg`/`Theme.glassEdge`.

- [ ] **Step 2: Перезапустить виджеты и снять факт**

Run: `systemctl --user restart quickshell-widgets.service && sleep 4 && hyprctl layers | grep qs-widgets`
Expected: три поверхности; X и Y совпадают с расчётом (карточка `16 …`, низ у всех `y + h = 1064`), эквалайзер `68` высотой.

- [ ] **Step 3: Проверить вид**

Run: временно поднять тихий звук (`vlc` 3 %) и снять `grim -o eDP-1 /tmp/opencode/rice-scene.png`; после — закрыть VLC.
Expected: низ всех трёх на одной линии, стекло одинаковое.

- [ ] **Step 4: Коммит**

```bash
git add quickshell/widgets && git commit -m "feat(widgets): единое стекло и общая линия низа"
```

---

### Task 12: Жизнь в доке

**Files:**
- Modify: `Dock/Dock.qml`, `Dock/DockItem.qml`

**Interfaces:**
- Produces: у `DockItem` — свойство `running: bool` (из `Hyprland.toplevels` по классу), подъём иконки под курсором (масштаб до 1.12, смещение 2 px, `Behavior` 120 мс), точка-индикатор снизу (`Theme.mauve` при `running`), подпись-подсказка над иконкой; иконки из темы `Papirus-Dark`.

- [ ] **Step 1: Реализовать состояние и анимацию**

Клик по запущенному приложению — подъём окна прежним способом (`hl.get_window("address:0x…")` + `hl.dsp.focus`), клик по незапущенному — запуск `Process` с argv.

- [ ] **Step 2: Проверить факты**

Run: `systemctl --user restart quickshell-widgets.service && sleep 4 && hyprctl layers | grep qs-widgets` (поверхность дока на месте, размер не изменился на скрытой геометрии).
Run: `logger -t qsdiag "…"`/`journalctl` для проверки соответствия «класс окна → running» при открытом kitty — открыть и закрыть kitty, увидеть изменение состояния в логе.
Expected: точка появляется/исчезает.

- [ ] **Step 3: Коммит**

```bash
git add quickshell/widgets/Dock && git commit -m "feat(dock): подъём под курсором и индикатор запущенного"
```

---

### Task 13: Жизнь в карточке плеера

**Files:**
- Modify: `Cards/PlayerCard.qml`, `shell.qml`

**Interfaces:**
- Consumes: логику выбора плеера в `shell.qml` (`pickPlayer`, `isSounding`).
- Produces: появление/уход карточки анимацией (прозрачность 0→1 и смещение по Y 8 px, 180 мс), клик по обложке — подъём окна играющего плеера тем же способом, что в доке (Task 12), аккуратная заглушка обложки.

- [ ] **Step 1: Реализовать анимацию и клик**

Анимация — на корневом элементе карточки, через `states`/`Behavior` и `opacity`/`y`; при отсутствии плеера карточка по-прежнему не создаётся (поведение сохраняется).

- [ ] **Step 2: Проверить оба конца**

Run: тихий сигнал `vlc` 3 % → `hyprctl layers | grep qs-widgets | wc -l` → 3 поверхности; закрыть VLC → снова 2.
Expected: появление и уход плавные (проверить снимками подряд), пустой рамки нет.
Run: `hyprctl configerrors` (виджеты не при чём) и `journalctl --user -u quickshell-widgets.service --since '-2min' | grep -i error`
Expected: пусто.

- [ ] **Step 3: Коммит**

```bash
git add quickshell/widgets && git commit -m "feat(player): появление карточки анимацией и подъём плеера по клику"
```

---

### Task 14: Жизнь в эквалайзере

**Files:**
- Modify: `Cava/CavaBar.qml`

**Interfaces:**
- Produces: плавная интерполяция высот (сглаживание между кадрами, `Behavior`/`SmoothedAnimation` 90 мс), градиент столбиков `mauve → blue`, приглушённая базовая линия в тишине (`Theme.surface0` вместо пустоты).

- [ ] **Step 1: Реализовать визуал**

- [ ] **Step 2: Проверить на живом звуке**

Run: тихий сигнал `vlc` 3 % → 5 снимков `grim` подряд → убедиться, что столбики меняются и не рвутся; закрыть VLC → базовая линия приглушена.
Expected: движение плавное, цвета из палитры.

- [ ] **Step 3: Коммит**

```bash
git add quickshell/widgets/Cava && git commit -m "feat(cava): градиент и плавная интерполяция"
```

---

### Task 15: Локскрин на том же кадре

**Files:**
- Modify: `~/.config/hypr/hyprlock.conf`, `hypr/hyprlock.conf`

**Interfaces:**
- Consumes: `…-lock.png` из Task 7.

- [ ] **Step 1: Переписать композицию**

Фон — тёмный вариант обоев, `blur_passes = 2`, `blur_size = 6`, `vibrancy` из палитры; время, дата, приветствие, поле ввода с акцентом `mauve`, радиус 16.

- [ ] **Step 2: Проверить снимком**

Run: `hyprlock --grace 0 & sleep 3; grim -o eDP-1 /tmp/opencode/rice-lock.png; pkill -x hyprlock`
Expected: снимок содержит фон, время и поле ввода в палитре. Если снимок не получился из-за блокировки — попросить пользователя заблокировать экран (`SUPER+L`) и снять в этот момент, записав это в отчёт.

- [ ] **Step 3: Коммит**

```bash
git add hypr/hyprlock.conf && git commit -m "feat(lock): локскрин на кадре стола и в общей палитре"
```

---

### Task 16: Лаунчер в общее стекло

**Files:**
- Modify: `~/.config/wofi/style.css`

- [ ] **Step 1: Довести стиль**

Скругление 16, размытая подложка (правило слоя `wofi` уже есть), фокус-подсветка акцентом, иконки `Papirus-Dark`, моно-шрифт, размеры строк/отступы под бар.

- [ ] **Step 2: Проверить**

Run: `wofi --show drun & sleep 2; grim -o eDP-1 /tmp/opencode/rice-launcher.png; pkill -x wofi`
Expected: окно в палитре и стекле; иконки на месте; Esc и клик вне закрывают.

- [ ] **Step 3: Коммит**

```bash
git add -A && git commit -m "feat(wofi): лаунчер в общем стекле и палитре"
```

---

### Task 17: Анимации и отступы

**Files:**
- Modify: `~/.config/hypr/hyprland.lua`, `hypr/hyprland.lua`

- [ ] **Step 1: Вылизать анимации и геометрию**

Кривые и скорости по листьям (`global`, `border`, `windows`, `windowsIn/Out`, `fade`, `layers`, `workspaces`) — в одном ритме с анимациями виджетов (120–200 мс); отступы `gaps_in = 6`, `gaps_out = 14`, `border_size = 2`, `rounding = 12` — проверить на maximized-окне, что окна не заезжают под бар.

- [ ] **Step 2: Проверить**

Run: `luajit -bl ~/.config/hypr/hyprland.lua >/dev/null && hyprctl reload && hyprctl configerrors`
Expected: пусто.
Run: открыть maximized-окно, `grim -o eDP-1 /tmp/opencode/rice-gaps.png`
Expected: окно не перекрывает бар, отступы ровные, градиент границы виден.

- [ ] **Step 3: Коммит**

```bash
git add hypr/hyprland.lua && git commit -m "feat(hyprland): единый ритм анимаций и отступов"
```

---

### Task 18: Упаковка и воспроизводимость

**Files:**
- Modify: `install.sh`, `uninstall.sh`, `README.md`

**Interfaces:**
- Consumes: всё предыдущее.
- Produces: `install.sh` раскладывает `theme/` → запускает `render.py`, генерирует обои, ставит сервис виджетов, синхронизирует `hypr`-конфиги; флаг `--dry-run` печатает действия без записи. `uninstall.sh` возвращает mako/swayosd, снимает блюр бара, останавливает сервис, восстанавливает старые конфиги из бэкапов.

- [ ] **Step 1: Написать/дополнить оба скрипта с `--dry-run`**

- [ ] **Step 2: Проверить синтаксис и холостой прогон**

Run: `bash -n install.sh && bash -n uninstall.sh && ./install.sh --dry-run | tee /tmp/opencode/install-dry.txt`
Expected: код 0, в выводе есть пункты про палитру, обои, сервис, gsettings; ни один файл не изменён (`git status --short` до и после — одинаковый).

- [ ] **Step 3: Обновить README**

Что это, как поставить, как откатить, как сменить обои/вариант, где источник палитры, что проверяет `check.sh`.

- [ ] **Step 4: Коммит**

```bash
git add install.sh uninstall.sh README.md && git commit -m "chore: установка и откат полировки с нуля"
```

---

### Task 19: Финальная приёмка

**Files:**
- Modify: `docs/plans/2026-10-18-unixporn-polish.md` (отметки), README (скриншоты)

- [ ] **Step 1: Прогнать весь список приёмки спеки §12.2**

Каждая строка — с фактом: скриншот или вывод команды.

- [ ] **Step 2: Собрать пачку скриншотов**

Run: `mkdir -p /tmp/opencode/rice-preview && …` (пустой стол со всеми тремя виджетами при тихом звуке, бар, лаунчер, уведомление с OSD, локскрин, GTK-приложение, терминал с fastfetch)
Expected: 7 файлов, показать пользователю.

- [ ] **Step 3: Замеры и гигиена**

Run: `ps -o rss= -C quickshell | awk '{s+=$1} END {print s/1024 " МБ"}'` → < 250 МБ.
Run: `cd ~/rice && ./theme/check.sh && python3 -m unittest discover -s tests -p 'test_*.py'`
Expected: 0 и PASS.
Run: `systemctl --user is-active quickshell-widgets.service; pgrep -x mako; pgrep -x swayosd-server`
Expected: служба active, старых демонов нет (если они вернулись — вернуть вывод в отчёт).

- [ ] **Step 4: Откат-проверка**

Run: `./uninstall.sh --dry-run` → список возвратов; затем вручную проверить «одну строку»: вернуть `hl.exec_cmd("mako")` + привязки `swayosd-client` в копии конфига и `hyprctl configerrors` — чисто (живой конфиг не трогать).
Expected: откат описан и работоспособен.

- [ ] **Step 5: Финальный коммит и отчёт**

```bash
git add -A && git commit -m "chore: финальная приёмка полировки"
```

Отчёт пользователю: таблица FPS, список скриншотов, честные оговорки (что проверить не удалось: нажатия клавиш, реакция OSD на яркость — по факту).
