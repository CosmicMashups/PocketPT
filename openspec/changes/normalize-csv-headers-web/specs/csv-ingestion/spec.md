<!-- OPENSPEC:START -->
## MODIFIED Requirements: CSV Ingestion Normalization

- Requirement: Header keys from `assets/data/exercises.csv` MUST be normalized before access.
  - Normalization: strip BOM (U+FEFF), remove `\r`, trim, strip surrounding `"..."`, lowercase, convert spaces to `_`.
  - Canonical examples:
    - `Other_Muscles` → `other_muscles`
    - `Other Muscles` → `other_muscles`
    - `"Other_Muscles"` → `other_muscles`

#### Scenario: Web reads CSV with BOM and CRLF
- Given a CSV whose first header cell includes a BOM and CRLF,\
  When headers are normalized,\
  Then `Other_Muscles` is accessible via canonical key `other_muscles`.

#### Scenario: Quoted headers
- Given headers are quoted,\
  When normalized,\
  Then quotes are removed and the key matches the canonical form.

#### Scenario: Missing column handling
- Given a column is truly missing,\
  When accessing via normalized keys,\
  Then the system logs a warning and continues with best-effort behavior instead of aborting plan generation.

- Requirement: Field access MUST use a safe lookup with the normalized header map.

#### Scenario: Safe cell access out-of-range
- Given a shorter row,\
  When accessing a field,\
  Then an empty string is returned without throwing.
<!-- OPENSPEC:END -->

