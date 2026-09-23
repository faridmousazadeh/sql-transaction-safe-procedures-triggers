# Transaction-Safe SQL Server Procedures and Triggers

A portfolio edition of IST 659 Problem Set 8. The examples apply explicit transactions and `TRY...CATCH` handling to TinyU and vBay data logic, then use an `INSTEAD OF` trigger to enforce a per-major student limit.

## Exercises

| File | Database | Exercise |
| --- | --- | --- |
| [`sql/01_transactional_major_upsert.sql`](sql/01_transactional_major_upsert.sql) | TinyU | Upsert by major code and reject unexpected row counts. |
| [`sql/02_transactional_place_bid.sql`](sql/02_transactional_place_bid.sql) | vBay | Place and verify User 2's $105 bid on Item 36. |
| [`sql/03_transactional_rate_user.sql`](sql/03_transactional_rate_user.sql) | vBay | Commit a rating and demonstrate rollback when the database rejects a self-rating. |
| [`sql/04_major_student_limit_trigger.sql`](sql/04_major_student_limit_trigger.sql) | TinyU | Allow a valid enrollment and reject a change that would exceed 15 students in a major. |
| [`docs/design-notes.md`](docs/design-notes.md) | — | Transaction boundaries, trigger logic, and assumptions. |
| [`docs/verification-notes.md`](docs/verification-notes.md) | — | Scope and unverified runtime dependencies. |

## Before running

Use a disposable/course copy of the databases: the examples insert bids and ratings, and alter student records. The trigger exercise expects the Problem Set 7 student status columns (`student_active` and `student_inactive_date`) to exist. The supplied test data also assumes major ID 2 is ADS with 15 students, major ID 3 is below capacity, and student ID 40 currently belongs to major 3.

Run each numbered script separately in SQL Server Management Studio or Azure Data Studio. If the client stops after the intentionally rejected trigger update, run the final verification query as a separate batch.

## Scope

These are SQL Server exercises tied to the course schemas. The scripts document expected calls and verification queries, but no live TinyU/vBay database was attached here, so no runtime output is claimed.
