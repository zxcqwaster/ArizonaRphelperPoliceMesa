const fs = require('fs');
const path = require('path');
const readline = require('readline');
const express = require('express');
const OpenAI = require('openai');

const app = express();
const port = Number(process.env.PORT || 3000);
const configPath = path.join(__dirname, 'aipd.local.json');

function readStoredConfig() {
  try {
    if (!fs.existsSync(configPath)) {
      return {};
    }

    const raw = fs.readFileSync(configPath, 'utf8');
    const parsed = JSON.parse(raw);
    return typeof parsed === 'object' && parsed ? parsed : {};
  } catch (error) {
    console.warn('Failed to read aipd.local.json:', error.message);
    return {};
  }
}

function storeConfig(config) {
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf8');
}

function askHidden(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

async function resolveApiKey() {
  if (process.env.OPENAI_API_KEY) {
    return process.env.OPENAI_API_KEY.trim();
  }

  const stored = readStoredConfig();
  if (stored.openaiApiKey) {
    return String(stored.openaiApiKey).trim();
  }

  console.log('Первый запуск AIPD сервера: введите OPENAI API key.');
  const key = await askHidden('API key: ');

  if (!key) {
    return '';
  }

  storeConfig({ ...stored, openaiApiKey: key });
  console.log('Ключ сохранен в aipd.local.json (локально).');
  return key;
}

const SYSTEM_PROMPT = `Ты — ИИ-помощник сотрудника полиции Arizona RP Mesa.
Отвечай коротко, по делу, на русском языке.
Если вопрос связан с уставом/ЕФК — опирайся на предоставленную базу знаний.
Если данных недостаточно — прямо скажи, что нужен фрагмент правил/доказательства.
Не придумывай несуществующие статьи.
Всегда предлагай безопасный и законный с точки зрения сервера вариант действий.`;

const KNOWLEDGE_BASE = `
Краткая база знаний Arizona RP Mesa (МЮ):
- Устав обязателен для всех сотрудников МЮ; незнание не освобождает от ответственности.
- Задержание: представиться, назвать причину, зачитать Миранду.
- Стадии силы: присутствие -> устное предупреждение -> физическая сила -> спецсредства -> оружие.
- В погоне по ТС: перед стрельбой по колёсам нужно 3 предупреждения в мегафон с интервалом ~10 сек.
- Запрещено выдавать розыск без доказательств и без RP-отыгровок.
- Запрещено выдавать розыск игроку в маске, если не видели его без маски (кроме кейсов уголовного дела).
- По правилам обыска: обыск только при наличии оснований (задержание, арест, допрос, посты/проверки и иные регламентные случаи).
- Юрисдикции: нельзя пересекать чужую без причины; исключения — ЧС, активная погоня, общая юрисдикция и др.
- ФБР работает по всему штату; может иметь отдельные полномочия и ограничения для ПД/ТСР.
- Для спорных случаев по наказаниям/розыску нужны видеодоказательства и /time.
- Вежливость обязательна при общении с гражданами, подозреваемыми и руководством.
- Ключевые тэн-коды: 10-15 арест, 10-46 обыск, 10-57 VICTOR авто-погоня, 10-57 FOXTROT пешая погоня, 10-99 ситуация урегулирована.
- Примеры ЕФК:
  * 8.1 Неподчинение сотруднику при исполнении — 4 уровень розыска.
  * 1.1 Нападение на гражданское лицо — 3 уровень.
  * 1.2 Нападение на сотрудника — 6 уровень.
  * 3.1 Убийство — 6 уровень.
  * 4.1 Попытка угона — 2 уровень, 4.2 Угон — 4 уровень.
  * 6.2 Хранение оружия без лицензии — 6 уровень.
  * 10.1 Хранение наркотических веществ — 3 уровень (10.1.2 крупный размер 30+ — 5 уровень).
  * 20.1 Отказ предоставить документы — 2 уровень.
`;

async function start() {
  const apiKey = await resolveApiKey();
  if (!apiKey) {
    console.error('API ключ не задан. Укажите OPENAI_API_KEY или введите его на первом запуске.');
    process.exit(1);
  }

  const client = new OpenAI({ apiKey });

  app.use(express.json({ limit: '2mb' }));

  app.get('/health', (_, res) => {
    res.json({ ok: true });
  });

  app.post('/chat', async (req, res) => {
    try {
      const question = String(req.body?.question || '').trim();

      if (!question) {
        return res.status(400).json({ error: 'question is required' });
      }

      const response = await client.responses.create({
        model: process.env.OPENAI_MODEL || 'gpt-4.1-mini',
        input: [
          { role: 'system', content: SYSTEM_PROMPT },
          { role: 'system', content: KNOWLEDGE_BASE },
          { role: 'user', content: question }
        ],
        temperature: 0.2,
        max_output_tokens: 400
      });

      const answer = response.output_text?.trim() || 'Не удалось сформировать ответ.';
      return res.json({ answer });
    } catch (error) {
      console.error('Chat error:', error);
      return res.status(500).json({
        error: 'internal_error',
        details: error?.message || String(error)
      });
    }
  });

  app.listen(port, '0.0.0.0', () => {
    console.log(`AIPD server started on http://0.0.0.0:${port}`);
  });
}

start();
