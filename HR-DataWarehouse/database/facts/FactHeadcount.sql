-- ============================================================
-- HRDB_DW — FactHeadcount
-- Workforce snapshot with movement flags.
-- Grain: 1 row per employee per snapshot month.
--
-- A row exists for an employee in a given month if:
--   - They were active at month-end (IsActive = 1), OR
--   - They terminated during the month (IsTerminatedThisMonth = 1)
--
-- Turnover, new hires, and headcount are all derived from
-- this single table using flag filters. No separate FactTurnover.
-- Load via: sp_LoadFactHeadcount (run at each month-end)
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.FactHeadcount', 'U') IS NOT NULL
    DROP TABLE dbo.FactHeadcount;
GO

CREATE TABLE dbo.FactHeadcount (
    HeadcountKey            INT             NOT NULL IDENTITY(1,1),
    -- Dimension foreign keys
    DateKey                 INT             NOT NULL,   -- Month-end snapshot date (YYYYMMDD)
    EmployeeKey             INT             NOT NULL,
    DepartmentKey           INT             NOT NULL,
    JobRoleKey              INT             NOT NULL,
    LocationKey             INT             NOT NULL,
    TerminationReasonKey    INT             NULL,       -- FK → DimTerminationReason; NULL if active
    -- Workforce event flags
    IsActive                BIT             NOT NULL DEFAULT 1,   -- 1 = active at month-end
    IsNewHire               BIT             NOT NULL DEFAULT 0,   -- 1 = hired within snapshot month
    IsTerminatedThisMonth   BIT             NOT NULL DEFAULT 0,   -- 1 = terminated within snapshot month
    -- Measures
    FTEValue                DECIMAL(5,2)    NULL,       -- e.g. 1.00, 0.60 (converted from FTEPercentage/100)
    TenureDays              INT             NULL,       -- Days from HireDate to month-end (or termination date)
    -- Audit
    ETLLoadDate             DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_FactHeadcount PRIMARY KEY (HeadcountKey),
    CONSTRAINT FK_FactHeadcount_Date        FOREIGN KEY (DateKey)               REFERENCES dbo.DimDate (DateKey),
    CONSTRAINT FK_FactHeadcount_Employee    FOREIGN KEY (EmployeeKey)           REFERENCES dbo.DimEmployee (EmployeeKey),
    CONSTRAINT FK_FactHeadcount_Department  FOREIGN KEY (DepartmentKey)         REFERENCES dbo.DimDepartment (DepartmentKey),
    CONSTRAINT FK_FactHeadcount_JobRole     FOREIGN KEY (JobRoleKey)            REFERENCES dbo.DimJobRole (JobRoleKey),
    CONSTRAINT FK_FactHeadcount_Location    FOREIGN KEY (LocationKey)           REFERENCES dbo.DimLocation (LocationKey),
    CONSTRAINT FK_FactHeadcount_TermReason  FOREIGN KEY (TerminationReasonKey)  REFERENCES dbo.DimTerminationReason (TerminationReasonKey)
);
GO

-- Prevent duplicate rows for the same employee in the same snapshot month
CREATE UNIQUE NONCLUSTERED INDEX UX_FactHeadcount_EmployeeDate
    ON dbo.FactHeadcount (DateKey, EmployeeKey);

-- Primary analytical query: filter by date, pull headcount/FTE/flags
CREATE NONCLUSTERED INDEX IX_FactHeadcount_DateKey
    ON dbo.FactHeadcount (DateKey)
    INCLUDE (EmployeeKey, DepartmentKey, IsActive, IsNewHire, IsTerminatedThisMonth, FTEValue);

-- Department-level analysis (turnover by dept, headcount by dept)
CREATE NONCLUSTERED INDEX IX_FactHeadcount_Department
    ON dbo.FactHeadcount (DepartmentKey, DateKey)
    INCLUDE (IsActive, IsNewHire, IsTerminatedThisMonth, FTEValue, TerminationReasonKey);

-- Turnover analysis: filter on IsTerminatedThisMonth quickly
CREATE NONCLUSTERED INDEX IX_FactHeadcount_Terminations
    ON dbo.FactHeadcount (IsTerminatedThisMonth, DateKey)
    INCLUDE (DepartmentKey, JobRoleKey, TerminationReasonKey, TenureDays)
    WHERE IsTerminatedThisMonth = 1;
GO

PRINT 'Created table: dbo.FactHeadcount (with workforce movement flags)';
GO
