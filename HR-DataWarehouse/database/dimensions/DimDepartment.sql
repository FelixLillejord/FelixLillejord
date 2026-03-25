-- ============================================================
-- HRDB_DW — DimDepartment
-- Organisational hierarchy: Division → Department → Team
-- SCD Type 1 (overwrite on change — no history)
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.DimDepartment', 'U') IS NOT NULL
    DROP TABLE dbo.DimDepartment;
GO

CREATE TABLE dbo.DimDepartment (
    DepartmentKey       INT             NOT NULL IDENTITY(1,1),
    -- Natural key from Agresso
    OrgUnitCode         NVARCHAR(20)    NOT NULL,
    -- Hierarchy attributes (denormalised for easy reporting)
    DepartmentName      NVARCHAR(200)   NULL,
    DivisionName        NVARCHAR(200)   NULL,   -- Level 1
    BusinessUnitName    NVARCHAR(200)   NULL,   -- Level 2 (optional)
    TeamName            NVARCHAR(200)   NULL,   -- Level 3 (if applicable)
    CostCentre          NVARCHAR(20)    NULL,
    HierarchyLevel      INT             NULL,   -- 1=Division, 2=Dept, 3=Team
    -- Parent reference (for hierarchy navigation)
    ParentOrgUnitCode   NVARCHAR(20)    NULL,
    IsActive            BIT             NOT NULL DEFAULT 1,
    -- Audit
    ETLLoadDate         DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_DimDepartment PRIMARY KEY (DepartmentKey)
);
GO

-- Unknown member for FK integrity
SET IDENTITY_INSERT dbo.DimDepartment ON;
INSERT INTO dbo.DimDepartment (DepartmentKey, OrgUnitCode, DepartmentName, IsActive)
VALUES (-1, 'UNKNOWN', 'Unknown', 0);
SET IDENTITY_INSERT dbo.DimDepartment OFF;
GO

CREATE NONCLUSTERED INDEX IX_DimDepartment_OrgUnitCode
    ON dbo.DimDepartment (OrgUnitCode);
GO

PRINT 'Created table: dbo.DimDepartment';
GO
