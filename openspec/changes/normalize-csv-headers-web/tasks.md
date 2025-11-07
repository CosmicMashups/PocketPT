<!-- OPENSPEC:START -->
1. Add a CSV utility (`lib/data/csv_utils.dart`) providing:
   - Header normalization (strip BOM, remove `\r`, trim, strip quotes, lowercase, replace spaces with underscores).
   - `buildHeaderIndexMap`, `safeCell`, and `loadCsvAsset(cache: false)` helpers.
2. Update CSV consumers used by the `lib/assessment/generate_plan.dart` flow (e.g., `generateRehabilitationPlanFromCSV`, exercise/treatment data services) to:
   - Load CSV with `loadCsvAsset('assets/data/exercises.csv')`.
   - Build a normalized header map once and use `safeCell` for accesses.
   - Replace brittle raw-string column checks with normalized key checks; warn and continue if missing.
3. Map header variants to canonical names (`Other_Muscles` / `Other Muscles` → `other_muscles`).
4. Confirm `pubspec.yaml` includes `assets/data/exercises.csv`.
5. Add debug-only logs for detected header variants and normalization results.
6. Web validation:
   - Build: `flutter build web --debug --base-href /PocketPT/ --pwa-strategy none`.
   - Run: `flutter run -d chrome` and verify plan generation uses `other_muscles`.
   - Deploy to GitHub Pages and verify no stale CSV (cache bypass effective).
7. Android regression:
   - Build: `flutter build apk --debug` and verify plan generation unaffected.
8. Optional: Unit test normalization (BOM, CRLF, quoted headers, spaces vs underscores).
<!-- OPENSPEC:END -->

