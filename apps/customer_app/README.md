# Varnixo — Customer App

Flutter customer app for the Varnixo platform. Clean architecture,
feature-first structure, Riverpod state management, go_router navigation.

## ⚠️ Environment note

This app was built in an environment **without the Flutter SDK installed**,
so none of this code has been run through `flutter pub get`, `flutter
analyze`, `flutter test`, or a real build. Every file was hand-written to be
syntactically correct and internally consistent (imports, constructor
signatures, and package APIs were cross-checked manually against the
versions pinned in `pubspec.yaml`), but **you must treat first build as
integration, not just "run it."** Expect to fix a handful of minor issues
`flutter analyze` will surface — that's normal for code that's never been
compiled.

## Setup

```bash
cd apps/customer_app

# 1. Generate native platform folders (android/, ios/, web/) — these are
#    intentionally NOT checked in since they must be scaffolded by your
#    installed Flutter SDK version.
flutter create . --project-name varnixo --org com.varnixo

# 2. Install dependencies
flutter pub get

# 3. Configure environment
cp .env.example .env
# Edit .env: point API_BASE_URL at your running backend (see ../../backend).
# 10.0.2.2 is the Android emulator's loopback alias for the host machine;
# use your LAN IP for a physical device, or localhost for iOS simulator.

# 4. Run
flutter analyze   # fix whatever it flags first
flutter run
```

### Payments

- **Razorpay** is wired end-to-end in `features/checkout` using
  `razorpay_flutter` — set `RAZORPAY_KEY_ID` in `.env` and configure the
  corresponding secret on the backend.
- **Stripe** creates a PaymentIntent server-side (`checkout_repository.dart`)
  but does **not** launch Stripe's PaymentSheet — that's the one deliberately
  unfinished integration point, marked with a comment in
  `checkout_screen.dart`. Wire `flutter_stripe`'s `PaymentSheet` there once
  you've configured platform-native Stripe keys via `flutter create .`.
- **Google/Apple Sign-In** packages (`google_sign_in`, `sign_in_with_apple`)
  are dependencies but not yet called from the login screen — the backend
  endpoint (`POST /auth/oauth/google`) is ready; wiring the native sign-in
  flow needs the platform config from step 1 above.
- **Firebase** (push notifications, analytics, crashlytics) packages are
  included but require `flutterfire configure` to generate
  `google-services.json` / `GoogleService-Info.plist`, which needs a real
  Firebase project.

## Architecture

```
lib/
├── core/                    # Cross-cutting: theme, network, router, widgets
│   ├── config/              # Env (.env-driven runtime config)
│   ├── network/             # Dio client, auth interceptor (silent refresh),
│   │                          exception mapping, pagination helper
│   ├── providers/           # App-wide Riverpod providers (storage, API, theme)
│   ├── router/               # go_router config, auth-gated redirects
│   ├── storage/              # Secure token storage
│   ├── theme/                 # Material 3 light/dark theme
│   └── widgets/               # Shared UI: buttons, skeletons, price tag, etc.
├── features/
│   └── <feature>/
│       ├── data/             # Repositories — talk to ApiClient only
│       ├── domain/           # Plain Dart models (manual fromJson/toJson —
│       │                       no code generation required to build)
│       └── presentation/     # Screens + Riverpod StateNotifiers
└── shared/                   # MainShell (persistent bottom-nav)
```

**Why no `freezed`/`json_serializable` codegen in the actual model code?**
`build_runner` wasn't runnable in the authoring environment, so every model
is a hand-written plain class with a manual `fromJson`/`copyWith`. The
packages remain in `pubspec.yaml` for future contributors who want to
migrate incrementally — nothing here depends on generated `.g.dart` files,
so the app builds without a codegen step.

## Features implemented

Splash → onboarding → auth (email/password, OTP login with auto-registration,
Google OAuth endpoint wired), home (categories, new arrivals, trending,
recently viewed), search (debounced), category browsing (infinite scroll,
sort/filter), product detail (variant selection, image carousel, related
products), cart (live pricing/stock, save-for-later, coupons), wishlist,
address book, checkout (COD / wallet / Razorpay), order tracking (status
timeline, invoice download via share sheet), returns/exchange requests,
wallet, profile (theme toggle, account deletion).

Every screen talks to the real backend endpoints built in Phases 1–5 — there
is no mock data or placeholder API layer.
