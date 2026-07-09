import DOMPurify from 'dompurify';

/**
 * Escape a value for safe HTML text node insertion (not attribute-safe).
 */
export function h(value) {
  if (value === null || value === undefined) return '';
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Sanitize a user-provided string, stripping HTML tags.
 */
export function sanitizeText(value, maxLen = 500) {
  if (!value) return '';
  const cleaned = DOMPurify.sanitize(String(value), { ALLOWED_TAGS: [], ALLOWED_ATTR: [] });
  return cleaned.slice(0, maxLen);
}

/**
 * Set innerHTML on an element using DOMPurify to sanitize HTML.
 */
export function setSafeHTML(idOrEl, html) {
  const el = typeof idOrEl === 'string' ? document.getElementById(idOrEl) : idOrEl;
  if (!el) return;
  el.innerHTML = DOMPurify.sanitize(html);
}

let _innerHTMLPatched = false;

/**
 * Intercept all direct innerHTML writes globally and sanitize them.
 */
export function installInnerHTMLSanitizer() {
  if (_innerHTMLPatched) return;
  const nativeDescriptor = Object.getOwnPropertyDescriptor(Element.prototype, 'innerHTML');
  if (!nativeDescriptor || !nativeDescriptor.configurable) return;

  Object.defineProperty(Element.prototype, 'innerHTML', {
    set(value) {
      nativeDescriptor.set.call(this, DOMPurify.sanitize(value));
    },
    get() {
      return nativeDescriptor.get.call(this);
    },
    configurable: true,
    enumerable: nativeDescriptor.enumerable,
  });
  _innerHTMLPatched = true;
}
