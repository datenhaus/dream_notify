-- =========================================================================
--  dream_notify · Shared helpers (client + server)
--  Everything that enters the script (exports, events, commands) is cleaned here first:
--  wrong types are dropped, texts are cut, control characters are removed, numbers are clamped.
-- =========================================================================
DreamNotify = {}

if type(Config) ~= 'table' then Config = {} end      -- config.lua broken/missing: run with built-in defaults
if type(Locales) ~= 'table' then Locales = {} end

local TYPES = {
    info = 'info', success = 'success', warning = 'warning', error = 'error',
    -- common names used by other notify resources
    inform = 'info', primary = 'info', warn = 'warning', danger = 'error', fail = 'error', failed = 'error', ok = 'success',
}

-- Built-in English texts, used only if locales.lua is missing or a text was deleted there
local FALLBACK = {
    title_info = 'Info', title_success = 'Success', title_warning = 'Warning', title_error = 'Error',
    announcement = 'Announcement', by = 'by %s', console = 'Console',
    no_permission = 'You are not allowed to use this command.',
    cooldown = 'Please wait %d seconds before the next announcement.',
    usage = 'Usage: /%s <text>',
    too_short = 'The text is too short (at least %d characters).',
    too_long = 'The text is too long (at most %d characters).',
    sent = 'Announcement sent to all players.',
    suggestion = 'Send an announcement to all players', suggestion_text = 'text',
    test_info = 'This is an info notification.', test_success = 'Everything worked.',
    test_warning = 'Please be careful.', test_error = 'Something went wrong.',
}

-- number with default and limits (never returns nil / NaN)
function DreamNotify.Num(v, def, min, max)
    v = tonumber(v)
    if not v or v ~= v then v = def end
    if min and v < min then v = min end
    if max and v > max then v = max end
    return v
end

-- config sub-table or an empty table
function DreamNotify.Tbl(v)
    if type(v) == 'table' then return v end
    return {}
end

-- cut a text to max characters without breaking a multi-byte (UTF-8) character
local function truncate(s, max)
    if #s <= max then return s end                    -- bytes <= max means characters <= max
    local len = nil
    if type(utf8) == 'table' and utf8.len then len = utf8.len(s) end
    if not len then                                   -- invalid UTF-8 (or no utf8 library): keep plain ASCII only
        s = s:gsub('[\128-\255]', '')
        return s:sub(1, max)
    end
    if len <= max then return s end
    local cut = utf8.offset(s, max + 1)
    if cut then return s:sub(1, cut - 1) end
    return s
end

-- any value -> safe text. Returns '' for nil / tables / functions.
function DreamNotify.Clean(v, max, keepNewlines)
    local t = type(v)
    if t == 'number' or t == 'boolean' then v = tostring(v) elseif t ~= 'string' then return '' end
    if #v > 4000 then v = v:sub(1, 4000) end          -- hard cap before any pattern work
    v = v:gsub('\r\n', '\n'):gsub('\r', '\n')
    if keepNewlines then
        v = v:gsub('[^\n%C]', ' ')                    -- control characters except line breaks -> space
        v = v:gsub('\n\n\n+', '\n\n')
    else
        v = v:gsub('%c', ' ')
    end
    if Config.StripColorCodes ~= false then
        v = v:gsub('~[%a_][%w_]*~', '')               -- ~r~  ~INPUT_CONTEXT~
        v = v:gsub('%^%d', '')                        -- ^1
    end
    v = v:gsub('[ \t]+', ' ')
    v = v:gsub('^%s+', ''):gsub('%s+$', '')
    v = truncate(v, DreamNotify.Num(max, 400, 1, 2000))
    return v
end

function DreamNotify.Type(v)
    if type(v) == 'string' then
        local t = TYPES[v:lower()]
        if t then return t end
    end
    return TYPES[Config.DefaultType] or 'info'
end

-- text from locales.lua (falls back to English, then to the key itself)
function DreamNotify.L(key, ...)
    local set = Locales[Config.Locale]
    if type(set) ~= 'table' then set = Locales.en end
    if type(set) ~= 'table' then set = {} end
    local s = set[key]
    if type(s) ~= 'string' and type(Locales.en) == 'table' then s = Locales.en[key] end
    if type(s) ~= 'string' then s = FALLBACK[key] end
    if type(s) ~= 'string' then s = tostring(key) end
    if select('#', ...) > 0 then
        local ok, out = pcall(string.format, s, ...)
        if ok then return out end
    end
    return s
end

-- Accepts every supported call style and returns one clean table or nil (nothing to show):
--   Notify({ title = '', message = '', type = '', duration = 5000, icon = '' })   (description / text also work for message)
--   Notify('message', 'type', duration, 'title')                                   (ESX.ShowNotification order)
--   Notify('type', duration, 'message', 'title')                                   (esx_notify order)
function DreamNotify.Normalize(a, b, c, d)
    local title, message, ntype, duration, icon
    if type(a) == 'table' then
        title, ntype, duration, icon = a.title, a.type, a.duration, a.icon
        message = a.message
        if message == nil then message = a.description end
        if message == nil then message = a.text end
        if message == nil then message = a.msg end
    elseif type(a) == 'string' and type(b) == 'number' and (type(c) == 'string' or type(c) == 'number') then
        ntype, duration, message, title = a, b, c, d
    else
        message, ntype, duration, title = a, b, c, d
    end
    title = DreamNotify.Clean(title, DreamNotify.Num(Config.MaxTitleLength, 60, 1, 200), false)
    message = DreamNotify.Clean(message, DreamNotify.Num(Config.MaxMessageLength, 400, 1, 2000), true)
    if title == '' and message == '' then return nil end
    ntype = DreamNotify.Type(ntype)
    if title == '' and Config.DefaultTitles ~= false then title = DreamNotify.L('title_' .. ntype) end
    local minD = DreamNotify.Num(Config.MinDuration, 1500, 500, 60000)
    local maxD = DreamNotify.Num(Config.MaxDuration, 30000, minD, 120000)
    duration = math.floor(DreamNotify.Num(duration, DreamNotify.Num(Config.DefaultDuration, 5000, minD, maxD), minD, maxD))
    if type(icon) == 'string' and #icon <= 24 and icon:match('^[%w_%-]+$') then icon = icon:lower() else icon = nil end
    return { title = title, message = message, type = ntype, duration = duration, icon = icon }
end

-- Announcement: 'text' or { message = '', title = '', sender = '', duration = 10000 } -> clean table or nil
function DreamNotify.NormalizeAnnounce(a)
    local A = DreamNotify.Tbl(Config.Announce)
    local message, title, sender, duration
    if type(a) == 'table' then
        message, title, sender, duration = a.message, a.title, a.sender, a.duration
        if message == nil then message = a.text end
    else
        message = a
    end
    -- the display limit is a bit above the command limit so that exports may send slightly longer texts
    message = DreamNotify.Clean(message, DreamNotify.Num(A.maxLength, 200, 10, 1000) + 200, true)
    if message == '' then return nil end
    title = DreamNotify.Clean(title, 60, false)
    sender = DreamNotify.Clean(sender, 40, false)
    duration = math.floor(DreamNotify.Num(duration, DreamNotify.Num(A.duration, 10000, 3000, 60000), 3000, 60000))
    return { message = message, title = title ~= '' and title or nil, sender = sender ~= '' and sender or nil, duration = duration }
end
