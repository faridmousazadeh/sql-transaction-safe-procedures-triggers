# SQL Server Transactions, Concurrency & Data Integrity

## Overview

This repository presents SQL Server transaction, error-handling, and data-integrity coursework from IST 659 Problem Set 8. The TinyU and vBay exercises demonstrate explicit transactions, `TRY/CATCH`, row-count checks, selected lock hints, and an enrollment-limit trigger.

The examples demonstrate specific safeguards and their limits. They do not establish that all operations are concurrency-safe or suitable for production use.

## Course

**IST 659 — Data Administration Concepts and Database Management**  
Syracuse University

## Objectives

- Apply explicit transaction and error-handling patterns to stored procedures.
- Check expected affected-row counts and rethrow errors.
- Coordinate selected procedure operations with lock hints.
- Apply a per-major enrollment limit to insert and update statements.
- Document database-state assumptions needed by the examples.

## Technical Skills

- SQL Server / T-SQL
- Stored procedures and parameters
- `BEGIN TRANSACTION`, `COMMIT`, and conditional rollback using `XACT_STATE()`
- `TRY/CATCH`, `THROW`, and `SET XACT_ABORT ON`
- `@@ROWCOUNT` validation
- `UPDLOCK` and `HOLDLOCK`
- Set-based triggers using `inserted` and `deleted`
- Business-rule checks with subqueries and `NOT EXISTS`

## Transaction and Concurrency Concepts

Each of the three procedure scripts uses `BEGIN TRANSACTION`, `COMMIT`, and `TRY/CATCH`. In each `CATCH` block, the script checks `XACT_STATE()`, rolls back if a transaction remains active, and rethrows the error with `THROW`. The scripts set `XACT_ABORT ON` before the procedure definition and demonstration calls. The procedures check `@@ROWCOUNT` after applicable lookup, update, or insert operations.

The procedures do not use savepoints or transaction-count-aware handling. They are not designed to safely compose inside an existing caller transaction: an error path's unqualified `ROLLBACK` can roll back the entire ambient transaction.

### Major upsert

`dbo.p_upsert_major` uses `UPDLOCK, HOLDLOCK` on the `major_code` lookup to coordinate the update-or-insert decision for that code. When inserting, it calculates `COALESCE(MAX(major_id), 0) + 1`. This manual ID-allocation approach can still race when concurrent insertions use different major codes.

### Bid placement

`dbo.p_place_bid` locks the selected item row while it reads the current valid-bid threshold and inserts the new bid. This is intended to coordinate callers using this procedure for the same item. It does not control direct writes to the bids table that bypass the procedure.

### Rating insertion

`dbo.p_rate_user` wraps the rating insert in a transaction, but the procedure does not itself validate or reject self-ratings. The expected rejection depends on an external database constraint or trigger.

## Procedures and Trigger

| File | Database | Purpose |
| --- | --- | --- |
| [`sql/01_transactional_major_upsert.sql`](sql/01_transactional_major_upsert.sql) | TinyU | Upserts by major code, checks affected-row counts, and uses a lock hint on the lookup. Manual ID allocation has a documented concurrency limitation. |
| [`sql/02_transactional_place_bid.sql`](sql/02_transactional_place_bid.sql) | vBay | Calculates bid status from seller identity, reserve price, and the highest valid bid, then inserts the bid in a transaction. |
| [`sql/03_transactional_rate_user.sql`](sql/03_transactional_rate_user.sql) | vBay | Inserts a rating in a transaction. Self-rating rejection depends on a database constraint or trigger. |
| [`sql/04_major_student_limit_trigger.sql`](sql/04_major_student_limit_trigger.sql) | TinyU | An `INSTEAD OF INSERT, UPDATE` trigger that checks a per-major enrollment limit of 15. |

## Enrollment-Limit Business Rule

The trigger checks the resulting student count for each affected non-NULL major in the current insert or update statement. It uses `inserted` and `deleted` to count unaffected existing students plus proposed rows, excluding the previous versions of updated rows. If any resulting count exceeds 15, it throws before applying the base-table changes; otherwise, it applies accepted rows set-wise.

This demonstrates a set-based check for each affected statement. The repository does not provide evidence that the trigger serializes concurrent statements or prevents two simultaneous statements from exceeding the limit.

The sample cases assume ADS is major ID 2 with 15 students, major ID 3 has room, and student ID 40 currently belongs to major 3. The trigger also expects the status columns introduced in Problem Set 7.

## Project Structure

```text
sql-transaction-safe-procedures-triggers/
├── README.md
├── .gitignore
├── docs/
│   ├── design-notes.md
│   └── verification-notes.md
└── sql/
    ├── 01_transactional_major_upsert.sql
    ├── 02_transactional_place_bid.sql
    ├── 03_transactional_rate_user.sql
    └── 04_major_student_limit_trigger.sql
```

## Execution Context

The scripts target the SQL Server course databases TinyU and vBay. Run each numbered script separately in SQL Server Management Studio or Azure Data Studio against a disposable or course database copy.

The examples insert bids and ratings and alter student records. The trigger exercise expects the Problem Set 7 student status columns. Script 4's sample state includes a successful enrollment in major ID 3 and an attempted move of student ID 40 into full major ID 2. If a client stops after the intentionally rejected update, the final verification query can be run as a separate batch.

## Source Integrity and Provenance

The repository presents itself as a portfolio edition of Problem Set 8. It does not include a separate original-submission SQL copy, so the published scripts cannot be directly compared with the submitted source. The design and verification notes describe the intended behavior, assumptions, and limitations.

## Verification / Limitations

The TinyU and vBay databases are not included. The repository contains no runtime execution logs, screenshots, database exports, concurrency tests, benchmarks, or execution plans. The verification notes state that SQL was not run because the course databases were unavailable.

The repository does not establish complete concurrency safety, elimination of all race conditions, production readiness, empirically verified correctness, or performance improvement. The manual `MAX(major_id) + 1` allocation can race for concurrent inserts using different major codes. The bid procedure's lock coordination applies to callers using that procedure; direct writes are outside it. The trigger checks each statement's proposed resulting state but does not demonstrate serialization against concurrent statements. The procedures also lack savepoint-based handling for execution inside an existing transaction.

## Relationship to SQL Database Programming

The earlier [SQL Database Programming — TinyU](https://github.com/faridmousazadeh/sql-database-programming) repository presents related Problem Set 7 functionality, including `dbo.p_upsert_major` and a student-status trigger. Problem Set 8 builds on related TinyU functionality with transaction and error-handling patterns, row-count checks, lock hints, and additional business-rule work in vBay and the enrollment-limit trigger.

Both repositories define a procedure named `dbo.p_upsert_major`. Running this repository's script replaces the earlier procedure definition in the same TinyU database. The repositories remain separate because they demonstrate different coursework stages and capabilities.

## Key Takeaways

The coursework demonstrates transaction and data-integrity patterns in stored procedures and a set-based trigger, alongside limitations involving database state, concurrent access, and calls made inside an existing transaction.

## Course Context

This repository presents TinyU and vBay transaction, procedure, and trigger coursework from **IST 659 — Data Administration Concepts and Database Management**, Problem Set 8.
