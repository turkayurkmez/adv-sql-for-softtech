SELECT * FROM Products WHERE CategoryID = 8

--Bir tabloda sadece 1 Clustered Index olabilir. -> PK
--                   1'den fazla nonclustered olabilir. -> Sıkça filtrelenen kolonlar için uygun.

CREATE NONCLUSTERED INDEX IX_OrderDate
ON Orders(OrderDate)

--Unique Index:
-- Atandığı sütunda benzersiz veriler olmasını sağlar.

DISABLE TRIGGER tr_ProductDelete ON Products

CREATE UNIQUE NONCLUSTERED INDEX  IX_ProductName
ON Products(ProductName)

INSERT into Products(ProductName, UnitPrice) values ('Domates',1)

--Composite Index
  --Birden fazla sütunun aynı indexte olması isteniyorsa:
  --Eğer CustomerID, EmployeeID birlikte kritere tabii oluyorsa:
  CREATE NONCLUSTERED INDEX IX_Employee_Customer
  ON Orders(CustomerID, EmployeeID) 

--Filtered Index
CREATE NONCLUSTERED INDEX IX_Active
ON Products(ProductId, ProductName, UnitPrice)
WHERE Discontinued = 0

ALTER INDEX CategoryName
ON Categories
REBUILD WITH(FILLFACTOR = 80) 

DBCC 

DBCC INDEXDEFRAG (Northwind, Products, SupplierId)
DBCC SHOWCONTIG (Products)

/*
 Bu index önerisini SQL Server Tuning Advisor yaptı:
*/

CREATE NONCLUSTERED INDEX [IX_Order Details_Composite] ON [dbo].[Order Details]
(
	[ProductID] ASC,
	[Quantity] DESC,
	[UnitPrice] ASC
)
INCLUDE([OrderID]) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
