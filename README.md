# AIPD Assistant (Arizona RP Mesa)

Готовый комплект:
- `aipd_moonloader.lua` — MoonLoader скрипт с ImGui-окном по команде `/AIPD`.
- `server.js` — локальный AI API-сервер (`POST /chat`) для ответов.
- `package.json` — список Node.js зависимостей для сервера.
  `Если ии не отвечает меняйте модель у себя в sever.js в коде 398 строчка`
---

## 1) Куда кидать файлы

По вашему требованию, папка сервера:

`C:\PYTONFILE\aip\`

Итоговая структура должна быть такой:

```text
C:\PYTONFILE\aip\
  ├─ server.js
  ├─ package.json
  ├─ README.md
  └─ aipd.local.json      (создастся автоматически после первого запуска)
```

### Важно
- `package.json` должен лежать **в той же папке**, что и `server.js`.
- Команды `npm install` и `node server.js` запускать **из `C:\PYTONFILE\aip\`**.

---

## 2) Подробный запуск с нуля (Windows)

### Шаг 1. Установить Node.js
1. Скачайте и установите Node.js LTS: https://nodejs.org/
2. После установки откройте PowerShell и проверьте:

```powershell
node -v
npm -v
```

Если команды не найдены — перезапустите ПК или переоткройте PowerShell.

### Шаг 2. Подготовить папку

```powershell
mkdir C:\PYTONFILE\aip -Force
cd C:\PYTONFILE\aip
```

Скопируйте в эту папку файлы:
- `server.js`
- `package.json`
- (опционально) `README.md`

### Шаг 3. Установить зависимости

Находясь в `C:\PYTONFILE\aip` выполните:

```powershell
npm install
```

Ожидаемый результат: появится папка `node_modules` и файл `package-lock.json`.

### Шаг 4. Первый запуск сервера

```powershell
node server.js
```

При первом запуске сервер попросит API ключ в консоли:

```text
Первый запуск AIPD сервера: введите OPENAI API key.
API key:
```

Вставьте ключ и нажмите Enter.

После этого ключ сохранится в `aipd.local.json`, и повторно вводить его не нужно.

### Шаг 5. Проверить, что сервер работает

Оставьте окно PowerShell с сервером открытым и в другом окне выполните:

```powershell
curl http://127.0.0.1:3000/health
```

Должно вернуть:

```json
{"ok":true}
```

---

## 3) Быстрый запуск в следующий раз

Когда ключ уже сохранён:

```powershell
cd C:\PYTONFILE\aip
node server.js
```

---

## 4) Альтернатива: запуск через переменные окружения

Если не хотите хранить ключ в `aipd.local.json`, задайте переменную среды:

```powershell
$env:OPENAI_API_KEY="ВАШ_КЛЮЧ"
$env:OPENAI_MODEL="gpt-4.1-mini"
cd C:\PYTONFILE\aip
node server.js
```

> `OPENAI_API_KEY` из окружения имеет приоритет над ключом из файла.

---

## 5) Подключение MoonLoader скрипта

1. Скопируйте `aipd_moonloader.lua` в папку `moonloader` вашего клиента GTA SA / Arizona RP.
2. Убедитесь, что установлены Lua-библиотеки:
   - `mimgui`
   - `encoding`
   - `luasocket`
3. Запустите игру и зайдите на сервер.
4. Введите команду `/AIPD`.
5. В открывшемся окне:
   - введите вопрос,
   - нажмите `Отправить`,
   - получите ответ в этом же окне.
6. Кнопка `HELP` в GUI открывает поддержку: `https://t.me/sntney`.

---


## 6) Ручное обновление `aipd_moonloader.lua`

Автообновление убрано. Теперь обновление только вручную командой:

```text
/aiupdate
```

Что делает `/aiupdate`:
1. Скачивает `aipd_moonloader.lua` из GitHub репозитория:
   - `https://raw.githubusercontent.com/zxcqwaster/ArizonaRphelperPoliceMesa/main/aipd_moonloader.lua`
   - если не удалось, пробует `master` ветку.
2. Перезаписывает текущий локальный `aipd_moonloader.lua`.
3. Пытается автоматически перезагрузить скрипт.

Если перезагрузка не сработала — перезапустите MoonLoader/игру вручную.

---

## 7) Типичный порядок запуска перед игрой

1. Запустить `node server.js` в `C:\PYTONFILE\aip`.
2. Убедиться, что сервер поднялся (`AIPD server started on http://0.0.0.0:3000`).
3. Запустить игру.
4. В игре вызвать `/AIPD` и проверить ответ.

---

## 8) Частые проблемы и решения

### Проблема: `/AIPD` не отвечает / ошибка HTTP
- Проверьте, что `node server.js` реально запущен.
- Проверьте `http://127.0.0.1:3000/health`.
- Убедитесь, что порт `3000` не занят другим приложением.

### Проблема: `npm install` не работает
- Проверьте интернет/прокси.
- Проверьте версии Node/NPM: `node -v`, `npm -v`.
- Запускайте команду именно в папке с `package.json`.

### Проблема: попросил ключ снова
- Проверьте, создался ли `aipd.local.json` в `C:\PYTONFILE\aip`.
- Проверьте права на запись в папку.

### Проблема: окно открылось, но ответы пустые
- Проверьте правильность API ключа.
- Проверьте сообщения об ошибках в консоли, где запущен `node server.js`.

---

## 9) Команды для диагностики

```powershell
cd C:\PYTONFILE\aip
node -v
npm -v
npm install
node server.js
curl http://127.0.0.1:3000/health
```
