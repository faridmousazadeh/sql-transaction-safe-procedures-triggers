USE TinyU;
GO

DROP TRIGGER IF EXISTS dbo.tr_limit_major_students;
GO

CREATE TRIGGER dbo.tr_limit_major_students
ON dbo.students
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Count the table's unaffected rows plus the proposed rows for every
    -- non-NULL major represented in this statement. Reject the whole statement
    -- if any resulting major count would exceed 15.
    IF EXISTS
    (
        SELECT 1
        FROM
        (
            SELECT DISTINCT student_major_id
            FROM inserted
            WHERE student_major_id IS NOT NULL
        ) AS proposed
        WHERE
        (
            SELECT COUNT(*)
            FROM dbo.students AS current_students
            WHERE current_students.student_major_id = proposed.student_major_id
              AND NOT EXISTS
              (
                  SELECT 1
                  FROM deleted AS old_students
                  WHERE old_students.student_id = current_students.student_id
              )
        )
        +
        (
            SELECT COUNT(*)
            FROM inserted AS new_students
            WHERE new_students.student_major_id = proposed.student_major_id
        ) > 15
    )
    BEGIN
        THROW 50301, 'A major cannot have more than 15 students.', 1;
    END;

    -- INSTEAD OF triggers must apply accepted changes to the base table.
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE current_students
        SET student_firstname = new_students.student_firstname,
            student_lastname = new_students.student_lastname,
            student_year_name = new_students.student_year_name,
            student_major_id = new_students.student_major_id,
            student_gpa = new_students.student_gpa,
            student_notes = new_students.student_notes,
            student_active = new_students.student_active,
            student_inactive_date = new_students.student_inactive_date
        FROM dbo.students AS current_students
        INNER JOIN inserted AS new_students
            ON new_students.student_id = current_students.student_id;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.students
            (student_firstname, student_lastname, student_year_name,
             student_major_id, student_gpa, student_notes,
             student_active, student_inactive_date)
        SELECT student_firstname, student_lastname, student_year_name,
               student_major_id, student_gpa, student_notes,
               student_active, student_inactive_date
        FROM inserted;
    END;
END;
GO

-- Check current enrollment in the assignment's ADS major (ID 2).
SELECT student_major_id, COUNT(*) AS student_count
FROM dbo.students
WHERE student_major_id = 2
GROUP BY student_major_id;
GO

-- Success case: major ID 3 is expected to be below the 15-student limit.
INSERT INTO dbo.students
    (student_firstname, student_lastname, student_year_name,
     student_major_id, student_gpa, student_notes,
     student_active, student_inactive_date)
VALUES
    ('Q8', 'Success', 'Freshman', 3, 3.000,
     'Q8 final success', 'Y', NULL);
GO

SELECT student_id, student_firstname, student_lastname, student_major_id
FROM dbo.students
WHERE CAST(student_notes AS varchar(max)) = 'Q8 final success';
GO

-- Failure case: student 40 is expected to be in major 3. ADS (ID 2) already
-- has 15 students, so this update should be rejected in full.
UPDATE dbo.students
SET student_major_id = 2
WHERE student_id = 40;
GO

-- Run this verification query even if the client stopped after the rejected
-- statement. Student 40 should still have major ID 3.
SELECT student_id, student_firstname, student_lastname, student_major_id
FROM dbo.students
WHERE student_id = 40;
GO
