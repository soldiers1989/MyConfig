USE [serp3];
GO
/****** Object:  StoredProcedure [dbo].[proc_tb_customAfter_shiyongzhuan_10614]    Script Date: 2018/9/3 13:52:03 ******/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
--exec [proc_tb_customAfter_10614] 86,2014
ALTER PROC [dbo].[proc_tb_customAfter_pingji_10614]
    @orderId INT ,
    @manuId INT
AS
    BEGIN
        BEGIN TRY
            BEGIN TRAN;
	    --判断是否已经审核过
            IF ( ( SELECT   COUNT(*)
                   FROM     tb_order_10614
                   WHERE    ID = @orderId
                            AND status = 1
                 ) = 1 )
                BEGIN
                    DECLARE @fristzengsong INT = 0 ,
                        @secondzengsong INT ,
                        @custId INT ,
                        @fristcustId INT ,
                        @secondcustId INT ,
                        @catalogId INT ,
                        @fristcatalogId INT ,
                        @secondcatalogId INT ,
                        @goodsId INT , --取订单第一个商品
                        @mssage NVARCHAR(500)= '';  
		--按照推荐级别来赠送
                    SELECT  @custId = cust_id
                    FROM    tb_order_10614
                    WHERE   ID = @orderId;


                    SELECT  @catalogId = a.customer_catalog_id ,
                            @fristcatalogId = b.customer_catalog_id ,
                            @secondcatalogId = c.customer_catalog_id ,
                            @fristcustId = b.tb_customerID ,
                            @secondcustId = c.tb_customerID
                    FROM    tb_customer_10614 a
                            LEFT JOIN tb_customer_10614 b ON a.oldparent_id = b.tb_customerID
                            LEFT JOIN tb_customer_10614 c ON b.oldparent_id = c.tb_customerID
                    WHERE   a.tb_customerID = @custId;
		   
                    SELECT TOP 1
                            @goodsId = goods_id
                    FROM    dbo.tb_order_detail_10614
                    WHERE   order_id = @orderId;	

                    PRINT @goodsId;
                    PRINT @custId;
                    PRINT @fristcatalogId;
                    PRINT @secondcatalogId;
		  
		   --第一级如果比他小或者相等 第二个就有  
                    IF ( @fristcatalogId <= @catalogId )
                        BEGIN
                            IF ( @fristcatalogId = @catalogId )
                                BEGIN
					--第一级
                                    SELECT TOP 1
                                            @fristzengsong = ISNULL(value, 0)
                                    FROM    tb_setting
                                    WHERE   manufacturer_id = 10614
                                            AND [key] = 'tjYiDaiYongJiuPurchase'
                                            AND setting_catalog_code = CAST(@fristcatalogId AS NVARCHAR(100));
                                    PRINT @fristzengsong;
                                    EXEC dbo.sp_order_stock_in_or_out_10474 @manuid = 10614, -- int
                                        @order_id = @orderId, -- int
                                        @cust_id = @fristcustId, -- int
                                        @to_cust_id = 0, -- int
                                        @goods_id = @goodsId, -- int
                                        @quantity = @fristzengsong, -- int
                                        @type = 1, -- int
                                        @in_or_out = N'in', -- nvarchar(20)
                                        @mssage = @mssage OUTPUT;
				
                                END;
                            IF ( @secondcatalogId = @catalogId )
                                BEGIN
					--第二级
                                    SELECT TOP 1
                                            @secondzengsong = ISNULL(value, 0)
                                    FROM    tb_setting
                                    WHERE   manufacturer_id = 10614
                                            AND [key] = 'tjErDaiYongJiuPurchase'
                                            AND setting_catalog_code = CAST(@secondcatalogId AS NVARCHAR(100));
                                    PRINT @secondzengsong;
                                    EXEC dbo.sp_order_stock_in_or_out_10474 @manuid = 10614, -- int
                                        @order_id = @orderId, -- int
                                        @cust_id = @secondcustId, -- int
                                        @to_cust_id = 0, -- int
                                        @goods_id = @goodsId, -- int
                                        @quantity = @secondzengsong, -- int
                                        @type = 1, -- int
                                        @in_or_out = N'in', -- nvarchar(20)
                                        @mssage = @mssage OUTPUT;
                                END;
                        END;
                END;
            PRINT '提交事务';
            COMMIT TRAN;
        END TRY
        BEGIN CATCH
            PRINT '回滚事务';
            ROLLBACK TRAN;
        END CATCH; 
    END;


 
