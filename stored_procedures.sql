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

GetCustomerOrdersByDate 'ALFKI', '2025-01-01', '2025-12-31'

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

-- Transaction management...

ALTER PROCEDURE CreateOrderWithDetails
  @CustomerID nchar(5),
  @EmployeeID int,
  @ShipperID int,
  @ProductID int,
  @Quantity int,
  @UnitPrice money
AS
BEGIN 
   SET NOCOUNT ON;
   DECLARE @OrderID int
   BEGIN TRY
     --Transaction 1: Sipariş oluştur:
	 BEGIN TRAN T1
		INSERT into Orders (CustomerID, EmployeeID, ShipVia) values (@CustomerID, @EmployeeID, @ShipperID)
		SET @OrderID = SCOPE_IDENTITY()
		BEGIN TRAN T2
		   INSERT INTO [Order Details] (OrderID, ProductID,Quantity,UnitPrice) values
		                               (@OrderID, @ProductID,@Quantity,@UnitPrice) 
		   BEGIN TRAN T3
		      UPDATE Products SET UnitsInStock = UnitsInStock - @Quantity
			  WHERE ProductID = @ProductID 
		   COMMIT TRAN T3
					
		COMMIT TRAN T2
     COMMIT TRAN T1 
   END TRY
   BEGIN CATCH
      ROLLBACK TRAN T1
	  SELECT ERROR_MESSAGE()
   END CATCH
END

CreateOrderWithDetails 'ALFKI', 3, 1, 4, 20,10

SELECT * FROM [Orders] WHERE CustomerID ='ALFKI'