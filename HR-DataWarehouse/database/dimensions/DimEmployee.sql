-- ============================================================
-- HRDB_DW — DimEmployee (SCD Type 2)
-- Employee dimension with full history tracking.
-- A new row is inserted whenever a key attribute changes.
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.DimEmployee', 'U') IS NOT NULL
    DROP TABLE dbo.DimEmployee;
GO

CREATE TABLE dbo.DimEmployee (
    EmployeeKey         INT             NOT NULL IDENTITY(1,1),
    -- Natural key from Agresso
    EmployeeID          NVARCHAR(20)    NOT NULL,
    -- Personal attributes
    FirstName           NVARCHAR(100)   NULL,
    LastName            NVARCHAR(100)   NULL,
    FullName            AS (ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '')),
    Gender              NVARCHAR(20)    NULL,
    DateOfBirth         DATE            NULL,
    -- Employment attributes
    HireDate            DATE            NULL,   -- Original hire date (does not change on Type 2)
    EmploymentType      NVARCHAR(50)    NULL,   -- Full-time, Part-time, Temp, Contractor
    FTEPercentage       DECIMAL(5,2)    NULL,
    -- FK to other dimensions (current version)
    DepartmentKey       INT             NULL,
    JobRoleKey          INT             NULL,
    LocationKey         INT             NULL,
    -- Manager reference (natural key for simplicity)
    ManagerEmployeeID   NVARCHAR(20)    NULL,
    -- SCD Type 2 columns
    EffectiveFrom       DATE            NOT NULL,
    EffectiveTo         DATE            NOT NULL CONSTRAINT DF_DimEmployee_EffectiveTo DEFAULT '9999-12-31',
    IsCurrent           BIT             NOT NULL CONSTRAINT DF_DimEmployee_IsCurrent DEFAULT 1,
    -- Audit
    ETLLoadDate         DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_DimEmployee PRIMARY KEY (EmployeeKey),
    CONSTRAINT FK_DimEmployee_Department FOREIGN KEY (DepartmentKey)
        REFERENCES dbo.DimDepartment (DepartmentKey),
    CONSTRAINT FK_DimEmployee_JobRole FOREIGN KEY (JobRoleKey)
        REFERENCES dbo.DimJobRole (JobRoleKey),
    CONSTRAINT FK_DimEmployee_Location FOREIGN KEY (LocationKey)
        REFERENCES dbo.DimLocation (LocationKey)
);
GO

-- Lookup index: find current record by EmployeeID
CREATE NONCLUSTERED INDEX IX_DimEmployee_EmployeeID_Current
    ON dbo.DimEmployee (EmployeeID, IsCurrent)
    INCLUDE (EmployeeKey, DepartmentKey, JobRoleKey, LocationKey, FTEPercentage);

-- Range scan for SCD Type 2 lookups
CREATE NONCLUSTERED INDEX IX_DimEmployee_EffectiveDates
    ON dbo.DimEmployee (EmployeeID, EffectiveFrom, EffectiveTo);
GO

PRINT 'Created table: dbo.DimEmployee (SCD Type 2)';
GO
