# Design notes

## Transaction pattern

Each stored procedure wraps its data change in `TRY...CATCH`, validates the expected affected-row count, and commits only when the operation succeeds. `SET XACT_ABORT ON` and `XACT_STATE()`-guarded rollback make errors safer to handle before the original error is rethrown.

`p_place_bid` locks the selected item row for the duration of the procedure call so concurrent executions of this procedure for the same item do not both evaluate the same old bid threshold. Direct writes that bypass the procedure are outside that serialization guarantee.

The major upsert follows the assignment's manually allocated `major_id` design. The `COALESCE` handles an empty table, but concurrent insertions of different major codes can still race while calculating `MAX(major_id) + 1`. A production allocator should use an identity/sequence or a serialized allocation strategy and enforce uniqueness on `major_code`.

## Rating rollback dependency

`p_rate_user` wraps the insert, but self-rating rejection is enforced by the TinyU/vBay schema's business rule (constraint or trigger), as implied by the assignment's expected test. The procedure alone does not invent that rule. The test catches the expected error and checks that the attempted self-rating is absent afterward.

## Instead-of trigger

The trigger checks the resulting count for each affected non-NULL major: unaffected existing students plus proposed inserted rows. It excludes old versions of updated students through `deleted`, so moving a student between majors is counted correctly. If any proposed count exceeds 15, it throws before applying the base-table insert/update. Accepted statements are applied set-wise, including statements that affect multiple students.

## Assignment-specific test assumptions

The sample cases rely on the supplied data state described in the assignment/source SQL: ADS is major ID 2 with 15 students; major ID 3 has room; student ID 40 is currently in major ID 3. The trigger also expects the two status columns introduced in Problem Set 7.
