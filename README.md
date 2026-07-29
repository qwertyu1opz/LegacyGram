# LegacyGram

LegacyGram — клиент Telegram для старых устройств Apple. Проект ориентирован на
iOS 6 и сохраняет совместимость со старым SDK, Objective-C runtime и
32-битной архитектурой ARMv7.

Текущая версия: **0.0.4**.

## Возможности

- авторизация и работа с Telegram на старых версиях iOS;
- диалоги, группы, каналы и отправка медиа;
- интерфейс, адаптированный для классического оформления iOS;
- экспериментальный модуль FuckDPI для обхода сетевых блокировок;
- WireGuard и AmneziaWG-совместимое ядро в `Modules/NekroEngine`;
- автоматический перебор встроенных WARP-профилей с проверкой доступности сети.

## FuckDPI

Модуль находится в меню `Настройки → FuckDPI`.

Переключатель **«Взлом РКН»** запускает подбор WARP-профиля. Зелёный статус
появляется только после успешной проверки передачи данных через выбранный
маршрут.

Туннелю требуются повышенные права для создания `utun` и изменения системной
маршрутизации. На текущем этапе функция предназначена для jailbroken-устройств
с установленным привилегированным движком. В дальнейшем движок будет
поставляться внутри LegacyGram как `FuckDPID`.

Встроенные конфигурации находятся в:

```text
Modules/NekroEngine/Profiles
```

## Сборка

Для эталонной сборки используются:

- macOS 10.9;
- Xcode 4.6.3;
- iPhoneOS SDK 6.1;
- архитектура ARMv7;
- deployment target iOS 6.0.

Перед сборкой создайте локальный `config.h` на основе `config.h.example` и
укажите собственные Telegram API ID и API hash:

```objective-c
#define SETUP_API_ID(apiId) apiId = 12345;
#define SETUP_API_HASH(apiHash) apiHash = @"your-api-hash";
```

Файл `config.h` исключён из Git и не должен попадать в публичный репозиторий.

Откройте `Telegram.xcworkspace` либо выполните:

```sh
xcodebuild \
  -project Telegraph.xcodeproj \
  -target Telegraph \
  -configuration "Debug AppStore" \
  -sdk iphoneos6.1 \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
```

Результат сборки находится в:

```text
build/Debug AppStore-iphoneos/Telegram.app
```

## Установка

Для запуска на обычном устройстве требуется корректная подпись приложения.
На jailbroken-устройстве сборку также можно установить в системный каталог
`/Applications/LegacyGram.app`, после чего обновить кэш приложений командой
`uicache`.

## Безопасность

Не публикуйте:

- `config.h` с Telegram API hash;
- сертификаты и provisioning profiles;
- пользовательские данные и журналы;
- рабочие приватные ключи WARP.

Дополнительная информация о конфигурации публичной сборки находится в
`SECURITY_AND_BUILD.md`.
