-- ============================================================
-- HR Data Warehouse — Database Creation
-- Run this script once on the SQL Server instance
-- ============================================================

USE master;
GO

-- ------------------------------------------------------------
-- HRDB_Staging: Raw landing zone for Agresso Unit4 exports
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'HRDB_Staging')
BEGIN
    CREATE DATABASE HRDB_Staging
    COLLATE Latin1_General_CI_AS;
    PRINT 'Created database: HRDB_Staging';
END
ELSE
    PRINT 'Database already exists: HRDB_Staging';
GO

-- ------------------------------------------------------------
-- HRDB_DW: Star schema data warehouse
-- ------------------------------------------------------------
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'HRDB_DW')
BEGIN
    CREATE DATABASE HRDB_DW
    COLLATE Latin1_General_CI_AS;
    PRINT 'Created database: HRDB_DW';
END
ELSE
    PRINT 'Database already exists: HRDB_DW';
GO

-- ------------------------------------------------------------
-- ETL audit log table in HRDB_DW
-- ------------------------------------------------------------
USE HRDB_DW;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_Log')
BEGIN
    CREATE TABLE dbo.ETL_Log (
        LogID           INT IDENTITY(1,1)   NOT NULL,
        PackageName     NVARCHAR(100)       NOT NULL,
        StartTime       DATETIME            NOT NULL DEFAULT GETDATE(),
        EndTime         DATETIME            NULL,
        Status          NVARCHAR(20)        NOT NULL DEFAULT 'Running',
        RowsExtracted   INT                 NULL,
        RowsLoaded      INT                 NULL,
        ErrorMessage    NVARCHAR(MAX)       NULL,
        CONSTRAINT PK_ETL_Log PRIMARY KEY (LogID)
    );
    PRINT 'Created table: dbo.ETL_Log';
END
GO

PRINT 'Database setup complete.';
GO
