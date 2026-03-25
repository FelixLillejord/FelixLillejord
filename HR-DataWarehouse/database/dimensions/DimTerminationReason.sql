-- ============================================================
-- HRDB_DW — DimTerminationReason
-- Categorises why employees leave the organisation
-- Static/reference dimension — load once and maintain manually
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.DimTerminationReason', 'U') IS NOT NULL
    DROP TABLE dbo.DimTerminationReason;
GO

CREATE TABLE dbo.DimTerminationReason (
    TerminationReasonKey    INT             NOT NULL IDENTITY(1,1),
    TerminationReasonCode   NVARCHAR(20)    NOT NULL,   -- Code from Agresso
    TerminationReason       NVARCHAR(200)   NULL,       -- Descriptive label
    TerminationCategory     NVARCHAR(50)    NULL,       -- Voluntary / Involuntary / Retirement / Other
    IsVoluntary             BIT             NOT NULL DEFAULT 0,
    IsActive                BIT             NOT NULL DEFAULT 1,
    ETLLoadDate             DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_DimTerminationReason PRIMARY KEY (TerminationReasonKey)
);
GO

-- Unknown member
SET IDENTITY_INSERT dbo.DimTerminationReason ON;
INSERT INTO dbo.DimTerminationReason (TerminationReasonKey, TerminationReasonCode, TerminationReason, TerminationCategory, IsVoluntary)
VALUES (-1, 'UNKNOWN', 'Unknown', 'Other', 0);
SET IDENTITY_INSERT dbo.DimTerminationReason OFF;
GO

-- Seed with common reason categories — update codes to match Agresso
INSERT INTO dbo.DimTerminationReason (TerminationReasonCode, TerminationReason, TerminationCategory, IsVoluntary) VALUES
('RES', 'Resignation',              'Voluntary',    1),
('RET', 'Retirement',               'Retirement',   1),
('PER', 'Personal Reasons',         'Voluntary',    1),
('NEW', 'New Opportunity',          'Voluntary',    1),
('REL', 'Relocation',               'Voluntary',    1),
('DIS', 'Dismissal',                'Involuntary',  0),
('RED', 'Redundancy',               'Involuntary',  0),
('END', 'End of Contract',          'Involuntary',  0),
('PRO', 'Probation Not Passed',     'Involuntary',  0),
('MUT', 'Mutual Agreement',         'Other',        0),
('DEC', 'Death',                    'Other',        0);
GO

PRINT 'Created and seeded table: dbo.DimTerminationReason';
GO
