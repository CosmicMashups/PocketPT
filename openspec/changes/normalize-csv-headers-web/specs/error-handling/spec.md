<!-- OPENSPEC:START -->
## MODIFIED Requirements: Error Handling on Column Presence

- Requirement: Column presence checks MUST operate on normalized keys and prefer degrade-and-continue behavior.

#### Scenario: "Other_Muscles" header variant present
- Given the data includes `Other Muscles`,\
  When normalized,\
  Then the system MUST NOT raise "missing column" and proceeds.

#### Scenario: Truly missing column
- Given the column is absent,\
  When generating a plan,\
  Then the system logs a concise warning and continues using available columns, avoiding a fatal error on Web or Android.
<!-- OPENSPEC:END -->

