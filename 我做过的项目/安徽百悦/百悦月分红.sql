USE [serp3]
GO
/****** Object:  StoredProcedure [dbo].[sp_team_month_Dividend_10563]    Script Date: 2018/8/1 16:30:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[sp_team_month_Dividend_10563]
AS
    BEGIN
        BEGIN TRY	
            BEGIN TRAN;
            PRINT '开始你的表演';
		--团队分红临时表
              CREATE TABLE #resultT--结果集
                (
                  Id INT IDENTITY(1, 1) ,
                  cstmId INT ,
                  yeji INT ,
                  fenhon DECIMAL(18, 2) ,--分红
             
		        );
            DECLARE @i INT = 1;
            DECLARE @tempCstmId INT ,
                @tempcatalog INT ,
                @tempYeJi DECIMAL(18, 2) ,
                @tempSetting DECIMAL(18, 2) ,
                @tempFenhon DECIMAL(18, 2) ,
                @max_catalog INT,
				@second_catalog INT,
				@manufacturer_id INT=10563,
				@nahuo_custId int; --最高级别的代理
	 
		--只有最高级别才会返佣
            
                SELECT  @max_catalog = tb_customer_catalogID
                FROM    dbo.tb_customer_catalog
                WHERE   manufacturer_id = 10563
                        AND parent_id = 0;

				 SELECT  @second_catalog = tb_customer_catalogID
                FROM    dbo.tb_customer_catalog
                WHERE   manufacturer_id = 10563
                        AND parent_id = @max_catalog;
			--把所有的代理都查出来然后按照推荐链倒序 最末端的就在第一条了
                INSERT  #resultT
                        ( cstmId ,
                          yeji ,
                          fenhon  
			            )
                        SELECT  tb_customerID ,
                                0.00 ,
                                0.00   
                        FROM    dbo.tb_customer_10563
						where (customer_catalog_id=@max_catalog OR customer_catalog_id=@second_catalog)
					 	--and tb_customerID IN(3,22)
                      
 
				    --遍历临时表中所有数据
                WHILE @i <= ( SELECT    COUNT(1)
                              FROM      #resultT
                            )
                    BEGIN
                        SELECT  @tempCstmId = cstmId
                        FROM    #resultT
                        WHERE   Id = @i;

						SELECT @nahuo_custId=parent_id FROM dbo.tb_customer_catalog WHERE tb_customer_catalogID=@tempCstmId

                        SELECT  @tempYeJi = ISNULL(SUM(money),0)
                        FROM    cust_payment_order_10563
                        WHERE   status = 1
                               -- AND pay_method != 3
                               AND create_time BETWEEN DATEADD(mm,
                                                            DATEDIFF(mm, 0,
                                                              DATEADD(MONTH,
                                                              -1, GETDATE())),
                                                            0)
                                            AND     DATEADD(mm,
                                                            DATEDIFF(mm, 0,
                                                              DATEADD(MONTH, 0,
                                                              GETDATE())), 0)
                                AND cust_id IN (
                                SELECT  tb_customerID
                                FROM    dbo.tb_customer_10563
                                WHERE   parent_str LIKE '%'
                                        + ( SELECT  parent_str
                                            FROM    tb_customer_10563
                                            WHERE   tb_customerID = @tempCstmId
                                          ) + '%' );
                        PRINT '钱钱' + CAST(@tempCstmId AS NVARCHAR(30));
                        PRINT @tempYeJi; 
				----计算个人业绩	 好像没什么用,先注释		
    --                        SELECT  @tempYeJi = ISNULL(SUM(money), 0)
    --                        FROM   cust_payment_order_10563 WHERE pay_method !=3 AND status=1
                                    --AND create_time > DATEADD(MONTH, -1,
                                    --                          GETDATE())
                                    --AND cust_id = @tempCstmId;
				--计算团队分红

                        SELECT TOP 1
                                @tempSetting = ISNULL(CAST(value AS DECIMAL),
                                                      0) / 100
                        FROM    dbo.tb_setting
                        WHERE   manufacturer_id = 10563
                                AND setting_catalog_code = 'fandian'
                                AND is_active = 1
                                AND [key] <= @tempYeJi
                        ORDER BY CAST([key] AS INT) DESC;
                        PRINT '比例';
                        PRINT @tempSetting;
                        SET @tempFenhon = @tempYeJi
                            * ISNULL(@tempSetting, 0);
                          
				PRINT '粉红的钱'+CAST(@tempFenhon AS NVARCHAR(30))
                                IF @tempFenhon > 0
								PRINT '开始分红'
                                    BEGIN
				--执行分红
			 
                                        EXEC dbo.sp_cust_personalcenter_in_currency @cust_id = @tempCstmId, -- int
                                            @source = 37, -- int
                                            @type = 1, -- int
                                            @business_id = 37, -- int
                                            @value = @tempFenhon, -- decimal
                                            @manufacturer_id = 10563, -- int
                                            @withdraw_status = 1, -- int
                                            @send_status = 0, -- int
                                            @tbfieldname = N'', -- nvarchar(200)
                                            @msg = N''; -- nvarchar(1000)
                                        INSERT  INTO dbo.tb_recommend_money_history_10563
                                                ( ordered_custId ,
                                                  money ,
                                                  recommend_custId ,
                                                  orderNum ,
                                                  createTime ,
                                                  type ,
                                                  brandId ,
                                                  json
                                                )
                                        VALUES  ( 0 ,
                                                  @tempFenhon ,
                                                  @tempCstmId ,
                                                  '' ,
                                                  GETDATE() ,
                                                  37 ,
                                                  0 ,
                                                  N''
                                                );

									   --从上级的佣金里面扣钱
									   IF(@nahuo_custId!=0)
									   BEGIN
									   DECLARE @msg1 NVARCHAR(30)
									    IF @tempFenhon > 0
										begin
									     INSERT  INTO dbo.tb_recommend_money_history_10563
                                                ( ordered_custId ,
                                                  money ,
                                                  recommend_custId ,
                                                  orderNum ,
                                                  createTime ,
                                                  type ,
                                                  brandId ,
                                                  json
                                                )
                                        VALUES  (  @tempCstmId,
                                                   @tempFenhon ,
                                                   @nahuo_custId,
                                                  '' ,
                                                  GETDATE() ,
                                                  22 ,
                                                  0 ,
                                                  N''
                                                );
									   	EXEC sp_cust_personalcenter_out @nahuo_custId,22,1,0,@tempFenhon,@manufacturer_id,@msg1
										end
									   END
									   
                                    
									 END;  
                               SET @i = @i + 1;  
                            END;
                  
            SELECT  *
            FROM    #resultT;
            PRINT '提交事务';
            COMMIT TRAN;
        END TRY
        BEGIN CATCH
            PRINT '回滚事务';
            ROLLBACK TRAN;
        END CATCH;
    END;

/**
获取所有董事 CstmId,个人业绩,可以分红的钱,oldparentStr
*/





