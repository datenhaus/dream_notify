/* Theme bridge: receives Config.Theme / Config.Colors from the client script and maps them to CSS variables.
   Only validated values reach the page: hex colours are parsed to numbers, other colours go through CSS.supports. */
(function () {
  'use strict';
  var T = { logo: 'DS', name: 'Your Server' };
  var TYPES = ['info', 'success', 'warning', 'error'];
  function hex(v) {
    var m = /^#?([0-9a-f]{3}|[0-9a-f]{6})$/i.exec(String(v == null ? '' : v).trim());
    if (!m) return null;
    var h = m[1];
    if (h.length === 3) h = h.charAt(0) + h.charAt(0) + h.charAt(1) + h.charAt(1) + h.charAt(2) + h.charAt(2);
    return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
  }
  function validColor(v) {
    try { return typeof v === 'string' && v.length < 64 && !!(window.CSS && CSS.supports && CSS.supports('color', v)); } catch (e) { return false; }
  }
  function ink(c) { return (c[0] * 299 + c[1] * 587 + c[2] * 114) / 1000 > 140 ? '#111111' : '#ffffff'; }
  T.apply = function (t) {
    if (!t || typeof t !== 'object') return;
    var st = document.documentElement.style;
    var a = hex(t.primary != null ? t.primary : t.accent);
    if (a) {
      st.setProperty('--accent', 'rgb(' + a.join(',') + ')');
      st.setProperty('--accent-rgb', a.join(','));
      st.setProperty('--accent-ink', ink(a));   // readable text colour on top of the primary colour
    }
    var x = hex(t.text);
    if (x) {
      st.setProperty('--theme-text', 'rgb(' + x.join(',') + ')');
      st.setProperty('--theme-text-rgb', x.join(','));
    }
    if (validColor(t.background)) st.setProperty('--theme-bg', t.background);
    if (t.logoText != null && String(t.logoText).trim() !== '') T.logo = Array.from(String(t.logoText).trim()).slice(0, 3).join('');
    if (t.serverName != null && String(t.serverName).trim() !== '') T.name = Array.from(String(t.serverName).trim()).slice(0, 40).join('');
  };
  /* colours of the four types; '' or an invalid value = back to the default (info = primary colour) */
  T.colors = function (c) {
    if (!c || typeof c !== 'object') return;
    var st = document.documentElement.style;
    TYPES.forEach(function (k) {
      var v = hex(c[k]);
      if (v) st.setProperty('--c-' + k + '-rgb', v.join(','));
      else st.removeProperty('--c-' + k + '-rgb');
    });
  };
  window.DSTheme = T;
})();
