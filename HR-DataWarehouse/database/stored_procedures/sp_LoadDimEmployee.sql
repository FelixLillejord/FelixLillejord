-- ============================================================
-- HRDB_DW — sp_LoadDimEmployee
-- SCD Type 2 load: tracks changes to employee attributes
-- over time by inserting new rows instead of overwriting.
-- Called by SSIS package: 02_Load_Dimensions.dtsx
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.sp_LoadDimEmployee', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_LoadDimEmployee;
GO

CREATE PROCEDURE dbo.sp_LoadDimEmployee
AS
BEGIN
    SET NOCOUNT ON;

    -- SCD Type 2 key attributes: any change in these creates a new row
    -- Non-SCD attributes (FirstName, LastName, etc.) are updated in-place

    -- --------------------------------------------------------
    -- Step 1: Close expired records (Type 2 change detected)
    -- Expire the current DimEmployee row when key attributes differ
    -- --------------------------------------------------------
    UPDATE dw
    SET
        dw.EffectiveTo  = CAST(GETDATE() AS DATE),
        dw.IsCurrent    = 0
    FROM dbo.DimEmployee dw
    INNER JOIN HRDB_Staging.dbo.STG_Employee stg
        ON dw.EmployeeID = stg.STGEmployeeID
        AND dw.IsCurrent = 1
    LEFT JOIN dbo.DimDepartment dept
        ON dept.OrgUnitCode = stg.OrgUnitCode
    LEFT JOIN dbo.DimJobRole jr
        ON jr.JobCode = stg.JobCode
    LEFT JOIN dbo.DimLocation loc
        ON loc.LocationCode = stg.LocationCode
    WHERE
        -- Key SCD2 attributes have changed
        ISNULL(dw.DepartmentKey, -1) <> ISNULL(dept.DepartmentKey, -1)
        OR ISNULL(dw.JobRoleKey, -1) <> ISNULL(jr.JobRoleKey, -1)
        OR ISNULL(dw.LocationKey, -1) <> ISNULL(loc.LocationKey, -1)
        OR ISNULL(dw.EmploymentType, '') <> ISNULL(stg.EmploymentType, '')
        OR ISNULL(dw.FTEPercentage, 0) <> ISNULL(stg.FTEPercentage, 0);

    PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' DimEmployee records expired (Type 2 change)';

    -- --------------------------------------------------------
    -- Step 2: Insert new rows for:
    --   a) Brand new employees (not in DimEmployee at all)
    --   b) Employees whose current record was just expired
    -- --------------------------------------------------------
    INSERT INTO dbo.DimEmployee (
        EmployeeID, FirstName, LastName,
        Gender, DateOfBirth, HireDate,
        EmploymentType, FTEPercentage,
        DepartmentKey, JobRoleKey, LocationKey, ManagerEmployeeID,
        EffectiveFrom, EffectiveTo, IsCurrent, ETLLoadDate
    )
    SELECT
        stg.STGEmployeeID,
        stg.FirstName,
        stg.LastName,
        stg.Gender,
        stg.DateOfBirth,
        stg.HireDate,
        stg.EmploymentType,
        stg.FTEPercentage,
        ISNULL(dept.DepartmentKey, -1),
        ISNULL(jr.JobRoleKey, -1),
        ISNULL(loc.LocationKey, -1),
        stg.ManagerEmployeeID,
        CAST(GETDATE() AS DATE),        -- EffectiveFrom
        '9999-12-31',                   -- EffectiveTo (open-ended = current)
        1,                              -- IsCurrent
        GETDATE()
    FROM HRDB_Staging.dbo.STG_Employee stg
    LEFT JOIN dbo.DimDepartment dept ON dept.OrgUnitCode = stg.OrgUnitCode
    LEFT JOIN dbo.DimJobRole jr      ON jr.JobCode = stg.JobCode
    LEFT JOIN dbo.DimLocation loc    ON loc.LocationCode = stg.LocationCode
    -- Only insert if there is no current active row (new employee or just expired)
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.DimEmployee dw
        WHERE dw.EmployeeID = stg.STGEmployeeID
          AND dw.IsCurrent = 1
    );

    PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' DimEmployee rows inserted';

    -- --------------------------------------------------------
    -- Step 3: Update non-SCD2 attributes on existing current rows
    -- (name corrections, DOB corrections etc. — overwrite in-place)
    -- --------------------------------------------------------
    UPDATE dw
    SET
        dw.FirstName            = stg.FirstName,
        dw.LastName             = stg.LastName,
        dw.Gender               = stg.Gender,
        dw.DateOfBirth          = stg.DateOfBirth,
        dw.ManagerEmployeeID    = stg.ManagerEmployeeID,
        dw.ETLLoadDate          = GETDATE()
    FROM dbo.DimEmployee dw
    INNER JOIN HRDB_Staging.dbo.STG_Employee stg
        ON dw.EmployeeID = stg.STGEmployeeID
        AND dw.IsCurrent = 1;

    PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' DimEmployee rows updated (non-SCD attributes)';

    -- Mark staging rows as processed
    UPDATE HRDB_Staging.dbo.STG_Employee SET STGIsProcessed = 1;
END;
GO

PRINT 'Created procedure: dbo.sp_LoadDimEmployee';
GO
