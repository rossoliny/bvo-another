---
name: bvo-build
description: Use when building a development or release .w3x map in the BvO Another repository.
---

# Сборка BvO Another

Применяй только в BvO Another. Запускай сборку из корня репозитория. Нужны Bash и возможность запускать программы из `toolkit/`.

| Режим | Команда | Результат |
| --- | --- | --- |
| С читами | `bash build-w3x.sh` | `build/BvO_Another_dev.w3x` |
| Без читов | `bash build-w3x.sh --release` | `build/BvO_Another_release.w3x` |

- `w3x-content/` — единственный источник содержимого карты; карта-основа не нужна.
- Основной JASS: `w3x-content/scripts/war3map.j`.
- Релиз полностью исключает читовый код из упакованного JASS без изменения исходника.
- Используй существующий `build-w3x.sh`; исходники и ресурсы не копируй и не изменяй при сборке.
- Сообщения идут в консоль. Скрипт удаляет временные файлы и отчёт тулкита; результат сохраняет только в `build/`.
