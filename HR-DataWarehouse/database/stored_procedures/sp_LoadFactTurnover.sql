-- ============================================================
-- HRDB_DW — sp_LoadFactTurnover
-- Incremental load of termination events from staging.
-- Grain: 1 row per employee termination.
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.sp_LoadFactTurnover', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_LoadFactTurnover;
GO

CREATE PROCEDURE dbo.sp_LoadFactTurnover
    @FromDate DATE = NULL   -- Defaults to last ETL run date; NULL = load all
AS
BEGIN
    SET NOCOUNT ON;

    -- Load all terminations or only new ones since @FromDate
    INSERT INTO dbo.FactTurnover (
        TerminationDateKey, HireDateKey,
        EmployeeKey, DepartmentKey, JobRoleKey, LocationKey, TerminationReasonKey,
        IsVoluntary, TenureDays, EmployeeID, ETLLoadDate
    )
    SELECT
        -- TerminationDateKey
        YEAR(stg.TerminationDate) * 10000 + MONTH(stg.TerminationDate) * 100 + DAY(stg.TerminationDate),
        -- HireDateKey
        YEAR(stg.HireDate) * 10000 + MONTH(stg.HireDate) * 100 + DAY(stg.HireDate),
        -- EmployeeKey (use current/last active version)
        ISNULL(dw.EmployeeKey,
            (SELECT TOP 1 EmployeeKey FROM dbo.DimEmployee
             WHERE EmployeeID = stg.STGEmployeeID ORDER BY EffectiveFrom DESC)),
        -- DepartmentKey
        ISNULL(dept.DepartmentKey, -1),
        -- JobRoleKey
        ISNULL(jr.JobRoleKey, -1),
        -- LocationKey
        ISNULL(loc.LocationKey, -1),
        -- TerminationReasonKey (default -1 if reason not mapped)
        ISNULL(tr.TerminationReasonKey, -1),
        -- IsVoluntary from the reason dimension
        ISNULL(tr.IsVoluntary, 0),
        -- TenureDays
        DATEDIFF(DAY, stg.HireDate, stg.TerminationDate),
        stg.STGEmployeeID,
        GETDATE()
    FROM HRDB_Staging.dbo.STG_Employee stg
    -- Only terminated employees
    WHERE stg.TerminationDate IS NOT NULL
      AND (@FromDate IS NULL OR stg.TerminationDate >= @FromDate)
    -- Avoid duplicates
    AND NOT EXISTS (
        SELECT 1 FROM dbo.FactTurnover ft WHERE ft.EmployeeID = stg.STGEmployeeID
    )
    -- Resolve dimension keys
    LEFT JOIN dbo.DimEmployee dw
        ON dw.EmployeeID = stg.STGEmployeeID AND dw.IsCurrent = 1
    LEFT JOIN dbo.DimDepartment dept ON dept.OrgUnitCode = stg.OrgUnitCode
    LEFT JOIN dbo.DimJobRole jr      ON jr.JobCode = stg.JobCode
    LEFT JOIN dbo.DimLocation loc    ON loc.LocationCode = stg.LocationCode
    -- Termination reason: match Agresso exit code to DimTerminationReason
    -- Extend this JOIN if Agresso provides a reason code column
    LEFT JOIN dbo.DimTerminationReason tr ON tr.TerminationReasonCode = 'UNKNOWN';

    PRINT 'FactTurnover loaded: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' rows';
END;
GO

PRINT 'Created procedure: dbo.sp_LoadFactTurnover';
GO
