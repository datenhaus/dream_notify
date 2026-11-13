fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dream_notify'
author 'DreamScripts'
description 'Free notification & announcement system: stacked toasts with progress bar, 4 types, queue, admin /announce banner, themeable (ESX Legacy optional)'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts { 'config.lua', 'locales.lua', 'shared.lua' }
client_script 'client.lua'
server_script 'server.lua'

files { 'html/index.html', 'html/style.css', 'html/theme.js', 'html/app.js' }

-- No hard dependency on purpose: es_extended is optional.
-- With ESX Legacy: start this resource AFTER es_extended (ensure es_extended, then ensure dream_notify).
-- Free & open source: no escrow, no obfuscation. See LICENSE.
