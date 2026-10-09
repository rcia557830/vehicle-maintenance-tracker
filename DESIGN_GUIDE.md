# Motorcare UI guide

Motorcare uses one Material 3 theme in `lib/theme/app_theme.dart`. Navy anchors the navigation, teal identifies primary actions, and a light neutral canvas separates the content cards.

## Shared components

- `workspace.dart`: page headings, panels, form sections, responsive pairs and metadata rows.
- `common.dart`: metric tiles, section titles, empty states and maintenance status chips.
- `feedback.dart`: text-and-icon status badges, information banners, loading and saving indicators.
- `vehicle_card.dart`: garage summary and selection action.
- `maintenance_card.dart`: service summary reused by mobile history, expenses and the dashboard.
- `date_picker_field.dart`: calendar input; the calling screen owns its date and validation.
- `license_status.dart`: consistent license status presentation.

## Design rules

Use green for completed/valid states, amber for approaching deadlines, red for overdue/expired/errors, and blue for neutral information or future schedules. Every status includes text and an icon, so color is not the only cue.

Use the existing theme for buttons, fields, dialogs and cards. Primary actions use FilledButton; secondary actions use OutlinedButton; destructive actions use red text and retain their confirmation dialog. Forms use labeled fields, inline validation and disabled controls while saving. Blank screens offer a useful next action.

Layouts stack on phones and use columns or tables when space permits. Avoid fixed-height text containers; allow labels and buttons to wrap. The dashboard prioritizes the active vehicle, odometer, expense totals, service status and next maintenance, followed by the service queue, tire/license reminders and recent history.

## Architecture

This redesign changes presentation and feedback. Screens still call MaintenanceProvider, which uses the existing repository and notification services. Supabase authentication, schema, account isolation, CRUD operations and reminder calculations remain in their existing layers. No migration is needed for the redesign.

## Checks

Run `flutter pub get`, `flutter analyze` and `flutter test`. On Windows, `flutter test --dart-define=CAPTURE_UI=true` also writes preview images under `build/ui/`. Authentication tests use a mock Supabase client; they do not modify a live account.
