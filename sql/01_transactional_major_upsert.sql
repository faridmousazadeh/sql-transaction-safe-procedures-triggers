USE TinyU;
GO
SET XACT_ABORT ON;
GO

DROP PROCEDURE IF EXISTS dbo.p_upsert_major;
GO

CREATE PROCEDURE dbo.p_upsert_major
    @major_code char(3),
    @major_name varchar(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.majors WITH (UPDLOCK, HOLDLOCK)
            WHERE major_code = @major_code
        )
        BEGIN
            UPDATE dbo.majors
            SET major_name = @major_name
            WHERE major_code = @major_code;

            IF @@ROWCOUNT <> 1
                THROW 50001, 'p_upsert_major: update must affect exactly one row.', 1;
        END
        ELSE
        BEGIN
            DECLARE @next_major_id int;

            SELECT @next_major_id = COALESCE(MAX(major_id), 0) + 1
            FROM dbo.majors;

            INSERT INTO dbo.majors (major_id, major_code, major_name)
            VALUES (@next_major_id, @major_code, @major_name);

            IF @@ROWCOUNT <> 1
                THROW 50002, 'p_upsert_major: insert must affect exactly one row.', 1;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Demonstrate both the update path and the insert path.
EXEC dbo.p_upsert_major 'ADS', 'Applied Data Science';
SELECT major_id, major_code, major_name
FROM dbo.majors
WHERE major_code = 'ADS';
GO

EXEC dbo.p_upsert_major 'DSC', 'Data Science';
SELECT major_id, major_code, major_name
FROM dbo.majors
WHERE major_code = 'DSC';
GO
