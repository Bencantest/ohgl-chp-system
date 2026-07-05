# Security Headers

OCHP deployment should send the following headers for every frontend route.

| Header | Required Value | Purpose |
| --- | --- | --- |
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` | Enforce HTTPS. |
| `X-Content-Type-Options` | `nosniff` | Prevent MIME sniffing. |
| `X-Frame-Options` | `DENY` | Prevent clickjacking in legacy browsers. |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Limit referrer leakage. |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=(), payment=(), usb=()` | Disable unused browser capabilities. |
| `Cross-Origin-Opener-Policy` | `same-origin` | Reduce cross-origin window attack surface. |
| `X-DNS-Prefetch-Control` | `off` | Reduce speculative DNS leakage. |
| `Content-Security-Policy` | See `vercel.json` | Restrict script, style, image, connect, frame, base, and form targets. |

## CSP Notes

The current CSP allows inline scripts and inline styles because the existing static UI uses inline event handlers and inline styles. This should be tightened in a future frontend refactor by moving handlers into JavaScript modules and replacing inline styles with CSS classes.

Target future CSP:

```text
script-src 'self' https://cdn.jsdelivr.net;
style-src 'self' https://cdn.jsdelivr.net https://fonts.googleapis.com;
```

Before removing `unsafe-inline`, verify every page and modal interaction still works.
