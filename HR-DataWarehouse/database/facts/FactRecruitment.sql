-- ============================================================
-- HRDB_DW — FactRecruitment
-- Recruitment funnel — one row per application.
-- Grain: 1 row per VacancyID + ApplicantID combination.
-- Load via: sp_LoadFactRecruitment (incremental, daily)
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.FactRecruitment', 'U') IS NOT NULL
    DROP TABLE dbo.FactRecruitment;
GO

CREATE TABLE dbo.FactRecruitment (
    RecruitmentKey          INT             NOT NULL IDENTITY(1,1),
    -- Dimension foreign keys
    ApplicationDateKey      INT             NOT NULL,   -- FK → DimDate
    HireDateKey             INT             NULL,       -- FK → DimDate (NULL if not hired)
    PostingDateKey          INT             NULL,       -- FK → DimDate
    EmployeeKey             INT             NULL,       -- FK → DimEmployee (populated after hire)
    DepartmentKey           INT             NOT NULL,   -- Hiring department
    JobRoleKey              INT             NOT NULL,
    RecruitmentSourceKey    INT             NOT NULL,
    -- Funnel stage
    ApplicationStage        NVARCHAR(50)    NOT NULL,   -- Applied/Screened/Interviewed/Offered/Hired/Rejected
    -- Measures
    IsHired                 BIT             NOT NULL DEFAULT 0,
    IsOfferMade             BIT             NOT NULL DEFAULT 0,
    TimeToFillDays          INT             NULL,       -- PostingDate → HireDate
    TimeToHireDays          INT             NULL,       -- ApplicationDate → OfferAcceptDate
    -- Natural keys for traceability
    VacancyID               NVARCHAR(20)    NULL,
    ApplicantID             NVARCHAR(20)    NULL,
    -- Audit
    ETLLoadDate             DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_FactRecruitment PRIMARY KEY (RecruitmentKey),
    CONSTRAINT FK_FactRecruitment_AppDate   FOREIGN KEY (ApplicationDateKey) REFERENCES dbo.DimDate (DateKey),
    CONSTRAINT FK_FactRecruitment_HireDate  FOREIGN KEY (HireDateKey)        REFERENCES dbo.DimDate (DateKey),
    CONSTRAINT FK_FactRecruitment_PostDate  FOREIGN KEY (PostingDateKey)     REFERENCES dbo.DimDate (DateKey),
    CONSTRAINT FK_FactRecruitment_Employee  FOREIGN KEY (EmployeeKey)        REFERENCES dbo.DimEmployee (EmployeeKey),
    CONSTRAINT FK_FactRecruitment_Dept      FOREIGN KEY (DepartmentKey)      REFERENCES dbo.DimDepartment (DepartmentKey),
    CONSTRAINT FK_FactRecruitment_JobRole   FOREIGN KEY (JobRoleKey)         REFERENCES dbo.DimJobRole (JobRoleKey),
    CONSTRAINT FK_FactRecruitment_Source    FOREIGN KEY (RecruitmentSourceKey) REFERENCES dbo.DimRecruitmentSource (RecruitmentSourceKey)
);
GO

-- Prevent duplicate applications
CREATE UNIQUE NONCLUSTERED INDEX UX_FactRecruitment_VacancyApplicant
    ON dbo.FactRecruitment (VacancyID, ApplicantID)
    WHERE VacancyID IS NOT NULL AND ApplicantID IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_FactRecruitment_ApplicationDate
    ON dbo.FactRecruitment (ApplicationDateKey)
    INCLUDE (DepartmentKey, IsHired, TimeToFillDays, TimeToHireDays);

CREATE NONCLUSTERED INDEX IX_FactRecruitment_Department
    ON dbo.FactRecruitment (DepartmentKey, ApplicationDateKey)
    INCLUDE (IsHired, RecruitmentSourceKey, ApplicationStage);
GO

PRINT 'Created table: dbo.FactRecruitment';
GO
