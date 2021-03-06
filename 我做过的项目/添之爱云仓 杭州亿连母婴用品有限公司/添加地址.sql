USE [serp3]
GO
/****** Object:  StoredProcedure [dbo].[proc_tb_customAfter_10596]    Script Date: 2018/8/10 15:31:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec [proc_tb_customAfter_10596] 86,2014
alter PROC [dbo].[proc_tb_customAfterAddAddress_10596]
    @cust_id INT,
	@catalog_id INT
AS
 BEGIN
    BEGIN TRY
	   BEGIN TRAN

	    --判断是否已经审核过
		IF((SELECT COUNT(*) FROM tb_customer_audit_10596 WHERE to_audit_customer_id=@cust_id)=0)
		BEGIN
		DECLARE @province NVARCHAR(50),@city NVARCHAR(50) ,@area NVARCHAR(50)
		,@address NVARCHAR(100),@name NVARCHAR(100), @mobile NVARCHAR(100)
		
	    SELECT @province=provice,@city=city,@area=district,@name=name,@mobile=mobile FROM tb_customer_10596 WHERE tb_customerID=@cust_id
	 
		DECLARE @provinceCode INT = -1 ,--省份代码
				@cityCode INT = -1 ,	--市区代码
				@areaCode INT = -1 ;    --市区代码

		--检查是否存在 省份代码
		SELECT @provinceCode=tb_areaID FROM tb_area WHERE name like '%' +@province +'%'
		IF(@provinceCode=-1)
		BEGIN
			INSERT dbo.tb_area
					( name ,
					  parent_id 
					)
			VALUES  ( @province ,
					  0 
					);
			SELECT @provinceCode=@@IDENTITY
		END

		--检查是否存在 市区代码
		SELECT @cityCode=tb_areaID FROM tb_area WHERE name like '%' +@city +'%'
		IF(@cityCode=-1)
		BEGIN
			INSERT dbo.tb_area
					( name ,
					  parent_id 
					)
			VALUES  ( @city ,
					  0 
					);
			SELECT @cityCode=@@IDENTITY
		END

		--检查是否存在 市区代码
		SELECT @areaCode=tb_areaID FROM tb_area WHERE name like '%' +@area +'%'
		IF(@areaCode=-1)
		BEGIN
			INSERT dbo.tb_area
					( name ,
					  parent_id 
					)
			VALUES  ( @area ,
					  0 
					);
			SELECT @areaCode=@@IDENTITY
		END

		--插入常用地址（代理商收货地址）
		INSERT dbo.tb_cutomer_address_10594
				( ProvinceCode ,
				  CityCode ,
				  AreaCode ,
				  Address ,
				  Contact ,
				  phone ,
				  is_active ,
				  sign ,
				  cust_id
				)
		VALUES  ( @ProvinceCode , -- ProvinceCode - nvarchar(50)
				  @CityCode , -- CityCode - nvarchar(50)
				  @AreaCode , -- AreaCode - nvarchar(50)
				  @address , -- Address - nvarchar(200)
				  @name , -- Contact - nvarchar(50)
				  @mobile , -- phone - nvarchar(50)
				  1 , -- is_active - bit
				  1 , -- sign - int
				  @cust_id -- cust_id - int
				)

	end
	   PRINT '提交事务'
	   COMMIT TRAN
	END TRY
	BEGIN CATCH
	   PRINT '回滚事务'
	   ROLLBACK TRAN
	END CATCH 
 END


