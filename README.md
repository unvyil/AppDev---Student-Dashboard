# LPU Student Information App

Flutter coursework app covering API integration, responsive dashboards,
registration, local storage, and text-file export.

## Dart source inventory

| Dart file | Responsibility | Requirement coverage |
| --- | --- | --- |
| `lib/main.dart` | App entry point, theme, and home route | Flutter app setup |
| `lib/home_page.dart` | Four-destination navigation, compact profile, weather hero, health badges, quick actions, world clock, and live feed | Student dashboard |
| `lib/settings_page.dart` | Profile editing, appearance, data export, storage, API mode, and diagnostics | Settings and app management |
| `lib/students_page.dart` | Student and CCS programme analytics backed by local registrations | Student Stats and Program Stats |
| `lib/faculty_page.dart` | Standalone faculty directory section | Faculty directory challenge |
| `lib/registration_page.dart` | Validated student form and navigation to summary | Week 3 form and registration flow |
| `lib/summary_page.dart` | Student details and file-export confirmation | Week 3 summary and export flow |
| `lib/about_page.dart` | Legacy About placeholder (not in navigation) | Coming soon |
| `lib/files_page.dart` | Legacy file browser (export is available in Settings) | Week 3 file-management/retrieval demo |
| `lib/services/storage_service.dart` | Student model and SharedPreferences persistence | Week 3 local storage |
| `lib/services/app_preferences.dart` | Persisted theme, mock-data, and profile-photo preferences | Appearance, API mode, and profile photo |
| `lib/widgets/profile_avatar.dart` | Shared profile photo and initials fallback | Profile identity |
| `lib/services/file_service.dart` | Creates and reads `student_info.txt` | Week 3 file export |

Generated Dart files currently present in `.dart_tool` are build/tooling
outputs, not app source: `.dart_tool/extension_discovery/README.md` is not a
Dart file; `.dart_tool/flutter_build/dart_plugin_registrant.dart` and
`.dart_tool/dartpad/web_plugin_registrant.dart` are generated registrants.
Do not edit these generated files.

## Week 2 API notes

The app calls:

- `GET https://jsonplaceholder.typicode.com/users` for the API health indicator
- `GET https://api.open-meteo.com/v1/forecast` for current weather near
  LPU-Cavite (fixed coordinates, timezone `Asia/Manila`)
- `GET https://date.nager.at/api/v3/PublicHolidays/{year}/PH` for Philippine
  public holidays in the current year

The dashboard displays weather temperature, apparent temperature, humidity,
and a weather-code description from Open-Meteo. It displays upcoming holidays
from Nager.Date. Both integrations show loading and retryable error states.
Weather is for a fixed Cavite location rather than device GPS.

Dashboard system indicators use `connectivity_plus` to distinguish Wi-Fi from
other network types, `geolocator` to check whether the device location service
is enabled (without requesting or reading location), and successful
SharedPreferences access for the app-storage status. “API Online” is shown
only when the weather, holiday, and JSONPlaceholder endpoints all respond
successfully in Live API mode. Settings can switch the dashboard to clearly
identified local sample data for weather and calendar cards; device health
checks remain live. The world clock displays Manila, Tokyo, and UTC times.

The faculty identity/contact values in the Faculty tab are clearly mock data,
not official LPU directory information.

## Week 3 behavior

- Registration requires student name, ID, valid email, program, and year
  level. Contact number and address are optional. Validation failures are
  shown inline; duplicate student IDs produce a SnackBar.
- Registered records are persisted in SharedPreferences and reloaded on the
  Students page after app restart.
- `student_info.txt` is written to the app's documents directory and includes
  student name, ID, email, program, year level, contact, and address. Student
  records can be exported from Settings. The app-private documents folder can
  be inspected with Android Studio Device Explorer while the device is
  connected.
- Dashboard health, quick-action, and Students programme cards use two columns
  on phone-sized screens and four columns on wider screens. Programme counts
  reflect saved student records tagged with each track code.
- The dashboard greeting is “Hello, Novy” and the compact Student Details
  card uses a saved Novy record if available; otherwise it shows the Novy
  Chariz Tablac sample profile. Full details are behind the profile sheet.
- The bottom navigation contains Home, Students, Faculty, and Settings.
  Settings is also opened from the profile avatar. Files are exported from
  Settings rather than shown as a navigation destination.
- Aggregate Student Stats and attendance values are illustrative metrics.
  Actual registered records and programme enrollment counts come from local
  storage.
- Profile photos are selected from the gallery or camera and stored with app
  preferences. Removing a photo restores the initials avatar.
- The dashboard has a seven-day calendar strip and recent activity timeline
  for registration and record exports.

## Reflection

### Week 2: How do APIs support system integration and real-time information?

APIs provide a defined way for independent systems to exchange structured
data. A mobile application can request current information from a service
instead of storing a separate, stale copy of that information. The app parses
the response, presents loading and error states, and refreshes the display
when new data is requested. This lets systems integrate while keeping their
internal implementations separate.

### Week 3 written answers

1. **Local storage vs. file storage:** Local key-value storage is intended for
   small, structured values the app needs to retrieve quickly. File storage
   is suited to larger or human-readable documents that users or other tools
   may inspect or share.
2. **Why save information locally?** Local persistence keeps useful app data
   available between launches and can reduce repeated network requests. It
   also supports basic offline access, subject to privacy and security needs.
3. **SharedPreferences vs. text files:** Use SharedPreferences for small
   settings or simple persistent values owned by the app. Use a text file when
   the data should be formatted as a document or inspected/exported outside
   the app.
4. **Responsive design:** Adapting layout to available width makes content
   readable and controls usable on both phones and tablets, instead of
   stretching or crowding one fixed layout.
5. **File-export challenges:** App-private files are not necessarily visible
   in a consumer Files app. Finding the export requires knowing the app's
   documents-directory path and using Android Studio Device Explorer or an
   appropriate device file tool. Permissions and Android storage restrictions
   can also affect access.

## Required evidence to capture

Screenshots and physical-device deployment evidence are not source-code
artifacts. Capture these from the actual development environment/device:

- `screenshots/dashboard-portrait.png` contains the portrait dashboard captured
  from the connected Android phone.
- Android Studio Welcome screen and Installed Components summary
- SDK Platforms and Tools verification
- Terminal output of `flutter devices`
- Dashboard in landscape
- App running on the physical Android device
- Week 3 home, registration, summary, stored-data retrieval, exported
  `student_info.txt` in Device Explorer, and phone/tablet responsive layouts
- API output (including `/users` and `/posts`) and the dashboard view

Connected-device deployment and UI evidence should be rechecked on the
submission machine; a build or device-list output alone is not a substitute
for those screenshots.
