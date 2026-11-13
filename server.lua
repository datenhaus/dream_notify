-- =========================================================================
--  dream_notify · Server
--  SECURITY: this file registers NO network event. Players cannot trigger anything here.
--  The only way a player reaches this file is the /announce command, and its permission,
--  cooldown and text are checked right here on the server.
-- =========================================================================
local Num, Tbl = DreamNotify.Num, DreamNotify.Tbl
local lastAnnounce = {}        -- [player id] = os.time() of the last announcement

local function A() return Tbl(Config.Announce) end

-- ---------------------------------------------------------------- ESX (optional)
-- Fetched fresh when needed, so the start order and restarts of es_extended do not matter.
local function getESX()
    if GetResourceState('es_extended') ~= 'started' then return nil end
    local ok, obj = pcall(function() return exports['es_extended']:getSharedObject() end)
    if ok and type(obj) == 'table' then return obj end
    return nil
end

local function esxGroup(src)
    local esx = getESX()
    if not esx then return nil end
    local ok, group = pcall(function()
        local x = esx.GetPlayerFromId(src)
        if not x then return nil end
        if x.getGroup then return x.getGroup() end
        return x.group
    end)
    if ok and type(group) == 'string' then return group end
    return nil
end

-- May this player send announcements? Console (id 0) always may.
local function mayAnnounce(src)
    if src == 0 then return true end
    local ace = A().ace
    if type(ace) ~= 'string' or ace == '' then ace = 'dream_notify.announce' end
    if IsPlayerAceAllowed(tostring(src), ace) then return true end
    local groups = A().groups
    if type(groups) ~= 'table' then groups = { admin = true, superadmin = true } end   -- line deleted in the config: safe default
    local group = esxGroup(src)
    return group ~= nil and groups[group] == true
end

-- ---------------------------------------------------------------- Sending (server side)
-- target: player id, or -1 for all players
local function validTarget(target)
    target = tonumber(target)
    if not target then return nil end
    target = math.floor(target)
    if target == -1 then return -1 end
    if target < 1 then return nil end
    if GetPlayerName(tostring(target)) == nil then return nil end   -- not online
    return target
end

local function Notify(target, a, b, c, d)
    target = validTarget(target)
    if not target then return false end
    local ok, data = pcall(DreamNotify.Normalize, a, b, c, d)
    if not ok or type(data) ~= 'table' then return false end
    TriggerClientEvent('dream_notify:show', target, data)
    return true
end

-- data: 'text' or { message = '', title = '', sender = '', duration = 10000 }; target optional (default: all players)
local function Announce(data, target)
    if A().enabled == false then return false end
    target = validTarget(target == nil and -1 or target)
    if not target then return false end
    local ok, clean = pcall(DreamNotify.NormalizeAnnounce, data)
    if not ok or type(clean) ~= 'table' then return false end
    TriggerClientEvent('dream_notify:announce', target, clean)
    return true
end

-- Exports (server side):
--   exports['dream_notify']:Notify(source, { title = 'Bank', message = 'You received $500.', type = 'success' })
--   exports['dream_notify']:Notify(-1, { message = 'Server restart in 10 minutes.', type = 'warning' })   -- all players
--   exports['dream_notify']:Announce('Server restart in 10 minutes.')
exports('Notify', Notify)
exports('Announce', Announce)

-- The same as server events for scripts that do not want to use exports:
--   TriggerEvent('dream_notify:send', source, { message = 'Hello', type = 'info' })
--   TriggerEvent('dream_notify:sendAnnounce', 'Text')
-- These are LOCAL server events (AddEventHandler, not RegisterNetEvent): FiveM refuses them when a client sends them.
-- The extra check on "source" below is a second lock in case that ever changes.
local function fromClient()
    local s = tonumber(source)
    return s ~= nil and s > 0
end
AddEventHandler('dream_notify:send', function(target, a, b, c, d)
    if fromClient() then return end
    Notify(target, a, b, c, d)
end)
AddEventHandler('dream_notify:sendAnnounce', function(data, target)
    if fromClient() then return end
    Announce(data, target)
end)

-- ---------------------------------------------------------------- /announce <text>
local function reply(src, ntype, text)
    if src == 0 then
        print('[dream_notify] ' .. text)
    else
        TriggerClientEvent('dream_notify:show', src, { message = text, type = ntype, title = DreamNotify.L('announcement') })
    end
end

local function playerName(src)
    if src == 0 then return DreamNotify.L('console') end
    local ok, name = pcall(GetPlayerName, tostring(src))
    name = DreamNotify.Clean(ok and name or '', 40, false)
    if name == '' then name = '#' .. tostring(src) end
    return name
end

local function charCount(s)
    local n = nil
    if type(utf8) == 'table' and utf8.len then n = utf8.len(s) end
    return n or #s
end

local function announceCommand(source, args, raw)
    local src = math.floor(tonumber(source) or 0)
    local cfg = A()
    local cmd = (type(cfg.command) == 'string' and cfg.command ~= '') and cfg.command or 'announce'

    if not mayAnnounce(src) then
        reply(src, 'error', DreamNotify.L('no_permission'))
        return
    end

    -- text: everything behind the command name (keeps quotes); fallback: the split arguments
    local text = nil
    if type(raw) == 'string' then text = raw:match('^%s*%S+%s+(.+)$') end
    if not text and type(args) == 'table' then
        local parts = {}
        for i = 1, #args do parts[#parts + 1] = tostring(args[i]) end
        text = table.concat(parts, ' ')
    end
    local minLen = math.floor(Num(cfg.minLength, 3, 1, 100))
    local maxLen = math.floor(Num(cfg.maxLength, 200, 10, 1000))
    -- clean first (control characters, colour codes, line breaks, double spaces), then check the length
    text = DreamNotify.Clean(text, maxLen + 1, false)

    if text == '' then
        reply(src, 'info', DreamNotify.L('usage', cmd))
        return
    end
    local len = charCount(text)
    if len < minLen then
        reply(src, 'error', DreamNotify.L('too_short', minLen))
        return
    end
    if len > maxLen then
        reply(src, 'error', DreamNotify.L('too_long', maxLen))
        return
    end

    -- cooldown per player (the console has none)
    local cooldown = math.floor(Num(cfg.cooldown, 15, 0, 3600))
    local now = os.time()
    if src ~= 0 and cooldown > 0 then
        local last = lastAnnounce[src]
        if last and (now - last) < cooldown then
            reply(src, 'warning', DreamNotify.L('cooldown', cooldown - (now - last)))
            return
        end
        lastAnnounce[src] = now
    end

    local name = playerName(src)
    local data = { message = text, duration = cfg.duration }
    if cfg.showSender ~= false then data.sender = name end
    if not Announce(data, -1) then return end

    if cfg.log ~= false then
        print(('[dream_notify] announcement by %s (id %d): %s'):format(name, src, text))
    end
    reply(src, 'success', DreamNotify.L('sent'))
end

if A().enabled ~= false then
    local cmd = A().command
    if type(cmd) ~= 'string' or cmd == '' or not cmd:match('^[%w_%-]+$') then cmd = 'announce' end
    -- "false" = not restricted by FiveM itself, because the permission is checked above (ESX group or ACE)
    RegisterCommand(cmd, function(source, args, raw)
        local ok, err = pcall(announceCommand, source, args, raw)
        if not ok then print('[dream_notify] announce command failed: ' .. tostring(err)) end
    end, false)
end

AddEventHandler('playerDropped', function()
    local src = tonumber(source)
    if src then lastAnnounce[src] = nil end
end)
