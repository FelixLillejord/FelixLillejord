# Power BI DAX Measures

Power BI-specific measures and patterns. These complement the SSAS measures
and are for use when connecting Power BI directly to HRDB_DW (without SSAS).

---

## Connection Setup (Direct to SQL Server)

If connecting Power BI directly to `HRDB_DW` (no SSAS):

1. **Get Data → SQL Server**
2. Import all `Dim*` and `Fact*` tables
3. In Model view: create relationships (same as SSAS diagram)
4. Add all measures below to a dedicated **Measures** table

---

## Core Measures

```dax
-- Table: [Measures] (blank table used as a measure container)

Active Headcount =
CALCULATE(
    COUNTROWS(FactHeadcount),
    FactHeadcount[IsActive] = 1
)

FTE Total =
CALCULATE(
    SUM(FactHeadcount[FTEValue]),
    FactHeadcount[IsActive] = 1
)

New Hires =
CALCULATE(COUNTROWS(FactHeadcount), FactHeadcount[IsNewHire] = 1)

Terminations = COUNTROWS(FactTurnover)

Voluntary Terminations =
CALCULATE(COUNTROWS(FactTurnover), FactTurnover[IsVoluntary] = 1)

Turnover Rate % =
VAR AvgHeadcount =
    DIVIDE(
        CALCULATE([Active Headcount], DATEADD(DimDate[FullDate], -1, MONTH))
            + [Active Headcount],
        2
    )
RETURN DIVIDE([Terminations], AvgHeadcount, 0) * 100

Voluntary Turnover Rate % =
VAR AvgHeadcount =
    DIVIDE(
        CALCULATE([Active Headcount], DATEADD(DimDate[FullDate], -1, MONTH))
            + [Active Headcount],
        2
    )
RETURN DIVIDE([Voluntary Terminations], AvgHeadcount, 0) * 100

Total Applications = COUNTROWS(FactRecruitment)

Total Hires =
CALCULATE(COUNTROWS(FactRecruitment), FactRecruitment[IsHired] = 1)

Offer Acceptance Rate % =
DIVIDE(
    [Total Hires],
    CALCULATE(COUNTROWS(FactRecruitment), FactRecruitment[IsOfferMade] = 1),
    0
) * 100

Avg Time to Fill (Days) =
AVERAGEX(
    FILTER(FactRecruitment, FactRecruitment[TimeToFillDays] > 0),
    FactRecruitment[TimeToFillDays]
)

Avg Time to Hire (Days) =
AVERAGEX(
    FILTER(FactRecruitment, FactRecruitment[TimeToHireDays] > 0),
    FactRecruitment[TimeToHireDays]
)
```

---

## Dynamic Titles (for slicer-driven page titles)

```dax
Selected Department Label =
IF(
    ISFILTERED(DimDepartment[DepartmentName]),
    SELECTEDVALUE(DimDepartment[DepartmentName], "Multiple Departments"),
    "All Departments"
)

Selected Period Label =
VAR MinDate = MIN(DimDate[MonthYearLabel])
VAR MaxDate = MAX(DimDate[MonthYearLabel])
RETURN
    IF(MinDate = MaxDate, MinDate, MinDate & " – " & MaxDate)
```

---

## Conditional Formatting Rules

Apply these as Conditional Formatting → Rules on KPI cards:

```
Turnover Rate %:
  < 10%   → Green
  10–15%  → Amber
  > 15%   → Red

Avg Time to Fill:
  < 30 days  → Green
  30–45 days → Amber
  > 45 days  → Red

Offer Acceptance Rate %:
  > 85%   → Green
  75–85%  → Amber
  < 75%   → Red
```

---

## Bookmarks & Navigation

Suggested bookmarks for exec navigation:
- `Overview_Default` — reset all slicers, show current month
- `YTD_View` — filter to YTD on all pages
- `PriorYear_Compare` — show current + prior year on trend charts

Use **Page Navigation buttons** with bookmarks for a guided executive experience.
