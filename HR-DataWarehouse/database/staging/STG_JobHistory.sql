-- ============================================================
-- HRDB_Staging — STG_JobHistory
-- Job change events from Agresso Unit4 HR module
-- ============================================================

USE HRDB_Staging;
GO

IF OBJECT_ID('dbo.STG_JobHistory', 'U') IS NOT NULL
    DROP TABLE dbo.STG_JobHistory;
GO

CREATE TABLE dbo.STG_JobHistory (
    STGEmployeeID       NVARCHAR(20)    NOT NULL,
    EffectiveDate       DATE            NOT NULL,   -- Date the change took effect
    OrgUnitCode         NVARCHAR(20)    NULL,
    JobCode             NVARCHAR(20)    NULL,
    PositionCode        NVARCHAR(20)    NULL,
    FTEPercentage       DECIMAL(5,2)    NULL,
    ChangeReason        NVARCHAR(100)   NULL,       -- Promotion, Transfer, Rehire, etc.
    -- ETL audit columns
    STGLoadDate         DATETIME        NOT NULL DEFAULT GETDATE(),
    STGSourceFile       NVARCHAR(255)   NULL,
    STGIsProcessed      BIT             NOT NULL DEFAULT 0
);
GO

CREATE NONCLUSTERED INDEX IX_STG_JobHistory_EmployeeID
    ON dbo.STG_JobHistory (STGEmployeeID, EffectiveDate);
GO

PRINT 'Created table: dbo.STG_JobHistory';
GO
