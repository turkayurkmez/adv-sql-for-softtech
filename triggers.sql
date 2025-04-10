
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

CREATE DATABASE TriggerNightmare
GO
use TriggerNightmare
CREATE TABLE Students
( 
   ID int identity(1,1) not null,
   Name nvarchar(50),
   LastName nvarchar(50),
   Score int
)
GO
CREATE TABLE Successed
( 
   ID int not null,
   Name nvarchar(50),
   LastName nvarchar(50),
   Score int
)
GO
CREATE TABLE Failed
( 
   ID int not null,
   Name nvarchar(50),
   LastName nvarchar(50),
   Score int
)

use TriggerNightmare
ALTER DATABASE TriggerNightmare
SET RECURSIVE_TRIGGERS ON
GO

CREATE TRIGGER tr_Student
ON Students
AFTER INSERT
AS
BEGIN
   DECLARE @ID int, @score int
   DECLARE @Name nvarchar(50), @LastName nvarchar(50)
   SELECT @ID=ID, @Name=Name, @LastName=LastName, @score = Score FROM inserted

   IF @score > 50
     INSERT into Successed(Id,Name,LastName,Score) values (@ID, @Name,@LastName,@score)
   ELSE
      INSERT into Failed(Id,Name,LastName,Score) values (@ID, @Name,@LastName,@score)
END

INSERT into Students(Name,LastName,Score) values ('Emin','Tekin',80)
INSERT into Students(Name,LastName,Score) values ('Türkay','Ürkmez',45)

CREATE TRIGGER tr_Successed
ON Successed
INSTEAD OF INSERT
AS
BEGIN 
   DECLARE @score int
   DECLARE @Name nvarchar(50), @LastName nvarchar(50)
   SELECT  @Name=Name, @LastName=LastName, @score = Score FROM inserted

   INSERT into Students(Name,LastName,Score) values (@Name,@LastName,@score)
END

INSERT INTO Successed(Id,Name,LastName,Score) values (3, 'A','B',90)

-- kılavuzu Trigger olanın burnu bug'dan kurtulmaz.



