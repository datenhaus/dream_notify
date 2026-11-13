/* dream_notify · NUI
   SECURITY: every text that comes from the game is written with textContent only (never as HTML),
   so HTML or script code inside a notification is shown as plain characters and never executed.
   Icons are built from the fixed list below; unknown icon names fall back to the icon of the type. */
(function () {
  'use strict';

  var RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : null;   // null = opened in a normal browser (preview.html)
  var TH = window.DSTheme || { logo: 'DS', name: 'Your Server', apply: function () {}, colors: function () {} };
  var SVG = 'http://www.w3.org/2000/svg';

  var TYPES = { info: true, success: true, warning: true, error: true };
  var POSITIONS = { 'top-right': true, 'top-left': true, 'top-center': true, 'bottom-right': true, 'bottom-left': true, 'bottom-center': true };

  /* 24x24 outline icons (path data only) */
  var ICONS = {
    info: ['M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z', 'M12 11v6', 'M12 7.5v.5'],
    success: ['M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z', 'm8 12.5 2.8 2.8L16 9.8'],
    warning: ['M12 3.5 2.5 20h19z', 'M12 10v4.5', 'M12 17v.5'],
    error: ['M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z', 'm9 9 6 6', 'm15 9-6 6'],
    megaphone: ['M4 10v4h3l7 4V6l-7 4z', 'M17.5 9a4 4 0 0 1 0 6', 'M7 14v4.5h2.5V15.5'],
    bell: ['M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z', 'M10 20.5a2.2 2.2 0 0 0 4 0'],
    money: ['M3 7h18v10H3z', 'M12 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5z', 'M6 10v4', 'M18 10v4'],
    bank: ['M3 9 12 4l9 5', 'M5 10v7', 'M9.5 10v7', 'M14.5 10v7', 'M19 10v7', 'M3 20h18'],
    car: ['M4 16v-4l2.3-5h11.4L20 12v4', 'M3 16h18v3H3z', 'M7 12.5h.5', 'M16.5 12.5h.5'],
    phone: ['M8 2.5h8a1.5 1.5 0 0 1 1.5 1.5v16A1.5 1.5 0 0 1 16 21.5H8A1.5 1.5 0 0 1 6.5 20V4A1.5 1.5 0 0 1 8 2.5z', 'M11 18.5h2'],
    mail: ['M3 6h18v12H3z', 'm3 7 9 6.5L21 7'],
    star: ['m12 3 2.7 5.6 6.1.8-4.5 4.2 1.1 6-5.4-3-5.4 3 1.1-6L3.2 9.4l6.1-.8z'],
    shield: ['M12 3 20 6v6c0 5-3.5 8.3-8 9-4.5-.7-8-4-8-9V6z'],
    user: ['M12 4a4 4 0 1 0 0 8 4 4 0 0 0 0-8z', 'M4.5 20.5c.7-3.6 3.6-5.5 7.5-5.5s6.8 1.9 7.5 5.5'],
    heart: ['M12 20.5 4.6 13a4.7 4.7 0 0 1 6.6-6.7l.8.8.8-.8a4.7 4.7 0 0 1 6.6 6.7z'],
    lock: ['M5 11h14v9.5H5z', 'M8 11V8a4 4 0 0 1 8 0v3'],
    key: ['M8 11a4 4 0 1 0 0 8 4 4 0 0 0 0-8z', 'M11 12.5 20 3.5', 'm16 7.5 2.5 2.5', 'M18.5 5 21 7.5'],
    wrench: ['M14.7 6.3a4.5 4.5 0 0 0-5.9 5.9L3.5 17.5a2.1 2.1 0 0 0 3 3l5.3-5.3a4.5 4.5 0 0 0 5.9-5.9l-2.8 2.8-2.6-.4-.4-2.6z'],
    clock: ['M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z', 'M12 7v5l3 2'],
    pin: ['M12 21.5s-6.5-6-6.5-11a6.5 6.5 0 0 1 13 0c0 5-6.5 11-6.5 11z', 'M12 8.3a2.3 2.3 0 1 0 0 4.6 2.3 2.3 0 0 0 0-4.6z'],
    gift: ['M4 11h16v9.5H4z', 'M3 7.5h18V11H3z', 'M12 7.5v13', 'M12 7.5C10 3 5.5 4.5 7.5 7.5', 'M12 7.5c2-4.5 6.5-3 4.5 0'],
    briefcase: ['M3 8h18v12H3z', 'M9 8V5h6v3', 'M3 13.5h18'],
    medic: ['M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18z', 'M12 8v8', 'M8 12h8']
  };

  /* short beeps per type: frequencies in Hz, played one after another */
  var TONES = { info: [880], success: [660, 990], warning: [520, 520], error: [330, 247], announce: [523, 659, 784] };

  var CFG = { position: 'top-right', maxVisible: 4, maxQueue: 30, sound: true, volume: 0.25, reduced: false, badge: true, annSound: true };
  var TXT = { announcement: 'Announcement', by: 'by %s' };

  var queue = [];        // toasts waiting for a free slot
  var visible = 0;       // toasts on screen
  var annQueue = [];     // announcements waiting
  var annBusy = false;
  var live = [];         // { el, timer } of everything on screen (for "clear")
  var audio = null;

  function ensure(id) {
    var el = document.getElementById(id);
    if (!el) { el = document.createElement('div'); el.id = id; document.body.appendChild(el); }
    return el;
  }
  var elToasts = ensure('toasts');
  var elAnn = ensure('announce');

  /* ---------------------------------------------------------------- helpers */
  function text(v, max) {
    if (v == null || typeof v === 'object' || typeof v === 'function') return '';
    var s = String(v);
    if (s.length > max) s = Array.from(s).slice(0, max).join('');
    return s;
  }
  function num(v, def, min, max) {
    v = Number(v);
    if (!isFinite(v)) v = def;
    return Math.min(max, Math.max(min, v));
  }
  function reduced() {
    if (CFG.reduced) return true;
    try { return !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches); } catch (e) { return false; }
  }
  function icon(name) {
    var paths = ICONS[name] || ICONS.info;
    var svg = document.createElementNS(SVG, 'svg');
    svg.setAttribute('viewBox', '0 0 24 24');
    svg.setAttribute('aria-hidden', 'true');
    for (var i = 0; i < paths.length; i++) {
      var p = document.createElementNS(SVG, 'path');
      p.setAttribute('d', paths[i]);
      svg.appendChild(p);
    }
    return svg;
  }
  function div(cls, txt) {
    var d = document.createElement('div');
    d.className = cls;
    if (txt != null) d.textContent = txt;
    return d;
  }
  function badge(cls) {
    var b = div(cls, TH.logo);
    b.setAttribute('data-n', String(Array.from(String(TH.logo)).length));
    return b;
  }
  function bar(ms) {
    var wrap = div('t-bar');
    var fill = document.createElement('i');
    fill.style.animationDuration = ms + 'ms';
    wrap.appendChild(fill);
    return wrap;
  }
  function post(name, data) {
    if (!RES) return;
    try {
      fetch('https://' + RES + '/' + name, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(data || {}) })
        .catch(function () {});
    } catch (e) { /* not in game */ }
  }

  /* ---------------------------------------------------------------- sound (generated, no audio files) */
  function beep(kind) {
    if (!CFG.sound || CFG.volume <= 0) return;
    try {
      var Ctor = window.AudioContext || window.webkitAudioContext;
      if (!Ctor) return;
      if (!audio) audio = new Ctor();
      if (audio.state === 'suspended' && audio.resume) { var r = audio.resume(); if (r && r.catch) r.catch(function () {}); }
      var notes = TONES[kind] || TONES.info;
      var peak = Math.max(0.002, CFG.volume * 0.35);
      var t0 = audio.currentTime + 0.02;
      for (var i = 0; i < notes.length; i++) {
        var osc = audio.createOscillator();
        var gain = audio.createGain();
        var start = t0 + i * 0.11;
        osc.type = 'sine';
        osc.frequency.value = notes[i];
        gain.gain.setValueAtTime(0.0001, start);
        gain.gain.exponentialRampToValueAtTime(peak, start + 0.015);
        gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.2);
        osc.connect(gain);
        gain.connect(audio.destination);
        osc.start(start);
        osc.stop(start + 0.22);
      }
    } catch (e) { /* sound is optional */ }
  }

  /* ---------------------------------------------------------------- toasts */
  function cleanToast(d) {
    if (!d || typeof d !== 'object') return null;
    var title = text(d.title, 200).trim();
    var message = text(d.message, 2000).trim();
    if (!title && !message) return null;
    var type = (typeof d.type === 'string' && TYPES[d.type] === true) ? d.type : 'info';
    var ic = (typeof d.icon === 'string' && Object.prototype.hasOwnProperty.call(ICONS, d.icon)) ? d.icon : type;
    return { title: title, message: message, type: type, icon: ic, duration: Math.round(num(d.duration, 5000, 500, 120000)) };
  }

  function untrack(el) {
    for (var i = live.length - 1; i >= 0; i--) if (live[i].el === el) live.splice(i, 1);
  }

  function removeToast(el) {
    if (el._gone) return;
    el._gone = true;
    el.classList.add('out');
    setTimeout(function () {
      if (el.parentNode) el.parentNode.removeChild(el);
      untrack(el);
      visible = Math.max(0, visible - 1);
      pump();
    }, reduced() ? 130 : 290);
  }

  function showToast(d) {
    var el = div('toast t-' + d.type);
    el.setAttribute('role', d.type === 'error' ? 'alert' : 'status');
    var ico = div('t-ico');
    ico.appendChild(icon(d.icon));
    var body = div('t-body');
    body.appendChild(div('t-title', d.title));
    body.appendChild(div('t-msg', d.message));
    el.appendChild(ico);
    el.appendChild(body);
    if (CFG.badge) el.appendChild(badge('t-badge'));
    el.appendChild(bar(d.duration));
    elToasts.appendChild(el);
    visible++;
    var timer = setTimeout(function () { removeToast(el); }, d.duration);
    live.push({ el: el, timer: timer });
    beep(d.type);
  }

  function pump() {
    while (visible < CFG.maxVisible && queue.length) showToast(queue.shift());
  }

  function notify(raw) {
    var d = cleanToast(raw);
    if (!d) return;
    if (visible < CFG.maxVisible && !queue.length) { showToast(d); return; }
    if (CFG.maxQueue <= 0) return;                       // queue switched off: drop
    while (queue.length >= CFG.maxQueue) queue.shift();  // full: the oldest waiting toast is dropped
    queue.push(d);
    pump();
  }

  /* ---------------------------------------------------------------- announcement banner (one at a time) */
  function cleanAnn(d) {
    if (!d || typeof d !== 'object') return null;
    var message = text(d.message, 1500).trim();
    if (!message) return null;
    return { message: message, title: text(d.title, 80).trim(), sender: text(d.sender, 60).trim(), duration: Math.round(num(d.duration, 10000, 2000, 120000)) };
  }

  function removeAnn(el) {
    if (el._gone) return;
    el._gone = true;
    el.classList.add('out');
    setTimeout(function () {
      if (el.parentNode) el.parentNode.removeChild(el);
      untrack(el);
      annBusy = false;
      pumpAnn();
    }, reduced() ? 130 : 310);
  }

  function showAnn(d) {
    annBusy = true;
    var el = div('ann');
    el.setAttribute('role', 'alert');
    el.appendChild(badge('ann-badge'));
    var body = div('ann-body');
    var head = div('ann-head');
    head.appendChild(icon('megaphone'));
    var label = document.createElement('span');
    label.textContent = d.title || TXT.announcement;
    var server = document.createElement('em');
    server.textContent = TH.name;
    head.appendChild(label);
    head.appendChild(server);
    body.appendChild(head);
    body.appendChild(div('ann-msg', d.message));
    body.appendChild(div('ann-by', d.sender ? TXT.by.split('%s').join(d.sender) : ''));
    el.appendChild(body);
    el.appendChild(bar(d.duration));
    elAnn.appendChild(el);
    var timer = setTimeout(function () { removeAnn(el); }, d.duration);
    live.push({ el: el, timer: timer });
    if (CFG.annSound) beep('announce');
  }

  function pumpAnn() {
    if (!annBusy && annQueue.length) showAnn(annQueue.shift());
  }

  function announce(raw) {
    var d = cleanAnn(raw);
    if (!d) return;
    if (annQueue.length >= 5) annQueue.shift();
    annQueue.push(d);
    pumpAnn();
  }

  function clearAll() {
    queue = [];
    annQueue = [];
    var list = live.slice();
    for (var i = 0; i < list.length; i++) {
      clearTimeout(list[i].timer);
      if (list[i].el.classList.contains('ann')) removeAnn(list[i].el); else removeToast(list[i].el);
    }
  }

  /* ---------------------------------------------------------------- settings from config.lua */
  function init(m) {
    var c = (m && typeof m.config === 'object' && m.config) || {};
    var pos = (typeof c.position === 'string' && POSITIONS[c.position] === true) ? c.position : 'top-right';
    CFG.position = pos;
    CFG.maxVisible = Math.round(num(c.maxVisible, 4, 1, 8));
    CFG.maxQueue = Math.round(num(c.maxQueue, 30, 0, 200));
    CFG.sound = c.sound !== false;
    CFG.volume = num(c.volume, 0.25, 0, 1);
    CFG.reduced = c.reducedMotion === true;
    CFG.badge = c.showBadge !== false;
    CFG.annSound = c.announceSound !== false;

    var root = document.documentElement;
    root.style.setProperty('--scale', String(num(c.scale, 1, 0.6, 1.6)));
    root.style.setProperty('--mx', (num(c.offsetX, 24, 0, 600) / 16) + 'rem');
    root.style.setProperty('--my', (num(c.offsetY, 24, 0, 600) / 16) + 'rem');
    root.classList.toggle('reduced', CFG.reduced);
    elToasts.className = 'pos-' + pos;
    elAnn.className = c.announcePosition === 'middle' ? 'pos-middle' : 'pos-top';

    TH.apply(m.theme);
    TH.colors(c.colors);

    var t = (m && typeof m.texts === 'object' && m.texts) || {};
    if (typeof t.announcement === 'string' && t.announcement) TXT.announcement = text(t.announcement, 60);
    if (typeof t.by === 'string' && t.by) TXT.by = text(t.by, 60);
    pump();
  }

  window.addEventListener('message', function (e) {
    var m = e && e.data;
    if (!m || typeof m !== 'object') return;
    try {
      if (m.action === 'init') init(m);
      else if (m.action === 'notify') notify(m.data);
      else if (m.action === 'announce') announce(m.data);
      else if (m.action === 'clear') clearAll();
    } catch (err) { /* one broken message must never stop the notifications */ }
  });

  /* tell the client script that the page is loaded; it answers with the "init" message */
  post('ready', {});
})();
