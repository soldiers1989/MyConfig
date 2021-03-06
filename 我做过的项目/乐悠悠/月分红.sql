USE [serp3];
GO
/****** Object:  StoredProcedure [dbo].[proc_tb_customAfter_gaoji_10609]    Script Date: 2018/9/11 11:32:26 ******/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO  
--exec [proc_tb_customAfter_10609] 86,2014
ALTER PROC [dbo].[sp_team_month_Dividend_10609]
    @orderId INT ,
    @manuId INT
AS
    BEGIN
        BEGIN TRY
            BEGIN TRAN;
            
            SELECT  *
            INTO    #tb_customer
            FROM    dbo.tb_customer_10609
            WHERE   customer_catalog_id > 2591;
            WHILE((SELECT   COUNT(*) FROM     #tb_customer) != 0 )
                BEGIN
				--变量放在里面定义比较好点
				 DECLARE @fristzengsong INT = 0 ,
                @secondzengsong INT ,
                @custId INT ,
                @targetcustId INT ,--拿货上级
                @fristcustId INT ,
                @catalogId INT ,
                @fristcatalogId INT ,
                @quanlity INT , --自己的拿货数量
                @fanyongmoney DECIMAL(18, 2) ,
                @Order_num NVARCHAR(30) ,
                @target_quanlity INT ,
                @msg NVARCHAR(500)= ''; 

	--遍历每一行代理 然后删掉他
                    SELECT TOP 1
                            @custId = tb_customerID
                    FROM    #tb_customer;

                    SELECT  @catalogId = a.customer_catalog_id ,
                            @fristcatalogId = b.customer_catalog_id ,
                            @fristcustId = b.tb_customerID,
							@targetcustId=a.parent_id
                    FROM    tb_customer_10609 a
                            LEFT JOIN tb_customer_10609 b ON a.oldparent_id = b.tb_customerID
                            LEFT JOIN tb_customer_10609 c ON b.oldparent_id = c.tb_customerID
                    WHERE   a.tb_customerID = @custId;        			       
 --判断是否符合条件
                    SELECT TOP 1
                            @target_quanlity = ISNULL(value, 0)
                    FROM    tb_setting
                    WHERE   manufacturer_id = 10609
                            AND [key] = 'pingjijiang1'
                            AND setting_catalog_code = CAST(@fristcatalogId AS NVARCHAR(100));


                    SELECT  @quanlity = ISNULL(SUM(quantity),0)
                    FROM    tb_order_10609
                    WHERE   cust_id = @custId;
                    PRINT @custId;
                    PRINT @fristcatalogId;
                    PRINT @target_quanlity;
                    PRINT @quanlity;
					--如果不满足条件就不返了
                    IF ( @quanlity >= @target_quanlity )
                        BEGIN
						DECLARE @sonQuanlity INT --被推荐人的拿货量
		   --推荐平级并且只有第一个才有返佣
		       SELECT @sonQuanlity=ISNULL(SUM(quantity),0) FROM dbo.tb_order_10609 WHERE cust_id IN (SELECT tb_customerID FROM tb_customer_10609 WHERE oldparent_id=@custId)

                                    SELECT TOP 1
                                            @fristzengsong = ISNULL(value,0) 
                                    FROM    tb_setting
                                    WHERE   manufacturer_id = 10609
                                            AND [key] = 'pingjijiang2'
                                            AND setting_catalog_code = CAST(@fristcatalogId AS NVARCHAR(100));
									--计算钱
                                    SET @fanyongmoney = CAST(@fristzengsong AS DECIMAL(18,
                                                              2)) * @sonQuanlity;
	
                                    PRINT @fristzengsong;
                                    PRINT @fanyongmoney; 

									--这张单要判断是否超过上限
                                    DECLARE @max DECIMAL(18, 2) ,
                                        @totalfanli DECIMAL(18, 2);
                                    SELECT TOP 1
                                            @max = ISNULL(value, 0)
                                    FROM    tb_setting
                                    WHERE   manufacturer_id = 10609
                                            AND [key] = 'pingjijiang3'
                                            AND setting_catalog_code = CAST(@fristcatalogId AS NVARCHAR(100));
								 
                                    SELECT  @totalfanli =ISNULL(SUM(value),0)
                                    FROM    dbo.cust_personal_center_in_10609
                                    WHERE   source = 22
                                            AND cust_id = @custId;
                                    IF ( @totalfanli + @fanyongmoney > @max )
                                        BEGIN
                                            SET @fanyongmoney = @max
                                                - @totalfanli;
                                        END;
                                    IF ( @fanyongmoney > 0 )
                                        BEGIN
                                            EXEC dbo.sp_cust_personalcenter_in @cust_id = @fristcustId, -- int
                                                @source = 22, -- int --第一级推荐奖
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
                                                      22 , -- type - smallint --推荐奖
                                                      0 , -- brandId - int
                                                      N''  -- json - nvarchar(2000)
							                        );
							--扣上级的钱
                                            IF ( @targetcustId != 0 )
                                                BEGIN
                                                    EXEC dbo.sp_cust_personalcenter_out @cust_id = @targetcustId,
                                                        @source = 24,
                                                        @type = 1,
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
                                                              24 , -- type - smallint --推荐奖
                                                              0 , -- brandId - int
                                                              N''  -- json - nvarchar(2000)
							                                );

                                                END;
                                        END;	
                                END;
              
						
				--删除遍历这行
                    DELETE  #tb_customer
                    WHERE   tb_customerID = @custId;
                END;
            PRINT '提交事务';
            COMMIT TRAN;
        END TRY
        BEGIN CATCH
            PRINT '回滚事务';
            ROLLBACK TRAN;
        END CATCH; 
    END;


 
