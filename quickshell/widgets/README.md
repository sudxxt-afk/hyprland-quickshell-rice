# Виджеты рабочего стола (Quickshell)

Три виджета поверх обоев, под всеми окнами:

| Виджет | Где | Что показывает |
|---|---|---|
| `Cards/PlayerCard.qml` | слева снизу | обложка, название, исполнитель, прогресс, три кнопки (MPRIS) |
| `Dock/Dock.qml` | по центру снизу | kitty, chromium, VS Code, Happ, Wireshark; точка — приложение запущено |
| `Cava/CavaBar.qml` | справа снизу | спектр звука, который реально играет (cava) |

Бар (Wayle) живёт отдельно и этими виджетами не затрагивается.

## Как запускается

Служба пользователя:

```
systemctl --user status quickshell-widgets.service
systemctl --user restart quickshell-widgets.service    # после правки кода
systemctl --user stop quickshell-widgets.service
```

Юнит: `~/.config/systemd/user/quickshell-widgets.service`
(`Restart=always` — если процесс упадёт, виджеты вернутся сами).

Запуск при входе в сессию — строка в `~/.config/hypr/hyprland.lua`:

```lua
hl.exec_cmd("systemctl --user start quickshell-widgets.service")
```

Вручную, без службы (полезно для отладки):

```bash
pkill -x quickshell
quickshell -n --path ~/rice/quickshell/widgets
```

## Как это устроено

* **Слой.** Все окна — `WlrLayershell.layer: WlrLayer.Bottom`, поэтому
  виджеты всегда под окнами и никогда не занимают место
  (`exclusionMode: ExclusionMode.Ignore`).
* **Стекло.** Размытие включает правило слоя в `~/.config/hypr/hyprland.lua`:

  ```lua
  hl.layer_rule({ match = { namespace = "qs-widgets" }, blur = true, ignore_alpha = 0.3 })
  ```

  namespace берётся из `Theme.ns`. Без этого правила фон остаётся просто
  полупрозрачным.
* **Эквалайзер.** cava ничего не рисует — он отдаёт значения полосок
  текстом (конфиг `cava-raw.conf`), а рисует их QML. Источник звука
  задан явно: `@DEFAULT_MONITOR@`. Здесь это принципиально: при
  `source = auto` cava берёт *источник по умолчанию*, а на этой машине
  это микрофон — спектр стоял бы ровной тишиной.
* **Выбор плеера.** На шине обычно несколько MPRIS-клиентов. Правила
  выбора (`shell.qml`, `pickPlayer()`) учитывают проверенные на практике
  случаи:
  * `playerctld` — агрегатор: повторяет чужой трек и переживает закрытие
    настоящего плеера, поэтому пропускается;
  * Telegram умеет «залипнуть»: сообщает «играю» без потока звука и без
    позиции, причём до перезапуска. Поэтому играющим считается тот плеер,
    у которого реально есть поток звука (`pactl -f json list sink-inputs`);
  * если про звук данных нет (например, не установлен `pactl`), выбор
    работает просто по MPRIS — без выдумок.

## Зависимости

`quickshell`, `cava`, `pactl` (pulseaudio-utils), `Hyprland`, иконки из
темы (Papirus/Adwaita), шрифт JetBrains Mono Nerd Font.

## Проверка

```bash
# виджеты на нижнем слое, у каждого своя геометрия
hyprctl layers | grep qs-widgets

# служба жива и поднимается после падения
systemctl --user is-active quickshell-widgets.service
kill -9 $(systemctl --user show quickshell-widgets.service -p MainPID --value)

# эквалайзер реагирует на звук (должны быть ненулевые значения)
cava -p ~/rice/quickshell/widgets/cava-raw.conf
```
