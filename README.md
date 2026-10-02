# SMD-корпуса — справочник для Android

Офлайн-справочник синонимов SMD-корпусов: обозначения JEDEC, EIAJ/JEITA и производителей (NXP/Nexperia, TI, ADI/Linear, Maxim, onsemi, Sanyo, Toshiba, ROHM, Renesas, Panasonic, Infineon, Diodes, Vishay, ST).

- **APK:** [последний релиз](https://github.com/wadi-li/smd-packages-android/releases/latest) — Android 7.0+, без разрешений и без интернета.
- **Веб-версия (PWA):** https://wadi-li.github.io/smd-packages-android/

## Разделы

| Раздел | Записей |
|---|---|
| Полупроводники (SOD, SOT, SC-70, SOIC/TSSOP, QFN/DFN, LQFP, силовые) | 78 |
| Чип-резисторы и MLCC (дюймовые и метрические коды, коды серий) | 26 |
| Танталовые конденсаторы (EIA-535 и буквы производителей) | 24 |
| Алюминиевые V-chip | 14 |
| Полимерные (POSCAP, SP-Cap, OS-CON) | 21 |
| Сравнение MLCC и тантала | — |

Поиск сразу по всем разделам без учёта регистра, дефисов, скобок и «×/x» (`sc88a` → SC-88A, `0603` → 0603 и 1608), карточки и таблица, избранное, фильтр по группам, выбор столбцов, светлая/тёмная тема, экспорт в CSV (`;`, UTF-8 с BOM; в APK — в «Загрузки»).

## Оговорки

«≈» — близкий, но не идентичный корпус. Пустая ячейка — обозначение не найдено или корпус не выпускается. Часть кодов внесена без первоисточника: перед применением сверяйте посадочное место с чертежом в даташите.

## Структура

```
web/data.js        данные справочника
web/app.html       приложение (данные встраиваются при сборке)
web/landing.html   стартовая страница сайта
android/           манифест, MainActivity (WebView + мост Android), ресурсы
tools/build.sh     сборка APK и сайта
tools/icons.py     генерация иконок (Pillow)
docs/              GitHub Pages
```

## Сборка

Нужны JDK 17, Android SDK (`build-tools;34.0.0`, `platforms;android-34`), Python 3 с Pillow, Node.js. Gradle не используется: APK собирается напрямую через aapt2 → javac → d8 → zipalign → apksigner.

```bash
export ANDROID_HOME=~/Android/Sdk JAVA_HOME=/path/to/jdk-17
export KEYSTORE=/path/to/release.keystore KEYSTORE_PASS=...   # иначе будет создан новый ключ
VER=1.0 VC=1 ./tools/build.sh
# результат: build/SMD-packages-1.0.apk и build/site/
```

Ключ подписи в репозиторий не входит. Обновления APK должны подписываться тем же ключом, иначе Android не установит их поверх старой версии.
