-- ============================================================
-- HRDB_Staging — STG_Employee
-- Raw employee master records from Agresso Unit4
-- ============================================================

USE HRDB_Staging;
GO

IF OBJECT_ID('dbo.STG_Employee', 'U') IS NOT NULL
    DROP TABLE dbo.STG_Employee;
GO

CREATE TABLE dbo.STG_Employee (
    STGEmployeeID       NVARCHAR(20)    NOT NULL,
    FirstName           NVARCHAR(100)   NULL,
    LastName            NVARCHAR(100)   NULL,
    Gender              NVARCHAR(10)    NULL,
    DateOfBirth         DATE            NULL,
    NationalID          NVARCHAR(20)    NULL,   -- Hash/mask before loading if GDPR applies
    HireDate            DATE            NULL,
    TerminationDate     DATE            NULL,   -- NULL = active employee
    OrgUnitCode         NVARCHAR(20)    NULL,
    JobCode             NVARCHAR(20)    NULL,
    PositionCode        NVARCHAR(20)    NULL,
    LocationCode        NVARCHAR(20)    NULL,
    EmploymentType      NVARCHAR(50)    NULL,   -- Full-time, Part-time, Temp, Contractor
    FTEPercentage       DECIMAL(5,2)    NULL,   -- e.g. 100.00, 60.00, 50.00
    ManagerEmployeeID   NVARCHAR(20)    NULL,
    -- ETL audit columns
    STGLoadDate         DATETIME        NOT NULL DEFAULT GETDATE(),
    STGSourceFile       NVARCHAR(255)   NULL,
    STGIsProcessed      BIT             NOT NULL DEFAULT 0
);
GO

-- Index for ETL lookup
CREATE NONCLUSTERED INDEX IX_STG_Employee_EmployeeID
    ON dbo.STG_Employee (STGEmployeeID);
GO

PRINT 'Created table: dbo.STG_Employee';
GO
