USE [serp3];
GO
/****** Object:  StoredProcedure [dbo].[proc_tb_customAfter_pingji_10609]    Script Date: 2018/9/3 15:41:55 ******/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
--exec [proc_tb_customAfter_10609] 86,2014
CREATE PROC [dbo].[proc_tb_customAfter_gaoji_10609]
    @orderId INT ,
    @manuId INT
AS
    BEGIN
        BEGIN TRY
            BEGIN TRAN;
	    --判断是否已经审核过
            IF ( ( SELECT   COUNT(*)
                   FROM     tb_order_10609
                   WHERE    ID = @orderId
                            AND status = 1
                 ) = 1 )
                BEGIN
                    DECLARE @fristzengsong INT = 0 ,
                        @secondzengsong INT ,
                        @custId INT ,
                        @targetcustId INT ,--拿货上级
                        @fristcustId INT ,
                        @secondcustId INT ,
                        @catalogId INT ,
                        @fristcatalogId INT ,
                        @secondcatalogId INT ,
                        @goodsId INT , --取订单第一个商品,
                        @quanlity INT ,
                        @fanyongmoney DECIMAL(18, 2) ,
                        @Order_num NVARCHAR(30) ,
                        @msg NVARCHAR(500)= '';  
		--按照推荐级别来赠送
                    SELECT  @custId = cust_id ,
                            @quanlity = quantity ,
                            @Order_num = Order_num ,
                            @targetcustId = target_cust_id
                    FROM    tb_order_10609
                    WHERE   ID = @orderId;


                    SELECT  @catalogId = a.customer_catalog_id ,
                            @fristcatalogId = b.customer_catalog_id ,
                            @secondcatalogId = c.customer_catalog_id ,
                            @fristcustId = b.tb_customerID ,
                            @secondcustId = c.tb_customerID
                    FROM    tb_customer_10609 a
                            LEFT JOIN tb_customer_10609 b ON a.oldparent_id = b.tb_customerID
                            LEFT JOIN tb_customer_10609 c ON b.oldparent_id = c.tb_customerID
                    WHERE   a.tb_customerID = @custId;
		   
                    SELECT TOP 1
                            @goodsId = goods_id
                    FROM    dbo.tb_order_detail_10609
                    WHERE   order_id = @orderId;	

                    PRINT @goodsId;
                    PRINT @custId;
                    PRINT @fristcatalogId;
                    PRINT @secondcatalogId;
		  
		   --推荐高级才有返佣
                    IF ( @fristcatalogId < @catalogId )
                        BEGIN
                         
					--第一级
                            SELECT TOP 1
                                    @fristzengsong = ISNULL(value, 0)
                            FROM    tb_setting
                            WHERE   manufacturer_id = 10609
                                    AND [key] = 'gaojijiang1'
                                    AND setting_catalog_code = CAST(@fristcatalogId AS NVARCHAR(100));
                            SET @fanyongmoney = CAST(@fristzengsong AS DECIMAL(18,
                                                              2)) * @quanlity;
	
                            PRINT @fristzengsong;
                            PRINT @fanyongmoney; 

									--这张单要判断是否超过上限
                            DECLARE @max DECIMAL(18, 2) ,
                                @totalfanli DECIMAL(18, 2);
                            SELECT TOP 1
                                    @fristzengsong = ISNULL(value, 0)
                            FROM    tb_setting
                            WHERE   manufacturer_id = 10609
                                    AND [key] = 'gaojijiang2'
                                    AND setting_catalog_code = CAST(@fristcatalogId AS NVARCHAR(100));
								 
                            SELECT  @totalfanli = SUM(value)
                            FROM    dbo.cust_personal_center_in_10609
                            WHERE   source = 21
                                    AND cust_id = @custId;
                            IF ( @totalfanli + @fanyongmoney > @max )
                                BEGIN
                                    SET @fanyongmoney = @max - @totalfanli;
                                END;
                            IF ( @fanyongmoney > 0 )
                                BEGIN
                                    EXEC dbo.sp_cust_personalcenter_in @cust_id = @fristcustId, -- int
                                        @source = 21, -- int --第一级推荐奖
                                        @type = 1, -- int
                                        @business_id = @orderId, -- int
                                        @value = @fanyongmoney, -- decimal
                                        @manufacturer_id = 10609, -- int
                                        @withdraw_status = 1, -- int
                                        @send_status = 0, -- int
                                        @msg = N''; -- nvarchar(1000)
						      
                                    INSERT  INTO dbo.tb_recommend_money_history_10609
                                            ( ordered_custId ,
                                              money ,
                                              recommend_custId ,
                                              orderNum ,
                                              createTime ,
                                              type ,
                                              brandId ,
                                              json
							                )
                                    VALUES  ( @custId , -- ordered_custId - int
                                              @fanyongmoney , -- money - decimal
                                              @fristcustId , -- recommend_custId - int
                                              @Order_num , -- orderNum - varchar(20)
                                              GETDATE() , -- createTime - datetime
                                              21 , -- type - smallint --推荐奖
                                              0 , -- brandId - int
                                              N''  -- json - nvarchar(2000)
							                );
							--扣上级的钱
                                    IF ( @targetcustId != 0 )
                                        BEGIN
                                            EXEC dbo.sp_cust_personalcenter_out @cust_id = @targetcustId,
                                                @source = 23, @type = 1,
                                                @business_id = @orderId,
                                                @value = @fanyongmoney,
                                                @manufacturer_id = 10609,
                                                @msg = @msg;	
                                            INSERT  INTO dbo.tb_recommend_money_history_10609
                                                    ( ordered_custId ,
                                                      money ,
                                                      recommend_custId ,
                                                      orderNum ,
                                                      createTime ,
                                                      type ,
                                                      brandId ,
                                                      json
							                        )
                                            VALUES  ( @fristcustId , -- ordered_custId - int
                                                      @fanyongmoney , -- money - decimal
                                                      @targetcustId , -- recommend_custId - int
                                                      @Order_num , -- orderNum - varchar(20)
                                                      GETDATE() , -- createTime - datetime
                                                      23 , -- type - smallint --推荐奖
                                                      0 , -- brandId - int
                                                      N''  -- json - nvarchar(2000)
							                        );

                                        END;
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


 
