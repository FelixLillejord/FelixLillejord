-- ============================================================
-- HRDB_DW — sp_LoadFactRecruitment
-- Incremental load of recruitment funnel events from staging.
-- Grain: 1 row per VacancyID + ApplicantID.
-- Upserts: updates ApplicationStage and metrics as applicant progresses.
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.sp_LoadFactRecruitment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_LoadFactRecruitment;
GO

CREATE PROCEDURE dbo.sp_LoadFactRecruitment
    @FromDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- --------------------------------------------------------
    -- Step 1: Update existing records (stage progression)
    -- --------------------------------------------------------
    UPDATE fr
    SET
        fr.ApplicationStage = stg.ApplicationStage,
        fr.IsHired          = CASE WHEN stg.HireDate IS NOT NULL THEN 1 ELSE 0 END,
        fr.IsOfferMade      = CASE WHEN stg.OfferDate IS NOT NULL THEN 1 ELSE 0 END,
        fr.TimeToFillDays   = CASE WHEN stg.HireDate IS NOT NULL AND stg.PostingDate IS NOT NULL
                                    THEN DATEDIFF(DAY, stg.PostingDate, stg.HireDate)
                                    ELSE NULL END,
        fr.TimeToHireDays   = CASE WHEN stg.OfferAcceptDate IS NOT NULL AND stg.ApplicationDate IS NOT NULL
                                    THEN DATEDIFF(DAY, stg.ApplicationDate, stg.OfferAcceptDate)
                                    ELSE NULL END,
        fr.HireDateKey      = CASE WHEN stg.HireDate IS NOT NULL
                                    THEN YEAR(stg.HireDate) * 10000 + MONTH(stg.HireDate) * 100 + DAY(stg.HireDate)
                                    ELSE NULL END,
        fr.EmployeeKey      = CASE WHEN stg.HiredEmployeeID IS NOT NULL
                                    THEN (SELECT TOP 1 EmployeeKey FROM dbo.DimEmployee
                                          WHERE EmployeeID = stg.HiredEmployeeID AND IsCurrent = 1)
                                    ELSE NULL END,
        fr.ETLLoadDate      = GETDATE()
    FROM dbo.FactRecruitment fr
    INNER JOIN HRDB_Staging.dbo.STG_Recruitment stg
        ON fr.VacancyID = stg.VacancyID AND fr.ApplicantID = stg.ApplicantID;

    PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' FactRecruitment rows updated';

    -- --------------------------------------------------------
    -- Step 2: Insert new applications
    -- --------------------------------------------------------
    INSERT INTO dbo.FactRecruitment (
        ApplicationDateKey, HireDateKey, PostingDateKey,
        EmployeeKey, DepartmentKey, JobRoleKey, RecruitmentSourceKey,
        ApplicationStage, IsHired, IsOfferMade,
        TimeToFillDays, TimeToHireDays,
        VacancyID, ApplicantID, ETLLoadDate
    )
    SELECT
        -- ApplicationDateKey
        YEAR(stg.ApplicationDate) * 10000 + MONTH(stg.ApplicationDate) * 100 + DAY(stg.ApplicationDate),
        -- HireDateKey
        CASE WHEN stg.HireDate IS NOT NULL
            THEN YEAR(stg.HireDate) * 10000 + MONTH(stg.HireDate) * 100 + DAY(stg.HireDate)
            ELSE NULL END,
        -- PostingDateKey
        CASE WHEN stg.PostingDate IS NOT NULL
            THEN YEAR(stg.PostingDate) * 10000 + MONTH(stg.PostingDate) * 100 + DAY(stg.PostingDate)
            ELSE NULL END,
        -- EmployeeKey (populated on hire)
        CASE WHEN stg.HiredEmployeeID IS NOT NULL
            THEN (SELECT TOP 1 EmployeeKey FROM dbo.DimEmployee
                  WHERE EmployeeID = stg.HiredEmployeeID AND IsCurrent = 1)
            ELSE NULL END,
        ISNULL(dept.DepartmentKey, -1),
        ISNULL(jr.JobRoleKey, -1),
        ISNULL(src.RecruitmentSourceKey, -1),
        stg.ApplicationStage,
        CASE WHEN stg.HireDate IS NOT NULL THEN 1 ELSE 0 END,
        CASE WHEN stg.OfferDate IS NOT NULL THEN 1 ELSE 0 END,
        CASE WHEN stg.HireDate IS NOT NULL AND stg.PostingDate IS NOT NULL
            THEN DATEDIFF(DAY, stg.PostingDate, stg.HireDate) ELSE NULL END,
        CASE WHEN stg.OfferAcceptDate IS NOT NULL AND stg.ApplicationDate IS NOT NULL
            THEN DATEDIFF(DAY, stg.ApplicationDate, stg.OfferAcceptDate) ELSE NULL END,
        stg.VacancyID,
        stg.ApplicantID,
        GETDATE()
    FROM HRDB_Staging.dbo.STG_Recruitment stg
    LEFT JOIN dbo.DimDepartment dept         ON dept.OrgUnitCode = stg.OrgUnitCode
    LEFT JOIN dbo.DimJobRole jr              ON jr.JobCode = stg.JobCode
    LEFT JOIN dbo.DimRecruitmentSource src   ON src.SourceName = stg.RecruitmentSource
    WHERE (@FromDate IS NULL OR stg.ApplicationDate >= @FromDate)
      AND NOT EXISTS (
            SELECT 1 FROM dbo.FactRecruitment fr
            WHERE fr.VacancyID = stg.VacancyID AND fr.ApplicantID = stg.ApplicantID
      );

    PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' FactRecruitment rows inserted';
END;
GO

PRINT 'Created procedure: dbo.sp_LoadFactRecruitment';
GO
