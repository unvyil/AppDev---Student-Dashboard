# Progressive student portal snapshots

Each folder is a standalone Flutter package. Run `flutter pub get` and `flutter run` from the selected week folder.

- **week_1** — app entry point, responsive 364 px content area, input form, profile, overview, and navigation scaffold.
- **week_2** — includes the Week 1 foundation plus JSONPlaceholder student directory, faculty cards, and the four CCS track summaries.
- **week_3** — includes Week 2 plus student registration, local student-list persistence, theme preference persistence, dashboard count synchronization, and text export.

The week folders intentionally contain snapshots so coursework can be submitted independently. Week 3 mirrors the current project files as of the snapshot and remains separate from the original project root.

## Notes

- The API directory uses JSONPlaceholder sample users, not actual student records.
- Programme enrolment counts are the supplied fixed lab-sheet figures; they are not calculated from registered records.
