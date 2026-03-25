-- ============================================================
-- HRDB_DW — DimDate
-- Pre-generated date dimension covering 2015–2035
-- Populate by running sp_LoadDimDate after creating this table
-- ============================================================

USE HRDB_DW;
GO

IF OBJECT_ID('dbo.DimDate', 'U') IS NOT NULL
    DROP TABLE dbo.DimDate;
GO

CREATE TABLE dbo.DimDate (
    DateKey         INT             NOT NULL,   -- YYYYMMDD format (e.g. 20240131)
    FullDate        DATE            NOT NULL,
    DayOfWeek       INT             NOT NULL,   -- 1=Monday … 7=Sunday (ISO)
    DayName         NVARCHAR(20)    NOT NULL,
    DayOfMonth      INT             NOT NULL,
    DayOfYear       INT             NOT NULL,
    WeekOfYear      INT             NOT NULL,   -- ISO week number
    MonthNumber     INT             NOT NULL,
    MonthName       NVARCHAR(20)    NOT NULL,
    MonthShort      NVARCHAR(3)     NOT NULL,   -- Jan, Feb, etc.
    Quarter         INT             NOT NULL,   -- 1–4
    QuarterName     NVARCHAR(6)     NOT NULL,   -- Q1–Q4
    [Year]          INT             NOT NULL,
    IsWeekend       BIT             NOT NULL,
    IsHoliday       BIT             NOT NULL DEFAULT 0,
    -- Fiscal calendar (adjust FiscalYearStartMonth to match your org)
    FiscalYear      INT             NOT NULL,
    FiscalQuarter   INT             NOT NULL,
    FiscalMonth     INT             NOT NULL,
    -- Labels for slicers
    MonthYearLabel  NVARCHAR(20)    NOT NULL,   -- e.g. "Jan 2024"
    FiscalYearLabel NVARCHAR(10)    NOT NULL,   -- e.g. "FY2024"
    CONSTRAINT PK_DimDate PRIMARY KEY (DateKey)
);
GO

-- ============================================================
-- Populate DimDate — 2015-01-01 to 2035-12-31
-- Fiscal year starts in January (FiscalYearStartMonth = 1)
-- Change @FiscalYearStartMonth to e.g. 4 for April start
-- ============================================================
DECLARE @StartDate              DATE = '2015-01-01';
DECLARE @EndDate                DATE = '2035-12-31';
DECLARE @FiscalYearStartMonth   INT  = 1;   -- 1 = calendar year, 4 = April start, etc.
DECLARE @Date                   DATE = @StartDate;

WHILE @Date <= @EndDate
BEGIN
    DECLARE @DateKey        INT  = YEAR(@Date) * 10000 + MONTH(@Date) * 100 + DAY(@Date);
    DECLARE @MonthNum       INT  = MONTH(@Date);
    DECLARE @YearNum        INT  = YEAR(@Date);
    DECLARE @DayOfWeekISO   INT  = (DATEPART(WEEKDAY, @Date) + 5) % 7 + 1; -- ISO: Mon=1

    -- Fiscal year calculation
    DECLARE @FiscalYear     INT;
    DECLARE @FiscalMonth    INT;
    IF @MonthNum >= @FiscalYearStartMonth
    BEGIN
        SET @FiscalYear  = @YearNum + CASE WHEN @FiscalYearStartMonth = 1 THEN 0 ELSE 1 END;
        SET @FiscalMonth = @MonthNum - @FiscalYearStartMonth + 1;
    END
    ELSE
    BEGIN
        SET @FiscalYear  = @YearNum + CASE WHEN @FiscalYearStartMonth = 1 THEN 0 ELSE 0 END;
        SET @FiscalMonth = @MonthNum + (12 - @FiscalYearStartMonth + 1);
    END

    INSERT INTO dbo.DimDate (
        DateKey, FullDate, DayOfWeek, DayName, DayOfMonth, DayOfYear,
        WeekOfYear, MonthNumber, MonthName, MonthShort,
        Quarter, QuarterName, [Year], IsWeekend, IsHoliday,
        FiscalYear, FiscalQuarter, FiscalMonth,
        MonthYearLabel, FiscalYearLabel
    )
    VALUES (
        @DateKey,
        @Date,
        @DayOfWeekISO,
        DATENAME(WEEKDAY, @Date),
        DAY(@Date),
        DATEPART(DAYOFYEAR, @Date),
        DATEPART(ISO_WEEK, @Date),
        @MonthNum,
        DATENAME(MONTH, @Date),
        LEFT(DATENAME(MONTH, @Date), 3),
        DATEPART(QUARTER, @Date),
        'Q' + CAST(DATEPART(QUARTER, @Date) AS NVARCHAR(1)),
        @YearNum,
        CASE WHEN @DayOfWeekISO IN (6, 7) THEN 1 ELSE 0 END,
        0,
        @FiscalYear,
        (@FiscalMonth - 1) / 3 + 1,
        @FiscalMonth,
        LEFT(DATENAME(MONTH, @Date), 3) + ' ' + CAST(@YearNum AS NVARCHAR(4)),
        'FY' + CAST(@FiscalYear AS NVARCHAR(4))
    );

    SET @Date = DATEADD(DAY, 1, @Date);
END
GO

PRINT 'DimDate populated: 2015-01-01 to 2035-12-31';
GO
