# Phase 4 — Polish & i18n

**Target version:** `0.5.0` (MINOR)
**Goal:** готовность к community-plugins: полная локализация en+ru, понятные ошибки,
README, чистая загрузка, отсутствие секретов и лишних процессов.

Исполнитель: **implementer** + **docs**; проверяющий: **qa**, **reviewer**.

## Non-goals

- новые фичи вне SPEC;
- новые entry, settings или IPC-события;
- публикация (Phase 5);
- `luau-analyze`/`selene`/`stylua` — локально не установлены, в гейт не входят.

## Dependencies

Phases 0–3.

## Tasks

1. Аудит всех user-facing строк → ключи в `en.json` + `ru.json` (вложенный JSON).
2. Ошибки: `cli-missing`, `daemon-down`, `unregistered`, `timeout`, `command-failed`,
   `decode-failed` — по одному понятному тексту на код + рекомендация действия.
3. README: установка, зависимость, `--accept-tos`, path-source, IPC-таблица, ограничения
   (Families write-only, glyph в Control Center, клики ЛК/ПК), лицензия, network/process list.
4. `thumbnail.webp` в корне плагина (community-plugins требует именно `.webp`).
5. Проверить `advanced`/`visible_when` у настроек; лишние настройки убрать.
6. Убедиться: нет `sudo`, нет секретов, нет shell-строк с payload.
7. Прогон QA-матрицы и чистая загрузка.

## Settings / State / IPC

Без изменений. Любая новая настройка в Phase 4 = MINOR сверх фазы → эскалировать
orchestrator, а не добавлять «по ходу».

## Files

| Файл | Действие |
|------|----------|
| `translations/en.json`, `ru.json` | полный набор, паритет ключей |
| `README.md` | финальная версия |
| `thumbnail.webp` | новый (1280×720 или квадрат, ≤ 1 МБ) |
| `panel.luau`, `widget.luau`, `shortcut.luau` | только тексты/ключи, без логики |
| `CHANGELOG.md` | `0.5.0` |

## Acceptance criteria

### A. Линт и манифест

- [ ] `noctalia plugins lint cloudflare-warp` → exit 0,
      `0 errors, 0 warnings`.
      (Команды `noctalia validate-plugin` не существует — не использовать.)
- [ ] `python3 -c "import tomllib;d=tomllib.load(open('cloudflare-warp/plugin.toml','rb'));print(d['version'],d['plugin_api'])"`
      → `0.5.0 24`.
- [ ] В манифесте нет неиспользуемых настроек и нет настроек без `label_key`.

### B. Паритет переводов

- [ ] Одинаковый набор путей ключей в en и ru (вложенный JSON, сравнение рекурсивное):

```bash
cd /home/code_warlord/DEV/cloudflare-warp-plugin
python3 - <<'PY'
import json, sys
def flat(d, p=""):
    for k, v in d.items():
        key = f"{p}{k}"
        if isinstance(v, dict):
            yield from flat(v, key + ".")
        else:
            yield key
en = set(flat(json.load(open("cloudflare-warp/translations/en.json", encoding="utf-8"))))
ru = set(flat(json.load(open("cloudflare-warp/translations/ru.json", encoding="utf-8"))))
print("keys:", len(en))
print("missing in ru:", sorted(en - ru))
print("extra in ru:", sorted(ru - en))
sys.exit(0 if en == ru else 1)
PY
```

- [ ] Все `label_key`/`description_key` из `plugin.toml` присутствуют в обоих файлах.
- [ ] В `ru.json` нет английских строк-заглушек (глазами, выборочно 10 ключей).

### C. Чистая загрузка

Команды выполняются на живом shell, лог — `~/.cache/noctalia/noctalia.log`.

- [ ] `noctalia msg plugins enable code-warlord/cloudflare-warp` → `ok …`.
- [ ] В логе есть `loaded plugin 'code-warlord/cloudflare-warp' (4 entries)` и
      `started service 'code-warlord/cloudflare-warp:service'`.
- [ ] Нет ни одной строки `[plugin-i18n] plugin translation key … not found`,
      относящейся к нашим ключам:
      `grep -n "plugin translation key" ~/.cache/noctalia/noctalia.log | tail -5` → наших ключей нет.
- [ ] Нет `disabled after repeated timeouts` для нашего плагина.
- [ ] Нет `[ERR]`-строк, содержащих `cloudflare-warp`.
- [ ] Переключение языка Noctalia на ru → подписи настроек и панели на русском
      (Settings → Plugins → Cloudflare WARP).
- [ ] Переключение обратно на en → английские.

### D. Ошибки и UX

- [ ] Каждый `errorCode` имеет текст в en и ru; ни один не показывает сырой ключ
      (`error.foo` в UI = FAIL).
- [ ] При `unregistered` панель предлагает Register, а не «ошибку».
- [ ] При `switch_locked` mode-селектор disabled и есть объяснение.
- [ ] При недоступном CLI (`available = false`) панель не пустая и не врёт про WARP.
- [ ] Tooltip бара не содержит пустых строк/`nil`.

### E. Trust surface

- [ ] `grep -Rn "sudo\|pkexec\|systemctl" cloudflare-warp --include=*.luau` → пусто.
- [ ] `grep -Rn "runAsync(\"" cloudflare-warp --include=*.luau` → пусто (только argv).
- [ ] `grep -RniE "license|public_key|device_id" cloudflare-warp --include=*.luau`
      → только комментарии/README, ни одного чтения в state/лог.
- [ ] Список процессов и сети в README совпадает с кодом:

| Вызов | Когда | Данные |
|-------|-------|--------|
| `warp-cli … status` | poll | локальный CLI |
| `warp-cli … settings list` | poll (реже) | локальный CLI |
| `warp-cli … registration show` | poll (реже) | локальный CLI |
| `warp-cli … connect/disconnect/mode/dns families/tunnel protocol set/registration new` | по команде | локальный CLI |
| `warp-cli --version` | старт | локальный CLI |
| `HTTPS GET https://www.cloudflare.com/cdn-cgi/trace` | trace | публичный egress IP уходит Cloudflare |

### F. Репозиторий

- [ ] `thumbnail.webp` существует, открывается, вес ≤ 1 МБ:
      `file cloudflare-warp/thumbnail.webp && du -h cloudflare-warp/thumbnail.webp`.
- [ ] README содержит все 5 обязательных разделов docs-i18n
      (зависимость, установка, IPC, ограничения, лицензия).
- [ ] `CHANGELOG.md` содержит `0.5.0`.
- [ ] QA-матрица (`.agents/skills/qa/SKILL.md`) — PASS.
- [ ] Reviewer — APPROVE.

## Risks

| Risk | Mitigation |
|------|------------|
| Расхождение ключей en/ru | скрипт паритета в CI-подобном виде, запускать перед PR |
| Сырые ключи в UI | проверка «нет `error.`/`panel.` в тексте» глазами + grep по `tr(` |
| `thumbnail.webp` не тот формат | `file` + требование community-plugins |
| Случайно добавленная фича | любая новая настройка/entry → эскалация orchestrator |

## Version bump

`0.4.0` → `0.5.0`
