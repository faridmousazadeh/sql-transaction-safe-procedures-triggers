USE vBay;
GO
SET XACT_ABORT ON;
GO

DROP PROCEDURE IF EXISTS dbo.p_place_bid;
GO

CREATE PROCEDURE dbo.p_place_bid
    @bid_item_id int,
    @bid_user_id int,
    @bid_amount money
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @max_bid_amount money;
        DECLARE @item_seller_user_id int;
        DECLARE @item_reserve money;
        DECLARE @bid_status varchar(20);

        IF @bid_amount IS NULL
            THROW 50100, 'p_place_bid: bid amount is required.', 1;

        -- Serialize procedure calls for the same item while the current bid
        -- threshold is read and the new bid is written.
        SELECT @item_seller_user_id = item_seller_user_id,
               @item_reserve = item_reserve
        FROM dbo.vb_items WITH (UPDLOCK, HOLDLOCK)
        WHERE item_id = @bid_item_id;

        IF @@ROWCOUNT <> 1
            THROW 50101, 'p_place_bid: item was not found.', 1;

        SELECT @max_bid_amount = MAX(bid_amount)
        FROM dbo.vb_bids
        WHERE bid_item_id = @bid_item_id
          AND bid_status = 'ok';

        SET @max_bid_amount = COALESCE(@max_bid_amount, @item_reserve);

        -- Seller status takes precedence over the low-bid status.
        SET @bid_status = CASE
            WHEN @item_seller_user_id = @bid_user_id THEN 'item_seller'
            WHEN @bid_amount <= @max_bid_amount THEN 'low_bid'
            ELSE 'ok'
        END;

        INSERT INTO dbo.vb_bids
            (bid_user_id, bid_item_id, bid_amount, bid_status)
        VALUES
            (@bid_user_id, @bid_item_id, @bid_amount, @bid_status);

        IF @@ROWCOUNT <> 1
            THROW 50102, 'p_place_bid: insert must affect exactly one row.', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Assignment demonstration: User 2 bids $105 on Item 36.
EXEC dbo.p_place_bid
    @bid_item_id = 36,
    @bid_user_id = 2,
    @bid_amount = 105;
GO

SELECT bid_id, bid_user_id, bid_item_id, bid_amount, bid_status, bid_datetime
FROM dbo.vb_bids
WHERE bid_item_id = 36
  AND bid_user_id = 2
  AND bid_amount = 105
ORDER BY bid_datetime DESC;
GO
