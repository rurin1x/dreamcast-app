<p align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="96" height="96" alt="Dream Cast app icon">
</p>

<h1 align="center">Dream Cast</h1>

<p align="center">
  Современный Android-клиент для просмотра релизов Dream Cast.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white">
  <img alt="Android" src="https://img.shields.io/badge/Android-Material%203-3DDC84?style=flat-square&logo=android&logoColor=white">
  <img alt="License" src="https://img.shields.io/badge/License-GPLv3-blue?style=flat-square">
</p>

---

Основной фокус — быстро открыть тайтл, выбрать серию и спокойно смотреть.

Приложение написано на Flutter, но по ощущениям старается быть именно Android-приложением: Material 3, динамические цвета Monet, компактная навигация, нормальная работа с жестами, PiP и локальное хранение прогресса.

## Что умеет

- Получать все релизы с сайта Dream Cast.
- Показывает постеры, описания, метаданные и список серий.
- Поддерживает поиск по тайтлам.
- Хранит закладки и библиотеку пользователя.
- Запоминает прогресс просмотра.
- Поддерживает HLS и DASH-потоки.
- Работает с Picture-in-Picture.
- Показывает календарь релизов.
- Умеет уведомлять о новых сериях в подписанных тайтлах.
- Использует локальный кэш.

## Внутри

Проект не использует WebView как основу интерфейса. Данные проходят через собственный слой:

```text
Dream Cast
→ Dio
→ HTML/API parser
→ PlayerJS decoder
→ Repository
→ Drift cache
→ Riverpod providers
→ Flutter UI
```

Основные технологии:

- Flutter / Dart
- Riverpod
- GoRouter
- Dio
- Drift
- Material 3
- dynamic_color
- video_player
- Workmanager
- flutter_local_notifications

## Сборка

Нужны Flutter SDK и Android Studio с Android SDK.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Для релизной сборки:

```bash
flutter build apk --release
```

Перед публичной раздачей APK нужно настроить свой release-keystore. Ключ подписи должен быть постоянным: если потерять его, пользователи не смогут обновиться поверх старой версии.

Создать ключ можно так:

```bash
keytool -genkey -v -keystore android/app/dreamcast-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dreamcast
```

После этого создайте локальный файл `android/key.properties`:

```properties
storePassword=ВАШ_ПАРОЛЬ_ОТ_KEYSTORE
keyPassword=ВАШ_ПАРОЛЬ_ОТ_КЛЮЧА
keyAlias=dreamcast
storeFile=app/dreamcast-release.jks
```

`android/key.properties` и `.jks` уже добавлены в `.gitignore`. Не коммитьте их в репозиторий и сделайте резервную копию ключа в надёжном месте.

## Структура

```text
lib/
  app/          запуск приложения, роутер, тема
  core/         база данных, сеть, настройки, логирование
  features/
    home/       главная страница
    library/    закладки и библиотека
    notifications/
    onboarding/
    player/
    profile/
    releases/   парсинг, репозитории и экраны тайтлов
    schedule/
    settings/
```

## Лицензия

Проект распространяется по лицензии GPLv3.

Некоторые идеи парсинга основаны на `anicli-api` под лицензией MIT. Реализация для приложения переписана на Dart.

## Благодарности

Спасибо Dream Cast за релизы, open-source сообществу за инструменты и людям, которые спокойно тестировали приложение, пока оно училось быть нормальным Android-клиентом.

---

<p align="center">
  Dream Cast · GPLv3 · 2026
</p>
