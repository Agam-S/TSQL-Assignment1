IF OBJECT_ID('Sale') IS NOT NULL
DROP TABLE SALE;

IF OBJECT_ID('Product') IS NOT NULL
DROP TABLE PRODUCT;

IF OBJECT_ID('Customer') IS NOT NULL
DROP TABLE CUSTOMER;

IF OBJECT_ID('Location') IS NOT NULL
DROP TABLE LOCATION;

GO

CREATE TABLE CUSTOMER (
CUSTID	INT
, CUSTNAME	NVARCHAR(100)
, SALES_YTD	MONEY
, STATUS	NVARCHAR(7)
, PRIMARY KEY	(CUSTID) 
);


CREATE TABLE PRODUCT (
PRODID	INT
, PRODNAME	NVARCHAR(100)
, SELLING_PRICE	MONEY
, SALES_YTD	MONEY
, PRIMARY KEY	(PRODID)
);

CREATE TABLE SALE (
SALEID	BIGINT
, CUSTID	INT
, PRODID	INT
, QTY	INT
, PRICE	MONEY
, SALEDATE	DATE
, PRIMARY KEY 	(SALEID)
, FOREIGN KEY 	(CUSTID) REFERENCES CUSTOMER
, FOREIGN KEY 	(PRODID) REFERENCES PRODUCT
);

CREATE TABLE LOCATION (
  LOCID	NVARCHAR(5)
, MINQTY	INTEGER
, MAXQTY	INTEGER
, PRIMARY KEY 	(LOCID)
, CONSTRAINT CHECK_LOCID_LENGTH CHECK (LEN(LOCID) = 5)
, CONSTRAINT CHECK_MINQTY_RANGE CHECK (MINQTY BETWEEN 0 AND 999)
, CONSTRAINT CHECK_MAXQTY_RANGE CHECK (MAXQTY BETWEEN 0 AND 999)
, CONSTRAINT CHECK_MAXQTY_GREATER_MIXQTY CHECK (MAXQTY >= MINQTY)
);

IF OBJECT_ID('SALE_SEQ') IS NOT NULL
DROP SEQUENCE SALE_SEQ;
CREATE SEQUENCE SALE_SEQ;

GO

-- ADD_CUSTOMER STORED PROCEDURE

IF OBJECT_ID('ADD_CUSTOMER') IS NOT NULL
DROP PROCEDURE ADD_CUSTOMER;
GO

CREATE PROCEDURE ADD_CUSTOMER @PCUSTID INT, @PCUSTNAME NVARCHAR(100) AS

BEGIN
    BEGIN TRY

        IF @PCUSTID < 1 OR @PCUSTID > 499
            THROW 50020, 'Customer ID out of range', 1

        INSERT INTO CUSTOMER (CUSTID, CUSTNAME, SALES_YTD, STATUS) 
        VALUES (@PCUSTID, @PCUSTNAME, 0, 'OK');

    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 2627
            THROW 50010, 'Duplicate customer ID', 1
        ELSE IF ERROR_NUMBER() = 50020
            THROW
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;

END;

GO
EXEC ADD_CUSTOMER @pcustid = 1, @pcustname = 'testdude1';
EXEC ADD_CUSTOMER @pcustid = 3, @pcustname = 'testdude2';
EXEC ADD_CUSTOMER @pcustid = 5, @pcustname = 'testdude3';
EXEC ADD_CUSTOMER @pcustid = 499, @pcustname = 'testdude4';

select * from customer;


-- DELETE_ALL_CUSTOMERS STORED PROCEDURE

IF OBJECT_ID('DELETE_ALL_CUSTOMERS') IS NOT NULL
DROP PROCEDURE DELETE_ALL_CUSTOMERS;
GO

CREATE PROCEDURE DELETE_ALL_CUSTOMERS AS

BEGIN
    BEGIN TRY
        DELETE FROM Customer;
        DECLARE @ROWSDELETED INT = @@ROWCOUNT;
        SELECT @ROWSDELETED
    END TRY
        BEGIN CATCH 
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH

END
GO

EXEC DELETE_ALL_CUSTOMERS;  
select * from customer; 

-- ADD_PRODUCT STORED PROCEDURE 

IF OBJECT_ID('ADD_PRODUCT') IS NOT NULL 
DROP PROCEDURE ADD_PRODUCT; 
GO  

CREATE PROCEDURE ADD_PRODUCT @pprodid INT, @pprodname NVARCHAR(100), @pprice MONEY AS

BEGIN
    BEGIN TRY

        IF @pprodid < 1000 OR @pprodid > 2500
            THROW 50040, 'Product ID out of range' , 10
         ELSE IF @pprice < 0 OR @pprice > 999.99
                 THROW 50050, 'Price out of range', 1

        INSERT INTO PRODUCT (PRODID, PRODNAME, SELLING_PRICE, SALES_YTD) 
        VALUES (@pprodid, @pprodname, @pprice, 0);

    END TRY
            BEGIN CATCH
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END CATCH; 

END;

GO
EXEC ADD_PRODUCT @pprodid = 1002, @pprodname = "HelloProduct", @pprice = 100;


select * from PRODUCT;

-- DELETE_ALL_PRODUCTS STORED PROCEDURE


IF OBJECT_ID('DELETE_ALL_PRODUCTS') IS NOT NULL
DROP PROCEDURE DELETE_ALL_PRODUCTS;
GO

CREATE PROCEDURE DELETE_ALL_PRODUCTS AS

BEGIN
    BEGIN TRY
        DELETE FROM PRODUCT;
        DECLARE @PRODUCTROWSDELETED INT = @@ROWCOUNT;
        RETURN @PRODUCTROWSDELETED
    END TRY
        BEGIN CATCH 
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH

END
GO

EXEC DELETE_ALL_PRODUCTS;
select * from PRODUCT;

--  GET_CUSTOMER_STRING PROCEDURE

IF OBJECT_ID('GET_CUSTOMER_STRING') IS NOT NULL
DROP PROCEDURE GET_CUSTOMER_STRING;
GO

CREATE PROCEDURE GET_CUSTOMER_STRING @pCUSTID INT, @pReturnString NVARCHAR (1000) OUT AS

BEGIN
    BEGIN TRY
    DECLARE @CNAME NVARCHAR(100);
    DECLARE @STATUS NVARCHAR(7);
    DECLARE @SYTD MONEY;

    SELECT @CNAME = CUSTNAME, @STATUS = STATUS, @SYTD = SALES_YTD
    FROM CUSTOMER WHERE CUSTID = @pCUSTID;
    
    SET @pReturnString = CONCAT(' Custid: ', @pCUSTID, ' Name: ', @CNAME, ' Status: ', @STATUS, ' SalesYTD: ', @SYTD);
    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 2627
            THROW 50060, 'Customer ID not found', 1
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;

END;

GO 

INSERT INTO CUSTOMER (custid, custname, status, sales_ytd) VALUES (998, 'Agampreet Singh', 'OK', 99)


BEGIN
    DECLARE @RetStr NVARCHAR(1000);
    SET @RetStr = 'original value';

    EXEC GET_CUSTOMER_STRING @pCUSTID = 998, @pReturnString = @RetStr OUT;

    print(@RetStr);
END;

-- UPD_CUST_SALESYTD PROCEDURE
IF OBJECT_ID('UPD_CUST_SALESYTD') IS NOT NULL
    DROP PROCEDURE UPD_CUST_SALESYTD
GO

CREATE PROCEDURE UPD_CUST_SALESYTD @pCUSTID INT, @pAMT MONEY AS
BEGIN
    
    BEGIN TRY
        IF @pAMT < -999.99 OR @pAMT > 999.99
            THROW 50080, 'Amount out of range', 1
        
        UPDATE CUSTOMER SET SALES_YTD = SALES_YTD + @pAMT   WHERE CUSTID = @pCUSTID;
    END TRY
    BEGIN CATCH
         if ERROR_NUMBER() = 2627
            THROW 50070, 'Customer ID not found', 1
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 

    END CATCH
END;

EXEC UPD_CUST_SALESYTD @pCUSTID = 998, @pAMT = 10;

SELECT * from CUSTOMER;

-- GET_PROD_STRING PROCEDURE

IF OBJECT_ID('GET_PROD_STRING') IS NOT NULL
    DROP PROCEDURE GET_PROD_STRING
GO


CREATE PROCEDURE GET_PROD_STRING @pprodid INT, @pReturnString NVARCHAR(1000) OUT AS

BEGIN

    BEGIN TRY
    DECLARE @PPRODNAME NVARCHAR(100);
    DECLARE @PSELLING_PRICE MONEY;
    DECLARE @PSYTD MONEY;

    SELECT @PPRODNAME = PRODNAME, @PSELLING_PRICE = SELLING_PRICE, @PSYTD = SALES_YTD
    FROM PRODUCT WHERE PRODID = @pprodid;
    
    SET @pReturnString = CONCAT(' Prodid: ', @pprodid, ' Name: ', @pprodname,  ' Price: ', @PSELLING_PRICE, ' SalesYTD: ' , @PSYTD);
    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 2627
            THROW 50090, 'Product ID not found', 1
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 
    END CATCH;

END;

GO 

INSERT INTO PRODUCT (Prodid, ProdName, Selling_Price, sales_ytd) VALUES (999, 'Ultimate Gaming PC (full set) ', 999.99 , 99999.99)
INSERT INTO PRODUCT (Prodid, ProdName, Selling_Price, sales_ytd) VALUES (998, 'Charger', 10.00 , 10.00)

BEGIN
    DECLARE @ProRetStr NVARCHAR(1000);
    SET @ProRetStr = 'original value';

    EXEC GET_PROD_STRING @pprodid = 999, @pReturnString = @ProRetStr OUT;

    print(@ProRetStr)
END;

--  UPD_PROD_SALESYTD PROCEDURE

IF OBJECT_ID('UPD_PROD_SALESYTD') IS NOT NULL
DROP PROCEDURE UPD_PROD_SALESYTD;
GO

CREATE PROCEDURE UPD_PROD_SALESYTD @pprodid INT, @pamt MONEY AS
BEGIN
    BEGIN TRY
    IF @pamt < -999.99 OR @pamt > 999.99
            THROW 50110, 'Amount out of range', 1
        
        UPDATE PRODUCT SET SALES_YTD = SALES_YTD + @pamt  WHERE PRODID = @pprodid;
    END TRY
    BEGIN CATCH
         if ERROR_NUMBER() = 2627
            THROW 50100, 'Product ID not found', 1
        ELSE
            BEGIN
                DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
                THROW 50000, @ERRORMESSAGE, 1
            END; 

    END CATCH

END

GO

-- select * from PRODUCT
EXEC UPD_PROD_SALESYTD @pprodid = 998, @pamt = 10;

-- UPD_CUSTOMER_STATUS PROCEDURE

IF OBJECT_ID('UPD_CUSTOMER_STATUS') IS NOT NULL
DROP PROCEDURE UPD_CUSTOMER_STATUS;
GO

CREATE PROCEDURE UPD_CUSTOMER_STATUS @pcustid INT, @pstatus NVARCHAR(7) AS

BEGIN
    BEGIN TRY
    IF @pstatus <> 'OK' AND @pstatus <> 'SUSPEND'
        THROW 50130, 'Invalid Status value', 1

    UPDATE CUSTOMER SET STATUS = @pstatus WHERE CUSTID = @pcustid;
    
    IF @@ROWCOUNT = 0
            THROW 50120, 'Customer ID not found', 1
    END TRY

    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END
select * from customer;


EXEC UPD_CUSTOMER_STATUS @pcustid = 998, @pstatus = 'OK'
GO


-- ADD ADD_SIMPLE_SALE
IF OBJECT_ID('ADD_SIMPLE_SALE') IS NOT NULL
DROP PROCEDURE ADD_SIMPLE_SALE;
GO

CREATE PROCEDURE ADD_SIMPLE_SALE @PCUSTID INT, @PPRODID INT, @PQTY INT AS

BEGIN
    BEGIN TRY
        DECLARE @price INT, @ytdValue INT

        IF @PQTY < 1 OR @PQTY > 999
            THROW 50140, 'Sale Quantity outside valid range', 1

        IF (SELECT STATUS FROM CUSTOMER WHERE CUSTID = @pcustid) != 'OK'
            THROW 50150, 'Customer status is not OK', 1
        
        IF NOT EXISTS(SELECT * FROM CUSTOMER WHERE CUSTID = @pcustid)
            THROW 50160, 'Customer ID not found', 1
        
        IF NOT EXISTS(SELECT * FROM PRODUCT WHERE PRODID = @pprodid)
            THROW 50170, 'Product ID not found', 1

        SELECT @price = SELLING_PRICE
        FROM PRODUCT
        WHERE PRODID = @pprodid

        SET @ytdValue = @PQTY * @price

        EXEC UPD_CUST_SALESYTD @pcustid = @pcustid, @pamt = @ytdValue
        EXEC UPD_PROD_SALESYTD @pprodid = @pprodid, @pamt = @ytdValue

    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() IN (50140, 50150, 50160, 50170)
            THROW
        ELSE
            DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
            THROW 50000, @ERRORMESSAGE, 1

    END CATCH
END

GO


IF OBJECT_ID('SUM_CUSTOMER_SALESYTD') IS NOT NULL
    DROP PROCEDURE SUM_CUSTOMER_SALESYTD

GO

CREATE PROCEDURE SUM_CUSTOMER_SALESYTD AS

BEGIN
    BEGIN TRY 
        DECLARE @SUM INT
        SELECT @SUM = SUM(SALES_YTD)
        FROM CUSTOMER
    END TRY
    BEGIN CATCH

        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1

    END CATCH
    RETURN @SUM
END

GO 


-- SUM_PRODUCT_SALESYTD

IF OBJECT_ID('SUM_PRODUCT_SALESYTD') IS NOT NULL
    DROP PROCEDURE SUM_PRODUCT_SALESYTD

GO

CREATE PROCEDURE SUM_PRODUCT_SALESYTD AS
BEGIN
    BEGIN TRY
        DECLARE @SUM INT

        SELECT @SUM = SUM(SALES_YTD)
        FROM PRODUCT

    END TRY
    BEGIN CATCH

        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1

    END CATCH
    RETURN @SUM
END

GO

-- GET_ALL_CUSTOMERS

IF OBJECT_ID('GET_ALL_CUSTOMERS') IS NOT NULL
    DROP PROCEDURE GET_ALL_CUSTOMERS

GO

CREATE PROCEDURE GET_ALL_CUSTOMERS @POUTCUR CURSOR VARYING OUTPUT AS
BEGIN
    BEGIN TRY
        -- SET @POUTCUR = CURSOR
    
        -- SELECT * FROM CUSTOMER
        -- OPEN @POUTCUR

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END


-- GET_ALL_PRODUCTS

IF OBJECT_ID('GET_ALL_PRODUCTS') IS NOT NULL
    DROP PROCEDURE GET_ALL_PRODUCTS

GO

CREATE PROCEDURE GET_ALL_PRODUCTS @POUTCUR CURSOR VARYING OUTPUT AS
BEGIN
    BEGIN TRY
        -- SET @POUTCUR = CURSOR
        
        -- SELECT * FROM PRODUCT
        -- OPEN @POUTCUR

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END


-- ADD_LOCTION

IF OBJECT_ID('ADD_LOCATION') IS NOT NULL
    DROP PROCEDURE ADD_LOCATION

GO

CREATE PROCEDURE ADD_LOCATION @ploccode NVARCHAR(MAX), @pminqty INT, @pmaxqty INT AS
BEGIN
    BEGIN TRY
     
        IF LEN(@ploccode) != 5
            THROW 50190, 'Location Code length invalid', 1
        ELSE IF @pminqty < 0 OR @pminqty > 999
            THROW 50200, 'Minimum Qty out of range', 1
        ELSE IF @pmaxqty < 0 OR @pmaxqty > 999
            THROW 50210, 'Maximum Qty out of range', 1
        ELSE IF @pminqty > @pmaxqty
            THROW 50220, 'Minimum Qty larger than Maximum Qty', 1

        INSERT INTO LOCATION (LOCID, MINQTY, MAXQTY) 
        VALUES (@ploccode, @pminqty, @pmaxqty);

    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() = 2627
            THROW 50180, 'Duplicate location ID', 1
        ELSE IF ERROR_NUMBER() IN (50190, 50200, 50210, 50220)
            THROW
        ELSE
            DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
            THROW 50000, @ERRORMESSAGE, 1

    END CATCH
END

GO


EXEC ADD_LOCATION @ploccode = "XYZ09", @pminqty = 9, @pmaxqty = 9;
EXEC ADD_LOCATION @ploccode = "ABC12", @pminqty = 9, @pmaxqty = 9;

SELECT * FROM LOCATION;


--ADD_COMPLEX_SALE

IF OBJECT_ID('ADD_COMPLEX_SALE') IS NOT NULL
    DROP PROCEDURE ADD_COMPLEX_SALE

GO

CREATE PROCEDURE ADD_COMPLEX_SALE @pcustid INT, @pprodid INT, @pqty INT, @pdate NVARCHAR(MAX) AS
BEGIN
    DECLARE @price MONEY
    DECLARE @ytdValue MONEY
    BEGIN TRY

        IF @pqty < 1 OR @pqty > 999
            THROW 50230, 'Sale Quantity outside valid range', 1
        ELSE IF (SELECT STATUS FROM CUSTOMER WHERE CUSTID = @pcustid) != 'OK'
            THROW 50240, 'Customer status is not OK', 1
        ELSE IF ISDATE(@pdate) = 0
            THROW 50250, 'Date not valid', 1
        ELSE IF NOT EXISTS(SELECT * FROM CUSTOMER WHERE CUSTID = @pcustid)
            THROW 50260, 'Customer ID not found', 1
        ELSE IF NOT EXISTS(SELECT * FROM PRODUCT WHERE PRODID = @pprodid)
            THROW 50270, 'Product ID not found', 1

        SELECT @price = SELLING_PRICE FROM PRODUCT WHERE PRODID = @pprodid;

        INSERT INTO SALE (SALEID, CUSTID, PRODID, QTY, PRICE, SALEDATE) VALUES
        (NEXT VALUE FOR SALE_SEQ, @pcustid, @pprodid, @pqty, @price, @pdate);

        SELECT @price = SELLING_PRICE
        FROM PRODUCT
        WHERE PRODID = @pprodid

        SET @ytdValue = @pqty * @price

        EXEC UPD_CUST_SALESYTD @pcustid = @pcustid, @pamt = @ytdValue
        EXEC UPD_PROD_SALESYTD @pprodid = @pprodid, @pamt = @ytdValue

    END TRY
    BEGIN CATCH

        IF ERROR_NUMBER() IN (50230, 50240, 50250, 50260, 50270)
            THROW
        ELSE
            DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
            THROW 50000, @ERRORMESSAGE, 1

    END CATCH
END

GO

SELECT * FROM SALE

--GET_ALL_SALES

IF OBJECT_ID('GET_ALL_SALES') IS NOT NULL
    DROP PROCEDURE GET_ALL_SALES

GO

CREATE PROCEDURE GET_ALL_SALES @POUTCUR CURSOR VARYING OUTPUT AS
BEGIN
    BEGIN TRY
    --     SET @POUTCUR = CURSOR
    --     SELECT * FROM SALE
    --     OPEN @POUTCUR

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END


--COUNT_PRODUCT_SALES

IF OBJECT_ID('COUNT_PRODUCT_SALES') IS NOT NULL
DROP PROCEDURE COUNT_PRODUCT_SALES;
GO

CREATE PROCEDURE COUNT_PRODUCT_SALES @pdays INT, @pcount INT OUTPUT AS
BEGIN
    BEGIN TRY

    SELECT COUNT(SALEID) FROM SALE
    WHERE SALEDATE>=(GETDATE()-@pdays)

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH;
END;
GO


EXEC ADD_COMPLEX_SALE @pcustid = 998, @pprodid = 999, @pqty = 1, @pdate = '2021/08/12'
--DELETE_SALE

IF OBJECT_ID('DELETE_SALE') IS NOT NULL
    DROP PROCEDURE DELETE_SALE

GO

CREATE PROCEDURE DELETE_SALE @saleid BIGINT OUTPUT AS
BEGIN
    DECLARE @custid INT, @prodid INT, @price INT, @qty INT, @amt INT
    BEGIN TRY
        SELECT @saleid = SALEID, @custid = CUSTID, @prodid = PRODID, @price = PRICE, @qty = QTY
        FROM SALE
        WHERE SALEID = (SELECT MIN(SALEID) FROM SALE)

        IF @@ROWCOUNT = 0
            THROW 50280, 'No Sale Rows Found', 1;

        SET @amt = -1 * (@price * @qty)
        EXEC UPD_CUST_SALESYTD @pcustid = @custid, @pamt = @amt
        EXEC UPD_PROD_SALESYTD @pprodid = @prodid, @pamt = @amt

        DELETE FROM SALE
        WHERE SALEID = (SELECT MIN(SALEID) FROM SALE)

        IF @@ROWCOUNT = 0
            THROW 50280, 'No Sale Rows Found', 1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 50280
            THROW
        ELSE
            DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
            THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END

GO


--DELETE_ALL_SALES

IF OBJECT_ID('DELETE_ALL_SALES') IS NOT NULL
    DROP PROCEDURE DELETE_ALL_SALES

GO

CREATE PROCEDURE DELETE_ALL_SALES  AS
BEGIN
    BEGIN TRY
        DELETE FROM SALE

        UPDATE CUSTOMER
        SET SALES_YTD = 0;

        UPDATE PRODUCT
        SET SALES_YTD = 0;

    END TRY
    BEGIN CATCH
        DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
        THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END

GO

EXEC DELETE_ALL_SALES


--DELETE_CUSTOMER

IF OBJECT_ID('DELETE_CUSTOMER') IS NOT NULL
    DROP PROCEDURE DELETE_CUSTOMER

GO

CREATE PROCEDURE DELETE_CUSTOMER @pcustid INT AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS(SELECT * FROM CUSTOMER WHERE CUSTID = @pcustid)
            THROW 50290, 'Customer ID not found', 1
        IF EXISTS(SELECT * FROM SALE WHERE CUSTID = @pcustid)
            THROW 50300, 'Customer cannot be deleted as sales exist', 1

        DELETE FROM CUSTOMER WHERE CUSTID = @pcustid

    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (50290, 50300)
            THROW
        ELSE
            DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
            THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END

GO

EXEC ADD_CUSTOMER @pcustid = 1, @pcustname = 'agam';
EXEC ADD_COMPLEX_SALE @pcustid = 998, @pprodid = 999, @pqty = 1, @pdate = '2021/08/12'
SELECT * FROM CUSTOMER
SELECT * FROM SALE


EXEC DELETE_ALL_SALES
EXEC DELETE_CUSTOMER @pcustid = 1


--DELETE_PRODUCT

IF OBJECT_ID('DELETE_PRODUCT') IS NOT NULL
    DROP PROCEDURE DELETE_PRODUCT

GO

CREATE PROCEDURE DELETE_PRODUCT @pprodid INT AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS(SELECT * FROM PRODUCT WHERE PRODID = @pprodid)
            THROW 50310, 'Product ID not found', 1
        IF EXISTS(SELECT * FROM SALE WHERE PRODID = @pprodid)
            THROW 50320, 'Product cannot be deleted as sales exist', 1

        DELETE FROM PRODUCT WHERE PRODID = @pprodid

    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() IN (50290, 50300)
            THROW
        ELSE
            DECLARE @ERRORMESSAGE NVARCHAR(MAX) = ERROR_MESSAGE();
            THROW 50000, @ERRORMESSAGE, 1
    END CATCH
END

GO

EXEC ADD_PRODUCT @pprodid = 2000, @pprodname = "MOUSE", @pprice = 80
SELECT * FROM PRODUCT

EXEC DELETE_PRODUCT @pprodid = 2000

----------------------------------------------------------------------------------