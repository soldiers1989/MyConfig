
update tb_cust_upgradeorder_10596 SET status=0 WHERE id=1

SELECT * FROM tb_cust_upgradeorder_10596

SELECT * FROM tb_customer_10596
 SELECT * FROM dbo.tb_stock_10596 WHERE cust_id=2

 --EXEC proc_upgrade_shiyongzhuan_10596 5,2423
 --1232
 EXEC proc_upgrade_shiyongzhuan_10596 @cust_id_str=N'2',@catalog_id__str=N'2423'

UPDATE  dbo.cust_personal_center_10596 SET bond_account='8988' WHERE cust_id=5
  SELECT * FROM dbo.cust_personal_center_in_10596

  select COUNT(1) from tb_customer_10596 WHERE oldparent_id=1 and customer_catalog_id>=2424

UPDATE  tb_customer_10596 SET customer_catalog_id=2425 WHERE tb_customerID=2
  