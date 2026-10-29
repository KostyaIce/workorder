# Ключ подписи Android

Release APK подписывается ключом вне репозитория. Каталог лежит рядом с проектом:

```text
Project/
  workorder/
  workorder-signing/
    key.properties
    workorder-key.jks
```

Нужен JDK: команда `keytool` входит в него. Ключ создаётся один раз. Потерянный файл или пароль нельзя восстановить, и обновление уже опубликованного приложения этой подписью станет невозможно.

## Создать ключ

```bash
mkdir -p ~/Documents/Project/workorder-signing
keytool -genkeypair -v \
  -keystore ~/Documents/Project/workorder-signing/workorder-key.jks \
  -alias workorder \
  -keyalg RSA -keysize 2048 -validity 10000
```

`keytool` спросит пароль хранилища, пароль ключа и данные владельца. Пароли записываются в `~/Documents/Project/workorder-signing/key.properties`:

```properties
storeFile=workorder-key.jks
storePassword=<пароль хранилища>
keyAlias=workorder
keyPassword=<пароль ключа>
```

Строки только `key=value`, без Java-properties escape-последовательностей. `storeFile` может быть абсолютным путём или именем файла относительно каталога подписи.

Release-сборка читает этот каталог как `../workorder-signing` от корня проекта. Другой каталог задаётся так:

```bash
SIGNING_DIR=/absolute/path/workorder-signing bash prod_build/build_android_apk.sh release
```

Имя пакета приложения: `com.workorder`.

## Снять SHA-256

Отпечаток нужен для кабинета Яндекса (платформа Android) и для других сервисов, которые проверяют подпись приложения.

```bash
keytool -list -v \
  -keystore ~/Documents/Project/workorder-signing/workorder-key.jks \
  -alias workorder
```

В выводе нужна строка `SHA256:`. В кабинет её копируют целиком, вместе с двоеточиями, например `AA:BB:CC:...`.
