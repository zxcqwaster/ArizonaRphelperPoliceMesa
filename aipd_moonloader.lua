script_name('AIPD Assistant')
script_author('zxcqwaster')
script_version('1.2.0')

local ffi = require('ffi')
local imgui = require('mimgui')
local encoding = require('encoding')
local http = require('socket.http')
local ltn12 = require('ltn12')

encoding.default = 'CP1251'
u8 = encoding.UTF8

local windowState = imgui.new.bool(false)
local inputBuffer = imgui.new.char[2048]()
local questionHistory = ''
local answerText = 'Готов к работе. Введите вопрос и нажмите "Отправить".'
local waiting = false

local SERVER_URL = 'http://127.0.0.1:3000/chat'

-- Ручное обновление с GitHub репозитория (команда /aiupdate)
local AIPD_UPDATE_URLS = {
  'https://raw.githubusercontent.com/zxcqwaster/ArizonaRphelperPoliceMesa/main/aipd_moonloader.lua',
  'https://raw.githubusercontent.com/zxcqwaster/ArizonaRphelperPoliceMesa/master/aipd_moonloader.lua'
}

local function trimZero(str)
  local zeroPos = str:find('\0')
  if zeroPos then
    return str:sub(1, zeroPos - 1)
  end
  return str
end

local function httpGet(url)
  local responseBody = {}
  local _, code = http.request {
    method = 'GET',
    url = url,
    sink = ltn12.sink.table(responseBody)
  }

  if code ~= 200 then
    return false, ('HTTP %s'):format(tostring(code))
  end

  return true, table.concat(responseBody)
end

local function getSelfPath()
  local ok, script = pcall(thisScript)
  if ok and script and script.path then
    return script.path
  end

  local src = debug.getinfo(1, 'S').source
  if src and src:sub(1, 1) == '@' then
    return src:sub(2)
  end

  return nil
end

local function writeFile(path, content)
  local f, err = io.open(path, 'wb')
  if not f then
    return false, err or 'open_error'
  end

  f:write(content)
  f:close()
  return true
end

local function restartCurrentScript()
  local ok, script = pcall(thisScript)
  if ok and script and script.reload then
    script:reload()
    return true
  end

  return false
end

local function parseVersionFromScript(content)
  local ver = content:match("script_version%('([%d%.]+)'%)")
  return ver or 'unknown'
end

local function downloadRemoteScript()
  for _, url in ipairs(AIPD_UPDATE_URLS) do
    local ok, content = httpGet(url)
    if ok then
      return true, content, url
    end
  end

  return false, 'Не удалось скачать файл обновления из GitHub (main/master).'
end

local function manualUpdateFromGitHub()
  local currentVersion = thisScript().version

  local ok, remoteScript, sourceUrl = downloadRemoteScript()
  if not ok then
    sampAddChatMessage('[AIPD] ' .. tostring(remoteScript), -1)
    return
  end

  if not remoteScript:find("script_name%('AIPD Assistant'%)") then
    sampAddChatMessage('[AIPD] Загруженный файл не похож на aipd_moonloader.lua', -1)
    return
  end

  local selfPath = getSelfPath()
  if not selfPath then
    sampAddChatMessage('[AIPD] Не удалось определить путь к текущему скрипту.', -1)
    return
  end

  local saved, saveErr = writeFile(selfPath, remoteScript)
  if not saved then
    sampAddChatMessage('[AIPD] Ошибка сохранения обновления: ' .. tostring(saveErr), -1)
    return
  end

  local remoteVersion = parseVersionFromScript(remoteScript)
  sampAddChatMessage(('[AIPD] Обновление загружено из GitHub (%s). %s -> %s'):format(sourceUrl, currentVersion, remoteVersion), -1)
  sampAddChatMessage('[AIPD] Перезагружаю скрипт...', -1)

  if not restartCurrentScript() then
    sampAddChatMessage('[AIPD] Не удалось перезагрузить автоматически. Перезапустите MoonLoader вручную.', -1)
  end
end


local function openHelpLink()
  local url = 'https://t.me/sntney'
  local cmd = ('start "" "%s"'):format(url)
  local ok = os.execute(cmd)

  if not ok then
    sampAddChatMessage('[AIPD] Не удалось открыть ссылку. Откройте вручную: ' .. url, -1)
  end
end

local function postQuestion(question)
  local payload = encodeJson({ question = question })
  local responseBody = {}

  local _, code = http.request {
    method = 'POST',
    url = SERVER_URL,
    headers = {
      ['Content-Type'] = 'application/json',
      ['Content-Length'] = tostring(#payload)
    },
    source = ltn12.source.string(payload),
    sink = ltn12.sink.table(responseBody)
  }

  if code ~= 200 then
    return false, ('Ошибка сервера. HTTP: %s'):format(tostring(code))
  end

  local decoded = decodeJson(table.concat(responseBody))
  if not decoded or not decoded.answer then
    return false, 'Некорректный ответ от AI-сервера.'
  end

  return true, tostring(decoded.answer)
end

function main()
  repeat wait(0) until isSampAvailable()

  sampRegisterChatCommand('AIPD', function()
    windowState[0] = not windowState[0]
  end)

  sampRegisterChatCommand('aiupdate', function()
    lua_thread.create(function()
      manualUpdateFromGitHub()
    end)
  end)

  while true do
    wait(0)
  end
end

imgui.OnFrame(
  function() return windowState[0] end,
  function()
    imgui.SetNextWindowSize(imgui.ImVec2(720, 500), imgui.Cond.FirstUseEver)
    imgui.Begin(u8'AI помощник полиции Arizona RP Mesa (/AIPD)', windowState)

    imgui.TextWrapped(u8'Задайте вопрос по уставу, ЕФК, задержанию, погоне, трафик-стопу и т.д.')
    imgui.TextWrapped(u8'Ручное обновление скрипта: /aiupdate')
    imgui.TextWrapped(u8'Тех. поддержка: кнопка HELP или https://t.me/sntney')
    imgui.Separator()

    imgui.Text(u8'Ваш вопрос:')
    imgui.InputTextMultiline('##aipd_question', inputBuffer, ffi.sizeof(inputBuffer), imgui.ImVec2(-1, 110))

    if waiting then
      imgui.BeginDisabled()
    end

    if imgui.Button(u8'Отправить', imgui.ImVec2(140, 0)) then
      local question = trimZero(ffi.string(inputBuffer))
      question = question:gsub('^%s+', ''):gsub('%s+$', '')

      if question == '' then
        answerText = 'Введите вопрос перед отправкой.'
      else
        waiting = true
        answerText = 'Думаю над ответом...'
        questionHistory = question

        lua_thread.create(function()
          local _, result = postQuestion(question)
          answerText = result
          waiting = false
        end)
      end
    end

    imgui.SameLine()
    if imgui.Button(u8'Очистить', imgui.ImVec2(140, 0)) then
      inputBuffer[0] = 0
      questionHistory = ''
      answerText = 'Очищено.'
    end

    imgui.SameLine()
    if imgui.Button(u8'HELP', imgui.ImVec2(120, 0)) then
      openHelpLink()
    end

    if waiting then
      imgui.EndDisabled()
    end

    imgui.Separator()
    imgui.Text(u8'Последний вопрос:')
    imgui.TextWrapped(u8(questionHistory ~= '' and questionHistory or '—'))

    imgui.Separator()
    imgui.Text(u8'Ответ AI:')
    imgui.BeginChild('##answer_zone', imgui.ImVec2(0, 170), true)
    imgui.TextWrapped(u8(answerText))
    imgui.EndChild()

    imgui.End()
  end
)
