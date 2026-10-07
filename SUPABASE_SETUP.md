# Connect Motorcare to Supabase

The app now uses Supabase for its active database. SQLite is kept only to import your previous garage and run local tests. There is no silent local fallback. Without project configuration the app shows a setup screen.

## 1. Create the database

Create a Supabase project, open **SQL Editor**, and run the entire file:

`supabase/migrations/202609300001_motorcare.sql`

Run this once on a new project. It creates vehicles, service records, schedules, tires and account settings, with row-level security. Each signed-in user can access only their own rows. Child records must belong to a vehicle owned by the same user. Anonymous database access is disabled.

The migration also creates transactional functions for unit conversion, schedule completion, and local data import. Completion and import can be safely retried without duplicate records.

## 2. Add the public client configuration

Copy `config/supabase.example.json` to `config/supabase.json` and replace both placeholders with your project URL and publishable key from the project's Connect/API settings. A legacy **anon** key is also supported. Do not use a secret or service-role key.

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_your_key"
}
```

The local config file is ignored by Git. Client keys are included in compiled apps; database security depends on the supplied RLS policies, not hiding the public key. See [Supabase Flutter initialization](https://supabase.com/docs/reference/dart/initializing) and [row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security).

## 3. Configure sign-in links

Enable the **Email** provider in Supabase Authentication. The app supports email/password sign-in, account creation, confirmation emails, and password recovery. Keep email confirmation enabled for normal use.

In **Authentication → URL Configuration**, set the development Site URL to `http://localhost:8080` and add these Redirect URLs:

- `http://localhost:8080/`
- `io.motorcare.app://login-callback/`

The Android callback intent is already configured. Add your actual HTTPS site origin if you host the web build. For confirmation/recovery during development, keep the app running and open the email link on the same device/browser that requested it (PKCE stores a verifier there). After confirming the account, sign in if required. Configure your own SMTP delivery before wider use.

## 4. Run or build

From the project folder:

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define-from-file=config/supabase.json
```

For an Android emulator or connected phone:

```powershell
flutter devices
flutter run -d YOUR_DEVICE_ID --dart-define-from-file=config/supabase.json
```

Build commands:

```powershell
flutter build web --dart-define-from-file=config/supabase.json
flutter build apk --debug --dart-define-from-file=config/supabase.json
```

Restart the app after changing these values; hot reload does not replace compile-time configuration. Laragon is not needed. Internet access is required to load and save cloud records. Use **Refresh garage** or pull to refresh to see changes made on another device. The app does not provide offline writes or a realtime subscription.

## 5. Import existing records

Sign in and open **Settings → Cloud account → Import local garage** before adding a new cloud vehicle or loading sample data. The cloud garage must be empty to avoid ambiguous merges.

Use the same Android installation, or the same Chrome browser/profile and exact origin (scheme, host and port) that held the old data. Browser and Android legacy databases are separate. The import copies vehicles, maintenance records, schedules, tires (if present), selection, and per-vehicle service intervals; it remaps local IDs into new cloud IDs. It keeps all local originals. A failed import rolls back the whole upload; retrying a successful import does not duplicate it. Notifications start disabled after import so you can enable them on the intended Android device.

An empty cloud garage does not mean your local data was deleted. If you already added cloud records, use another empty account or retain the local originals for a later deliberate merge; the app never automatically deletes cloud records to make room.

## LTO driver's license expiry

No additional SQL is required for license tracking. The app saves the validity and printed expiry date in the existing private `settings` table under `driver_license`.

Use **Dashboard or Settings → LTO driver's license → Add LTO license**. Choose 5 or 10 years as printed on the license, then select the exact expiry date. It is personal to your account and stays the same across vehicles. Edit it after renewal; the optional renewal estimate adds 5 or 10 years to the previous saved expiry date, with February 29 clamped to February 28 in a non-leap year. Verify estimates against the renewed license.

Dashboard status highlights expiry within 60 days, expiry today, and expired dates. Enable **Maintenance & license notifications** in Settings on Android for future alerts at 60, 30 and 7 days before expiry and on the day, around 9 AM. Delivery depends on Android notification permissions and battery restrictions. Chrome shows the dashboard status only.

[LTO guidance](https://lto.gov.ph/wp-content/uploads/2023/10/MEMO_11102021_CitizenCharter_Licensing-Transaction.pdf) ties expiry to the holder's birthday and specifies conditions for ten-year validity. The app tracks the entered date; it does not verify license eligibility or legal status.

## Tire replacement estimates

Open **Tire care** from the phone toolbar, desktop sidebar, dashboard, or garage. Each vehicle supports front-left, front-right, rear-left, rear-right and spare entries.

- Enter the manufacture month and year, brand/model if known, and a replacement age between 1 and 10 years.
- The default planning age is **6 years**, adjustable to the vehicle or tire manufacturer's guidance.
- Target = manufacture month/year + chosen age. For example, September 2022 + 6 years gives **September 2028**.
- If only the manufacture year is known, January provides a conservative estimate.
- The app flags tires at 5 years for inspection, targets within 6 months, and reached targets. These are planning flags, not a measured health score or a guaranteed expiry date.
- Record the new manufacture date when replacing a tire. Regular inspections remain necessary because tread, pressure, damage, storage and use affect tire life. Spare tires also age.

[NHTSA tire guidance](https://www.nhtsa.gov/vehicle-safety/tires) describes age-related replacement guidance of 6–10 years from some manufacturers and how to read the DOT manufacture week/year. Follow the specific tire and vehicle guidance if it calls for earlier replacement.

## Validation and limitations

`flutter analyze` and `flutter test` cover the app, tire date boundaries, per-vehicle isolation, cloud HTTP requests, and legacy database behavior. To execute the migration and security/transaction checks in embedded PostgreSQL:

```powershell
npm.cmd install --prefix build/sql-validation @electric-sql/pglite
node scripts/test_supabase.mjs
```

These checks use local Auth stubs and two user roles. A live Supabase project, real email delivery, and Android deep links/reminder delivery still need a smoke test after you supply project configuration. No cloud database is provisioned or connected by the code alone. Builds made without configuration intentionally show the setup screen.
