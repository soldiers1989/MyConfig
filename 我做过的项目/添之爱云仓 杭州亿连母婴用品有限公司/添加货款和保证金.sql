USE [serp3]
GO
/****** Object:  StoredProcedure [dbo].[proc_tb_customAfter_10596]    Script Date: 2018/8/10 14:22:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [proc_tb_customAfter_10596] 86,2014
alter PROC [dbo].[proc_tb_customAfter_10596]
    @cust_id INT,
	@catalog_id INT
AS
 BEGIN
    BEGIN TRY
	   BEGIN TRAN

		DECLARE @bzjVal DECIMAL = 0;
		DECLARE @huokuanVal DECIMAL = 0;
		-- 读取保证金
		SELECT TOP 1 @bzjVal = ISNULL(value,0) FROM dbo.tb_setting WHERE manufacturer_id = 10596 AND setting_catalog_code = CAST(@catalog_id AS NVARCHAR(100)) AND [key] = 'bzjmoney';

		EXEC dbo.sp_cust_personalcenter_in_currency @cust_id = @cust_id, -- int
		    @source = 12, -- int
		    @type = 0, -- int
		    @business_id = @cust_id, -- int
		    @value = @bzjVal, -- decimal
		    @manufacturer_id = 10596, -- int
		    @withdraw_status = 1, -- int
		    @send_status = 0, -- int
		    @tbfieldname = N'bond_account', -- nvarchar(200)
		    @msg = N'' -- nvarchar(1000)
		
		--添加货款
		 SELECT TOP 1 @huokuanVal= ISNULL(value,0)  FROM tb_setting WHERE manufacturer_id=10596 AND [key]='chongzhihuokuan' AND setting_catalog_code=CAST(@catalog_id AS NVARCHAR(100))
		 EXEC dbo.sp_cust_personalcenter_in @cust_id = @cust_id, -- int
		    @source = 13, -- int
		    @type = 4, -- int
		    @business_id = @cust_id, -- int
		    @value = @huokuanVal, -- decimal
		    @manufacturer_id = 10596, -- int
		    @withdraw_status = 1, -- int
		    @send_status = 0, -- int
		    
		    @msg = N'' -- nvarchar(1000)


	   PRINT '提交事务'
	   COMMIT TRAN
	END TRY
	BEGIN CATCH
	   PRINT '回滚事务'
	   ROLLBACK TRAN
	END CATCH 
 END


