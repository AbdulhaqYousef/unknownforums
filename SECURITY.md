# Security Report — UnknownForums

Generated: 2026-05-04  
Scanner: Brakeman 8.0.4 · Bundler-Audit (ruby-advisory-db 2026-03-30)

---

## Scan Results

| Tool | Result |
|------|--------|
| Brakeman (static analysis) | ✅ 0 warnings |
| Bundler-Audit (CVE database) | ✅ No vulnerabilities found |
| RuboCop (code quality) | ✅ 0 offenses |

---

## Security Controls In Place

### Authentication
- **Password hashing**: BCrypt via `has_secure_password` (Rails built-in, no plaintext storage)
- **Password policy**: minimum 8 chars, must include uppercase, lowercase, and a number; cannot equal username
- **Brute-force protection**: Account locked after 5 failed login attempts for 15 minutes (`MAX_LOGIN_ATTEMPTS = 5`, `LOCKOUT_DURATION = 15.minutes`)
- **Email 2FA (OTP)**: Optional per-user; 6-digit code, expires in 10 minutes, max 5 attempts, 60-second resend cooldown
- **Session hardening**: `cookie_store` with `httponly: true`, `secure: true`, `same_site: :lax`, 24-hour expiry, `reset_session` on login/logout to prevent session fixation

### Authorization
- **Role system**: 3 roles — `user`, `moderator`, `admin` (enum, integer-backed)
- **Enforced at controller level**: `require_login`, `require_admin`, `require_moderator`, `require_owner_or_moderator` before_actions
- **Admin namespace**: All `/admin/*` routes require `require_moderator` or `require_admin`
- **Resource ownership**: Post/attachment deletion checks `current_user == resource.user || moderator_or_admin?`

### HTTP Security Headers (Rack middleware `SecurityHeaders`)
| Header | Value |
|--------|-------|
| `X-Frame-Options` | `SAMEORIGIN` |
| `X-Content-Type-Options` | `nosniff` |
| `X-XSS-Protection` | `1; mode=block` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | camera=(), microphone=(), geolocation=(), payment=() |
| `X-Permitted-Cross-Domain-Policies` | `none` |
| `X-Download-Options` | `noopen` |

### Content Security Policy
- `default-src 'self'` — no external script execution
- `object-src 'none'` — no plugins (Flash, etc.)
- `frame-src 'none'` / `frame-ancestors 'none'` — blocks embedding/clickjacking
- `form-action 'self'` — forms can only POST to own origin
- `script-src 'self' 'unsafe-inline'` — inline scripts allowed (needed for Turbo/importmap)
- `img-src 'self' data: https` — images from HTTPS sources only

### CSRF Protection
- Rails `protect_from_forgery` enabled globally (ActionController::Base default)
- CSRF token in all non-GET forms via `csrf_meta_tags`

### SQL Injection Prevention
- All queries use ActiveRecord parameterized binds (`where(id: ids)`)
- `DISTINCT ON` queries use `Arel.sql()` for static strings only — no user input interpolated
- Search inputs use `sanitize_sql_like` before ILIKE queries
- No raw string interpolation in SQL

### File Upload Security
- **MIME type whitelist**: Only allowed types accepted (`ALLOWED_TYPES` constant)
- **Size limit**: Configurable per site, category, and subforum (hard ceiling 350 GB); files over 5 GB use R2 multipart direct upload
- **VirusTotal scanning**: All zip, pdf, torrent, executable, and script uploads scanned before approval
- **Download warning**: Files with `suspicious`, `malicious`, `pending`, or `skipped` VT status show interstitial warning before download
- **DM files**: Private message attachments stored under separate R2 key prefix (`dmfile/`), accessible only to sender/recipient/moderator/admin
- **Storage**: Files stored in Cloudflare R2 (S3-compatible), never served from app server

### Rate Limiting / Abuse Prevention
- **Login lockout**: 5 attempts → 15-minute lockout
- **OTP lockout**: 5 attempts → OTP invalidated
- **VirusTotal quota**: DB-backed quota model (`virus_total_quotas`) — 4 req/min, 500/day, 15,500/month. Rate-limited scans requeue automatically
- **Attack event logging**: Suspicious requests logged to `attack_events` table

### Cache Security
- All HTML responses include `Cache-Control: no-store, no-cache, must-revalidate, private` to prevent sensitive pages being cached by proxies
- Auth forms (`login`, `register`, `OTP verify`) use `data-turbo="false"` for full-page reloads

### Secrets Management
- All secrets via environment variables (`ENV[]`) — no hardcoded secrets in code
- Required env vars: `VIRUSTOTAL_API_KEY`, `RESEND_API_KEY`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`, `R2_ENDPOINT`, `SECRET_KEY_BASE`

---

## Known Accepted Risks

| Issue | Reason Accepted |
|-------|----------------|
| `script-src 'unsafe-inline'` in CSP | Required for Rails importmap + Turbo inline scripts |
| Admin mass assignment permit (`:role`, `:banned`, etc.) | Admin-only controller, behind `require_admin` authorization |

---

## Recommendations (Not Yet Implemented)

- [ ] Add `nonce`-based CSP to eliminate `unsafe-inline` (requires Turbo/importmap changes)
- [ ] Add rate limiting on registration endpoint (currently only login is rate-limited)
- [ ] Consider adding IP-based request throttling (Rack::Attack gem)
- [ ] Rotate `SECRET_KEY_BASE` periodically and on any suspected compromise
- [ ] Enable HSTS preload submission at hstspreload.org (HSTS header is set but preload requires submission)
