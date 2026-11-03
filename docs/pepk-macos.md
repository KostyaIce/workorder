# PEPK на macOS: экспорт ключа для Google Play

PEPK (Play Encrypt Private Key) — утилита Google Play, которая зашифрованно
экспортирует существующий ключ подписи приложения и готовит ZIP для загрузки в
Play Console.

## Когда нужен PEPK

PEPK нужен, если:

- вы подключаете **Play App Signing** для уже существующего приложения;
- вы хотите передать в Google свой текущий ключ как **ключ подписи приложения**;
- Play Console предлагает «Export and upload a key from Java keystore» или
  «Предоставить копию ключа подписи приложения».

PEPK **не нужен**:

- для обычной загрузки AAB в Google Play;
- если Google сам генерирует ключ подписи приложения;
- для RuStore, F-Droid или прямой установки APK.

## Что понадобится

- macOS;
- JDK 17 или 21 (`java` и `keytool` должны работать в терминале);
- ваш keystore, например:
  `$HOME/Documents/Project/workorder-signing/workorder-key.jks`;
- alias ключа, обычно `workorder`;
- доступ администратора в Play Console.

Проверить Java:

```bash
java -version
keytool -help | head
```

## Что скачать

Скачивать нужно **только из Play Console**, на странице:

**Play Console → Защищено Google Play → Распространение в Google Play →
Подписание приложений в Google Play**.

Там будут две кнопки:

- **Download PEPK tool** — скачает `pepk.jar`;
- **Download encryption public key** — скачает `encryption_public_key.pem`.

Обычно файлы попадают в `~/Downloads`.

> Не берите `pepk.jar` со сторонних сайтов. Используйте файл из Play Console.

## Пошаговая инструкция

### 1. Откройте настройки подписания

В Play Console откройте своё приложение и перейдите:

**Защищено Google Play → Распространение в Google Play → Подписание
приложений в Google Play**.

Выберите вариант с загрузкой существующего ключа из Java keystore.

### 2. Скачайте файлы

Нажмите:

- **Download PEPK tool**;
- **Download encryption public key**.

Проверьте, что файлы на месте:

```bash
ls -lh ~/Downloads/pepk.jar ~/Downloads/encryption_public_key.pem
```

### 3. Подготовьте пути

Для этого проекта ключ обычно лежит здесь:

```text
$HOME/Documents/Project/workorder-signing/workorder-key.jks
```

Alias: `workorder`.

Выходной ZIP лучше положить рядом с ключом, но **не в git**:

```text
$HOME/Documents/Project/workorder-signing/workorder-play-signing.zip
```

### 4. Запустите PEPK

Выполните в терминале:

```bash
java -jar "$HOME/Downloads/pepk.jar" \
  --keystore="$HOME/Documents/Project/workorder-signing/workorder-key.jks" \
  --alias=workorder \
  --output="$HOME/Documents/Project/workorder-signing/workorder-play-signing.zip" \
  --include-cert \
  --rsa-aes-encryption \
  --encryption-key-path="$HOME/Downloads/encryption_public_key.pem"
```

PEPK запросит два пароля:

```text
Enter password for store '...workorder-key.jks':
Enter password for key 'workorder':
```

Введите пароль хранилища и пароль ключа из
`../workorder-signing/key.properties`.

Пароли не сохраняются в истории, если вводить их в ответ на запрос PEPK.

### 5. Проверьте результат

```bash
ls -lh "$HOME/Documents/Project/workorder-signing/workorder-play-signing.zip"
```

Должен появиться ZIP-файл.

### 6. Загрузите ZIP в Play Console

Вернитесь в Play Console на страницу настройки подписания приложений и нажмите
**Upload generated ZIP** / **Загрузить сгенерированный ZIP**. Выберите
`workorder-play-signing.zip`.

После загрузки Google расшифрует ключ у себя и будет использовать его как ключ
подписи приложения.

## Важно про ключи

При Play App Signing используются два ключа:

- **Upload key** — им вы подписываете AAB перед загрузкой. Он остаётся у вас.
- **App signing key** — им Google подписывает APK для пользователей. Именно его
  вы передаёте через PEPK, если хотите использовать свой существующий ключ.

Не теряйте:

- `workorder-key.jks`;
- пароли к нему;
- резервную копию ключа.

PEPK-архив `workorder-play-signing.zip` содержит зашифрованный приватный ключ.
Не публикуйте его и не пересылайте никому, кроме загрузки в Play Console.

## Частые ошибки

### `Unable to access jarfile pepk.jar`

Укажите полный путь:

```bash
java -jar "$HOME/Downloads/pepk.jar" ...
```

### `keystore password was incorrect`

Проверьте `storePassword` в `key.properties` и введите его без пробелов.

### `Alias <...> does not exist`

Проверьте alias в `key.properties`. Для WorkOrder обычно `workorder`.

### `encryption_public_key.pem` не найден

Скачайте файл заново из Play Console и укажите правильный путь в
`--encryption-key-path`.

### PEPK не запускается на новой Java

Используйте JDK 17 или 21:

```bash
/usr/libexec/java_home -V
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
export PATH="$JAVA_HOME/bin:$PATH"
```
