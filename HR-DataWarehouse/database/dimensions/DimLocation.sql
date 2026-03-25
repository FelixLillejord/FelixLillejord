-- ============================================================
-- HRDB_DW — DimLocation
-- Work location hierarchy: Site → Region → Country
-- SCD Type 1
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.DimLocation', 'U') IS NOT NULL
    DROP TABLE dbo.DimLocation;
GO

CREATE TABLE dbo.DimLocation (
    LocationKey         INT             NOT NULL IDENTITY(1,1),
    -- Natural key from Agresso
    LocationCode        NVARCHAR(20)    NOT NULL,
    -- Hierarchy
    LocationName        NVARCHAR(200)   NULL,   -- Site/office name
    City                NVARCHAR(100)   NULL,
    Region              NVARCHAR(100)   NULL,   -- County/state/region
    Country             NVARCHAR(100)   NULL,
    CountryCode         NVARCHAR(3)     NULL,   -- ISO 3166-1 alpha-2 (NO, SE, GB, etc.)
    IsRemote            BIT             NOT NULL DEFAULT 0,
    IsActive            BIT             NOT NULL DEFAULT 1,
    -- Audit
    ETLLoadDate         DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_DimLocation PRIMARY KEY (LocationKey)
);
GO

SET IDENTITY_INSERT dbo.DimLocation ON;
INSERT INTO dbo.DimLocation (LocationKey, LocationCode, LocationName, IsActive)
VALUES (-1, 'UNKNOWN', 'Unknown', 0);
SET IDENTITY_INSERT dbo.DimLocation OFF;
GO

CREATE NONCLUSTERED INDEX IX_DimLocation_LocationCode
    ON dbo.DimLocation (LocationCode);
GO

PRINT 'Created table: dbo.DimLocation';
GO
