-- ============================================================
-- HRDB_Staging — STG_Recruitment
-- Vacancy and applicant data from Agresso Unit4 recruitment module
-- ============================================================

USE HRDB_Staging;
GO

IF OBJECT_ID('dbo.STG_Recruitment', 'U') IS NOT NULL
    DROP TABLE dbo.STG_Recruitment;
GO

CREATE TABLE dbo.STG_Recruitment (
    VacancyID           NVARCHAR(20)    NOT NULL,
    ApplicantID         NVARCHAR(20)    NOT NULL,
    OrgUnitCode         NVARCHAR(20)    NULL,   -- Hiring department
    JobCode             NVARCHAR(20)    NULL,
    PostingDate         DATE            NULL,   -- Vacancy published date
    ApplicationDate     DATE            NULL,   -- Application received
    ApplicationStage    NVARCHAR(50)    NULL,   -- Applied/Screened/Interviewed/Offered/Hired/Rejected
    RecruitmentSource   NVARCHAR(100)   NULL,   -- LinkedIn, Internal, Referral, Agency, etc.
    OfferDate           DATE            NULL,
    OfferAcceptDate     DATE            NULL,   -- NULL if offer rejected or pending
    HireDate            DATE            NULL,   -- NULL if not hired
    HiredEmployeeID     NVARCHAR(20)    NULL,   -- Links to STG_Employee.STGEmployeeID
    -- ETL audit columns
    STGLoadDate         DATETIME        NOT NULL DEFAULT GETDATE(),
    STGSourceFile       NVARCHAR(255)   NULL,
    STGIsProcessed      BIT             NOT NULL DEFAULT 0
);
GO

CREATE NONCLUSTERED INDEX IX_STG_Recruitment_VacancyApplicant
    ON dbo.STG_Recruitment (VacancyID, ApplicantID);

CREATE NONCLUSTERED INDEX IX_STG_Recruitment_ApplicationDate
    ON dbo.STG_Recruitment (ApplicationDate);
GO

PRINT 'Created table: dbo.STG_Recruitment';
GO
