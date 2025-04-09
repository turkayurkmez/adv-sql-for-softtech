-- Bir siparişin detaylarını veren sorgu:
CREATE PROC GetOrderDetails
 @OrderId int
AS 
SELECT 
  o.OrderID,
  o.OrderDate,
  o.ShippedDate,
  c.CompanyName 'CustomerName',
  c.Country,
  e.FirstName + ' ' + e.LastName 'Employee',
  p.ProductName,
  od.Quantity,
  od.UnitPrice,
  od.Discount,
  (od.UnitPrice * od.Quantity * (1-od.Discount)) 'TotalAmount'
FROM Orders as o 
JOIN Customers as c ON o.CustomerID = c.CustomerID
JOIN Employees as e ON o.EmployeeID = e.EmployeeID
JOIN Shippers as s ON o.ShipVia = s.ShipperID
JOIN [Order Details] as od ON od.OrderID = o.OrderID
JOIN Products as p ON p.ProductID = od.ProductID
WHERE od.OrderID = @OrderId

EXEC GetOrderDetails @OrderId = 10248

GetOrderDetails 10250

GO
--Belirli Bir müşterinin belirli bir tarih aralığındaki sipariş özetini veren prosedür.
CREATE PROC GetCustomerOrdersByDate
  @CustomerID nchar(5),
  @StartDate datetime,
  @EndDate datetime
AS
BEGIN 
   SET NOCOUNT ON
SELECT 
   o.OrderID,
   o.OrderDate,
   o.RequiredDate,
   o.ShippedDate,
   SUM(od.Quantity * od.UnitPrice) 'TotalAmount'   
FROM Orders o JOIN [Order Details] od
ON o.OrderID = od.OrderID
WHERE o.CustomerID = @CustomerID
AND o.OrderDate BETWEEN @StartDate AND @EndDate
GROUP BY o.OrderID, o.OrderDate, o.RequiredDate, o.ShippedDate
ORDER BY o.OrderDate

END

GetCustomerOrdersByDate 'ANTON', '1997-01-01', '1997-12-31'

--Bir ürünün fiyatını güncelleyen prosedür:

ALTER PROC UpdateProductPrice
  @ProductId int,
  @UnitPrice money
as
BEGIN
  BEGIN TRY 
    SET Nocount on;
	  IF @UnitPrice <= 0
	      THROW 50001, 'Ürün Fiyatı negatif olamaz', 1;
	  
	  IF NOT EXISTS(SELECT 1 FROM Products where ProductID = @ProductId)
	      THROW 50002, 'Belirtilen ürün bulunamadı',1
   
	UPDATE Products SET UnitPrice = @UnitPrice WHERE ProductID = @ProductId
	Print('Güncelleme başarılı')
  END TRY
  BEGIN CATCH
    SELECT ERROR_MESSAGE(), ERROR_SEVERITY(), ERROR_STATE()

  END CATCH
END


UpdateProductPrice 125, 256
--test...
--deneme
