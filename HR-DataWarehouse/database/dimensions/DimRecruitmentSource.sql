-- ============================================================
-- HRDB_DW — DimRecruitmentSource
-- How candidates found or were found by the organisation
-- Static/reference dimension
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.DimRecruitmentSource', 'U') IS NOT NULL
    DROP TABLE dbo.DimRecruitmentSource;
GO

CREATE TABLE dbo.DimRecruitmentSource (
    RecruitmentSourceKey    INT             NOT NULL IDENTITY(1,1),
    SourceName              NVARCHAR(100)   NOT NULL,   -- e.g. "LinkedIn", "Internal"
    SourceCategory          NVARCHAR(50)    NULL,       -- Digital / Internal / Agency / Direct / Other
    IsInternalSource        BIT             NOT NULL DEFAULT 0,
    IsActive                BIT             NOT NULL DEFAULT 1,
    ETLLoadDate             DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_DimRecruitmentSource PRIMARY KEY (RecruitmentSourceKey)
);
GO

SET IDENTITY_INSERT dbo.DimRecruitmentSource ON;
INSERT INTO dbo.DimRecruitmentSource (RecruitmentSourceKey, SourceName, SourceCategory, IsInternalSource)
VALUES (-1, 'Unknown', 'Other', 0);
SET IDENTITY_INSERT dbo.DimRecruitmentSource OFF;
GO

-- Seed with common sources
INSERT INTO dbo.DimRecruitmentSource (SourceName, SourceCategory, IsInternalSource) VALUES
('Internal Job Posting',    'Internal',     1),
('Employee Referral',       'Internal',     1),
('LinkedIn',                'Digital',      0),
('FINN.no',                 'Digital',      0),
('Indeed',                  'Digital',      0),
('Company Website',         'Direct',       0),
('Recruitment Agency',      'Agency',       0),
('Executive Search',        'Agency',       0),
('University / Graduate',   'Direct',       0),
('Walk-in / Unsolicited',   'Direct',       0),
('Other',                   'Other',        0);
GO

PRINT 'Created and seeded table: dbo.DimRecruitmentSource';
GO
