-- ============================================================
-- HRDB_DW — DimJobRole
-- Job catalogue: job families, levels, pay grades
-- SCD Type 1 (overwrite on change)
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.DimJobRole', 'U') IS NOT NULL
    DROP TABLE dbo.DimJobRole;
GO

CREATE TABLE dbo.DimJobRole (
    JobRoleKey          INT             NOT NULL IDENTITY(1,1),
    -- Natural key from Agresso
    JobCode             NVARCHAR(20)    NOT NULL,
    -- Descriptive attributes
    JobTitle            NVARCHAR(200)   NULL,
    JobFamily           NVARCHAR(100)   NULL,   -- HR, Finance, IT, Operations, Sales, etc.
    JobSubFamily        NVARCHAR(100)   NULL,   -- e.g. within HR: Talent, Comp&Ben, HRBP
    JobLevel            NVARCHAR(50)    NULL,   -- Junior, Mid, Senior, Lead, Manager, Director, VP
    PayGrade            NVARCHAR(20)    NULL,   -- Pay band from Agresso
    IsManagerRole       BIT             NOT NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,
    -- Audit
    ETLLoadDate         DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_DimJobRole PRIMARY KEY (JobRoleKey)
);
GO

-- Unknown member
SET IDENTITY_INSERT dbo.DimJobRole ON;
INSERT INTO dbo.DimJobRole (JobRoleKey, JobCode, JobTitle, IsActive)
VALUES (-1, 'UNKNOWN', 'Unknown', 0);
SET IDENTITY_INSERT dbo.DimJobRole OFF;
GO

CREATE NONCLUSTERED INDEX IX_DimJobRole_JobCode
    ON dbo.DimJobRole (JobCode);
GO

PRINT 'Created table: dbo.DimJobRole';
GO
