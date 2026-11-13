-- =========================================================================
--  dream_notify · Client
--  Shows toasts and announcements in the NUI. Never takes mouse or keyboard focus.
--  The client sends NOTHING to the server (there is no client -> server event in this script).
-- =========================================================================
local ready = false            -- true once the NUI page has loaded and asked for its settings
local pending = {}             -- messages that arrived before the NUI was ready
local lastKey, lastAt = nil, 0 -- duplicate filter

local Num, Tbl = DreamNotify.Num, DreamNotify.Tbl

local function nuiInit()
    local A, S, T, C = Tbl(Config.Announce), Tbl(Config.Sound), Tbl(Config.Theme), Tbl(Config.Colors)
    SendNUIMessage({
        action = 'init',
        config = {
            position        = tostring(Config.Position or 'top-right'),
            offsetX         = Num(Config.OffsetX, 24, 0, 600),
            offsetY         = Num(Config.OffsetY, 24, 0, 600),
            scale           = Num(Config.Scale, 1.0, 0.6, 1.6),
            maxVisible      = math.floor(Num(Config.MaxVisible, 4, 1, 8)),
            maxQueue        = math.floor(Num(Config.MaxQueue, 30, 0, 200)),
            sound           = S.enabled ~= false,
            volume          = Num(S.volume, 0.25, 0, 1),
            reducedMotion   = Config.ReducedMotion == true,
            showBadge       = T.showBadge ~= false,
            announcePosition = tostring(A.position or 'top'),
            announceSound   = A.sound ~= false,
            colors          = { info = C.info, success = C.success, warning = C.warning, error = C.error },
        },
        theme = { primary = T.primary or T.accent, background = T.background, text = T.text, logoText = T.logoText, serverName = T.serverName },
        texts = { announcement = DreamNotify.L('announcement'), by = DreamNotify.L('by', '%s') },
    })
end

local function flush()
    local list = pending
    pending = {}
    for i = 1, #list do SendNUIMessage(list[i]) end
end

local function push(msg)
    if ready then
        SendNUIMessage(msg)
    elseif #pending < 20 then
        pending[#pending + 1] = msg
    end
end

-- ---------------------------------------------------------------- Toast
local function Notify(a, b, c, d)
    local ok, data = pcall(DreamNotify.Normalize, a, b, c, d)
    if not ok or type(data) ~= 'table' then return false end
    local window = Num(Config.DedupeMs, 300, 0, 10000)
    if window > 0 then
        local key = data.type .. '|' .. data.title .. '|' .. data.message
        local now = GetGameTimer()
        if key == lastKey and (now - lastAt) < window then return false end
        lastKey, lastAt = key, now
    end
    push({ action = 'notify', data = data })
    return true
end

-- ---------------------------------------------------------------- Announcement banner
local function Announce(a)
    if Tbl(Config.Announce).enabled == false then return false end
    local ok, data = pcall(DreamNotify.NormalizeAnnounce, a)
    if not ok or type(data) ~= 'table' then return false end
    push({ action = 'announce', data = data })
    return true
end

-- remove all toasts and the banner
local function Clear()
    pending = {}
    if ready then SendNUIMessage({ action = 'clear' }) end
    return true
end

-- Exports (client side):
--   exports['dream_notify']:Notify({ title = 'Garage', message = 'Vehicle stored.', type = 'success', duration = 5000, icon = 'car' })
--   exports['dream_notify']:Announce('Text')   -- banner for this player only
--   exports['dream_notify']:Clear()
exports('Notify', Notify)
exports('Announce', Announce)
exports('Clear', Clear)

-- Events sent by the server side of this resource (server.lua). A client cannot send these to other clients:
-- FiveM only delivers client events from the server or from scripts running on the same PC.
RegisterNetEvent('dream_notify:show', function(a, b, c, d) Notify(a, b, c, d) end)
RegisterNetEvent('dream_notify:announce', function(a) Announce(a) end)
RegisterNetEvent('dream_notify:clear', function() Clear() end)

-- ---------------------------------------------------------------- NUI
RegisterNUICallback('ready', function(_, cb)
    ready = true
    nuiInit()
    flush()
    cb({ ok = true })
end)

-- Safety net: if the page never reports "ready" (very slow PC), send the settings anyway after 10 seconds
CreateThread(function()
    Wait(10000)
    if not ready then
        ready = true
        nuiInit()
        flush()
    end
end)

-- ---------------------------------------------------------------- ESX override (optional, Config.EsxOverride)
if Config.EsxOverride == true then
    -- 1) notifications the server sends through ESX (xPlayer.showNotification)
    RegisterNetEvent('esx:showNotification', function(message, ntype, length, title)
        Notify({ message = message, type = ntype, duration = length, title = title })
    end)
    -- 2) client scripts calling ESX.ShowNotification: ESX forwards them to exports['esx_notify']:Notify(type, length, message).
    --    This answers that export while the resource esx_notify is stopped.
    AddEventHandler('__cfx_export_esx_notify_Notify', function(setCB)
        if type(setCB) == 'function' or type(setCB) == 'table' then
            setCB(function(ntype, length, message, title)
                Notify({ message = message, type = ntype, duration = length, title = title })
            end)
        end
    end)
    -- If both ways deliver the same text, the duplicate filter (Config.DedupeMs) shows it only once.
end

-- ---------------------------------------------------------------- Test command (only the player himself sees the toasts)
if type(Config.TestCommand) == 'string' and Config.TestCommand ~= '' then
    RegisterCommand(Config.TestCommand, function()
        local i = 0
        for _, t in ipairs({ 'info', 'success', 'warning', 'error' }) do
            i = i + 1
            push({ action = 'notify', data = DreamNotify.Normalize({ message = DreamNotify.L('test_' .. t), type = t, duration = 5000 + i * 500 }) })
        end
    end, false)
end

-- ---------------------------------------------------------------- Chat suggestion for /announce (harmless if the chat resource is missing)
CreateThread(function()
    local A = Tbl(Config.Announce)
    if A.enabled == false then return end
    local cmd = (type(A.command) == 'string' and A.command ~= '') and A.command or 'announce'
    Wait(2000)
    TriggerEvent('chat:addSuggestion', '/' .. cmd, DreamNotify.L('suggestion'), { { name = DreamNotify.L('suggestion_text'), help = '' } })
end)
