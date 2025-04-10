
--Sipariş Detaylarına yeni bir ürün ve adedi eklendiğinde bu adedi ürün stoğunda otomatik güncellesin.

ALTER TRIGGER trg_UpdateStock
ON [Order Details]
AFTER INSERT, UPDATE,DELETE
AS
BEGIN
  DECLARE @Adet int
  DECLARE @UrunId int
  DECLARE @instertedToplam int
  DECLARE @deletedToplam int
  DECLARE @eskiAdet int
  DECLARE @yeniAdet int
  --Eğer sadece inserted doluysa INSERT
  --Hem insert hem delete doluysa UPDATE
  --Sadece delete doluysa DELETE
  SELECT @instertedToplam = COUNT(*) FROM inserted
  SELECT @deletedToplam = COUNT(*) from deleted
  IF @instertedToplam > 0 AND @deletedToplam = 0
    BEGIN
      SELECT @Adet=Quantity, @UrunId=ProductID FROM inserted  
      UPDATE Products SET UnitsInStock = UnitsInStock - @Adet WHERE ProductID = @UrunId
	END
  ELSE IF  @instertedToplam > 0 AND @deletedToplam > 0
    BEGIN     
	 
	  SELECT @eskiAdet=Quantity FROM deleted
	  SELECT @UrunId=ProductId,  @yeniAdet=Quantity FROM inserted
	  SET @Adet = @yeniAdet - @eskiAdet
	  UPDATE Products SET UnitsInStock = UnitsInStock - @Adet WHERE ProductID = @UrunId
    END
   ELSE IF @instertedToplam = 0 AND @deletedToplam > 0
     BEGIN
	    SELECT @UrunId = ProductID FROM deleted
		
		SELECT @yeniAdet = Quantity FROM deleted
		SET @Adet = -@yeniAdet 
	    UPDATE Products SET UnitsInStock = UnitsInStock - @Adet WHERE ProductID = @UrunId
	 END
  
END

SELECT ProductName, UnitPrice, Discontinued FROM Products

DELETE FROM Products WHERE ProductID=1

CREATE TRIGGER tr_ProductDelete
ON Products
INSTEAD OF DELETE
AS 
  BEGIN
     UPDATE Products SET Discontinued = 1 WHERE ProductID IN (SELECT ProductID FROM deleted)
  END
  PRINT('Ürün silmek yerine, Flag güncellendi [SOFT DELETE]')

DELETE FROM Products WHERE ProductID = 3

--Trigger'in dezavantajları:
--1. Performans yükünü arttırır.
--2. Hata ayıklama kabus olabilir.
--3. Yönetilemez ise recursive olabilir.