USE [serp3]
GO
/****** Object:  StoredProcedure [dbo].[tb_customer_user_INSERT_10602]    Script Date: 2018/8/15 15:00:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		
-- Create date: 20180606
-- Description:	代理商注册

--EXEC	@return_value = [dbo].[tb_customer_user_INSERT_10602]
--		@name = N'huanchen201805141611',
--		@pwd = N'201805141611',
--		@customer_catalog_id = 2047,
--		@mobile = N'15977777772',
--		@weixi_no = N'wx201805141611',
--		@alipay_no = N'aplipay201805141611',
--		@id_card = N'201805141611',
--		@manuID = 10602,
--		@parent_ID = 0,
--		@openid = N'201805141611',
--		@province=N'',
--		@city=N'',
--		@area=N'',
--		@headImg=N'',
--		@certificateImg=N'',
--		@address = N'北京北京市东城区201805141611',
--		@Message = @Message OUTPUT
-- =============================================
alter  PROCEDURE [dbo].[tb_customer_user_INSERT_10602]
    @name NVARCHAR(50),							--账号
    @pwd NVARCHAR(100),							--密码
    @customer_catalog_id INT,					--被推荐代理商级别ID
    @mobile NVARCHAR(50),						--手机号
    @manuID INT,								--厂商ID
    @parent_ID INT ,							--推荐代理商ID(0:厂商)
    @Message NVARCHAR(200) OUTPUT				--存储过程返回字符串

AS
    BEGIN TRANSACTION;
    BEGIN TRY 
      
        DECLARE @parent_str NVARCHAR(500);		--拿货关系
        DECLARE @oldparent_str NVARCHAR(500);	--推荐关系

		DECLARE @xj_parent_str NVARCHAR(500);	


        SET @parent_str = '';					--拿货关系
        SET @oldparent_str = '';				--推荐关系

		--添加代理商
        DECLARE @audit_status INT,
				@is_active INT,
				@SQL NVARCHAR(2000),
				@code NVARCHAR(50),
				@Number INT,
				@parentid INT,
				@customercatalogid INT;
        SET @audit_status = 0;
        SET @is_active = 1;
        SET @code = CAST(CAST(RAND() * 99999999 AS BIGINT) AS VARCHAR(8)); 

		--获取被推荐的代理商级别是否需要审核
        SELECT  @audit_status = audit_type FROM tb_customer_catalog WHERE tb_customer_catalogID = @customer_catalog_id;
		--PRINT '被推荐的代理商级别是否需要审核(审核类型:0-需要审核;1不需要审核)';
		--PRINT @audit_status

		--验证手机号码是否重复
        SET @SQL = N'select @Number=count(1) from tb_customer_10602'
            + ' where mobile=@mobile AND is_active=1 AND audit_status !=-1';
        EXEC sp_executesql @SQL, N'@mobile nvarchar(500), @Number int output',
            @mobile, @Number OUTPUT;

        IF @Number > 0
            BEGIN
                SET @Message = '代理商手机号码不能重复';
                ROLLBACK TRANSACTION;
                RETURN; 
            END;
		--验证手机号码是否重复

		--获取被推荐代理商上级ID
        IF(@parent_ID=0 OR @customer_catalog_id=2293)										 --厂商推荐
        BEGIN
            SET	@parentid= 0;
			PRINT '厂商推荐';
        END
        ELSE
        BEGIN													--代理商推荐
			PRINT '代理商推荐';
			SELECT @customercatalogid=customer_catalog_id,@parent_str=parent_str FROM dbo.tb_customer_10602 WHERE tb_customerID=@parent_ID
            IF(@customercatalogid=@customer_catalog_id)			--推荐同级
            BEGIN
				 SELECT @parentid=parent_id FROM dbo.tb_customer_10602 WHERE tb_customerID=@parent_ID
            END
            ELSE IF(@customercatalogid<@customer_catalog_id)	--高级别推荐低级别
            BEGIN
                SET @parentid = @parent_ID;
            END
         
        END
		PRINT '获取被推荐代理商上级ID';
		PRINT @parentid
		PRINT @xj_parent_str
		--获取被推荐代理商上级ID

		--插入代理商信息
        SET @SQL = N'INSERT INTO [tb_customer_'+CAST(@manuID AS NVARCHAR(50))+']'
            + '(code,name,customer_catalog_id,parent_id,contact,mobile,weixi_no,id_card,manufacturer_id,audit_status,is_active,provice,city,district,[address],oldparent_id)'
            + 'VALUES (''' 
			+ CAST(@code AS NVARCHAR(50))+ ''','''
            + CAST(@name AS NVARCHAR(50))+ ''','''
            + CAST(@customer_catalog_id AS NVARCHAR(50))+ ''','''
            + CAST(@parentid AS NVARCHAR(50))+ ''','''
            + CAST(@name AS NVARCHAR(50))+ ''','''
            + CAST(@mobile AS NVARCHAR(50))+ ''','''
            +  ''','''
            + ''','''
            + CAST(@manuID AS NVARCHAR(50))+ ''','''
            + CAST(@audit_status AS NVARCHAR(50))+ ''','''

            + CAST(@is_active AS NVARCHAR(50))+ ''','''
			 + ''','''
			 + ''','''
			 + ''','''
            + ''','''
			+ ''')';
        EXEC (@SQL);
		--PRINT '插入代理商信息';
		--PRINT @SQL
		--插入代理商信息



		--更新被推荐代理商的拿货关系/推荐关系
        DECLARE @tb_CustomerID INT;						--刚刚插入的代理商
		DECLARE @sj_parent_str NVARCHAR(500)			--被推荐代理商的拿货关系
		DECLARE @sj_oldparent_str NVARCHAR(500)			--被推荐代理商的推荐关系
		DECLARE @tj_parentid INT						--推荐代理商的上级代理商ID
		DECLARE @xj_oldparent_str NVARCHAR(500);	

		--查询刚刚插入的代理商ID
        SET @SQL = N'select @tb_CustomerID=tb_customerID from tb_customer_10602 where code=@code';
        EXEC sp_executesql @SQL,N'@code nvarchar(500), @tb_CustomerID int output', @code,@tb_CustomerID OUTPUT;
		--PRINT '查询刚刚插入的代理商';
        --PRINT @tb_CustomerID;
        --查询刚刚插入的代理商

        IF ( @parent_ID = 0 )									--厂商推荐，推荐代理商级别为一级
            BEGIN
				SET @oldparent_str=',0,'+CAST(@tb_CustomerID AS NVARCHAR(50))+',';
            END;
        ELSE			
			IF(@customercatalogid=@customer_catalog_id)			--推荐代理商级别同级
			BEGIN
				--根据推荐代理商ID获取上级代理商ID，上级的推荐关系
				SELECT @tj_parentid=parent_id,@sj_oldparent_str=oldparent_str FROM dbo.tb_customer_10602 WHERE tb_customerID=@parent_ID					
				IF(@tj_parentid=0)								--被推荐的代理商级别是一级，则赋值默认拿货关系
				BEGIN
				    SET @oldparent_str=',0,'+CAST(@tb_CustomerID AS NVARCHAR(50))+',';
				END
				ELSE
			    SET @oldparent_str=@sj_oldparent_str+CAST(@tb_CustomerID AS NVARCHAR(50))+',';
			END
         


		--10602 拿货关系和推荐关系一样
        SET @SQL = 'update tb_customer_10602'
            + ' set code='''',createtime=GETDATE(),oldparent_str=@oldparent_str,parent_str=@oldparent_str where tb_customerID='
            + CAST(@tb_CustomerID AS NVARCHAR(50));
        --PRINT @SQL2;
        EXEC sp_executesql @SQL,
            N'@oldparent_str NVARCHAR(500)',
             @oldparent_str;
		--PRINT '更新被推荐代理商的拿货关系/推荐关系'
		--PRINT @parent_str;
		--PRINT @oldparent_str;
		--更新被推荐代理商的拿货关系/推荐关系



        INSERT  dbo.tb_user
                ( system_role_id,
                  custid,
                  employee_id,
                  manufacturer_id,
                  name,
                  password,
                  status,
                  last_login_time,
                  create_time,
                  openid
                )
        VALUES  ( -5, -- system_role_id - int
                  @tb_CustomerID, -- custid - int
                  0, -- employee_id - int
                  @manuID, -- manufacturer_id - int
                  @mobile, -- name - nvarchar(100)
                  @pwd, -- password - nvarchar(100)
                  0, -- status - int
                  GETDATE(), -- last_login_time - datetime
                  GETDATE(), -- create_time - datetime
                  ''  -- openid - varchar(28)
                );



		--返回代理商ID
        SET @Message = CAST(@tb_CustomerID AS VARCHAR(50));
		
	 COMMIT TRANSACTION;

    END TRY   
    BEGIN CATCH   
	--sql (处理出错动作) 
  
      SET @Message=ERROR_MESSAGE()
				 ROLLBACK TRANSACTION;
    END CATCH;  















