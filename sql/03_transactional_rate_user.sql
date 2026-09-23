USE vBay;
GO
SET XACT_ABORT ON;
GO

DROP PROCEDURE IF EXISTS dbo.p_rate_user;
GO

CREATE PROCEDURE dbo.p_rate_user
    @rating_by_user_id int,
    @rating_for_user_id int,
    @rating_astype varchar(20),
    @rating_value int,
    @rating_comment varchar(max)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.vb_user_ratings
            (rating_by_user_id, rating_for_user_id, rating_astype,
             rating_value, rating_comment)
        VALUES
            (@rating_by_user_id, @rating_for_user_id, @rating_astype,
             @rating_value, @rating_comment);

        IF @@ROWCOUNT <> 1
            THROW 50201, 'p_rate_user: insert must affect exactly one row.', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Valid six-star rating: expected to commit if permitted by the vBay schema.
EXEC dbo.p_rate_user
    @rating_by_user_id = 2,
    @rating_for_user_id = 1,
    @rating_astype = 'Buyer',
    @rating_value = 6,
    @rating_comment = 'great buyer';
GO

-- Self-rating is expected to be rejected by the vBay business rule (constraint
-- or trigger). Catch the expected error so the verification query can run.
BEGIN TRY
    EXEC dbo.p_rate_user
        @rating_by_user_id = 2,
        @rating_for_user_id = 2,
        @rating_astype = 'Buyer',
        @rating_value = 5,
        @rating_comment = 'rating myself';
END TRY
BEGIN CATCH
    PRINT CONCAT('Expected rejection: ', ERROR_MESSAGE());
END CATCH;
GO

-- No matching row should remain if the rejected call rolled back.
SELECT rating_by_user_id,
       rating_for_user_id,
       rating_astype,
       rating_value,
       CAST(rating_comment AS varchar(max)) AS rating_comment
FROM dbo.vb_user_ratings
WHERE rating_by_user_id = 2
  AND rating_for_user_id = 2
  AND CAST(rating_comment AS varchar(max)) = 'rating myself';
GO
