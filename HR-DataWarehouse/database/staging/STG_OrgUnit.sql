-- ============================================================
-- HRDB_Staging — STG_OrgUnit
-- Organisational unit hierarchy from Agresso Unit4
-- ============================================================

USE HRDB_Staging;
GO

IF OBJECT_ID('dbo.STG_OrgUnit', 'U') IS NOT NULL
    DROP TABLE dbo.STG_OrgUnit;
GO

CREATE TABLE dbo.STG_OrgUnit (
    OrgUnitCode         NVARCHAR(20)    NOT NULL,
    OrgUnitName         NVARCHAR(200)   NULL,
    ParentOrgUnitCode   NVARCHAR(20)    NULL,   -- NULL = top-level node
    OrgLevel            INT             NULL,   -- 1=Division, 2=Department, 3=Team
    CostCentre          NVARCHAR(20)    NULL,
    IsActive            BIT             NULL DEFAULT 1,
    -- ETL audit columns
    STGLoadDate         DATETIME        NOT NULL DEFAULT GETDATE(),
    STGSourceFile       NVARCHAR(255)   NULL,
    STGIsProcessed      BIT             NOT NULL DEFAULT 0
);
GO

CREATE NONCLUSTERED INDEX IX_STG_OrgUnit_Code
    ON dbo.STG_OrgUnit (OrgUnitCode);
GO

PRINT 'Created table: dbo.STG_OrgUnit';
GO
