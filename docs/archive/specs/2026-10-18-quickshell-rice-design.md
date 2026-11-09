# Quickshell-rice для Hyprland — дизайн

## 0. Изменения после утверждения

- **2026-10-18:** §15 — `qs ipc`-интерфейс **решено делать** (был открытый вопрос). Причина: при проверке по задачам панели нужно открывать командой — агент не может кликать мышью. Добавлен `IpcHandler { target: "shell" }` в `PopupHost`.
- **2026-10-18:** уточнено по факту: `node --test tests/` не работает на Node 22 — использовать `node --test 'tests/**/*.test.js'`; `.pragma library` не является валидным JavaScript, поэтому тестовый загрузчик `parse.js` снимает прагму перед `new Function`.

---

**Статус:** дизайн утверждён, спека на ревью
**Дата:** 2026-10-18
**Хост:** Fedora 44, Hyprland 0.56.2, eDP-1 1920×1080@60, Intel UHD 620, i7-8665U, 7.4 ГБ RAM
**Репозиторий:** `hyprland-quickshell-rice` (private)
**Отношение к текущему состоянию:** заменяет waybar на единый шелл Quickshell

---

## 1. Контекст

Сейчас рабочий стол собирается из отдельных демонов: `waybar` (бар), `wofi` (лаунчер),
`mako` (уведомления), `hyprpaper` (обои), `hyprlock`/`hypridle`, `swayosd` (OSD).
Стиль — Catppuccin Mocha, конфиги задокументированы на русском и вручную подогнаны
под слабое железо (`blur passes = 1`, `glow = false`, `render_unfocused_fps = 15`,
`no_blur` для видео).

Пользователь хочет добавить к этому:
1. **плавающие прозрачные карточки** на рабочем столе (плеер, системный монитор,
   часы, док быстрых ссылок);
2. **интерактивные выпадающие панели** из бара (громкость, Wi-Fi, Bluetooth,
   календарь, батарея, питание).

Ключевое ограничение: waybar не умеет рисовать оверлеи за пределами своего окна,
поэтому оба пункта требуют отдельного движка слоя. Выбран **Quickshell**
(Qt6/QML, один процесс) и решение **полностью заменить waybar**, чтобы не держать
два бара-демона и две системы стилей.

## 2. Цели и критерии успеха

| Цель | Критерий приёмки |
|---|---|
| Бар не хуже waybar | Все текущие модули на месте, воркспейсы 1–5, трей, клик по модулю работает |
| Плавающие карточки | Часы, системный монитор, плеер, док — видны, читаемы, не мешают окнам |
| Выпадающие панели | 6 панелей открываются/закрываются по клику и по Esc, клик снаружи закрывает |
| Единый стиль | Все элементы берут цвета/радиусы/шрифты из одного `Theme.qml` |
| Бюджет ресурсов | Один процесс Quickshell < 250 МБ RSS; плавность не хуже текущей |
| Обратимость | Возврат к waybar — одна строка в `hyprland.lua` + остановка сервиса |
| Развёртываемость | Установка и откат описаны в `install.sh` / `README.md` |

## 3. Не-цели (YAGNI)

Явно **вне области работ**: уведомления (`mako` остаётся), `hyprlock`, `hypridle`,
`swayosd`, лаунчер (`wofi` остаётся), обои и `hyprpaper`, погода, заметки/to-do,
анимации переходов между воркспейсами, многомониторные раскладки (сейчас один экран),
GTK/Qt-темы приложений.

## 4. Решения и обоснование

| # | Решение | Почему |
|---|---|---|
| D1 | Движок — Quickshell 0.3.2 из COPR `nett00n/hyprland` | Родные сервисы ровно под задачу (Mpris, Pipewire, UPower, Bluetooth, Networking, Hyprland, SystemTray), GPU-ускоренный QML, один процесс, IPC из коробки. Репа уже включена (`enabled=1`), зависимости (`qt6-qtbase`, `qt6-qtdeclarative`) стоят |
| D2 | waybar убираем из автозапуска, конфиги **архивируем, не удаляем** | Откат — одна строка. Чужую отполированную работу не уничтожаем |
| D3 | Конфиг в `~/.config/quickshell/rice/`, запуск `qs -c rice` | Документация Quickshell рекомендует именованную подпапку, а не корень `quickshell/` — оставляет место для других конфигов |
| D4 | Автозапуск — systemd user unit `quickshell.service` (`Restart=on-failure`) | Выживает падение демона, логи в journal. Фолбэк — `hl.exec_cmd("qs -c rice")` |
| D5 | Календарь живёт **только** в выпадающей панели; карточка часов открывает его по клику | Устраняет дублирование функциональности между карточкой и панелью |
| D6 | Wi-Fi — через `Quickshell.Networking`, **не** через `nmcli` | Нативный NetworkManager-бэкенд, никаких spawn-процессов и парсинга вывода |
| D7 | CPU/RAM — чтение `/proc` через `FileView` | В Quickshell нет сервиса мониторинга системы (проверено); `FileView` дешевле вызова процесса |
| D8 | Backlight — `/sys/class/backlight/...` через `FileView`, установка через `brightnessctl` | Нет сервиса яркости в Quickshell; чтение файла бесплатно, запись — только по действию пользователя |
| D9 | Blur в Hyprland: **включён только для popup-ов** | Панели живут секунды — разовый blur дёшев. Карточки/бар/док — полупрозрачная заливка без blur, как сейчас у waybar |
| D10 | PlayerCard автоскрывается при отсутствии активного плеера | Не висит пустая рамка поверх рабочего стола |
| D11 | Раскладка клавиатуры — опрос `hyprctl -j devices` по таймеру | В Quickshell нет сервиса раскладки (проверено). Помечено как кандидат на оптимизацию (см. §15) |

## 5. Архитектура

Один процесс, один слой, ноль вспомогательных UI-демонов.

```
ShellRoot
├── Theme (синглтон)          — палитра, размеры, шрифты, радиусы
├── PopupHost (синглтон)      — единственный владелец открытой панели
├── Variants over Quickshell.screens
│   ├── Bar        PanelWindow  namespace "qs-bar"
│   ├── Cards      PanelWindow ×3  namespace "qs-card"
│   └── Dock       PanelWindow  namespace "qs-dock"
└── Panels (PopupWindow ×6)   namespace "qs-popup"
```

**Контракт `PopupHost`** — единственная точка управления оверлеями:

```
PopupHost.open(name: string)     // открыть панель, закрыв предыдущую
PopupHost.close()                // закрыть любую открытую
PopupHost.toggle(name: string)   // клик по модулю бара
PopupHost.current: string        // "" если ничего не открыто
```

Клик по модулю бара вызывает `PopupHost.toggle(...)`, попап якорится к окну бара
через `PopupWindow.anchor` (`anchor.window`, `anchor.rect.x/y`), закрытие — по Esc
и по клику вне (через `HyprlandFocusGrab`).

Тот же `PopupHost` несёт `IpcHandler { target: "shell" }` — `togglePanel(name)`,
`closePanel()`, `listPanels()`. Это единственный внешний интерфейс управления
шеллом: он позволяет открывать панели командой (нужно для проверки и для хоткеев).

**Почему не по одному окну на панель:** одна точка владения исключает ситуацию
«открыты три панели одновременно» и позволяет единообразно реализовать закрытие.

## 6. Структура файлов

### 6.1 Репозиторий (local: `~/rice`)

```
~/rice/
  README.md                  # что это, как поставить, как откатить
  install.sh                 # раскладывает конфиги в ~/.config, включает сервис
  uninstall.sh               # возвращает waybar
  docs/
    specs/2026-10-18-quickshell-rice-design.md   # этот файл
    plans/                                       # план реализации (следующий шаг)
  quickshell/rice/           # через симлинк ~/.config/quickshell -> ~/rice/quickshell
  hypr/                      # hyprland.lua и соседи (синхронизируемые копии)
  systemd/quickshell.service # user-unit
```

`~/.config/quickshell` создаётся как **симлинк** на `~/rice/quickshell`
(папка ещё не существует, так что ничего переносить не нужно — переход безопасен).
Для `~/.config/hypr` симлинк не делаем: файлы копируются `install.sh`, чтобы
падение репозитория не оставило систему без конфига Hyprland.

### 6.2 Конфиг Quickshell

```
quickshell/rice/
  shell.qml                  # ShellRoot: Bar + Cards + Dock + Panels
  Theme.qml                  # singleton: палитра и токены
  Bar/
    Bar.qml
    Workspaces.qml  Title.qml  Clock.qml  Tray.qml  Stats.qml
    Volume.qml  Brightness.qml  Network.qml  Bluetooth.qml
    Battery.qml  Language.qml  Power.qml
  Panels/
    PopupHost.qml
    VolumePanel.qml  WifiPanel.qml  BluetoothPanel.qml
    CalendarPanel.qml  BatteryPanel.qml  PowerPanel.qml
  Cards/
    ClockCard.qml  SysMonCard.qml  PlayerCard.qml
  Dock/
    Dock.qml
  lib/
    Proc.qml        # разбор /proc/stat и /proc/meminfo, история для спарклайнов
    Format.qml      # форматирование времени, байт, процентов
    Icons.qml       # имена иконок Nerd Font
    Sparkline.qml   # переиспользуемый мини-график
```

## 7. Бар

`PanelWindow`, anchors `left`/`right`/`top`, высота 36, отступы: сверху 8, по бокам 12,
радиус 14, фон `rgba(24, 24, 37, 0.62)` — визуально как нынешний waybar.
`exclusiveZone` подбирается так, чтобы окна не заезжали под бар (с учётом
существующего `gaps_out = 12`).

| Зона | Модуль | Источник | Клик |
|---|---|---|---|
| слева | Workspaces 1–5 | `Hyprland.workspaces`, `monitor.activeWorkspace` | `Hyprland.dispatch("workspace N")` |
| слева | Title | `Hyprland.activeToplevel.title` | — |
| центр | Language | `hyprctl -j devices` (таймер) | — |
| центр | Clock | Qt | `PopupHost.toggle("calendar")` |
| справа | Tray | `SystemTray.items` | меню трея |
| справа | Stats (CPU/RAM) | `lib/Proc.qml` | `kitty -e btop` |
| справа | Volume | `Pipewire.defaultAudioSink.audio` | `PopupHost.toggle("volume")` |
| справа | Brightness | `/sys/class/backlight` | панели нет; scroll ↑/↓ меняет яркость через `brightnessctl` |
| справа | Network | `Networking.devices` | `PopupHost.toggle("wifi")` |
| справа | Bluetooth | `Bluetooth.defaultAdapter` | `PopupHost.toggle("bluetooth")` |
| справа | Battery | `UPower.displayDevice` | `PopupHost.toggle("battery")` |
| справа | Power | — | `PopupHost.toggle("power")` |

Активный воркспейс — заливка `#cba6f7`, текст `#11111b`; hover — `#313244`.
Все цвета только из `Theme.qml`.

## 8. Плавающие карточки

Общие свойства: `PanelWindow` без `exclusiveZone` (не резервируют место),
`WlrLayershell.layer = Top`, namespace `qs-card`, отступ от краёв 16,
радиус 16, фон `rgba(24, 24, 37, 0.62)`, **blur выключен**.

| Карточка | Позиция | Содержимое | Поведение |
|---|---|---|---|
| `ClockCard` | левый верх | время `HH:MM` крупно (JetBrainsMono NF), дата, день недели | клик → `PopupHost.toggle("calendar")` |
| `SysMonCard` | правый верх | CPU % и RAM % + два спарклайна (история ~60 с); температура из `/sys/class/thermal/thermal_zone0/temp`, строка скрыта, если файла нет | клик по CPU/RAM → `kitty -e btop` |
| `PlayerCard` | левый низ | обложка (`trackArtUrl`), название, исполнитель, прогресс, prev/play/next | скрыта, если `Mpris.players` пуст; обрезка длинных строк |

Источник данных плеера: `Mpris.players` (ObjectModel), первый активный плеер.
Прогресс: `position` / `length`, обновление по `Timer` 1 с только пока карточка видима.
Обложка: `Image` с `source` = `trackArtUrl`; при пустом url — заглушка-плейсхолдер.

## 9. Док

`PanelWindow` снизу по центру, anchors `bottom` (+ `left`/`right` для центрирования),
высота ~56, радиус 28 (таблетка), namespace `qs-dock`, blur выключен.
Закреплённые приложения: kitty, chromium, nautilus, VS Code.
Индикатор «запущено» — точка под иконкой, данные из `Hyprland.toplevels`
(сопоставление по классу окна). Клик — запуск/подъём окна, тултип — имя приложения.
Автоскрытие **не делаем** (одно поведение проще отлаживать; при желании — отдельная итерация).

## 10. Выпадающие панели

`PopupWindow`, namespace `qs-popup`, blur **включён**, ширина 340–420,
радиус 16, фон `rgba(17, 17, 27, 0.92)`, отступ от бара 8.
Закрытие: Esc, клик вне (`HyprlandFocusGrab`), повторный клик по модулю.

| Панель | Источник | Содержимое |
|---|---|---|
| `VolumePanel` | `Pipewire` (+ `PwObjectTracker`) | слайдер громкости default-sink, кнопка mute, список потоков приложений (`nodeType = Stream`) со своими слайдерами и mute |
| `WifiPanel` | `Networking` | текущее соединение; список сетей от `WifiDevice.networks` (ssid, `signalStrength`, `security`); клик → `connect()`, при `NoSecrets` — поле ввода пароля → `connectWithPsk(psk)`; тумблер `Networking.wifiEnabled` |
| `BluetoothPanel` | `Bluetooth` | тумблер адаптера; спаренные и доступные устройства; connect/disconnect, pair/forget; уровень заряда устройства, если отдаёт |
| `CalendarPanel` | Qt | сетка месяца, «сегодня» подсвечен (`#cba6f7` фон, `#1e1e2e` текст), неделя с понедельника, навигация по месяцам |
| `BatteryPanel` | `UPower` | крупный %, время до пустой/полной, состояние, `changeRate` в ваттах, спарклайн заряда за сессию |
| `PowerPanel` | `systemctl` / `loginctl` / `hyprctl` | блокировка (`hyprlock`), suspend, выход из сессии, reboot, shutdown |

Действия с побочными эффектами (выход, reboot, shutdown) выполняются через
`Quickshell.Io.Process` с явными аргументами.

## 11. Тема, blur, производительность

`Theme.qml` (синглтон) — единственный источник визуальных значений:

```
bg        #1e1e2e     mantle   #181825     crust    #11111b
text      #cdd6f4     subtext  #a6adc8     overlay  #6c7086
mauve     #cba6f7     blue     #89b4fa     red      #f38ba8
green     #a6e3a1     yellow   #f9e2af     teal     #94e2d5
peach     #fab387     sky      #89dceb     lavender #b4befe
surface0  #313244     surface1 #45475a
```

Радиусы: бар 14, карточки 16, панели 16, док 28, кнопки 8–10.
Шрифты: `JetBrainsMono Nerd Font` для текста и иконок, `JetBrainsMono NF` — вариант моно.
Базовый размер 13 px, крупные часы — 34 px.

Правила слоёв в `hyprland.lua`:

```lua
hl.layer_rule({ match = { namespace = "qs-bar" },    blur = false })
hl.layer_rule({ match = { namespace = "qs-card" },   blur = false })
hl.layer_rule({ match = { namespace = "qs-dock" },   blur = false })
hl.layer_rule({ match = { namespace = "qs-popup" },  blur = true, ignore_alpha = 0.3 })
```

Бюджет: Quickshell < 250 МБ RSS; таймеров с интервалом < 1 с нет,
кроме графика CPU (1 с) и часов (обновление раз в минуту).
Если бюджет не выдержан — первым режем спарклайны, карточки не трогаем.

## 12. Установка, автозапуск, откат

**Установка:** `sudo dnf install quickshell` (COPR уже включён).

**Автозапуск.** `~/.config/systemd/user/quickshell.service`:

```ini
[Unit]
Description=Quickshell (rice)
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/qs -c rice
Restart=on-failure
RestartSec=1
Slice=session.slice

[Install]
WantedBy=graphical-session.target
```

Запуск из `hyprland.lua`: в `hl.on("hyprland.start")` убрать `hl.exec_cmd("waybar")`
и добавить запуск скрипта, который импортирует Wayland-переменные в user-manager
и стартует сервис:

```
systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE
systemctl --user start quickshell.service
```

**Фолбэк**, если systemd мешает: `hl.exec_cmd("qs -c rice")` (без авторестарта).

Имя бинарника (`qs` или `quickshell`) уточняется сразу после `dnf install` —
в документации используется `qs`, в упаковке Fedora может отличаться.

**Откат:** `./uninstall.sh` (останавливает сервис, возвращает строку `waybar`
в `hyprland.lua`, вызывает `hyprctl reload`). Вручную то же самое:
`systemctl --user stop quickshell.service`, вернуть `hl.exec_cmd("waybar")`,
`hyprctl reload`. Конфиги waybar не тронуты.

**Перед правками** `hyprland.lua` создаётся бэкап
(`hyprland.lua.bak-<дата>`, как уже принято в этом каталоге).

## 13. Проверка

Автоматизируемое:
- `hyprctl layers` — подняты namespace `qs-bar` / `qs-card` / `qs-dock` / `qs-popup`,
  blur применён только к `qs-popup`;
- `ps -o rss= -C qs` (или фактическое имя бинарника) — память в бюджете, замер до/после;
- `systemd-analyze --user verify quickshell.service`;
- `qs ipc show` — зарегистрированные IPC-таргеты, если используются;
- проверка отката: бар waybar поднимается после возврата строки.

Ручное (скриншоты в отчёт):
- все 6 панелей: открытие, закрытие по Esc, закрытие по клику вне;
- карточки: часы, системный монитор (данные живые), плеер (play/pause/next), док;
- поведение плеера при отсутствии играющего трека (карточка скрыта);
- Wi-Fi: подключение к сети, ввод пароля;
- батарея: корректное время и ватты;
- отсутствие визуальных «дёрганий» при открытии панелей.

## 14. Этапы

**Этап 1 — фундамент и бар.**
Установка Quickshell, репозиторий и `install.sh`, `Theme.qml`, `shell.qml`,
бар со всеми модулями (без панелей), автозапуск через systemd, откат на waybar,
замер памяти. Критерий: бар функционально не хуже waybar, waybar возвращается одной строкой.

**Этап 2 — карточки, док, панели.**
`ClockCard`, `SysMonCard`, `PlayerCard`, `Dock`, `PopupHost` и 6 панелей,
layer-правила blur, полировка, финальные скриншоты и README.

Каждый этап завершается проверкой из §13 и коммитом в репозиторий.

## 15. Риски и открытые вопросы

| Риск | Влияние | Смягчение |
|---|---|---|
| Пакет из стороннего COPR, отставание версии | API 0.3.2 может отличаться от документации 0.3.1 | Сверять при реализации; при расхождении — сборка из исходников или фиксация версии |
| Имя бинарника в упаковке Fedora может быть `quickshell`, а не `qs` | Неверный `ExecStart` в unit | Проверить `rpm -ql quickshell` сразу после установки |
| Потребление памяти/GPU на UHD 620 | Тормоза анимаций, просадка FPS | Blur только на popup; спарклайны — первый кандидат на отсечение; замер на каждом этапе |
| Методы управления `MprisPlayer` (`next`/`previous`/`togglePlaying`) | Неверный API сломает плеер | Уточнить по локальной документации пакета при реализации Этапа 2 |
| Раскладка клавиатуры через опрос `hyprctl` | Лишний процесс раз в 1.5 с | Если заметно в профиле — перейти на подписку событий сокета Hyprland |
| Отсутствие `exclusiveZone`-настройки | Окна заезжают под бар | Подобрать значение на Этапе 1, проверить на maximized-окне |
| Потеря бара при падении Quickshell | Нет панели управления | `Restart=on-failure`, быстрый откат на waybar |

**Открытый вопрос (закрыт 2026-10-18):** `qs ipc`-интерфейс для управления шеллом
**делаем**. `IpcHandler` с `target: "shell"` и функциями `togglePanel(name)`,
`closePanel()`, `listPanels()`. Нужен прежде всего для проверки: панель открывается
командой `qs ipc call shell togglePanel volume`, а не только мышью, — при работе по
задачам агент не может кликать. Побочно даёт возможность вешать панели на хоткеи.

## 16. Проверенные факты об API

Всё ниже сверено с документацией Quickshell v0.3.1 (пакет 0.3.2), а не по памяти:

- `PanelWindow` — anchors, `margins`, `exclusiveZone`, `exclusionMode`, `focusable`;
  `WlrLayershell.layer` / `.namespace` (namespace нельзя менять после создания окна).
- `PopupWindow` — `anchor.window`, `anchor.rect.x/y`, `grabFocus`;
  для Hyprland рекомендуется `HyprlandFocusGrab`.
- `Quickshell.Io.IpcHandler` — `target` + типизированные функции, `qs ipc call <target> <fn>`.
- `Quickshell.Services.Mpris` — `Mpris.players`, `trackTitle`, `trackArtist`,
  `trackAlbum`, `trackArtUrl`, `length`, `position`, `canGoNext`, `canGoPrevious`,
  `canTogglePlaying`, `playbackState`.
- `Quickshell.Services.Pipewire` — `Pipewire.nodes`, `defaultAudioSink`
  (`.audio.volume`, `.audio.muted`), требует `PwObjectTracker` для записи.
- `Quickshell.Services.UPower` — `UPower.onBattery`, `displayDevice.percentage`,
  `.timeToEmpty`, `.timeToFull`, `.changeRate`, `.state`.
- `Quickshell.Services.SystemTray` — `SystemTray.items` (ObjectModel).
- `Quickshell.Bluetooth` — `Bluetooth.devices`, `adapters`, `defaultAdapter`;
  `BluetoothDevice.connect()/disconnect()/pair()/forget()`.
- `Quickshell.Networking` — `Networking.wifiEnabled`, `devices` (`NetworkDevice.networks`),
  `WifiDevice.scannerEnabled`; `WifiNetwork.signalStrength`, `.security`;
  `Network.connect()`, `WifiNetwork.connectWithPsk(psk)`.
- `Quickshell.Hyprland` — `workspaces`, `focusedWorkspace`, `activeToplevel`,
  `dispatch(request)`, `refreshMonitors/Workspaces/Toplevels`.
- `Quickshell.Io` — `Process` (+ `StdioCollector`), `FileView` (`watchChanges`),
  `Timer` для периодического перезапуска процесса.
- **Нет** сервисов мониторинга системы, яркости и раскладки клавиатуры —
  отсюда решения D7, D8, D11.
