# Motorcare · Vehicle Maintenance Tracker

A Flutter app for Android and Chrome with a navy and teal interface, multiple vehicles, service history, expenses in Philippine pesos, and tire replacement planning. Supabase provides account authentication and the active database.

## Start here

Follow **[SUPABASE_SETUP.md](SUPABASE_SETUP.md)** to create the tables, configure authentication, and add your project details when setting up a new installation. Existing installations use their saved `config/supabase.json`.

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define-from-file=config/supabase.json
```

For Android, replace `chrome` with a device ID from `flutter devices`. Without a config file, run without the `--dart-define-from-file` argument to view the setup screen. Laragon/MySQL is not needed.

## Features

- Email/password accounts, confirmation emails, password recovery, and sign-out.
- Private cloud records enforced through Supabase row-level security and ownership constraints.
- Multiple vehicles with remembered selection, independent histories, expenses, PMS intervals, and current odometers.
- Dashboard with selected vehicle, prioritized service schedule, spending metrics, tire replacement target, and recent activity.
- Tire position diagram, manufacture month/year, brand/model, notes, and adjustable replacement age. Each entry shows an estimated replacement month/year and age-related planning flags.
- Personal LTO driver's license expiry with 5- or 10-year validity, dashboard countdown, renewal estimates, and Android expiry reminders. Shared across vehicles in your account.
- Maintenance CRUD, search, type filters, desktop history table, and mobile lists.
- Atomic schedule completion with an optional expense record, without duplicates on retry.
- Six-month spending chart, period filters, and maintenance-type totals in PHP.
- Distance conversion across vehicles, records and schedules in one transaction.
- Android local date reminders for all vehicles, notification permissions, and reboot restoration.
- Responsive phone navigation and desktop sidebar, consistent forms and readable status labels.
- Import from the previous local SQLite/IndexedDB installation. Originals are kept, IDs are remapped, and retries do not duplicate imported rows.

Internet is required to load and save cloud records. Refresh or pull to refresh to load changes from another device; the app does not queue offline writes or subscribe to realtime updates.

## Tire estimates

Open **Tire care** from the phone toolbar, desktop sidebar, dashboard or garage. Save a manufacture month/year and an age limit for each current tire, including the spare. The default limit is 6 years and can be changed to match the manufacturer's guidance.

Example: September 2022 + 6 years = **September 2028**. This is an age-based replacement target, not a guaranteed expiry date or measurement of tire condition. The app flags reached targets, targets within six months, and tires aged five years for inspection. Wear or damage can require earlier replacement. See the setup guide for sources and limitations.

## LTO license expiry

Open **Dashboard or Settings → LTO driver's license → Add LTO license**. Select the 5- or 10-year validity shown on your card and enter its printed expiry date. This works even before adding a vehicle. Edit the entry after renewal, or use **Estimate 5/10-year renewal** to add the selected period to the previously saved expiry date, then check the result against the renewed card.

The dashboard highlights dates within 60 days, expiry today, and expired licenses. On Android, enable **Maintenance & license notifications** in Settings for alerts 60, 30 and 7 days before expiry and on the expiry date, around 9 AM. Chrome displays the dashboard status without scheduled notifications. Only future alerts are scheduled; Android may delay delivery.

Expiry is based on the printed date, not the issue date. The renewal calculator is a planning aid; it does not determine eligibility for 10-year validity or verify whether a license is suspended or revoked. [LTO validity guidance](https://lto.gov.ph/wp-content/uploads/2023/10/MEMO_11102021_CitizenCharter_Licensing-Transaction.pdf).

License tracking is stored as one JSON value under `driver_license` in the existing account-owned `settings` table. No SQL migration is needed. No license number or full birthdate is collected. Removing a vehicle leaves personal license tracking intact; removing license tracking cancels its local reminders.

## Import your existing garage

After signing in, use **Settings → Cloud account → Import local garage** before adding cloud vehicles or sample data. The cloud garage must be empty. Keep the same Android installation or Chrome profile, address and port that held the old records. Local originals are not deleted. See [import instructions](SUPABASE_SETUP.md#5-import-existing-records).

## Build

```powershell
flutter analyze
flutter test
flutter build web --dart-define-from-file=config/supabase.json
flutter build apk --debug --dart-define-from-file=config/supabase.json
```

The Android output is `build/app/outputs/flutter-apk/app-debug.apk`; the web output is `build/web`. The existing `scripts/build_android.cmd` helper automatically uses `config/supabase.json` when present and otherwise builds the setup screen. It also clears read-only attributes in generated build files to accommodate this OneDrive workspace.

Dependencies are pinned in `pubspec.lock`. Development uses Flutter 3.47.4 / Dart 3.13.3, Android min SDK 24, compile/target SDK 36, and Java 17 project settings. The time-zone plugin also needs SDK platform 35. Install SDK components through Android Studio. Debug APKs use development signing.

## Data and code

| Location | Purpose |
| --- | --- |
| `lib/main.dart`, `lib/cloud_app.dart` | Startup, accounts, responsive workspace and session lifecycle |
| `lib/database/maintenance_repository.dart` | Storage contract used by the provider |
| `lib/database/supabase_repository.dart` | Cloud CRUD, pagination, RPCs and legacy import |
| `lib/database/database_helper.dart` | Legacy import and tests; SQLite version 2 adds tires |
| `supabase/migrations/202609300001_motorcare.sql` | Tables, ownership policies, constraints and transactions |
| `lib/models/tire.dart` | Manufacture date, replacement target and age flags |
| `lib/providers/maintenance_provider.dart` | Selection, records, tires, totals, settings and reminders |
| `lib/screens/` | Account, dashboard, garage, forms, tires, history, expenses and preferences |
| `lib/theme/`, `lib/widgets/` | Navy/teal theme and responsive components |
| `lib/services/notification_service.dart` | Android reminders and serialized cancellation |

Tables: `vehicles`, `maintenance_records`, `maintenance_schedules`, `tires`, `settings`. Every row belongs to an authenticated user. Vehicle deletion cascades to its records, schedules and tires. A plate is unique within an account, and a tire position within a vehicle.

SQLite's web runtime files remain in `web/` so existing browser databases can be imported. They are not the active cloud database. Costs use PHP. Service readings do not automatically change the current odometer. PMS intervals are interpreted in the chosen distance unit.

## Validation

Flutter tests cover garage functionality, cloud HTTP payloads/pagination, sign-in/sign-out navigation, tire date boundaries, tire CRUD and per-vehicle isolation, phone/desktop layouts, and expenses. Optional Windows previews:

```powershell
flutter test test/garage_ui_test.dart test/tire_ui_test.dart test/cloud_ui_test.dart --dart-define=CAPTURE_UI=true
```

Previews are written to `build/ui/`. Capture mode uses Windows Segoe UI for readable images; ordinary tests do not depend on system fonts.

Run the actual SQL migration in embedded PostgreSQL with local Supabase Auth stubs:

```powershell
npm.cmd install --prefix build/sql-validation @electric-sql/pglite
node scripts/test_supabase.mjs
```

This checks two-account row isolation, denied anonymous access, ownership, import mapping/retries, rollback, conversion, duplicate prevention and cascading deletion. Live Supabase authentication, email links and hosted persistence still need a smoke test after configuration. Android launch, deep links and notification delivery need a connected device/emulator.

Notifications are Android-only, scheduled at approximately 9 AM local time, and may be delayed by power management. Tire age flags are in-app, not push notifications. There is no ECU/OBD integration, tire sensor, automatic condition assessment, or payment processing.
