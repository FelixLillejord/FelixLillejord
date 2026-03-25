-- ============================================================
-- HRDB_DW — FactHeadcount
-- Monthly snapshot of the active workforce.
-- Grain: 1 row per employee per month-end date.
-- Load via: sp_LoadFactHeadcount (run at each month-end)
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.FactHeadcount', 'U') IS NOT NULL
    DROP TABLE dbo.FactHeadcount;
GO

CREATE TABLE dbo.FactHeadcount (
    HeadcountKey        INT             NOT NULL IDENTITY(1,1),
    -- Dimension foreign keys
    DateKey             INT             NOT NULL,   -- Month-end date (e.g. 20240131)
    EmployeeKey         INT             NOT NULL,
    DepartmentKey       INT             NOT NULL,
    JobRoleKey          INT             NOT NULL,
    LocationKey         INT             NOT NULL,
    -- Measures
    IsActive            BIT             NOT NULL DEFAULT 1,
    FTEValue            DECIMAL(5,2)    NULL,           -- e.g. 1.00, 0.60, 0.50
    IsNewHire           BIT             NOT NULL DEFAULT 0,  -- Hired within snapshot month
    -- Audit
    ETLLoadDate         DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_FactHeadcount PRIMARY KEY (HeadcountKey),
    CONSTRAINT FK_FactHeadcount_Date        FOREIGN KEY (DateKey)       REFERENCES dbo.DimDate (DateKey),
    CONSTRAINT FK_FactHeadcount_Employee    FOREIGN KEY (EmployeeKey)   REFERENCES dbo.DimEmployee (EmployeeKey),
    CONSTRAINT FK_FactHeadcount_Department  FOREIGN KEY (DepartmentKey) REFERENCES dbo.DimDepartment (DepartmentKey),
    CONSTRAINT FK_FactHeadcount_JobRole     FOREIGN KEY (JobRoleKey)    REFERENCES dbo.DimJobRole (JobRoleKey),
    CONSTRAINT FK_FactHeadcount_Location    FOREIGN KEY (LocationKey)   REFERENCES dbo.DimLocation (LocationKey)
);
GO

-- Prevent duplicate snapshots for the same employee + month
CREATE UNIQUE NONCLUSTERED INDEX UX_FactHeadcount_EmployeeDate
    ON dbo.FactHeadcount (DateKey, EmployeeKey);

-- Analytical query indexes
CREATE NONCLUSTERED INDEX IX_FactHeadcount_DateKey
    ON dbo.FactHeadcount (DateKey)
    INCLUDE (EmployeeKey, DepartmentKey, IsActive, FTEValue);

CREATE NONCLUSTERED INDEX IX_FactHeadcount_Department
    ON dbo.FactHeadcount (DepartmentKey, DateKey)
    INCLUDE (IsActive, FTEValue, IsNewHire);
GO

PRINT 'Created table: dbo.FactHeadcount';
GO
