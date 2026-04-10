-- ============================================================
-- HRDB_DW — sp_LoadFactHeadcount
-- Loads the monthly workforce snapshot with movement flags.
-- Run at month-end (or pass @SnapshotDate explicitly).
--
-- Two-pass load:
--   Pass 1 — Active employees at month-end
--   Pass 2 — Employees who terminated during the snapshot month
--             (not active at month-end, but part of the movement)
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

    DECLARE @DateKey        INT  = YEAR(@SnapshotDate) * 10000
                                 + MONTH(@SnapshotDate) * 100
                                 + DAY(@SnapshotDate);
    -- First day of the snapshot month (for termination window)
    DECLARE @MonthStart     DATE = DATEFROMPARTS(YEAR(@SnapshotDate), MONTH(@SnapshotDate), 1);

    -- Guard: skip if snapshot already loaded for this date
    IF EXISTS (SELECT 1 FROM dbo.FactHeadcount WHERE DateKey = @DateKey)
    BEGIN
        PRINT 'Headcount snapshot already exists for DateKey: ' + CAST(@DateKey AS NVARCHAR);
        RETURN;
    END

    -- Validate DateKey exists in DimDate
    IF NOT EXISTS (SELECT 1 FROM dbo.DimDate WHERE DateKey = @DateKey)
    BEGIN
        RAISERROR('DateKey %d not found in DimDate. Run DimDate.sql first.', 16, 1, @DateKey);
        RETURN;
    END

    -- --------------------------------------------------------
    -- PASS 1: Active employees at month-end
    -- Employees with HireDate <= @SnapshotDate and no termination
    -- on or before @SnapshotDate
    -- --------------------------------------------------------
    INSERT INTO dbo.FactHeadcount (
        DateKey, EmployeeKey, DepartmentKey, JobRoleKey, LocationKey,
        TerminationReasonKey,
        IsActive, IsNewHire, IsTerminatedThisMonth,
        FTEValue, TenureDays, ETLLoadDate
    )
    SELECT
        @DateKey,
        dw.EmployeeKey,
        ISNULL(dw.DepartmentKey, -1),
        ISNULL(dw.JobRoleKey, -1),
        ISNULL(dw.LocationKey, -1),
        NULL,                                               -- TerminationReasonKey: NULL (active)
        1,                                                  -- IsActive
        CASE
            WHEN YEAR(dw.HireDate)  = YEAR(@SnapshotDate)
             AND MONTH(dw.HireDate) = MONTH(@SnapshotDate)
            THEN 1 ELSE 0
        END,                                                -- IsNewHire
        0,                                                  -- IsTerminatedThisMonth
        ISNULL(dw.FTEPercentage, 0) / 100.0,               -- FTEValue (% → fraction)
        DATEDIFF(DAY, dw.HireDate, @SnapshotDate),          -- TenureDays
        GETDATE()
    FROM dbo.DimEmployee dw
    -- Current version of the employee record
    WHERE dw.IsCurrent = 1
      -- Hired on or before the snapshot date
      AND dw.HireDate <= @SnapshotDate
      -- Not terminated on or before the snapshot date
      AND NOT EXISTS (
            SELECT 1
            FROM HRDB_Staging.dbo.STG_Employee stg
            WHERE stg.STGEmployeeID = dw.EmployeeID
              AND stg.TerminationDate IS NOT NULL
              AND stg.TerminationDate <= @SnapshotDate
      );

    PRINT 'Pass 1 (active): ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows inserted';

    -- --------------------------------------------------------
    -- PASS 2: Employees terminated within the snapshot month
    -- TerminationDate falls between @MonthStart and @SnapshotDate
    -- --------------------------------------------------------
    INSERT INTO dbo.FactHeadcount (
        DateKey, EmployeeKey, DepartmentKey, JobRoleKey, LocationKey,
        TerminationReasonKey,
        IsActive, IsNewHire, IsTerminatedThisMonth,
        FTEValue, TenureDays, ETLLoadDate
    )
    SELECT
        @DateKey,
        ISNULL(dw.EmployeeKey,
            -- Fallback: get last known surrogate key for this employee
            (SELECT TOP 1 EmployeeKey FROM dbo.DimEmployee
             WHERE EmployeeID = stg.STGEmployeeID ORDER BY EffectiveFrom DESC)
        ),
        ISNULL(dw.DepartmentKey, -1),
        ISNULL(dw.JobRoleKey, -1),
        ISNULL(dw.LocationKey, -1),
        ISNULL(tr.TerminationReasonKey, -1),                -- TerminationReasonKey
        0,                                                  -- IsActive (not active at month-end)
        CASE
            WHEN YEAR(stg.HireDate)  = YEAR(@SnapshotDate)
             AND MONTH(stg.HireDate) = MONTH(@SnapshotDate)
            THEN 1 ELSE 0
        END,                                                -- IsNewHire (hired and left same month)
        1,                                                  -- IsTerminatedThisMonth
        ISNULL(dw.FTEPercentage, 0) / 100.0,               -- FTEValue (at time of termination)
        DATEDIFF(DAY, stg.HireDate, stg.TerminationDate),  -- TenureDays (hire → actual termination)
        GETDATE()
    FROM HRDB_Staging.dbo.STG_Employee stg
    -- Terminated within the snapshot month
    WHERE stg.TerminationDate >= @MonthStart
      AND stg.TerminationDate <= @SnapshotDate
    -- Resolve current DimEmployee record
    LEFT JOIN dbo.DimEmployee dw
        ON dw.EmployeeID = stg.STGEmployeeID AND dw.IsCurrent = 1
    -- Resolve termination reason (extend JOIN condition once Agresso provides reason codes)
    LEFT JOIN dbo.DimTerminationReason tr
        ON tr.TerminationReasonCode = 'UNKNOWN'     -- Replace with stg.TerminationReasonCode
    -- Avoid duplicates (employee might already appear in Pass 1 if error in source data)
    AND NOT EXISTS (
        SELECT 1 FROM dbo.FactHeadcount fc
        WHERE fc.DateKey = @DateKey
          AND fc.EmployeeKey = dw.EmployeeKey
    );

    PRINT 'Pass 2 (terminated): ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows inserted';
    PRINT 'FactHeadcount snapshot complete for DateKey: ' + CAST(@DateKey AS NVARCHAR);
END;
GO

PRINT 'Created procedure: dbo.sp_LoadFactHeadcount (2-pass: active + terminated)';
GO
