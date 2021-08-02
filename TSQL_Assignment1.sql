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
DROP PROCEDURE UPD_CUST_SALESYTD;
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
DROP PROCEDURE GET_PROD_STRING;
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


BEGIN
    DECLARE @ProRetStr NVARCHAR(1000);
    SET @ProRetStr = 'original value';

    EXEC GET_PROD_STRING @pprodid = 999, @pReturnString = @ProRetStr OUT;

    print(@ProRetStr);
END;
