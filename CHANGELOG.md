# Changelog

## 1.0.0 (2026-11-13)

First public release.

- Stacked toast notifications with progress bar, four types (info, success, warning, error) and 23 built-in icons
- Six screen positions, maximum of visible toasts, queue with limit
- Generated notification sound (no audio files), can be switched off
- Reduced-motion mode (automatic and by config)
- Theme from the config: primary colour, background, text colour, logo badge from 1-3 letters, server name
- Announcement banner for all players with `/announce <text>`: ESX group or ACE permission, cooldown, text cleaning, length limit
- Client exports `Notify`, `Announce`, `Clear`; server exports `Notify`, `Announce`; local server events `dream_notify:send`, `dream_notify:sendAnnounce`
- Optional ESX override (`Config.EsxOverride`, off by default)
- Works without es_extended (announcements then use the ACE permission `dream_notify.announce`)
- English and German texts
- `preview.html` to try the design in a normal browser
