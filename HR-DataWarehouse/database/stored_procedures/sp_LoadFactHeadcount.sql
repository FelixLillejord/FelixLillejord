-- ============================================================
-- HRDB_DW — sp_LoadFactHeadcount
-- Creates a monthly headcount snapshot.
-- Grain: 1 row per active employee at the snapshot date.
-- Run at month-end or pass @SnapshotDate explicitly.
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.sp_LoadFactHeadcount', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_LoadFactHeadcount;
GO

CREATE PROCEDURE dbo.sp_LoadFactHeadcount
    @SnapshotDate   DATE = NULL     -- Defaults to last day of prior month
AS
BEGIN
    SET NOCOUNT ON;

    -- Default: last day of the previous month
    IF @SnapshotDate IS NULL
        SET @SnapshotDate = EOMONTH(DATEADD(MONTH, -1, GETDATE()));

    DECLARE @DateKey INT = YEAR(@SnapshotDate) * 10000
                         + MONTH(@SnapshotDate) * 100
                         + DAY(@SnapshotDate);

    -- Guard: skip if snapshot already loaded for this date
    IF EXISTS (SELECT 1 FROM dbo.FactHeadcount WHERE DateKey = @DateKey)
    BEGIN
        PRINT 'Headcount snapshot already exists for DateKey: ' + CAST(@DateKey AS NVARCHAR);
        RETURN;
    END

    -- Validate DateKey exists in DimDate
    IF NOT EXISTS (SELECT 1 FROM dbo.DimDate WHERE DateKey = @DateKey)
    BEGIN
        RAISERROR('DateKey %d not found in DimDate. Populate DimDate first.', 16, 1, @DateKey);
        RETURN;
    END

    INSERT INTO dbo.FactHeadcount (
        DateKey, EmployeeKey, DepartmentKey, JobRoleKey, LocationKey,
        IsActive, FTEValue, IsNewHire, ETLLoadDate
    )
    SELECT
        @DateKey,
        dw.EmployeeKey,
        ISNULL(dw.DepartmentKey, -1),
        ISNULL(dw.JobRoleKey, -1),
        ISNULL(dw.LocationKey, -1),
        1,                                              -- IsActive
        ISNULL(dw.FTEPercentage, 0) / 100.0,           -- Convert % to FTE (e.g. 100 → 1.00)
        CASE
            WHEN YEAR(dw.HireDate) = YEAR(@SnapshotDate)
             AND MONTH(dw.HireDate) = MONTH(@SnapshotDate)
            THEN 1 ELSE 0
        END,                                            -- IsNewHire
        GETDATE()
    FROM dbo.DimEmployee dw
    -- Active employees at snapshot date (use SCD2 date range)
    WHERE dw.EffectiveFrom <= @SnapshotDate
      AND dw.EffectiveTo   >= @SnapshotDate
      AND dw.IsCurrent = 1
      -- Exclude terminated employees
      AND NOT EXISTS (
            SELECT 1 FROM dbo.FactTurnover ft
            WHERE ft.EmployeeKey = dw.EmployeeKey
              AND ft.TerminationDateKey <= @DateKey
      );

    PRINT 'FactHeadcount loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR)
        + ' rows for DateKey ' + CAST(@DateKey AS NVARCHAR);
END;
GO

PRINT 'Created procedure: dbo.sp_LoadFactHeadcount';
GO
