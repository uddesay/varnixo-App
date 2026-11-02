# Varnixo

Production build and server instructions: [PRODUCTION.md](PRODUCTION.md). Run `npm run start:background` for the local production-mode app on port 5373, or `npm start` under a service manager. Public launch requirements are documented separately from the demo setup below.

Online marketplace for **fresh vegetables, fresh fruits and dry fruits** — customer storefront + admin panel + API, plus the Flutter customer app in `apps/customer_app`. Multi-vendor: farmers and sellers apply, get approved, and sell under one Varnixo storefront.

- **Categories:** Vegetables, Fresh Fruits, Dry Fruits. **Gaushala Products** already exists as a hidden category — switch it on in Admin → Catalog → Categories when those products are ready.
- **Customer contact:** +91 93392 44573 (call / WhatsApp) — shown in the header, footer and Help page. Change it in [web/src/store/brand.ts](web/src/store/brand.ts).

| | URL |
|---|---|
| Storefront | http://localhost:5373 |
| Admin panel | http://localhost:5373/login |
| API | http://localhost:4200/api/v1 |
| Health check | http://localhost:4200/healthz |
| API docs (Swagger) | http://localhost:4200/api/v1/docs |

Ports are deliberately different from the other local projects (RozShop 4000/5173, MUDIT SHOPING 4100/5273), so all can run side by side.

## Requirements

- Windows 10/11 (PowerShell or Git Bash), **no Docker needed**
- Node.js **20 or newer** (tested on 24.11)
- PostgreSQL **14+** running locally (tested on 16), plus a superuser login (usually `postgres`)
- Optional: Redis and Elasticsearch. Without them the API falls back to an in-process rate limiter and database search; development works normally.

## First-time setup

```powershell
cd varnixo-App
npm run install:all                     # npm ci for backend and web

# Creates backend/.env (random secrets + demo passwords), a dedicated
# varnixo_app role and the varnixo_dev database. The superuser
# password is used once and never saved.
$env:PG_ADMIN_USER = "postgres"
$env:PG_ADMIN_PASSWORD = "<your PostgreSQL superuser password>"
npm run setup                           # demo:setup + migrate + seed
Remove-Item Env:PG_ADMIN_PASSWORD

npm run dev                             # starts API (4200) and web (5373) in the background
```

`npm run stop` stops both. Logs are in `.runtime/api.log` and `.runtime/web.log`.

## Demo logins

`npm run setup` writes them to **`DEMO_CREDENTIALS.local.md`** (git-ignored). Passwords are random per machine and are never committed.

- **Super admin** — `admin@demo.varnixo.com` → http://localhost:5373/login
- **Shoppers** — `aarav@`, `diya@`, `kabir@`, `ishita@`, `rahul@`, `sneha@`, `farhan@`, `neha@demo.varnixo.com` → storefront “Sign in”
- **Sellers** — `seller@` (Varnixo Official Store), `kisan@` (Kisan Harvest Farms), `orchard@` (Orchard Basket), `kashmir@demo.varnixo.com` (Kashmir Dry Fruit House) — API / future seller app; sellers are blocked from the admin panel by design

## Demo data

`backend/db/seeds` creates clearly marked demo records only (all emails end in `@demo.varnixo.com`):

- 4 approved vendors with their own catalogues and warehouses, and 2 pending applications (Gau Seva Gaushala, Green Leaf Organics) with KYC documents to review
- 23 products sold by weight/pack (500 g / 1 kg, 6 / 12 pcs…) with per-pack prices, stock (including low/out-of-stock examples) and photography. Fresh produce is GST 0% with a 1-day freshness return window; dry fruits are GST 5% with 7-day returns
- 8 customers with addresses; 34 orders across every status over the last ~45 days, split into per-vendor shipments with commission, payments, refunds and a return
- Reviews (with a moderation queue), 4 coupons (`WELCOME10`, `FRESH50` active; `WINTER20` scheduled; `MANGO15` expired), banners, a Shipping & Returns page and FAQs

Rebuild everything from scratch at any time:

```powershell
npm --prefix backend run demo:reset     # wipes and re-seeds varnixo_dev only
```

Every seed and reset script refuses to run in production, against a non-local host, or against a database whose name doesn't contain `varnixo`.

## What's included

**Storefront** — animated hero, sticky glass navbar, mobile menu, search, category filters and sorting, trending / new-arrivals / bestseller rails, CMS-driven promo banners, product details with gallery and variants, wishlist (optimistic), bag with coupons, checkout (cash on delivery), order history with cancellation, support requests, Shipping & Returns, and a **“Start selling” vendor application** that lands in the admin’s approval queue. Respects reduced-motion settings.

**Admin** — dashboard (GMV, net sales, orders, AOV, customers, vendors, repeat and refund rates, sales chart, attention queues, live activity), analytics, products (create/edit with variants, media, SEO; bulk publish/unpublish/archive/category; CSV export), categories, brands, inventory (adjust/transfer/history), coupons, orders (filters, timeline, fulfilment steps, cancel & refund, printable invoice), returns, shipments, payouts, vendors (applications with KYC review, approve/reject/request info, profiles, commission overrides), customers, staff, reviews, support inbox, banners/pages/blog/FAQs, notifications, settings, audit logs, dark mode, Ctrl+K search.

**Backend security** — Argon2 password hashing, JWT with refresh rotation, staff-only `/admin` routes, per-permission RBAC, vendors restricted to their own shipments/products/inventory (verified), Joi validation on every route, audit logging, rate limiting.

## Checks run — 2 November 2026

| Check | Result |
|---|---|
| Backend lint | clean |
| Backend unit tests (`npm --prefix backend test`) | 91 passed |
| Demo setup + migrations + seeds | ran on a fresh PostgreSQL 16 database |
| End-to-end commerce suite (`npm --prefix backend run test:commerce`) | 22/22 |
| Web type-check + production build | passes |
| Web lint | 0 errors (26 Fast Refresh warnings, development-only) |
| Web unit tests | 12 passed |
| Browser smoke (Playwright) | home (desktop + mobile), vegetables listing, contact page, admin login — no console errors |

Not re-run for Varnixo (last verified on the MUDIT SHOPING base this was built from): full shopper/admin Playwright journeys, responsive sweep, access-control checks, production bootstrap, `npm audit`. The Flutter app has not been built or analysed — run `flutter pub get && flutter analyze` in `apps/customer_app`.

`test:commerce` needs the API on `PORT` (default 4200); set `PORT=5373` to run it against the production-mode server. It creates `varnixo-qa-*@example.com` customers and cancels its order; the COD-delivery check runs in a rolled-back transaction.

## Mobile app (Android, iOS later)

The app **is the storefront**: the same React code wrapped with [Capacitor](https://capacitorjs.com) (`web/capacitor.config.ts`, app id `com.varnixo.app`). Inside the app (`<html data-app>`, see `web/src/lib/appMode.ts`) the website top bar, footer and staff links are hidden and the bottom tab bar is the navigation; notch/safe areas are handled. Any storefront change ships to both website and app. The site is also installable from the browser (PWA manifest in `web/public`).

```powershell
cd web
copy .env.app.example .env.app     # set VITE_API_BASE_URL (must be absolute)
$env:VARNIXO_DEV_API = "1"         # only for a plain-http dev API (emulator: http://10.0.2.2:4200)
npm run app:apk                    # -> web/android-build/varnixo-debug.apk
npm run app:open                   # open in Android Studio (run on emulator/phone, signed release builds)
```

- Requires Android Studio (its JDK 21 and Android SDK 36 are picked up automatically).
- For a **Play Store release**: point `VITE_API_BASE_URL` at the live **https** API, leave `VARNIXO_DEV_API` unset, and build a signed bundle from Android Studio (Build → Generate Signed Bundle).
- The production API must list `https://localhost` (the app's origin) in `CORS_ORIGINS`.
- App icons and splash come from `python scripts/make-brand.py`.
- `apps/customer_app` is the older Flutter app from the base codebase. The Capacitor app above replaces it; it is kept only for reference.

## Going live

Production setup, the **required first-run bootstrap** (`npm --prefix backend run bootstrap:production`), backups, rollback and HTTPS requirements are in [PRODUCTION.md](PRODUCTION.md). Never run `setup`, `seed` or `demo:reset` against the production database.

## Not included / needs external services

- **Online payments**: Razorpay/Stripe code exists but no keys are configured; the storefront offers cash on delivery only. Seeded “razorpay” payments are demo records.
- **Image uploads** need S3-compatible storage (`S3_*`); otherwise paste image URLs.
- **Email/SMS** providers are not configured (OTP codes print to the API log).
- Courier booking APIs (Shiprocket/Delhivery/Blue Dart) need credentials; manual shipping status works.
- Demo photography is illustrative (Unsplash) and should be replaced with real seller photos.
- **Logo is a placeholder** generated by `python scripts/make-brand.py` (web logo, favicon and all Flutter launcher icons). Replace with the client's final artwork when available.
- Seller dashboard UI is the Flutter seller app (next phase); seller APIs are ready.

## Project layout

```
varnixo-App/
  backend/   Express + Knex + PostgreSQL API (migrations, seeds, demo scripts)
  web/       React + Vite: storefront (/) and admin panel (/login, /dashboard…)
  apps/customer_app/  Flutter customer app (package com.varnixo.app; API on :4200)
  assets/    Brand source (1024 px icon)
  scripts/   dev launcher, stop, brand asset generator
```

Troubleshooting:

- **Port in use** — run `npm run stop`, or change `PORT` in `backend/.env` and the proxy in `web/vite.config.ts`.
- **`demo:setup` can't connect** — check that PostgreSQL is running and that `PG_ADMIN_USER` / `PG_ADMIN_PASSWORD` are correct.
- **Seeds say a password is missing** — run `npm --prefix backend run demo:setup` again.
- **Blank page after a code change** — restart with `npm run stop` and then `npm run dev`.
