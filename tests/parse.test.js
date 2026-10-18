const { test } = require("node:test");
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const src = fs.readFileSync(path.join(__dirname, "../quickshell/rice/lib/parse.js"), "utf8");
// parse.js начинается с QML-директивы `.pragma library` — это не валидный
// JavaScript, поэтому перед `new Function` её нужно отбросить (см. parse.js).
const js = src.replace(/^\s*\.pragma[^\n]*\n?/, "");
const api = new Function(
  js + "\nreturn { parseProcStat, cpuPercent, parseMeminfo, memPercent, parseTemp, formatDuration };"
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
