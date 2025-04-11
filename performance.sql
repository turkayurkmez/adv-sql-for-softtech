--1. INDEX'lenmiş alan daha verimli sorgulanır.
SELECT * FROM Products WHERE ProductID =1

SELECT * FROM Products WHERE UnitPrice =25.92

SELECT * FROM Products WHERE ProductName LIKE 'A%'

-- 2. * operatörünü kullanmayın.
SELECT ProductName, UnitPrice, UnitsInStock FROM Products WHERE ProductName LIKE 'A%'

-- Birden fazla tabloyu birleştiriyorsanız bu sorguyu optimize etme:
-- Belirtilen kategorideki hangi ürün hangi müşteri tarafından alınmış?

SELECT 
   o.OrderID, c.CompanyName, p.ProductName, od.Quantity
FROM Orders o 
JOIN [Order Details] od
ON o.OrderID = od.OrderID
JOIN Customers c
ON c.CustomerID = o.CustomerID
JOIN Products p 
ON p.ProductID = od.ProductID
JOIN Categories ca
ON ca.CategoryID = p.CategoryID
WHERE CategoryName = 'Beverages'

-- yukarıdaki sorgunun optimize edilmiş hali.:
SELECT 
   o.OrderID, c.CompanyName, p.ProductName, od.Quantity
FROM Orders o 
JOIN [Order Details] od
ON o.OrderID = od.OrderID
JOIN Customers c
ON c.CustomerID = o.CustomerID
JOIN Products p 
ON p.ProductID = od.ProductID
WHERE p.CategoryID = (SELECT CategoryID FROM Categories WHERE CategoryName = 'Beverages')

-- Bir kategorinin altında kaç ürün var?

SELECT CategoryName, COUNT(ProductID) FROM Products RIGHT JOIN Categories 
            on Products.CategoryID = Categories.CategoryID  
GROUP BY CategoryName

SELECT CategoryName, (SELECT COUNT(ProductID) FROM Products WHERE CategoryID = c.CategoryID )

FROM Categories as c

-- performans sorunlu bir sorgu:
-- 20 dolardan fazla olan ürünlerin, adı, kategorisi, tedarikçisi ve sipariş tarihini istiyoruz.
-- Bu result set ürün adına göre sıralansın:

SELECT 
  p.ProductName,
  c.CategoryName,
  s.CompanyName,
  o.OrderDate 
FROM Products p JOIN Categories c
ON p.CategoryID = c.CategoryID
JOIN Suppliers s 
ON p.SupplierID = s.SupplierID
LEFT JOIN [Order Details] od  --> 2. Tüm siparişlerdeki tarihi seçmek için 2 tane left join yaptık hepsi büyük tablolar içeriyor
ON od.ProductID= p.ProductID
LEFT JOIN Orders o
ON o.OrderID = od.OrderID
WHERE p.UnitPrice > 20 --> 1. Nonclustered Index
ORDER BY p.ProductName

-- WHERE: En filtreleyici kriter en başta olmalı.
-- Fonksiyon kullanmak: Sütunda Scalar fonk. kullanmak index kullanılmasına engel olur.
-- LIKE Operatörü: '% _' gibi karakterler index'i verimli kullanmaz.
-- Order by: Gerçekten gerekiyor mu?
-- Geçici Tablolar: Büyük veri barındıran tabloları geçici tablolara almak performansı iyileştirir.
-- JOIN: Büyük tablodan küçüğe doğru join ilişkisi kurmak Bellek okuma performansını iyileştirir.





--Performansı arttırıyoruz.
SELECT 
   p.ProductName,
   s.CompanyName 'Tedarikçi',
   c.CategoryName,
   (SELECT MAX(o.OrderDate) FROM [Order Details] od JOIN Orders o ON od.OrderID = o.OrderId
    WHERE od.ProductID = p.ProductID
   ) 'EnSonSiparişTarihi'
FROM Products p JOIN Categories c
on p.CategoryID = c.CategoryID
JOIN Suppliers s 
ON p.SupplierID = s.SupplierID
WHERE UnitPrice > 20
ORDER BY p.ProductName

UPDATE Statistics Products

EXEC sp_updatestats