# Сборка APK

Профиль `Android` хранится в `export_presets.cfg`. Результат — `builds/kuratenn-debug.apk`. Папка `builds/` исключена из Git.

Пакет: `org.chikenjump.game`, название: «Куратень», версия: `0.1.0`. В APK включены ARM64, ARMv7 и x86-64. Минимальная версия Android задаётся официальным шаблоном Godot: API 24 (Android 7.0); текущая целевая версия — API 36. Это подписанная отладочная сборка для установки и тестирования.

## Установленные инструменты

- Godot 4.7.2 и соответствующие Android-шаблоны экспорта в `%APPDATA%/Godot/export_templates/4.7.2.stable/`.
- Java из Android Studio: `D:/Android Studio/jbr` (JDK 21).
- Android SDK: `%LOCALAPPDATA%/Android/Sdk`, Build Tools 36.0.0.

Пути Java и Android SDK сохранены в настройках редактора Godot: **Редактор → Настройки редактора → Export → Android**. Профиль использует обычный экспорт из готового шаблона; отдельная Gradle-сборка не требуется.

## Повторная сборка

Из папки проекта в PowerShell:

```powershell
$env:JAVA_HOME = 'D:/Android Studio/jbr'
$env:ANDROID_HOME = "$env:LOCALAPPDATA/Android/Sdk"
$env:GODOT_ANDROID_KEYSTORE_DEBUG_PATH = "$env:APPDATA/Godot/keystores/debug.keystore"
$env:GODOT_ANDROID_KEYSTORE_DEBUG_USER = 'androiddebugkey'
$env:GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD = 'android'
New-Item -ItemType Directory -Path builds -Force | Out-Null
godot_console.exe --headless --path . --export-debug Android builds/kuratenn-debug.apk
```

Здесь используется стандартный локальный отладочный ключ Godot. Для публикации потребуется отдельная релизная подпись; эта сборка предназначена для проверки игры.

В `project.godot` включён импорт ETC2/ASTC для Android. Профиль исключает тесты, документацию и инструменты MCP; экспортный плагин также убирает служебный autoload. Разрешение `android.permission.VIBRATE` включено. Разрешение доступа к интернету игре не требуется.

## Настройки игры

- `scripts/run_session.gd`: `DURATION = 20.0`, `STAR_BONUS = 1.5`.
- `scripts/wave_director.gd`: скорости, реверсы и интервал смены режима.
- `scripts/shadow_field.gd`: угловое ускорение.
- `scripts/game_feedback.gd`: музыка и тактильный отклик.
- `scripts/mobile_layout.gd`: размеры и безопасные отступы интерфейса.

Чувствительность вибрации, производительность и энергопотребление дополнительно проверяются на физических телефонах; эмулятор не заменяет такую проверку.
