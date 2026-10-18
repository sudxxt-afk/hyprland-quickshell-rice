# Quickshell-rice — план реализации

> **Для агентов-исполнителей:** ОБЯЗАТЕЛЬНЫЙ СУБ-НАВЫК: используйте `executing-plans` для реализации плана по задачам. Шаги отмечены чекбоксами (`- [ ]`).

**Цель:** заменить waybar единым шеллом Quickshell — бар, плавающие стеклянные карточки (часы, системный монитор, плеер), док и 6 выпадающих панелей в стиле Catppuccin Mocha.

**Архитектура:** один процесс Quickshell 0.3.2 (Qt6/QML). Конфиг `~/.config/quickshell/rice/` (симлинк на `~/rice/quickshell/rice`). Единый источник визуальных значений — синглтон `Theme`. Все оверлеи управляются единственной точкой `PopupHost` (PopupWindow + HyprlandFocusGrab). Системные данные — из родных сервисов Quickshell (Mpris, Pipewire, UPower, Bluetooth, Networking, Hyprland, SystemTray); CPU/RAM/температура — из `/proc` и `/sys` через FileView.

**Стек:** Fedora 44, Hyprland 0.56.2, Quickshell 0.3.2 (COPR `nett00n/hyprland`), Qt6 QML, Node 22 (только для юнит-тестов парсеров), brightnessctl.

**Спека:** `docs/specs/2026-10-18-quickshell-rice-design.md` — план аргументирует от неё, исполнителю нужно читать обе.

## Global Constraints

- Стиль: Catppuccin Mocha. Точные цвета **только** из `Theme.qml` (§11 спеки). Никаких литеральных хексов в компонентах.
- Палитра (verbatim): `base #1e1e2e`, `mantle #181825`, `crust #11111b`, `text #cdd6f4`, `subtext #a6adc8`, `overlay #6c7086`, `mauve #cba6f7`, `blue #89b4fa`, `red #f38ba8`, `green #a6e3a1`, `yellow #f9e2af`, `teal #94e2d5`, `peach #fab387`, `sky #89dceb`, `lavender #b4befe`, `surface0 #313244`, `surface1 #45475a`.
- Геометрия (verbatim): бар высота `36`, отступ сверху `8`, по бокам `12`, радиус `14`; карточки отступ `16`, радиус `16`; панели радиус `16`, ширина `360`, зазор от бара `8`; док высота `56`, радиус `28`; радиус элементов `9`.
- Шрифт: `JetBrainsMono Nerd Font` (иконки — Nerd Font-глифы из него же). Базовый размер `13`, крупные часы `34`.
- Поверхности: бар `rgba(24,24,37,0.62)`, карточка `rgba(24,24,37,0.62)`, док `rgba(24,24,37,0.62)`, панель `rgba(17,17,27,0.92)`.
- Namespace слоёв: бар `qs-bar`, карточки `qs-card`, док `qs-dock`, панели `qs-popup`.
- **Blur в Hyprland включён только для `qs-popup`.** Остальные — `blur = false`.
- Бюджет: процесс(ы) Quickshell суммарно **< 250 МБ RSS**. Таймеров с интервалом < 1 с нет (исключение — график CPU, 1 с).
- Один монитор: `eDP-1`, 1920×1080, scale 1.
- Backlight: `/sys/class/backlight/intel_backlight/brightness`, `/sys/class/backlight/intel_backlight/max_brightness` (=24242). Установка — `brightnessctl`.
- Температура: `/sys/class/thermal/thermal_zone0/temp`, значение в миллиградусах (50000 = 50 °C).
- Приложения дока: `kitty`, `chromium-browser`, `nautilus`, `code`.
- Запуск конфига: `qs -c rice`. Config discovery: `~/.config/quickshell/rice/shell.qml`.
- `graphical-session.target` в этой сессии **неактивен** — сервис стартует явно из `hyprland.lua`.
- Вне области: mako, hyprlock, hypridle, swayosd, wofi, hyprpaper, погода, заметки.
- Коммит после каждой задачи; сообщения — conventional commits (`feat:`, `test:`, `docs:`, `chore:`).

## Review Focus

Наиболее вероятные «болячки», которые тесты-команды должны пришпилить к своим задачам (спека — документ о намерении, её молчание не разрешает падать):

1. **Нет активного MPRIS-плеера** → `PlayerCard` не должна оставлять пустую рамку или ссылаться на null-плеер (Task 16).
2. **`Pipewire.nodes` пуст на старте** (`Pipewire.ready == false`) → панель громкости не должна падать с null (Task 8).
3. **Пакет без батареи / UPower-устройство не инициализировано** → модуль батареи не должен показывать `NaN%` (Task 6, Task 12).
4. **Длинные строки** (заголовок окна, название трека, SSID) → обрезка, а не выход за границы и не переносом ломающий геометрию бара (Task 4, Task 16).
5. **Wi-Fi с сохранённой сетью без пароля / с неверным паролем** → корректный путь `NoSecrets` → ввод пароля → `connectWithPsk` (Task 9).
6. **Клик по модулю у края экрана** → панель не должна уезжать за пределы монитора (Task 7).
7. **`Atom.abs`/clamp при отсутствии файла** `/sys/class/thermal/thermal_zone0/temp` → показывать отсутствие, а не 0 °C (Task 3).

---

## File Structure

```
~/rice/
  README.md                      # обновляется в Task 19
  install.sh                     # Task 1
  uninstall.sh                   # Task 1
  .gitignore                     # уже есть
  tests/parse.test.js            # Task 2 (node --test)
  quickshell/rice/
    shell.qml                    # Task 1 — ShellRoot, собирает всё
    Theme.qml                    # Task 1 — singleton: палитра, геометрия, шрифты
    Bar/Bar.qml                  # Task 1 — PanelWindow qs-bar
    Bar/Workspaces.qml           # Task 4
    Bar/Title.qml                # Task 4
    Bar/Clock.qml                # Task 5
    Bar/Language.qml             # Task 5
    Bar/Tray.qml                 # Task 6
    Bar/Stats.qml                # Task 3
    Bar/Volume.qml               # Task 6 (+клик в Task 8)
    Bar/Brightness.qml           # Task 6
    Bar/Network.qml              # Task 6 (+клик в Task 9)
    Bar/Bluetooth.qml            # Task 6 (+клик в Task 10)
    Bar/Battery.qml              # Task 6 (+клик в Task 12)
    Bar/Power.qml                # Task 1? нет — Task 6 (+клик в Task 7)
    lib/parse.js                 # Task 2 — чистые парсеры (.pragma library)
    lib/Proc.qml                 # Task 3 — singleton: cpu/mem/temp + история
    lib/Sparkline.qml            # Task 12 — Canvas-график
    lib/Format.qml               # Task 5 — форматирование времени/дат
    lib/Icons.qml                # Task 6 — имена иконок Nerd Font
    Panels/PopupHost.qml         # Task 7 — singleton: open/toggle/close
    Panels/PopupShell.qml        # Task 7 — общий визуал панели (рамка, фон, радиус)
    Panels/PowerPanel.qml        # Task 7
    Panels/VolumePanel.qml       # Task 8
    Panels/WifiPanel.qml         # Task 9
    Panels/BluetoothPanel.qml    # Task 10
    Panels/CalendarPanel.qml     # Task 11
    Panels/BatteryPanel.qml      # Task 12
    Cards/ClockCard.qml          # Task 14
    Cards/SysMonCard.qml         # Task 15
    Cards/PlayerCard.qml         # Task 16
    Dock/Dock.qml                # Task 17
  hypr/hyprland.lua              # Task 1 (автозапуск) + Task 18 (layer rules)
  hypr/scripts/qs-session.sh     # Task 1
  systemd/quickshell.service     # Task 1
```

Разделение по ответственности: `Bar/` — индикаторы и клики в баре; `Panels/` — содержимое оверлеев; `Cards/` — плавающие карточки; `Dock/` — док; `lib/` — переиспользуемое и системные данные.

### Общие интерфейсы (используются всеми задачами)

`Theme` (singleton, корень `rice/`, доступен из соседних файлов по имени; файлы в подпапках импортируют `import qs`):

```
// цвета
property color base, mantle, crust, text, subtext, overlay,
               mauve, blue, red, green, yellow, teal, peach, sky, lavender,
               surface0, surface1
// поверхности
property color barBg, cardBg, dockBg, panelBg
// геометрия
property int barHeight: 36
property int barMarginTop: 8
property int barMarginSide: 12
property int barRadius: 14
property int cardMargin: 16
property int cardRadius: 16
property int panelRadius: 16
property int panelWidth: 360
property int panelGap: 8
property int dockHeight: 56
property int dockRadius: 28
property int itemRadius: 9
// типографика
property string fontFamily: "JetBrainsMono Nerd Font"
property int fontSize: 13
property int clockSize: 34
// namespace'ы
property string nsBar: "qs-bar"
property string nsCard: "qs-card"
property string nsDock: "qs-dock"
property string nsPopup: "qs-popup"
```

`PopupHost` (singleton, `Panels/PopupHost.qml`):

```
property string current: ""          // "" — ничего не открыто
property real lastX: 0               // центр последнего клика по модулю (координаты окна бара)
property real clockX: 0              // центр модуля часов в баре; задаёт Bar.qml
property var barWindow: null         // окно бара; задаёт Bar.qml при старте
signal opened(name: string)
function open(name: string): void
function toggle(name: string, x: real): void   // x — центр модуля в координатах окна бара
function close(): void
// имена: "volume" | "wifi" | "bluetooth" | "calendar" | "battery" | "power"
```

`Proc` (singleton, `lib/Proc.qml`):

```
readonly property real cpuPercent      // 0..100
readonly property real memPercent      // 0..100
readonly property real tempC           // -1 если файла нет
readonly property var  cpuHistory      // 60 значений, старые первыми
readonly property var  memHistory      // 60 значений
```

`parse.js` (экспортируемые имена, `.pragma library`, без `module.exports`):

```
parseProcStat(text: string) -> { idle: number, total: number } | null
cpuPercent(prev, cur) -> number
parseMeminfo(text: string) -> { totalKb: number, availableKb: number } | null
memPercent(info) -> number
parseTemp(milliCelsius: string) -> number   // -1 при ошибке
formatDuration(seconds: number) -> string   // "4h 12m" | "12m" | "45s"
```

`Sparkline` (`lib/Sparkline.qml`):

```
property var   values: []          // числа 0..maxValue
property color lineColor
property color fillColor
property real  maxValue: 100
property real  lineWidth: 1.5
```

---

# Этап 1 — фундамент и бар

### Task 1: Установка, каркас, пустой бар, автозапуск

**Files:**
- Create: `quickshell/rice/Theme.qml`, `quickshell/rice/shell.qml`, `quickshell/rice/Bar/Bar.qml`, `systemd/quickshell.service`, `hypr/scripts/qs-session.sh`, `install.sh`, `uninstall.sh`
- Modify: `hypr/hyprland.lua` (автозапуск, хоткей `SUPER+W`)

**Interfaces:**
- Consumes: нет
- Produces: `Theme` с полным набором токенов (см. «Общие интерфейсы»); `Bar.qml` как `PanelWindow`; `qs -c rice` как команда запуска; `quickshell.service`; `hypr/scripts/qs-session.sh`.

- [ ] **Шаг 0: Зафиксировать baseline live-конфигов в репозитории**

Репозиторий должен быть источником правды, иначе правки Task 1 пойдут в пустоту:

```bash
mkdir -p ~/rice/hypr
cp ~/.config/hypr/hyprland.lua ~/.config/hypr/hypridle.conf \
   ~/.config/hypr/hyprlock.conf ~/.config/hypr/hyprpaper.conf ~/rice/hypr/
mkdir -p ~/rice/hypr/scripts
cp ~/.config/hypr/scripts/*.py ~/rice/hypr/scripts/ 2>/dev/null || true
```
Бэкапы `*.bak-*` не копировать — они уже в `.gitignore`. Проверить `git status`: должны появиться только сами конфиги, без бэкапов.

- [ ] **Шаг 1: Установить пакет и зафиксировать факты о нём**

```bash
sudo dnf install -y quickshell
rpm -ql quickshell | grep -E 'bin/'
quickshell --version 2>/dev/null || qs --version
```
Ожидаемо: версия вида `0.3.2`. Записать фактическое имя бинарника (`qs` или `quickshell`) — от него зависят `ExecStart` и скрипты. Если пакет не ставится, остановиться и доложить.

- [ ] **Шаг 2: Создать `Theme.qml` со всеми токенами**

`pragma Singleton`, корневой тип `Singleton` (см. спеку, §5 и «Общие интерфейсы»). Все значения — verbatim из Global Constraints. Никакой логики.

- [ ] **Шаг 3: Создать минимальный `shell.qml` с пустым баром**

`ShellRoot`, внутри — `Bar {}`. Без `Variants` пока (один экран), но с комментарием, где он появится при нескольких мониторах.

- [ ] **Шаг 4: Создать `Bar/Bar.qml`**

`PanelWindow`, `anchors { top: true; left: true; right: true }`, `implicitHeight: Theme.barHeight`, `margins { top: Theme.barMarginTop; left: Theme.barMarginSide; right: Theme.barMarginSide }`, `color: "transparent"`, `WlrLayershell.namespace: Theme.nsBar`, `WlrLayershell.layer: WlrLayer.Top`. Внутри — прямоугольник `Rectangle` с `color: Theme.barBg`, `radius: Theme.barRadius`, `anchors.fill: parent`. `exclusiveZone: Theme.barHeight + Theme.barMarginTop` — верхняя полоса экрана резервируется, окна под бар не заезжают.

- [ ] **Шаг 5: Проверить, что шелл запускается и бар виден**

```bash
qs -c rice &
sleep 2
hyprctl layers | grep -A3 qs-bar
```
Ожидаемо: в `hyprctl layers` есть слой с namespace `qs-bar`; на экране — полупрозрачная полоса сверху с радиусом. Убедиться заодно, что `import qs` в `Bar/Bar.qml` даёт доступ к `Theme` (это и есть проверка связки синглтона и подпапки). Если `Theme` не видно — исправить импорт здесь, а не в следующих задачах.

Обязательно проверить резервирование места (риск из §15 спеки):

```bash
hyprctl dispatch exec "kitty" ; sleep 2 ; hyprctl dispatch fullscreen 0
hyprctl clients | grep -E 'at: 0,0|size:'
```
Ожидаемо: окно разворачивается **ниже** бара, заголовок окна не спрятан под бар. Если спрятан — увеличить `exclusiveZone` и повторить.

- [ ] **Шаг 6: Создать systemd unit и скрипт запуска сессии**

`systemd/quickshell.service` — ровно как в спеке §12, `ExecStart` с фактическим именем бинарника из Шага 1, `Restart=on-failure`, `RestartSec=1`, `Slice=session.slice`, `WantedBy=graphical-session.target`.

`hypr/scripts/qs-session.sh`:

```sh
#!/usr/bin/env sh
set -eu
systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
systemctl --user start quickshell.service
```
`chmod +x`.

- [ ] **Шаг 7: Прописать автозапуск и заменить хоткей в `hyprland.lua`**

- Сделать бэкап: `cp ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.bak-$(date +%Y%m%d-%H%M%S)`.
- В `hl.on("hyprland.start", ...)`: убрать строку `hl.exec_cmd("waybar")`, добавить `hl.exec_cmd("$HOME/.config/hypr/scripts/qs-session.sh")` (не `~` — тильда в `exec_cmd` может не раскрыться).
- Хоткей `SUPER+W` (`pkill -SIGUSR1 waybar`) заменить на `systemctl --user restart quickshell.service`.
- Waybar **не удалять** из системы и конфиги не трогать.

- [ ] **Шаг 8: Создать `install.sh` и `uninstall.sh`**

`install.sh`: ставит пакет при отсутствии; создаёт симлинк `~/.config/quickshell` → `~/rice/quickshell` (если путь занят — остановиться и доложить, ничего не перезаписывать); копирует `hypr/*` в `~/.config/hypr` с бэкапом; ставит unit, `systemctl --user daemon-reload`; убирает `waybar` из автозапуска; `hyprctl reload`.
`uninstall.sh`: `systemctl --user stop quickshell.service`; возвращает `hl.exec_cmd("waybar")` вместо строки с `qs-session.sh`; `hyprctl reload`; печатает инструкцию вернуть вручную, если замены не нашлось.
Оба — `chmod +x`, идемпотентные (повторный запуск не ломает).

- [ ] **Шаг 9: Проверить автозапуск и откат**

```bash
systemctl --user status quickshell.service --no-pager | head -5
journalctl --user -u quickshell.service -n 20 --no-pager
pkill -f 'qs -c rice' ; sleep 3 ; systemctl --user is-active quickshell.service
```
Ожидаемо: сервис `active (running)`; после убийства процесса — снова `active` (сработал `Restart=on-failure`). Затем `./uninstall.sh` → бар waybar вернулся; `./install.sh` → снова Quickshell.

- [ ] **Шаг 10: Коммит**

```bash
git add -A && git commit -m "feat: каркас шелла, тема и автозапуск Quickshell вместо waybar"
```

---

### Task 2: Чистые парсеры `lib/parse.js` + юнит-тесты (TDD)

**Files:**
- Create: `quickshell/rice/lib/parse.js`, `tests/parse.test.js`

**Interfaces:**
- Consumes: нет
- Produces: `parseProcStat`, `cpuPercent`, `parseMeminfo`, `memPercent`, `parseTemp`, `formatDuration` (точные сигнатуры — в «Общих интерфейсах»)

- [ ] **Шаг 1: Написать падающий тест**

`tests/parse.test.js`, запуск через `node --test`. Загрузка модуля — через чтение файла и `new Function`, потому что `parse.js` написан в QML-стиле (обычные объявления функций, `.pragma library`) и **не** использует `module.exports`:

```js
const { test } = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const src = fs.readFileSync(path.join(__dirname, "../quickshell/rice/lib/parse.js"), "utf8");
const api = new Function(
  src + "\nreturn { parseProcStat, cpuPercent, parseMeminfo, memPercent, parseTemp, formatDuration };"
)();

const PROC = "cpu  100 0 50 800 20 0 5 0 0 0\ncpu0 1 2 3 4 5 6 7 8 9 10\n";
const MEM = "MemTotal:       7900000 kB\nMemFree:        1000000 kB\nMemAvailable:   3200000 kB\n";

test("parseProcStat суммирует поля первой строки", () => {
  assert.deepStrictEqual(api.parseProcStat(PROC), { idle: 820, total: 975 });
});
test("parseProcStat на мусоре возвращает null", () => {
  assert.strictEqual(api.parseProcStat("not a proc stat"), null);
});
test("cpuPercent считает прирост загрузки", () => {
  const a = { idle: 100, total: 200 };
  const b = { idle: 150, total: 300 };
  assert.strictEqual(api.cpuPercent(a, b), 50);
});
test("cpuPercent не делится на ноль", () => {
  const a = { idle: 1, total: 1 };
  assert.strictEqual(api.cpuPercent(a, a), 0);
});
test("parseMeminfo читает total и available", () => {
  assert.deepStrictEqual(api.parseMeminfo(MEM), { totalKb: 7900000, availableKb: 3200000 });
});
test("memPercent считает процент занятого", () => {
  assert.strictEqual(api.memPercent({ totalKb: 1000, availableKb: 250 }), 75);
});
test("parseTemp переводит миллиградусы в градусы", () => {
  assert.strictEqual(api.parseTemp("50000"), 50);
});
test("parseTemp на мусоре возвращает -1", () => {
  assert.strictEqual(api.parseTemp(""), -1);
  assert.strictEqual(api.parseTemp("abc"), -1);
});
test("formatDuration форматирует часы, минуты, секунды", () => {
  assert.strictEqual(api.formatDuration(15120), "4h 12m");
  assert.strictEqual(api.formatDuration(720), "12m");
  assert.strictEqual(api.formatDuration(45), "45s");
  assert.strictEqual(api.formatDuration(0), "0s");
});
```

- [ ] **Шаг 2: Запустить тест и убедиться, что падает**

Run: `node --test tests/`
Ожидаемо: FAIL — файл `parse.js` не найден.

- [ ] **Шаг 3: Реализовать `lib/parse.js`**

Начать файл с `.pragma library`. Только объявления функций, без экспортов. Правила:
- `parseProcStat`: первая строка, начинающаяся с `cpu ` (с пробелом, чтобы не поймать `cpu0`); поля — user, nice, system, idle, iowait, irq, softirq, steal; `idle = idle + iowait`; `total` — сумма этих восьми полей (**guest и guest_nice не включать** — они уже посчитаны в user); нераспознанное → `null`.
- `cpuPercent(prev, cur)`: `deltaTotal <= 0` → `0`; иначе `100 * (deltaTotal - deltaIdle) / deltaTotal`, результат зажать в `0..100`.
- `parseMeminfo`: строки `MemTotal:` и `MemAvailable:`, числа в kB.
- `memPercent`: `totalKb <= 0` → `0`; иначе округлить `100 * (1 - available/total)`.
- `parseTemp`: `parseFloat`, не конечное число → `-1`, иначе `/1000`.
- `formatDuration`: `< 60` → `"Ns"`; `< 3600` → `"Nm"`; иначе `"Nh Nm"`. Отрицательные и `NaN` → `"0s"`.

- [ ] **Шаг 4: Запустить тест и убедиться, что проходит**

Run: `node --test tests/`
Ожидаемо: PASS, 9 тестов.

- [ ] **Шаг 5: Коммит**

```bash
git add tests/parse.test.js quickshell/rice/lib/parse.js
git commit -m "feat: парсеры /proc и /sys с юнит-тестами"
```

---

### Task 3: `Proc` + модуль бара «Статистика»

**Files:**
- Create: `quickshell/rice/lib/Proc.qml`, `quickshell/rice/Bar/Stats.qml`
- Modify: `quickshell/rice/Bar/Bar.qml`

**Interfaces:**
- Consumes: `parse.js` (Task 2), `Theme` (Task 1)
- Produces: `Proc` singleton (`cpuPercent`, `memPercent`, `tempC`, `cpuHistory`, `memHistory`); компонент `Stats` — иконки CPU/RAM с процентами, клик → `kitty -e btop`

- [ ] **Шаг 1: Реализовать `lib/Proc.qml`**

`pragma Singleton` + `Singleton`. Внутри `import "parse.js" as Parse`.
- `FileView` на `/proc/stat` (`watchChanges: false`), `FileView` на `/proc/meminfo`, `FileView` на `/sys/class/thermal/thermal_zone0/temp`.
- `Timer` 1000 мс: перечитать `/proc/stat`, посчитать `cpuPercent` от предыдущего снимка, обновить `cpuPercent`, сдвинуть историю на 60 значений.
- `Timer` 5000 мс: `meminfo` → `memPercent`, история 60 значений (сдвиг раз в 5 с).
- `tempC`: из файла температуры; файла нет/ошибка → `-1`.
- Первый снимок `/proc/stat` — только запомнить baseline, `cpuPercent` в первый тик не менять (иначе первый замер — мусор).

- [ ] **Шаг 2: Реализовать `Bar/Stats.qml`**

Две `Text`-иконки (Nerd Font) + проценты: CPU — цвет `Theme.teal`, RAM — `Theme.mauve`. `tempC > 0` → третья метка с `°` и цветом `Theme.peach`; иначе скрыта (`visible: Proc.tempC > 0`). `MouseArea` → `kitty -e btop` через `Quickshell.Io.Process` (`command: ["kitty", "-e", "btop"]`).

- [ ] **Шаг 3: Подключить `Stats` в `Bar.qml`**

В правой группе, первым элементом.

- [ ] **Шаг 4: Проверить, что данные живые и правдивые**

```bash
qs -c rice &
sleep 3
# сравнить с системой
top -bn1 | grep -m1 '%Cpu'
free -m | awk '/Mem:/{printf "%.0f%%\n", $3/$2*100}'
cat /sys/class/thermal/thermal_zone0/temp
```
Ожидаемо: цифры в баре меняются, отклонение от `top`/`free` — в пределах нескольких процентов (разные окна усреднения). Температура совпадает с `thermal_zone0/1000`.

- [ ] **Шаг 5: Проверить устойчивость (Review Focus 7)**

Временно подменить путь температуры на несуществующий (`/sys/class/thermal/thermal_zone99/temp`), перезапустить шелл, убедиться: метка температуры скрыта, в логе нет ошибок, CPU/RAM продолжают работать. Вернуть путь обратно.

- [ ] **Шаг 6: Коммит**

```bash
git add -A && git commit -m "feat: модуль статистики в баре на данных /proc и /sys"
```

---

### Task 4: Бар — воркспейсы и заголовок окна

**Files:**
- Create: `quickshell/rice/Bar/Workspaces.qml`, `quickshell/rice/Bar/Title.qml`
- Modify: `quickshell/rice/Bar/Bar.qml`

**Interfaces:**
- Consumes: `Theme`, `Quickshell.Hyprland`
- Produces: `Workspaces` (1–5, persistent, клик переключает), `Title` (обрезка 48 символов)

- [ ] **Шаг 1: `Bar/Workspaces.qml`**

Источник — `Hyprland.workspaces` и `Hyprland.monitorFor(screen).activeWorkspace`. Всегда показаны воркспейсы 1–5 (persistent, как в waybar): модель — список чисел `[1,2,3,4,5]`, состояние — сравнение с id активного воркспейса. Стиль: активный — фон `Theme.mauve`, текст `Theme.crust`; обычный — текст `Theme.overlay`; hover — фон `Theme.surface0`, текст `Theme.text`; радиус `Theme.itemRadius`; `padding 0 9`, `margin 0 2`. Клик → `Hyprland.dispatch("workspace " + id)`.

- [ ] **Шаг 2: `Bar/Title.qml`**

`Hyprland.activeToplevel?.title ?? ""`. Обрезка до 48 символов с многоточием на уровне данных (не полагаться на `elide`, чтобы ширина бара не зависела от длины заголовка). Цвет `Theme.subtext`.

- [ ] **Шаг 3: Подключить в бар (левая группа)**

`Bar.qml`: слева `Workspaces`, затем `Title`.

- [ ] **Шаг 4: Проверить переключение и обрезку (Review Focus 4)**

```bash
hyprctl dispatch workspace 3
qs ipc prop get 2>/dev/null || true   # не обязательно
```
Действия: переключить воркспейсы кликом и хоткеем `SUPER+3` — подсветка следует. Открыть окно с очень длинным заголовком (например, `kitty -T "$(head -c 300 /etc/services)"`). Ожидаемо: заголовок обрезан, бар не меняет ширину, другие модули не сдвигаются.

- [ ] **Шаг 5: Коммит**

```bash
git add -A && git commit -m "feat: воркспейсы и заголовок окна в баре"
```

---

### Task 5: Бар — часы и раскладка

**Files:**
- Create: `quickshell/rice/Bar/Clock.qml`, `quickshell/rice/Bar/Language.qml`, `quickshell/rice/lib/Format.qml`
- Modify: `quickshell/rice/Bar/Bar.qml`

**Interfaces:**
- Consumes: `Theme`
- Produces: `Format` singleton (`timeHM(date)`, `dateShort(date)`, `monthGrid(year, month)` — используется и календарём в Task 11); `Clock`; `Language`

- [ ] **Шаг 1: `lib/Format.qml`**

`pragma Singleton` + `Singleton`. Функции: `timeHM(date) -> "HH:MM"`, `dateShort(date) -> "dd.MM.yy"`, `weekdayFull(date) -> "суббота"`, `monthGrid(year, month) -> list` из 6×7 чисел (день месяца или `0` для пустой клетки, неделя с понедельника). Локаль — системная.

- [ ] **Шаг 2: `Bar/Clock.qml`**

Часы: `HH:MM` цветом `Theme.text` + дата `dd.MM.yy` цветом `Theme.overlay`. Обновление — `Timer` раз в минуту (не раз в секунду: экономим). Клик — заглушка `PopupHost.toggle("calendar", x)`, раскомментируется в Task 11? **Нет** — клик добавляется в Task 11.

- [ ] **Шаг 3: `Bar/Language.qml`**

`Process` с `hyprctl -j devices`, `Timer` 1500 мс. Разобрать JSON, взять `keyboards` → первое устройство с `main: true` → `active_keymap` (или `layout`), показать первые 2 буквы верхним регистром. `RU` — цвет `Theme.red`, `EN` — `Theme.blue`, иначе `Theme.subtext`. Тултипа нет.

- [ ] **Шаг 4: Подключить в центр бара**

`Bar.qml`: центр — `Language`, затем `Clock`.

- [ ] **Шаг 5: Проверить часы и раскладку (Review Focus: не ронять бар)**

Действия: нажать `Alt+Shift` несколько раз. Ожидаемо: индикатор меняется `RU` ↔ `EN` в пределах ~1.5 с. Часы показывают текущее время, совпадают с `date +%H:%M`.

- [ ] **Шаг 6: Коммит**

```bash
git add -A && git commit -m "feat: часы и индикатор раскладки в баре"
```

---

### Task 6: Бар — трей, громкость, яркость, сеть, Bluetooth, батарея, питание

**Files:**
- Create: `Bar/Tray.qml`, `Bar/Volume.qml`, `Bar/Brightness.qml`, `Bar/Network.qml`, `Bar/Bluetooth.qml`, `Bar/Battery.qml`, `Bar/Power.qml`, `lib/Icons.qml`
- Modify: `Bar/Bar.qml`

**Interfaces:**
- Consumes: `Theme`, `Format` (Task 5)
- Produces: `Icons` singleton с именами глифов; модули правой группы. Клики по Volume/Network/Bluetooth/Battery/Power в этой задаче **не реализуются** — их добавляют Task 7–12.

- [ ] **Шаг 1: `lib/Icons.qml`**

`pragma Singleton`. Строковые константы Nerd Font: `volumeHigh`, `volumeMedium`, `volumeLow`, `volumeMuted`, `brightness`, `wifi`, `wifiOff`, `ethernet`, `bluetoothOn`, `bluetoothConnected`, `bluetoothOff`, `batteryCharging`, `battery` (список по уровням), `power`, `cpu`, `ram`, `temperature`, `prev`, `play`, `pause`, `next`, `lock`, `suspend`, `logout`, `reboot`, `shutdown`. Подобрать реальные глифы из `JetBrainsMono Nerd Font`, проверив отрисовку.

- [ ] **Шаг 2: `Bar/Tray.qml`**

`SystemTray.items` (ObjectModel). Иконка из `item.icon`, клик — `item.activate()`, правый клик — меню, если поддерживается. `icon-size 15`, `spacing 8`.

- [ ] **Шаг 3: `Bar/Volume.qml`**

`Pipewire.defaultAudioSink.audio` (с `PwObjectTracker`, иначе запись не работает). Иконка зависит от уровня/`muted`; процент цветом `Theme.blue`. Скролл ±5% меняет `volume`. `visible` — только если sink существует; `Pipewire.ready == false` → показать нейтральную иконку без процента.

- [ ] **Шаг 4: `Bar/Brightness.qml`**

`FileView` на `/sys/class/backlight/intel_backlight/brightness` и `max_brightness` (`watchChanges: true`). Процент цветом `Theme.yellow`. Скролл — `brightnessctl set 5%+` / `5%-` через `Process`.

- [ ] **Шаг 5: `Bar/Network.qml`**

`Networking.devices`: состояние `wifi`/`ethernet`/`disconnected`/`disabled`. Цвет `Theme.sky` при подключении, `Theme.overlay` при отключении.

- [ ] **Шаг 6: `Bar/Bluetooth.qml`**

`Bluetooth.defaultAdapter`: выключен → `Theme.overlay`; включён → `Theme.lavender`; есть подключённые устройства — показать их количество.

- [ ] **Шаг 7: `Bar/Battery.qml`**

`UPower.displayDevice`: `percentage` округлить до целого, иконка по уровню, при зарядке — иконка зарядки. **Батареи нет** или `percentage` не инициализирован (`isNaN`) → модуль скрыт целиком (Review Focus 3). Пороговые цвета: `< 25%` — `Theme.yellow`, `< 12%` — `Theme.red`.

- [ ] **Шаг 8: `Bar/Power.qml`**

Иконка `Icons.power` цветом `Theme.red`, `visible` всегда.

- [ ] **Шаг 9: Подключить правую группу в `Bar.qml`**

Порядок: `Tray`, `Stats`, `Volume`, `Brightness`, `Network`, `Bluetooth`, `Battery`, `Power`.

- [ ] **Шаг 10: Проверить все индикаторы**

```bash
brightnessctl set 40% ; brightnessctl set 80%   # за модулем следит яркость
bluetoothctl power off ; sleep 3 ; bluetoothctl power on
nmcli radio wifi off ; sleep 3 ; nmcli radio wifi on   # кратко роняет сеть, обратимо
```
Замечание: `nmcli radio wifi off` на 3 секунды разрывает соединение — для проверки это нормально, но не запускай строку во время длинной загрузки.
Ожидаемо: яркость, сеть и Bluetooth реагируют на изменения без перезапуска шелла. Значок трея отображает запущенные (`nm-applet`, `blueman-applet`). Проверить ложное срабатывание Review Focus 3: если батареи нет — модуль отсутствует, а не показывает `NaN%` (на этой машине батарея есть, так что проверить условие `isNaN`/`ready` инспекцией кода).

- [ ] **Шаг 11: Коммит**

```bash
git add -A && git commit -m "feat: правая группа модулей бара"
```

---

### Task 7: `PopupHost` и панель питания

**Files:**
- Create: `Panels/PopupHost.qml`, `Panels/PopupShell.qml`, `Panels/PowerPanel.qml`
- Modify: `shell.qml`, `Bar/Power.qml`, `Bar/Bar.qml`

**Interfaces:**
- Consumes: `Theme`, `Icons`
- Produces: `PopupHost` singleton c `current`/`opened`/`open(name)`/`toggle(name, x)`/`close()`; `PopupShell` — обёртка панели с сигнатурой `property string name`, `default property alias content`, слоты `anchors` наружу; имя панели `"power"`.

- [ ] **Шаг 1: `Panels/PopupHost.qml`**

`pragma Singleton` + `Singleton`. Реализовать контракт из «Общих интерфейсов». `toggle(name, x)` — если `current == name`, закрыть; иначе открыть и запомнить `lastX` (для центрирования под модулем). `close()` — и никаких исключений при `current == ""`.

- [ ] **Шаг 2: `Panels/PopupShell.qml`**

`PopupWindow` со `anchor.window: barWindow`, `anchor.rect.x` = clamp(`PopupHost.lastX - width/2`, 0, ширина бара − ширина), `anchor.rect.y: Theme.barHeight + Theme.barMarginTop + Theme.panelGap`, `width: Theme.panelWidth`, `visible: PopupHost.current === name`, `grabFocus: true`, `WlrLayershell.namespace: Theme.nsPopup`, `color: "transparent"`. Внутри — `Rectangle` с `Theme.panelBg`, `radius: Theme.panelRadius`, `padding`, и `HyprlandFocusGrab` для закрытия по клику вне (не полагаться только на `grabFocus`, тогда `visible` не сбросится).
`barWindow` передаётся свойством; `Bar.qml` отдаёт свой `id` всем панелям через `PopupHost` (сохранить окно бара в `PopupHost.barWindow` при старте бара).

- [ ] **Шаг 3: `Panels/PowerPanel.qml`**

`PopupShell { name: "power" }`. Список строк-кнопок: `Icons.lock` «Заблокировать» → `hyprlock`; `Icons.suspend` «Спящий режим» → `systemctl suspend`; `Icons.logout` «Выйти» → `loginctl terminate-session $XDG_SESSION_ID`; `Icons.reboot` «Перезагрузка» → `systemctl reboot`; `Icons.shutdown` «Выключить» → `systemctl poweroff`. Все — через `Quickshell.Io.Process` с явными аргументами, без `sh -c`. Наведение — фон `Theme.surface0`; «Выключить» — текст `Theme.red`.

- [ ] **Шаг 4: Подключить панель и клик**

`shell.qml`: добавить `PowerPanel {}`. `Bar/Power.qml`: `MouseArea` → `PopupHost.toggle("power", <центр модуля по x>)`. Координату брать как `mapToItem(null, width/2, 0).x` относительно окна бара.

- [ ] **Шаг 5: Проверить механику панели (Review Focus 6)**

Действия и ожидания:
- клик по 󰐥 → панель появилась под модулем; `hyprctl layers | grep qs-popup` показывает `qs-popup`;
- `Esc` → закрылась;
- клик в любом другом месте экрана → закрылась;
- повторный клик по модулю → закрылась;
- панель не выходит за левый/правый край экрана (проверить кликом по крайним модулям правой группы).

- [ ] **Шаг 6: Коммит**

```bash
git add -A && git commit -m "feat: PopupHost и панель управления питанием"
```

---

### Task 8: Панель громкости и микшер

**Files:**
- Create: `Panels/VolumePanel.qml`
- Modify: `shell.qml`, `Bar/Volume.qml`

**Interfaces:**
- Consumes: `PopupHost`, `PopupShell`, `Theme`, `Icons`
- Produces: панель `"volume"`

- [ ] **Шаг 1: `Panels/VolumePanel.qml` — выход**

`PopupShell { name: "volume" }`. Слайдер 0..100 для `Pipewire.defaultAudioSink.audio.volume` (запись в `.volume` в диапазоне `0..1`), кнопка mute (`audio.muted`), процент рядом. `PwObjectTracker` с `objects: [Pipewire.defaultAudioSink]`, иначе запись не сработает.

- [ ] **Шаг 2: Список потоков приложений**

Второй `PwObjectTracker` на `Pipewire.nodes` (фильтр: `nodeType == Stream` и узел имеет `audio`). Для каждого — имя (`node.name`/`properties["application.name"]`), свой слайдер и mute. `Repeater` + `ScriptModel` (чтобы не пересоздавать делегаты на каждое изменение) — или, если проще и стабильно, `Repeater` с `model: Pipewire.nodes`.

- [ ] **Шаг 3: Подключить клик в `Bar/Volume.qml`**

`MouseArea` → `PopupHost.toggle("volume", центр)`. Левый клик — панель, скролл остаётся громкостью.

- [ ] **Шаг 4: Проверить микшер (Review Focus 2)**

```bash
qs -c rice &   # перезапустить
# сразу после старта открыть панель громкости в первые секунды
```
Действия и ожидания:
- панель открывается даже если `Pipewire.ready` ещё `false` — не падает, показывает только регулятор выхода;
- играть музыку (`mpv --no-video <файл>` или браузер) → поток появляется в списке;
- слайдер выхода меняет громкость (проверить `wpctl get-volume @DEFAULT_AUDIO_SINK@`);
- mute из панели глушит звук;
- слайдер потока меняет громкость только этого приложения (`wpctl status` / pavucontrol для сверки).

- [ ] **Шаг 5: Коммит**

```bash
git add -A && git commit -m "feat: панель громкости с микшером потоков"
```

---

### Task 9: Панель Wi-Fi

**Files:**
- Create: `Panels/WifiPanel.qml`
- Modify: `shell.qml`, `Bar/Network.qml`

**Interfaces:**
- Consumes: `PopupHost`, `PopupShell`, `Theme`, `Icons`, `Quickshell.Networking`
- Produces: панель `"wifi"`

- [ ] **Шаг 1: Текущее подключение и тумблер**

`PopupShell { name: "wifi" }`. Сверху — имя активной сети или «Нет подключения»; `Switch` на `Networking.wifiEnabled`.

- [ ] **Шаг 2: Список сетей**

Источник — `WifiDevice.networks` (достать устройство типа Wifi из `Networking.devices`), `scannerEnabled: true`, пока панель открыта. Для каждой сети: SSID, `signalStrength` в процентах, значок замка при `security != Open`. Сортировка по силе сигнала.

- [ ] **Шаг 3: Подключение и ввод пароля (Review Focus 5)**

Клик по сети: если уже подключена — `disconnect()`; иначе `connect()`. Обработать `connectionFailed` с причиной `NoSecrets`: показать поле ввода пароля, по подтверждению — `connectWithPsk(psk)`. При неверном пароле показать состояние ошибки и дать повторить.

- [ ] **Шаг 4: Подключить клик в `Bar/Network.qml`**

`MouseArea` → `PopupHost.toggle("wifi", центр)`.

- [ ] **Шаг 5: Проверить**

Действия: открыть панель — список сетей заполняется в течение нескольких секунд (сканирование). Подключиться к сети с паролем (или проверить на сохранённой). Отключить Wi-Fi тумблером — список пустеет, бар показывает отключённое состояние. Включить обратно.

- [ ] **Шаг 6: Коммит**

```bash
git add -A && git commit -m "feat: панель Wi-Fi на нативном Networking"
```

---

### Task 10: Панель Bluetooth

**Files:**
- Create: `Panels/BluetoothPanel.qml`
- Modify: `shell.qml`, `Bar/Bluetooth.qml`

**Interfaces:**
- Consumes: `PopupHost`, `PopupShell`, `Theme`, `Icons`, `Quickshell.Bluetooth`
- Produces: панель `"bluetooth"`

- [ ] **Шаг 1: Тумблер адаптера и раздел «Подключено»**

`PopupShell { name: "bluetooth" }`. `Switch` на `defaultAdapter.enabled`. Секция подключённых устройств: имя, при `batteryAvailable` — `battery * 100`%, кнопка «Отключить» → `disconnect()`.

- [ ] **Шаг 2: Спаренные и доступные**

Секция «Спаренные»: `paired && !connected` → «Подключить» (`connect()`), «Забыть» (`forget()`) в контекстном меню. Секция «Доступные» (`!paired`): «Сопрячь» → `pair()`. Устройства брать из `Bluetooth.devices`, отфильтровать по `adapter`.

- [ ] **Шаг 3: Подключить клик в `Bar/Bluetooth.qml`**

`MouseArea` → `PopupHost.toggle("bluetooth", центр)`.

- [ ] **Шаг 4: Проверить**

```bash
bluetoothctl scan on &   # или через кнопку в GUI blueman
```
Ожидаемо: устройства появляются в «Доступных»; повторное открытие панели показывает актуальные состояния; отключение адаптера тумблером убирает списки.

- [ ] **Шаг 5: Коммит**

```bash
git add -A && git commit -m "feat: панель Bluetooth"
```

---

### Task 11: Панель календаря

**Files:**
- Create: `Panels/CalendarPanel.qml`
- Modify: `shell.qml`, `Bar/Clock.qml`

**Interfaces:**
- Consumes: `PopupHost`, `PopupShell`, `Theme`, `Format` (`monthGrid`, `weekdayFull`)
- Produces: панель `"calendar"`

- [ ] **Шаг 1: Сетка месяца**

`PopupShell { name: "calendar" }`. Заголовок «Месяц Год» + кнопки `‹` `›` (сдвиг месяца, не выходя за разумные границы). Сетка 7×6: строка заголовков `Пн Вт Ср Чт Пт Сб Вс`, затем дни из `Format.monthGrid(year, month)`. «Сегодня» — фон `Theme.mauve`, текст `Theme.crust`, radius `Theme.itemRadius`. Пустые клетки — невидимы.

- [ ] **Шаг 2: Подключить клик в `Bar/Clock.qml` и клик по карточке (готовится)**

`MouseArea` в `Bar/Clock.qml` → `PopupHost.toggle("calendar", x)`. Здесь же бар сообщает `PopupHost` позицию модуля часов (она нужна карточке из Task 14): `PopupHost.clockX = mapToItem(null, width / 2, 0).x`, обновлять на `onXChanged` и `onWidthChanged`. Панель одна на два входа — клик по часам бара и клик по карточке часов.

- [ ] **Шаг 3: Проверить**

Действия: клик по часам → календарь текущего месяца, сегодня подсвечен. `‹`/`›` листают месяцы. Переход с декабря на январь и обратно меняет год корректно. Даты совпадают с `cal`.

- [ ] **Шаг 4: Коммит**

```bash
git add -A && git commit -m "feat: панель календаря"
```

---

### Task 12: `Sparkline` и панель батареи

**Files:**
- Create: `lib/Sparkline.qml`, `Panels/BatteryPanel.qml`
- Modify: `shell.qml`, `Bar/Battery.qml`

**Interfaces:**
- Consumes: `PopupHost`, `PopupShell`, `Theme`, `Icons`, `parse.js` (`formatDuration`), `Quickshell.Services.UPower`
- Produces: `Sparkline` (пропсы из «Общих интерфейсов»; переиспользуется в Task 15); панель `"battery"`

- [ ] **Шаг 1: `lib/Sparkline.qml`**

`Canvas` с `onPaint`: ломаная по `values`, нормированная на `maxValue` (не на максимум списка — иначе график «дышит»), плюс полупрозрачная заливка под линией. `onValuesChanged` → `requestPaint()`. Один элемент на 60 точек — без анимаций.

- [ ] **Шаг 2: `Panels/BatteryPanel.qml` — сводка**

`PopupShell { name: "battery" }` (в файле `import "../lib/parse.js" as Parse`). Крупный процент, состояние (заряжается/разряжается/полная), время до пустой (`timeToEmpty`) или до полной (`timeToFull`) через `Parse.formatDuration`, мощность `changeRate` в ваттах одним знаком после запятой.

- [ ] **Шаг 3: График заряда за сессию**

`Timer` 60 с пишет `displayDevice.percentage` в историю (максимум 120 точек). `Sparkline` с `maxValue: 100`, `lineColor: Theme.green`, `fillColor` — тот же с прозрачностью `0.15`. При отсутствии батареи — вместо графика текст «Батарея не обнаружена».

- [ ] **Шаг 4: Подключить клик в `Bar/Battery.qml`**

`MouseArea` → `PopupHost.toggle("battery", центр)`. Учесть Review Focus 3: если батареи нет, модуль скрыт и клика нет.

- [ ] **Шаг 5: Проверить**

Действия: открыть панель — процент совпадает с баром; «заряжается» при подключении зарядки, время до полной меняется; `changeRate` сопоставить с `upower -i $(upower -e | grep BAT)`. График заполняется (проверить через несколько минут; на старте — одна точка).

- [ ] **Шаг 6: Коммит**

```bash
git add -A && git commit -m "feat: Sparkline и панель батареи"
```

---

### Task 13: Контрольная точка этапа 1 — бюджет ресурсов и откат

**Files:**
- Modify: `README.md` (раздел «Статус»)

**Interfaces:**
- Consumes: всё из Task 1–12
- Produces: зафиксированный замер памяти и подтверждённый откат

- [ ] **Шаг 1: Замерить память**

```bash
systemctl --user restart quickshell.service ; sleep 5
ps -o rss=,comm= -C qs 2>/dev/null || ps -o rss=,comm= -C quickshell
# суммарно по всем процессам шелла:
ps -o rss= -C qs 2>/dev/null | awk '{s+=$1} END {print s" KB"}'
```
Ожидаемо: сумма RSS процесса(ов) Quickshell **< 250000 KB**. Если больше — сначала отключить `Blur` у `qs-popup` (проверить вклад), затем снять sparkline-графики с истории. Записать фактическое число в отчёт.

- [ ] **Шаг 2: Проверить правила слоёв и blur**

```bash
hyprctl layers | grep -E 'qs-(bar|popup)'
```
Ожидаемо: на этом этапе есть `qs-bar` и `qs-popup`. Правил `layer_rule` для них ещё **нет**, поэтому blur не применяется ни к одному слою — и это правильно: правило для `qs-popup` добавляется в Task 18. Если `qs-bar` оказался размытым без правила — разобраться, откуда blur, до продолжения.

- [ ] **Шаг 3: Откат-дрель**

```bash
./uninstall.sh
hyprctl reload ; sleep 2
ps -C waybar >/dev/null && echo "waybar вернулся"
./install.sh
```
Ожидаемо: waybar поднимается, бар Quickshell останавливается; повторный `install.sh` возвращает Quickshell и не ломается при повторном запуске.

- [ ] **Шаг 4: Обновить статус в README и закоммитить**

```bash
git add -A && git commit -m "docs: контрольная точка этапа 1 — бар работает, откат проверен"
```

---

# Этап 2 — карточки, док, панели

### Task 14: Карточка часов

**Files:**
- Create: `Cards/ClockCard.qml`
- Modify: `shell.qml`

**Interfaces:**
- Consumes: `Theme`, `Format`, `PopupHost`
- Produces: `ClockCard` — `PanelWindow`, namespace `Theme.nsCard`

- [ ] **Шаг 1: `Cards/ClockCard.qml`**

`PanelWindow` без `exclusiveZone`: `anchors { top: true; left: true }`, `margins { top: Theme.cardMargin; left: Theme.cardMargin }`, `WlrLayershell.layer: WlrLayer.Top`, `WlrLayershell.namespace: Theme.nsCard`, `color: "transparent"`. Внутри — `Rectangle` `Theme.cardBg`, `radius: Theme.cardRadius`, `implicitWidth` по содержимому. Время `HH:MM` размером `Theme.clockSize` цветом `Theme.text`, ниже `Format.weekdayFull` и `Format.dateShort` цветом `Theme.subtext`.

- [ ] **Шаг 2: Обновление и клик**

`Timer` раз в минуту. `MouseArea` на всю карточку → `PopupHost.toggle("calendar", PopupHost.clockX)` — панель появляется под часами бара. Это та же панель, что открывается кликом по часам (Task 11); `PopupHost.clockX` уже задан баром.

- [ ] **Шаг 3: Подключить в `shell.qml`**

- [ ] **Шаг 4: Проверить**

```bash
hyprctl layers | grep -A2 qs-card
```
Действия: карточка в левом верхнем углу; время совпадает с часами в баре; клик открывает календарь; окно Hyprland не перекрывает карточку при `SUPER+F` (карточка в слое Top). Карточка не резервирует место: maximized-окно занимает весь экран.

- [ ] **Шаг 5: Коммит**

```bash
git add -A && git commit -m "feat: плавающая карточка часов"
```

---

### Task 15: Карточка системного монитора

**Files:**
- Create: `Cards/SysMonCard.qml`
- Modify: `shell.qml`

**Interfaces:**
- Consumes: `Theme`, `Proc`, `Sparkline`, `Icons`
- Produces: `SysMonCard`

- [ ] **Шаг 1: `Cards/SysMonCard.qml`**

`PanelWindow` как у карточки часов, но `anchors { top: true; right: true }`. Содержимое: строка CPU — иконка, `Proc.cpuPercent` c `%`, `Sparkline` (`lineColor: Theme.teal`); строка RAM — иконка, `Proc.memPercent` с `%`, `Sparkline` (`lineColor: Theme.mauve`); строка температуры — `visible: Proc.tempC > 0`. Размеры графиков: высота 24, ширина 120.

- [ ] **Шаг 2: Клик**

`MouseArea` по строкам CPU/RAM → `kitty -e btop` (`Process`, без `sh -c`).

- [ ] **Шаг 3: Подключить и проверить**

Действия: графики движутся. Нагрузка без внешних пакетов:

```bash
for i in 1 2; do yes > /dev/null & done ; sleep 15 ; kill %1 %2
```
Ожидаемо: CPU-график заметно растёт; после `kill` — падает. Открыть chromium — RAM-график растёт.

- [ ] **Шаг 4: Коммит**

```bash
git add -A && git commit -m "feat: карточка системного монитора со спарклайнами"
```

---

### Task 16: Карточка плеера

**Files:**
- Create: `Cards/PlayerCard.qml`
- Modify: `shell.qml`

**Interfaces:**
- Consumes: `Theme`, `Icons`, `Quickshell.Services.Mpris`
- Produces: `PlayerCard`

- [ ] **Шаг 1: Определить реальный API управления плеером**

Перед написанием кода выяснить точные имена методов `MprisPlayer` в установленной версии (в документации 0.3.1 подтверждены только свойства `canGoNext`, `canGoPrevious`, `canTogglePlaying`, `playbackState`, `position`, `length`):

```bash
rpm -ql quickshell | grep -iE 'qmltypes|Mpris' | head
grep -rn "togglePlaying\|MprisPlayer" /usr/lib64/qt6/qml/Quickshell/ 2>/dev/null | head
```
Использовать **только** найденные методы. Если методов управления в API нет — управлять через `playerctl` в `Process` (`playerctl play-pause`, `playerctl next`, `playerctl previous`) и зафиксировать выбор комментарием в файле.

- [ ] **Шаг 2: `Cards/PlayerCard.qml`**

`PanelWindow` `anchors { bottom: true; left: true }`, `margins { bottom: Theme.cardMargin; left: Theme.cardMargin }`. Активный плеер — первый из `Mpris.players`. Содержимое: обложка 64×64 (`Image` с `source: player.trackArtUrl`, при пустом — плейсхолдер-рамка), название (`trackTitle`, обрезка), исполнитель (`trackArtist`, цвет `Theme.subtext`, обрезка), прогресс-бар (`position`/`length`), кнопки prev/play-pause/next.

- [ ] **Шаг 3: Автоскрытие и тик прогресса (Review Focus 1)**

`visible: Mpris.players.length > 0 && player !== null`. `Timer` 1000 мс только пока карточка видима (`running: visible`) — обновлять прогресс. `position` обновлять из `player.position` (плееры отдают позицию с разной частотой; допускается инкремент локально между опросами, если позиция не меняется).

- [ ] **Шаг 4: Подключить в `shell.qml` и проверить (Review Focus 1, 4)**

```bash
# нет плеера
playerctl status 2>&1   # ожидаемо "No players found"
```
Действия и ожидания:
- без играющего плеера карточка **отсутствует** на экране, ошибок в логе нет;
- запустить `mpv --no-video <файл>` → карточка появилась, обложка/название/исполнитель верны;
- play/pause/next/prev работают, состояние кнопки play/pause соответствует `playbackState`;
- трек с длинным названием (>60 символов) — строка обрезана, карточка не разъезжается;
- переключение трека обновляет обложку;
- остановить плеер → карточка исчезает.

- [ ] **Шаг 5: Коммит**

```bash
git add -A && git commit -m "feat: карточка плеера с обложкой и управлением"
```

---

### Task 17: Док

**Files:**
- Create: `Dock/Dock.qml`
- Modify: `shell.qml`

**Interfaces:**
- Consumes: `Theme`, `Icons`, `Quickshell.Hyprland`, `Quickshell.Io`
- Produces: `Dock`

- [ ] **Шаг 1: `Dock/Dock.qml`**

`PanelWindow` `anchors { bottom: true; left: true; right: true }`, `implicitHeight: Theme.dockHeight`, `margins { bottom: Theme.cardMargin }`, `exclusiveZone` не задавать, `WlrLayershell.namespace: Theme.nsDock`, `color: "transparent"`. Внутри по центру — `Rectangle` `Theme.dockBg`, `radius: Theme.dockRadius`, горизонтальный ряд иконок.

- [ ] **Шаг 2: Приложения и индикатор запуска**

Список: `kitty`, `chromium-browser`, `nautilus`, `code`. Для каждого — путь к `.desktop`/иконке (`Quickshell.iconPath` по имени иконки). Индикатор: `Hyprland.toplevels` содержит `class`, соответствующий приложению (`kitty`, `chromium-browser`/`chromium`, `nautilus`, `code`/`code-oss`) → точка под иконкой цветом `Theme.mauve`. Клик: если есть окно — поднять (`Hyprland.dispatch("focuswindow class:^X$")`), иначе запустить через `Process`.

- [ ] **Шаг 3: Тултипы**

При наведении — имя приложения, реализованное плашкой внутри самого дока (`Rectangle` поверх иконки), без отдельного окна.

- [ ] **Шаг 4: Проверить**

Действия: запустить приложение из дока; индикатор появился; повторный клик переключает фокус на существующее окно, а не открывает второе; закрыть приложение — индикатор погас; док не перекрывает окна при maximized (не резервирует место); `hyprctl layers | grep qs-dock` показывает слой.

- [ ] **Шаг 5: Коммит**

```bash
git add -A && git commit -m "feat: док с индикатором запущенных приложений"
```

---

### Task 18: Правила слоёв, blur и полировка

**Files:**
- Modify: `hypr/hyprland.lua`, компоненты с найденными дефектами
- Sync: `~/.config/hypr/hyprland.lua`

**Interfaces:**
- Consumes: всё предыдущее
- Produces: финальные `layer_rule` для четырёх namespace'ов

- [ ] **Шаг 1: Добавить `layer_rule`**

В `hypr/hyprland.lua` (и в `~/.config/hypr/hyprland.lua`):

```lua
hl.layer_rule({ match = { namespace = "qs-bar" },   blur = false })
hl.layer_rule({ match = { namespace = "qs-card" },  blur = false })
hl.layer_rule({ match = { namespace = "qs-dock" },  blur = false })
hl.layer_rule({ match = { namespace = "qs-popup" }, blur = true, ignore_alpha = 0.3 })
```

Старые правила для `waybar`/`wofi`/`rofi`/`notifications`/`swayosd` **оставить** (wofi, mako и swayosd ещё в работе).

- [ ] **Шаг 2: Проверить blur выборочно (Review Focus: производительность)**

```bash
hyprctl reload ; sleep 2
hyprctl layers | grep -E 'qs-(bar|card|dock|popup)'
```
Действия: открыть панель громкости поверх обоев — под ней видно размытие; карточки и бар — без размытия, только полупрозрачная заливка. Сравнить плавность открытия панели с/без blur; если заметны рывки на UHD 620 — отключить blur у `qs-popup` и зафиксировать это в README.

- [ ] **Шаг 3: Полировка краевых случаев**

Пройти по Review Focus и закрыть оставшиеся дефекты визуально: единые отступы, отсутствие осцилляции ширины бара, корректные «пустые» состояния (трея нет, сетей нет, устройств Bluetooth нет, потоков нет) — везде осмысленный текст или скрытие, а не пустая рамка.

- [ ] **Шаг 4: Проверка горячего перезапуска**

```bash
systemctl --user restart quickshell.service ; sleep 3
```
Ожидаемо: все элементы возвращаются на свои места, ни один модуль не остаётся «мёртвым» после рестарта (проверить клики по всем панелям).

- [ ] **Шаг 5: Коммит**

```bash
git add -A && git commit -m "feat: правила слоёв и полировка краевых случаев"
```

---

### Task 19: Финальная приёмка и публикация

**Files:**
- Modify: `README.md`
- Add: скриншоты в `docs/`

**Interfaces:**
- Consumes: всё
- Produces: README с фактическими числами, скриншотами и статусом

- [ ] **Шаг 1: Финальный прогон проверок из спеки §13**

```bash
hyprctl layers | grep -E 'qs-(bar|card|dock|popup)'
ps -o rss=,comm= -C qs 2>/dev/null || ps -o rss=,comm= -C quickshell
systemd-analyze --user verify quickshell.service && echo "unit OK"
journalctl --user -u quickshell.service -p warning -n 50 --no-pager
```
Ожидаемо: все 4 namespace'а подняты, RSS < 250 МБ, `unit OK`, в журнале нет предупреждений и ошибок QML.

- [ ] **Шаг 2: Скриншоты**

Снять: пустой стол (бар + карточки + док), открытую панель громкости с играющим потоком, календарь, Wi-Fi со списком сетей. Сохранить в `docs/screenshots/`, вставить в README.

- [ ] **Шаг 3: Обновить README**

Заполнить «Статус» (оба этапа выполнены), вписать фактическое потребление памяти, команду запуска и результат отката. Указать ограничение железа: blur включён только для панелей.

- [ ] **Шаг 4: Коммит и пуш**

```bash
git add -A && git commit -m "docs: финальная приёмка, скриншоты и отчёт по ресурсам"
git push -u origin main
```

---

## Приложение: проверочный чек-лист перед объявлением готовности

- [ ] `node --test tests/` — PASS
- [ ] `hyprctl layers` — есть `qs-bar`, `qs-card`, `qs-dock`, `qs-popup`
- [ ] RSS Quickshell < 250 МБ (число записано в README)
- [ ] Все 6 панелей: открытие, `Esc`, клик вне, повторный клик
- [ ] Все 4 карточки/док: данные живые, пустые состояния корректны
- [ ] `./uninstall.sh` → waybar возвращается; `./install.sh` → Quickshell возвращается
- [ ] В журнале сервиса нет ошибок QML
- [ ] Нет литеральных цветов вне `Theme.qml`
