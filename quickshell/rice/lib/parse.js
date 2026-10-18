.pragma library

// Чистые парсеры системных данных (/proc, /sys).
//
// ВАЖНО: `.pragma library` — директива QML, а не JavaScript. Модуль используется
// в Quickshell через `import "parse.js" as Parse`. Юнит-тесты
// (tests/parse.test.js) загружают этот файл как JS через `fs.readFileSync` +
// `new Function`, поэтому перед выполнением директива `.pragma` отбрасывается
// (иного способа совместить QML-прагму и обычный JS-парсер нет).

// Первая строка, начинающаяся с "cpu " (именно с пробелом, чтобы не поймать
// "cpu0"). Поля: user, nice, system, idle, iowait, irq, softirq, steal.
// guest и guest_nice намеренно не включаются — они уже учтены в user.
function parseProcStat(text) {
    if (typeof text !== "string" || text.length === 0)
        return null;

    var lines = text.split("\n");
    var line = null;
    for (var i = 0; i < lines.length; i++) {
        if (lines[i].indexOf("cpu ") === 0) {
            line = lines[i];
            break;
        }
    }
    if (line === null)
        return null;

    var parts = line.replace(/^\s+/, "").split(/\s+/);
    if (parts.length < 9)
        return null;

    var fields = [];
    for (var j = 1; j <= 8; j++) {
        var value = parseInt(parts[j], 10);
        if (!isFinite(value))
            return null;
        fields.push(value);
    }

    var idle = fields[3] + fields[4]; // idle + iowait
    var total = 0;
    for (var k = 0; k < 8; k++)
        total += fields[k];

    return { idle: idle, total: total };
}

// Загрузка процессора между двумя снимками. deltaTotal <= 0 → 0.
function cpuPercent(prev, cur) {
    if (!prev || !cur)
        return 0;

    var deltaTotal = cur.total - prev.total;
    var deltaIdle = cur.idle - prev.idle;
    if (deltaTotal <= 0)
        return 0;

    var percent = 100 * (deltaTotal - deltaIdle) / deltaTotal;
    if (percent < 0)
        percent = 0;
    if (percent > 100)
        percent = 100;
    return percent;
}

// MemTotal / MemAvailable из /proc/meminfo, значения в kB.
function parseMeminfo(text) {
    if (typeof text !== "string" || text.length === 0)
        return null;

    var lines = text.split("\n");
    var totalKb = -1;
    var availableKb = -1;
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (line.indexOf("MemTotal:") === 0) {
            var total = parseInt(line.slice(line.indexOf(":") + 1), 10);
            if (isFinite(total))
                totalKb = total;
        } else if (line.indexOf("MemAvailable:") === 0) {
            var available = parseInt(line.slice(line.indexOf(":") + 1), 10);
            if (isFinite(available))
                availableKb = available;
        }
    }

    if (totalKb < 0 || availableKb < 0)
        return null;
    return { totalKb: totalKb, availableKb: availableKb };
}

// Процент занятой памяти, округлённый до целого.
function memPercent(info) {
    if (!info || !(info.totalKb > 0))
        return 0;
    return Math.round(100 * (1 - info.availableKb / info.totalKb));
}

// Температура: /sys/.../temp отдаёт миллиградусы. Не число → -1.
function parseTemp(milliCelsius) {
    var value = parseFloat(milliCelsius);
    if (!isFinite(value))
        return -1;
    return value / 1000;
}

// Секунды → "4h 12m" | "12m" | "45s". Отрицательные и NaN → "0s".
function formatDuration(seconds) {
    if (typeof seconds !== "number" || !isFinite(seconds) || seconds <= 0)
        return "0s";

    var total = Math.floor(seconds);
    if (total < 60)
        return total + "s";
    if (total < 3600)
        return Math.floor(total / 60) + "m";

    var hours = Math.floor(total / 3600);
    var minutes = Math.floor((total % 3600) / 60);
    return hours + "h " + minutes + "m";
}
