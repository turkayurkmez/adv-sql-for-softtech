-- En çok satan ilk 5 ürün:

SELECT TOP 5 
  p.ProductName, SUM(od.Quantity) as Total
FROM Products p JOIN [Order Details] od
ON p.ProductID = od.ProductID
GROUP BY p.ProductName
ORDER BY Total DESC
-- Common Table Expression (CTE)

WITH EnCokSatanUrunler AS 
(
  SELECT 
  p.ProductName, SUM(od.Quantity) as Total
  FROM Products p JOIN [Order Details] od
  ON p.ProductID = od.ProductID
  GROUP BY p.ProductName
)
SELECT ProductName,Total FROM EnCokSatanUrunler
ORDER BY Total DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY

--Hangi yıl ne kadar ciro yaptık?
SELECT 
  YEAR(o.OrderDate) as year,
  SUM(od.Quantity*od.UnitPrice) as TotalPrice
FROM Orders o JOIN [Order Details] od
ON o.OrderID = od.OrderID
GROUP BY YEAR(o.OrderDate)
ORDER BY year

/*
  1996     1997     1998     2023     2024
  227000   660000   ....     .....    .....
*/

SELECT * FROM
(
  SELECT 
		YEAR(o.OrderDate) as year,
		od.Quantity*od.UnitPrice as TotalPrice
  FROM Orders o JOIN [Order Details] od
  ON o.OrderID = od.OrderID 
)
AS Source
PIVOT(
 SUM(TotalPrice)
 FOR year IN ([1996],[1997],[1998])
) as pivotTable

-- 1997 yılında Kategorilere göre hangi çeyrekte ne kadar satış yapılmış?
SELECT * FROM
(
  SELECT c.CategoryName, DATEPART(Quarter,OrderDate) quarter, od.Quantity FROM Categories c JOIN Products p
  ON p.CategoryID = c.CategoryID
  JOIN [Order Details] od 
  ON od.ProductID = p.ProductID
  JOIN Orders o
  ON od.OrderID = o.OrderID
  WHERE YEAR(o.OrderDate) = 1997
)
AS Source
PIVOT(
  SUM(Quantity)
  FOR quarter IN ([1],[2],[3],[4])
) as pvtTable

--Recursive Queries:
SELECT EmployeeID, FirstName,LastName, ReportsTo FROM Employees

SELECT CalisanTablo.FirstName + ' ' + CalisanTablo.LastName as Calisan,
       MudurTablo.FirstName + ' ' + MudurTablo.LastName as Mudur
FROM Employees as CalisanTablo LEFT JOIN Employees as MudurTablo
ON CalisanTablo.ReportsTo = MudurTablo.EmployeeID

WITH EmployeeH AS 
(
  --1. Baz sorgu: En üst seviye (root) yöneticileri al.
  SELECT EmployeeID, FirstName + ' ' + LastName CalisanAdi, ReportsTo,
         0 Level
  FROM Employees WHERE ReportsTo is NULL

  UNION ALL
  SELECT e.EmployeeID, e.FirstName + ' ' + e.LastName, e.ReportsTo,
         eh.Level +1
  FROM Employees e
  INNER JOIN EmployeeH eh ON e.ReportsTo = eh.EmployeeID

)
SELECT CalisanAdi,Level , REPLICATE('--',Level) + CalisanAdi as Hiyerarsi

FROM EmployeeH
ORDER BY Level, CalisanAdi

-- WINDOW FUNCTIONS
-- Her kategorideki ürünlerin fiyat sıralaması
-- Kategori Adı, Ürün Adı, Fiyatı, Fiyat Sırası, Fiyat Rank'i Rank Yoğunlu, Ortalama Fiyat, Ortalama Farkı

SELECT 
  c.CategoryName,
  p.ProductName,
  p.UnitPrice,
  ROW_NUMBER() OVER (PARTITION BY c.CategoryId ORDER BY p.UnitPrice DESC) as FiyatSirasi,
  RANK() OVER (PARTITION BY c.CategoryId ORDER BY p.UnitPrice DESC) FiyatRank,
  DENSE_RANK() OVER (PARTITION BY c.CategoryId ORDER BY p.UnitPrice DESC) as RankYogunluk,
  ROUND(AVG(p.UnitPrice) OVER (PARTITION BY c.CategoryId),2) as KategoriOrtFiyat,
  ROUND(p.UnitPrice - AVG(UnitPrice) OVER (PARTITION BY c.CategoryId),2) as OrtalamaFarki
FROM Products p JOIN Categories c
ON p.CategoryID = c.CategoryID
ORDER BY c.CategoryName, p.UnitPrice

--Her bir kategorideki en pahalı üç ürün:
-- CTE veya tablo döndüren bir fonkisyonu resultset'in her bir satırı için uygulamanız gerekiyorsa APPLY
SELECT
   c.CategoryName,
   Urun.ProductName,
   Urun.UnitPrice
FROM Categories c 
CROSS APPLY 
(
   SELECT TOP 3 p.ProductName, p.UnitPrice 
   FROM  Products p
   WHERE P.CategoryID = c.CategoryID
   ORDER BY p.UnitPrice DESC
)as Urun
ORDER BY c.CategoryName ASC,
         Urun.UnitPrice DESC


SELECT CompanyName, Country,City,
(SELECT
    OrderID, OrderDate,ShipCity, ShipCountry
FROM Orders WHERE CustomerID = c.CustomerID  FOR JSON PATH
) as 'Orders'
FROM Customers as c
WHERE Country ='Germany'
FOR JSON PATH,
ROOT ('GermanCustomers')

--Dinamik ürün filtreleme ile prosedür oluşturmak:

ALTER PROC SearchProduct
  @Category nvarchar(50) = NULL,
  @Name nvarchar(50) = NULL,
  @max money = NULL,
  @min money = NULL,
  @order_column nvarchar(50) = 'ProductName',
  @order_nav nvarchar(4) = 'ASC'
AS  
  BEGIN
     --1 Gereken sorguyu oluştur.
	 --2 bu sorguyu çalıştır.
	 DECLARE @sql nvarchar(max)
	 SET @sql = N'SELECT ProductId, ProductName, CategoryName, UnitPrice, UnitsInStock  
	              FROM Products p JOIN Categories c ON c.CategoryId = p.CategoryId WHERE 1=1'

     IF @Category is not null
	 SET @sql = @sql + N' AND c.CategoryName = @Category'
      
	 IF @Name is not null
	 SET @sql = @sql + N' AND ProductName = @Name'

	 IF @max is not null
	 SET @sql = @sql + N' AND UnitPrice <= @max'

	 IF @min is not null
	 SET @sql = @sql + N' AND UnitPrice >= @min'
      
     SET @sql = @sql + N' ORDER BY '+QUOTENAME(@order_column) + ' ' + @order_nav 

	 print(@sql)
     
	 EXEC sp_executesql @sql,
	                    N'@Category nvarchar(50), @min money, @max money, @Name nvarchar(50)',
						@Category,@min,@max,@Name



  END

  EXEC SearchProduct @Category = 'Beverages', @Name='Chang', @max=50, @min=10, @order_column='UnitPrice', @order_nav='ASC'
