
--Scalar Functions:
  --Date 
SELECT GETDATE()
SELECT FirstName, LastName, YEAR(GetDate()) - YEAR(BirthDate)
FROM Employees

SELECT DATEPART(YEAR,GetDate())
SELECT DATEDIFF(DAY,'2025-04-09','2025-05-01')

SELECT OrderId, OrderDate, ShippedDate, DATEDIFF(DAY,OrderDate,ShippedDate) as 'Süre' FROM Orders
-- String:

SELECT UPPER(SUBSTRING(FirstName,1,1))+'.'+UPPER(SUBSTRING(LastName,1,1))+LOWER( SUBSTRING(LastName,2,LEN('Ürkmez')-1))
FROM Employees

--UDF:
--1. Scalar Functions:
-- İndirim ile birlikte fiyat hesapla:

CREATE FUNCTION FiyatHesapla
( 
  @fiyat money,
  @adet int,
  @indirim float
)
RETURNS money
AS 
BEGIN
   RETURN @fiyat * @adet * (1-@indirim)
END

SELECT dbo.FiyatHesapla(500,2,0.10)
SELECT OrderId,SUM(dbo.FiyatHesapla(UnitPrice,Quantity,Discount)) FROM [Order Details]
group by OrderID

CREATE FUNCTION KDVHesapla
(
  @Fiyat money,
  @KDVOrani float
)
RETURNS money
as
BEGIN 
   RETURN @Fiyat * (1+@KDVOrani)
END

SELECT ProductName, UnitPrice, dbo.KDVHesapla(UnitPrice,0.20) FROM Products


UPDATE Products SET UnitPrice = dbo.KDVHesapla(UnitPrice,0.20) 

SELECT * FROM Products

--Inline Tables:
-- Çıktısını tablo gibi sorgulayabileceğiniz fonksiyonlardır:
-- Bir müşterinin tüm siparişlerini tablo olarak döndüren fonksiyon:,

CREATE FUNCTION MusteriSiparisleri
(
  @CustomerID nchar(5)
)
RETURNS TABLE
AS
 RETURN SELECT OrderID, OrderDate, Freight FROM Orders Where CustomerID = @CustomerID

 Select Year(OrderDate), SUM(Freight) FROM  dbo.MusteriSiparisleri('BERGS')
 GROUP BY Year(OrderDate)

 --VIEW Karşılaştırma
 ALTER VIEW OrderSummary
 AS
    SELECT OrderID, OrderDate, Freight, CustomerID FROM Orders

 SELECT * FROM OrderSummary WHERE CustomerID = 'BERGS'
 SELECT * FROM dbo.MusteriSiparisleri('BERGS')

 --Multi-Statement Table-Valued: Fonksiyon çıktısı gövdesinde birden fazla ifade belirlenebilir.
 --Örnek: Id'si verilen bir kategorinin ürün detayları
 CREATE FUNCTION KategoriUrun
 (
   @CategoryId int
 )
 RETURNS @sonuc TABLE (UrunId int, UrunAdi nvarchar(50), KategoriAdi nvarchar(15), Fiyat money )
 AS
 BEGIN
    INSERT into @sonuc
	  SELECT ProductID, ProductName, CategoryName, UnitPrice FROM Products JOIN Categories
	         on Products.CategoryID = Categories.CategoryID
      WHERE Products.CategoryID = @CategoryId

	  RETURN
 END

 SELECT 
 c.CategoryName, 
 (SELECT MAX(Fiyat) FROM dbo.KategoriUrun(c.CategoryID)) AS MaxFiyat,
 (SELECT MIN(Fiyat) FROM dbo.KategoriUrun(c.CategoryID)) AS MinFiyat,
 (SELECT AVG(Fiyat) FROM dbo.KategoriUrun(c.CategoryID)) AS OrtalamaFiyat


 SELECT  UrunAdi FROM dbo.KategoriUrun(5)
 WHERE Fiyat = (SELECT MAX(Fiyat) FROM dbo.KategoriUrun(5) )

 FROM Categories as c
 ORDER BY MaxFiyat DESCs
 
 -- İki tarih arasındaki iş günlerini hesaplamak istiyoruz.
 -- Datepart, interval olarak weekday kullandığında Pazar -1 Cumartesi - 7 olacak biçimde değer döndürür.
 SELECT DATEPART(weekday,'2025-04-12')

 ALTER FUNCTION IsGunuSayisi
 (
   @Baslangic date,
   @Bitis date
 )
 RETURNS int
 AS
 BEGIN
    DECLARE @GunSayisi int = 0
	--belirtilen tarihler arasında tek tek ilerle; hafta içi olanları say:
	DECLARE @AktifGun date = @Baslangic
	WHILE @AktifGun < @Bitis
	 BEGIN
	   IF DATEPART(weekDay,@AktifGun) NOT IN (1,7)
	      SET @GunSayisi = @GunSayisi +1 
	      SET @AktifGun = DATEADD(day,1,@AktifGun)
	 END

	 RETURN @GunSayisi
 END

 SELECT dbo.IsGunuSayisi('2025-04-01','2025-04-08')

 SELECT 
   OrderID, CONVERT(nvarchar(15), OrderDate,103), CONVERT(nvarchar(15),RequiredDate,103),  dbo.IsGunuSayisi(OrderDate,RequiredDate) as 'Teslim iş günü'
 FROM Orders

 CREATE FUNCTION TedarikciInfo(@SupplierId int)
 RETURNS nvarchar(MAX)
 AS
 BEGIN
    DECLARE @CompanyName nvarchar(40)
	DECLARE @ProductCount int
	DECLARE @AvgPrice int
	DECLARE @result nvarchar(MAX)
	
	SELECT 
	   @CompanyName = CompanyName,
	   @ProductCount = (SELECT COUNT(ProductID) FROM Products WHERE SupplierID = @SupplierId),
	   @AvgPrice = ( SELECT AVG(UnitPrice) FROM Products WHERE SupplierID = @SupplierId)
	FROM Suppliers
	WHERE SupplierID = @SupplierId

	SET @result = @CompanyName + ' firmasının toplam ürünü: '
	             + CAST(@ProductCount as nvarchar(5))+', ortalama fiyatı' 
				 + FORMAT(@AvgPrice,'C','tr-TR')  

    RETURN @result
  
 END
 -- Exotic Lquids firmasının toplam ürünü 3, ortalama fiyatı: 22.56

 SELECT SupplierId, CompanyName, Country, City,  dbo.TedarikciInfo(SupplierId) FROM  Suppliers