# Progressive student portal snapshots

Each folder is a standalone Flutter package. Run `flutter pub get` and `flutter run` from the selected week folder.

- **week_1** — app entry point, responsive 364 px content area, input form, profile, overview, and navigation scaffold, styled to match the dashboard palette and Inter typography.
- **week_2** — includes the Week 1 foundation and visual system plus JSONPlaceholder student directory, faculty cards, and the four CCS track summaries.
- **week_3** — full dashboard snapshot with registration, summary, local JSON storage, file export, and responsive layout. It opens directly to Home without login/signup.
- **week_4** — Week 3 snapshot with login/signup retained, plus the Week 4 dashboard/API/CRUD progression from the lab activity.

The week folders intentionally contain snapshots so coursework can be submitted independently. Week 3 mirrors the current project files as of the snapshot and remains separate from the original project root.

## Notes

- The API directory uses JSONPlaceholder sample users, not actual student records.
- Programme enrolment counts are the supplied fixed lab-sheet figures; they are not calculated from registered records.
