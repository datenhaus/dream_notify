-- =========================================================================
--  dream_notify · Notifications & announcements · Config (shared: client + server)
--  FREE script by DreamScripts. No database. es_extended is optional.
--  Every value has a safe built-in default: if you delete a line, the script still runs.
-- =========================================================================
Config = {}

Config.Locale = 'en'              -- language of the built-in texts: 'en' | 'de' (texts: locales.lua)

-- ---------------------------------------------------------------- Toasts (small notifications)
-- Where the stack appears: 'top-right' | 'top-left' | 'top-center' | 'bottom-right' | 'bottom-left' | 'bottom-center'
Config.Position   = 'top-right'
Config.OffsetX    = 24            -- distance to the left/right screen edge (pixels at 1080p, scales with the resolution)
Config.OffsetY    = 24            -- distance to the top/bottom screen edge (pixels at 1080p)
Config.Scale      = 1.0           -- size of everything: 0.8 = smaller, 1.2 = bigger (allowed 0.6 - 1.6)
Config.MaxVisible = 4             -- how many toasts are visible at once (1 - 8); more are queued
Config.MaxQueue   = 30            -- how many toasts may wait in the queue; when full, the oldest waiting one is dropped

Config.DefaultType     = 'info'   -- type used when none is given: 'info' | 'success' | 'warning' | 'error'
Config.DefaultDuration = 5000     -- how long a toast stays (ms) when no duration is given
Config.MinDuration     = 1500     -- shortest allowed duration (ms)
Config.MaxDuration     = 30000    -- longest allowed duration (ms)
Config.DefaultTitles   = true     -- true = toasts without a title get "Info" / "Success" / ... (texts: locales.lua)

Config.MaxTitleLength   = 60      -- longer titles are cut
Config.MaxMessageLength = 400     -- longer messages are cut
Config.StripColorCodes  = true    -- remove GTA/FiveM colour codes like ~r~ or ^1 from texts (they would show as plain characters)
Config.DedupeMs         = 300     -- ignore the exact same toast if it arrives again within this time (ms); 0 = off

-- ---------------------------------------------------------------- Sound
-- No audio files: the UI plays a tiny generated beep.
Config.Sound = {
    enabled = true,               -- false = silent
    volume  = 0.25,               -- 0.0 - 1.0
}

-- true = never use slide animations (players whose Windows has animations switched off get this automatically)
Config.ReducedMotion = false

-- ---------------------------------------------------------------- Theme (colours & logo)
Config.Theme = {
    primary    = '#F5C400',             -- primary colour (hex, #RRGGBB): info toasts, announcement banner, logo badge
    background = 'rgba(13,13,15,0.92)', -- card background (any CSS colour, rgba() for transparency)
    text       = '#F4F2EA',             -- main text colour (hex, #RRGGBB)
    logoText   = 'DS',                  -- 1-3 letters, rendered as a logo badge in the primary colour (no image needed)
    serverName = 'Your Server',         -- shown on the announcement banner
    showBadge  = true,                  -- true = small logo badge on every toast; false = only on announcements
}

-- Colours of the four types (hex, #RRGGBB). '' = use the primary colour.
Config.Colors = {
    info    = '',
    success = '#3DDC84',
    warning = '#FF8A1F',
    error   = '#FF4D4D',
}

-- ---------------------------------------------------------------- ESX (optional)
-- false (default) = ESX keeps using its own notification resource.
-- true = notifications sent through ESX (ESX.ShowNotification / xPlayer.showNotification) are shown by this script.
--        IMPORTANT: stop the resource "esx_notify" when you turn this on (see README, section "ESX override").
Config.EsxOverride = false

-- ---------------------------------------------------------------- Test command
-- Client command that shows one sample toast of every type (only the player himself sees them). '' = no command
Config.TestCommand = 'notifytest'

-- ---------------------------------------------------------------- Announcements (/announce <text>)
-- A larger banner shown to ALL players. The permission is checked on the server only.
Config.Announce = {
    enabled   = true,                               -- false = no command, no banner
    command   = 'announce',                         -- command name (without the slash)
    groups    = { admin = true, superadmin = true },-- ESX groups that may announce
    ace       = 'dream_notify.announce',            -- ACE permission that may announce too (and the ONLY way without ESX)
                                                    -- server.cfg example: add_ace group.admin dream_notify.announce allow
    cooldown  = 15,                                 -- seconds a player has to wait between two announcements (0 = off)
    minLength = 3,                                  -- shortest allowed text (characters)
    maxLength = 200,                                -- longest allowed text (characters); longer texts are refused
    duration  = 10000,                              -- how long the banner stays (ms)
    position  = 'top',                              -- 'top' | 'middle'
    showSender = true,                              -- true = show "by <player name>" under the text
    sound     = true,                               -- play a short chime (needs Config.Sound.enabled)
    log       = true,                               -- print every announcement to the server console
}
