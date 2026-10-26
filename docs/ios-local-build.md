# Локальная iOS-сборка

Скрипт `prod_build/build_ios.sh` повторяет локальный сценарий Planer (`prod_build/build_ios.sh`). Команда разработчика записана в проект Xcode, подпись автоматическая. Файл профиля передавать не нужно. Это не сборка для App Store: приложение ставится только на устройства, зарегистрированные в команде.

Нужны Mac, Xcode, Qt iOS 6.8.3 и аккаунт команды в Xcode → Settings → Accounts. Команда по умолчанию — `74FAM6RATH`, как в проекте Planer.

## Установка на свои устройства

```bash
bash prod_build/build_ios.sh
```

Это development-подпись. Если iPhone подключён, скрипт добавляет его в профиль. Без подключённого телефона IPA ставится только на устройства, которые уже есть в профиле.

Для зарегистрированных устройств с Distribution-подписью:

```bash
bash prod_build/build_ios.sh ad-hoc
```

Результат: `build/ios-local/WorkOrder-development.ipa` или `build/ios-local/WorkOrder-ad-hoc.ipa`.

Установка: Xcode → Window → Devices and Simulators → устройство → Installed Apps → `+`.

Другая команда разработчика:

```bash
TEAM_ID=XXXXXXXXXX bash prod_build/build_ios.sh
```
