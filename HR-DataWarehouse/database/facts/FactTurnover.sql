-- ============================================================
-- HRDB_DW — FactTurnover
-- One row per termination event.
-- Grain: 1 row per employee termination.
-- Load via: sp_LoadFactTurnover (incremental, daily)
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.FactTurnover', 'U') IS NOT NULL
    DROP TABLE dbo.FactTurnover;
GO

CREATE TABLE dbo.FactTurnover (
    TurnoverKey             INT             NOT NULL IDENTITY(1,1),
    -- Dimension foreign keys
    TerminationDateKey      INT             NOT NULL,   -- FK → DimDate
    HireDateKey             INT             NOT NULL,   -- FK → DimDate (original hire date)
    EmployeeKey             INT             NOT NULL,   -- DimEmployee version at termination
    DepartmentKey           INT             NOT NULL,   -- Department at time of termination
    JobRoleKey              INT             NOT NULL,   -- Role at time of termination
    LocationKey             INT             NOT NULL,
    TerminationReasonKey    INT             NOT NULL,
    -- Measures
    IsVoluntary             BIT             NOT NULL DEFAULT 0,
    TenureDays              INT             NULL,       -- HireDate → TerminationDate
    TenureYears             AS (TenureDays / 365.25),  -- Computed for reporting
    -- Natural key reference (for traceability)
    EmployeeID              NVARCHAR(20)    NULL,
    -- Audit
    ETLLoadDate             DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_FactTurnover PRIMARY KEY (TurnoverKey),
    CONSTRAINT FK_FactTurnover_TermDate     FOREIGN KEY (TerminationDateKey) REFERENCES dbo.DimDate (DateKey),
    CONSTRAINT FK_FactTurnover_HireDate     FOREIGN KEY (HireDateKey)        REFERENCES dbo.DimDate (DateKey),
    CONSTRAINT FK_FactTurnover_Employee     FOREIGN KEY (EmployeeKey)        REFERENCES dbo.DimEmployee (EmployeeKey),
    CONSTRAINT FK_FactTurnover_Department   FOREIGN KEY (DepartmentKey)      REFERENCES dbo.DimDepartment (DepartmentKey),
    CONSTRAINT FK_FactTurnover_JobRole      FOREIGN KEY (JobRoleKey)         REFERENCES dbo.DimJobRole (JobRoleKey),
    CONSTRAINT FK_FactTurnover_Location     FOREIGN KEY (LocationKey)        REFERENCES dbo.DimLocation (LocationKey),
    CONSTRAINT FK_FactTurnover_TermReason   FOREIGN KEY (TerminationReasonKey) REFERENCES dbo.DimTerminationReason (TerminationReasonKey)
);
GO

-- One termination per employee
CREATE UNIQUE NONCLUSTERED INDEX UX_FactTurnover_EmployeeID
    ON dbo.FactTurnover (EmployeeID)
    WHERE EmployeeID IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_FactTurnover_TermDateKey
    ON dbo.FactTurnover (TerminationDateKey)
    INCLUDE (DepartmentKey, IsVoluntary, TenureDays);

CREATE NONCLUSTERED INDEX IX_FactTurnover_Department
    ON dbo.FactTurnover (DepartmentKey, TerminationDateKey)
    INCLUDE (IsVoluntary, TerminationReasonKey);
GO

PRINT 'Created table: dbo.FactTurnover';
GO
