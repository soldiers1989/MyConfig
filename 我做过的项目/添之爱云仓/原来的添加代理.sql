USE [serp3]
GO
/****** Object:  StoredProcedure [dbo].[tb_customer_user_INSERT_10596]    Script Date: 2018/8/15 15:13:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--exec [tb_customer_user_INSERT_10596] '11','111111',1381,'110000','11','11','11',10596,9,'11','11','11','11','11','11','11',''
ALTER PROCEDURE [dbo].[tb_customer_user_INSERT_10596]
    @name NVARCHAR(50) ,
    @pwd NVARCHAR(100) ,
    @customer_catalog_id INT ,
    @mobile NVARCHAR(50) ,
    @weixi_no NVARCHAR(50) ,

    @alipay_no NVARCHAR(50) ,
    @id_card NVARCHAR(100) ,
    @manuID INT ,
    @parent_ID INT ,
    @openid NVARCHAR(100) ,

    @province NVARCHAR(50) ,
    @city NVARCHAR(50) ,
    @area NVARCHAR(200) ,
    @address NVARCHAR(100) ,
    

    @certificateImg NVARCHAR(2000) ,
	--@firgoods INT,
    @Message NVARCHAR(200) OUTPUT	

AS
    BEGIN TRANSACTION;
    BEGIN TRY 
        DECLARE @errorSum INT;       
        DECLARE @parent_str NVARCHAR(500)
        DECLARE @oldparent_str NVARCHAR(500);

		SET @errorSum = 0;
        SET @parent_str = '';		--拿货关系
        SET @oldparent_str = '';	--推荐关系


		--添加代理商
        DECLARE @audit_status INT ,
				@is_active INT ,
				@SQL NVARCHAR(2000) ,
				@SQL1 NVARCHAR(2000) ,
				@SQL2 NVARCHAR(2000) ,
				@SQLFk NVARCHAR(2000),
				@SQLFk_Status INT = 0, -- 0未审核，1上级审核，2厂家审核
				@code NVARCHAR(50) ,
				@Number INT ,
				@parentid INT ,
				@customercatalogid INT ;
        SET @audit_status = 0;
        SET @is_active = 1;

        SET @code = CAST(CAST(RAND() * 99999999 AS BIGINT) AS VARCHAR(8)); 

		--获取代理商级别
        SELECT  @audit_status = audit_type FROM tb_customer_catalog WHERE tb_customer_catalogID = @customer_catalog_id;

		--验证手机号码是否重复
        SET @SQL = N'select @Number=count(1) from tb_customer_'
            + CAST(@manuID AS NVARCHAR(50))
            + ' where mobile=@mobile AND is_active=1 AND audit_status !=-1';
        EXEC sp_executesql @SQL, N'@mobile nvarchar(500), @Number int output',
            @mobile, @Number OUTPUT;

        IF @Number > 0
            BEGIN
                SET @Message = '代理商手机号码不能重复';
                SET @errorSum = @errorSum + 1;
                ROLLBACK TRANSACTION;
                RETURN; 
            END;
		--验证手机号码是否重复
        IF(@parent_ID=0)
        BEGIN
            SET @parentid = 0;
        END
        ELSE
        BEGIN
            SELECT @customercatalogid=customer_catalog_id FROM dbo.tb_customer_10596 WHERE tb_customerID=@parent_ID
            IF(@customercatalogid=@customer_catalog_id)--推荐同级
            BEGIN
                SELECT @parentid=parent_id FROM dbo.tb_customer_10596 WHERE tb_customerID=@parent_ID
            END
            ELSE
            BEGIN
                SET @parentid = @parent_ID;
            END
        END
     
        PRINT ( @code );
        SET @SQL = N'';
        SET @SQL = N'INSERT INTO [tb_customer_' + CAST(@manuID AS NVARCHAR(50))+ ']'
            + '(code,name,customer_catalog_id,parent_id,contact,
				mobile,weixi_no,id_card,manufacturer_id,audit_status,
				is_active,provice,city,district,[address],
				oldparent_id,certificateImg,alipay_no )'
            + 'VALUES (''' 
			+ CAST(@code AS NVARCHAR(50)) + ''','''
            + CAST(@name AS NVARCHAR(50)) + ''','
            + CAST(@customer_catalog_id AS NVARCHAR(50)) + ','
            + CAST(@parentid AS NVARCHAR(50)) + ','''
            + CAST(@name AS NVARCHAR(50)) + ''','''

            + CAST(@mobile AS NVARCHAR(50)) + ''','''
            + CAST(ISNULL(@weixi_no, '') AS NVARCHAR(50)) + ''','''
            + CAST(ISNULL(@id_card, '') AS NVARCHAR(50)) + ''','
            + CAST(@manuID AS NVARCHAR(50)) + ','
            + CAST(@audit_status AS NVARCHAR(50)) + ','

            + CAST(@is_active AS NVARCHAR(50)) + ','''
			+ CAST(ISNULL(@province, '') AS NVARCHAR(200)) + ''','''
			+ CAST(ISNULL(@city, '') AS NVARCHAR(200)) + ''','''
			+ CAST(ISNULL(@area, '') AS NVARCHAR(200)) + ''','''
            + CAST(ISNULL(@address, '') AS NVARCHAR(200)) + ''','''

            + CAST(ISNULL(@parent_ID, '') AS NVARCHAR(50)) + ''','''
           
            + CAST(ISNULL(@certificateImg, '') AS NVARCHAR(2000)) + ''','''
            + CAST(ISNULL(@alipay_no, '') AS NVARCHAR(50)) +''')';
			--+ CAST(ISNULL(@firgoods, '') AS NVARCHAR(50)) + ''')';
        SELECT  @SQL AS sql3;
        PRINT ( @SQL );
        EXEC (@SQL);

        SET @errorSum = @errorSum + @@ERROR;	
        PRINT '错误数555555';
        PRINT @errorSum;

		--更新parentStr字段  
        DECLARE @tb_CustomerID INT;    
		DECLARE @sj_parent_str NVARCHAR(500)
		DECLARE @sj_oldparent_str NVARCHAR(500)
		DECLARE @tj_parentid INT

        SET @SQL = N'select @tb_CustomerID=tb_customerID from tb_customer_'+ CAST(@manuID AS NVARCHAR(50)) + ' where code=@code';
        EXEC sp_executesql @SQL,N'@code nvarchar(500), @tb_CustomerID int output', @code,@tb_CustomerID OUTPUT;
        PRINT @tb_CustomerID;

		 PRINT '错误数 6666';
        
        IF ( @parent_ID = 0 )--厂家推荐
            BEGIN
				SET @SQLFk_Status = 1; -- 特殊处理，当上级为厂家，没有上级，则表示上级已审核
                SET @parent_str=',0,'+CAST(@tb_CustomerID AS NVARCHAR(50))+','
				SET @oldparent_str=',0,'+CAST(@tb_CustomerID AS NVARCHAR(50))+','
            END;
        ELSE
			BEGIN
				IF(@customercatalogid=@customer_catalog_id)--推荐同级
					BEGIN
						SELECT @tj_parentid=parent_id FROM dbo.tb_customer_10596 WHERE tb_customerID=@parent_ID
						SELECT @sj_oldparent_str=oldparent_str FROM dbo.tb_customer_10596 WHERE tb_customerID=@parent_ID
						IF(@tj_parentid=0)
						BEGIN
							SET @parent_str=',0,'+CAST(@tb_CustomerID AS NVARCHAR(50))+','
						END
						ELSE
						BEGIN
							SELECT @sj_parent_str=parent_str FROM dbo.tb_customer_10596 WHERE tb_customerID=@tj_parentid
							SET @parent_str=@sj_parent_str+CAST(@tb_CustomerID AS NVARCHAR(50))+','
					
						END
						SET @oldparent_str=@sj_oldparent_str+CAST(@tb_CustomerID AS NVARCHAR(50))+','
					END
				ELSE--推荐下级
					BEGIN
						SELECT @sj_parent_str=parent_str,@sj_oldparent_str=oldparent_str FROM dbo.tb_customer_10596 WHERE tb_customerID=@parent_ID
						SET @parent_str=@sj_parent_str+CAST(@tb_CustomerID AS NVARCHAR(50))+','
						SET @oldparent_str=@sj_oldparent_str+CAST(@tb_CustomerID AS NVARCHAR(50))+','
					END
			END 
		PRINT '错误数 7777';

        SET @SQL = 'update tb_customer_' + CAST(@manuID AS NVARCHAR(50))
            + ' set code='''',createtime=GETDATE(),oldparent_str=@oldparent_str,parent_str=@parent_str where tb_customerID='
            + CAST(@tb_CustomerID AS NVARCHAR(50));
        PRINT @SQL;
        EXEC sp_executesql @SQL,
            N'@parent_str NVARCHAR(500),@oldparent_str NVARCHAR(500)',
            @parent_str, @oldparent_str;
        SET @errorSum = @errorSum + @@ERROR;	
        PRINT @errorSum;

			PRINT '错误数 888888';
		
		BEGIN TRY
		 
	        SET @errorSum = @errorSum + @@ERROR;	
	        PRINT '错误数';
		END TRY
		BEGIN CATCH
			PRINT '-------------------------------------';
			SET @errorSum = @errorSum + 1;
		END CATCH


        INSERT  dbo.tb_user
                ( system_role_id ,
                  custid ,
                  employee_id ,
                  manufacturer_id ,
                  name ,
                  password ,
                  status ,
                  last_login_time ,
                  create_time ,
                  openid
                )
        VALUES  ( -5 , -- system_role_id - int
                  @tb_CustomerID , -- custid - int
                  0 , -- employee_id - int
                  @manuID , -- manufacturer_id - int
                  @mobile , -- name - nvarchar(100)
                  @pwd , -- password - nvarchar(100)
                  0 , -- status - int
                  GETDATE() , -- last_login_time - datetime
                  GETDATE() , -- create_time - datetime
                  @openid  -- openid - varchar(28)
                );
        SET @errorSum = @errorSum + @@ERROR;
        PRINT @errorSum;
--返回代理商ID
        SET @Message = CAST(@tb_CustomerID AS VARCHAR(50));
		
		 
    END TRY   
    BEGIN CATCH   
--sql (处理出错动作) 
        SELECT  ERROR_NUMBER() AS ErrorNumber ,
                ERROR_SEVERITY() AS ErrorSeverity ,
                ERROR_STATE() AS ErrorState ,
                ERROR_PROCEDURE() AS ErrorProcedure ,
                ERROR_LINE() AS ErrorLine ,
                ERROR_MESSAGE() AS ErrorMessage;   
    END CATCH;  

    IF @errorSum > 0
        BEGIN
            ROLLBACK TRANSACTION;
            PRINT '事物回滚';
        END;
    ELSE
        BEGIN
            COMMIT TRANSACTION;
            PRINT '事物执行';
        END;














