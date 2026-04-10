# DAX Measures Library — SSAS Tabular / Power BI

All measures are written in DAX and can be used in both the SSAS Tabular model
and directly in Power BI Desktop.

---

## Headcount & Workforce

```dax
-- Active headcount at selected date/period
Active Headcount =
CALCULATE(
    COUNTROWS(FactHeadcount),
    FactHeadcount[IsActive] = TRUE
)

-- FTE total (sum of FTE values for active employees)
FTE Total =
CALCULATE(
    SUM(FactHeadcount[FTEValue]),
    FactHeadcount[IsActive] = TRUE
)

-- New hires in selected period
New Hires =
CALCULATE(
    COUNTROWS(FactHeadcount),
    FactHeadcount[IsNewHire] = TRUE
)

-- Average FTE % across active employees
Avg FTE % =
DIVIDE(
    [FTE Total],
    [Active Headcount],
    0
) * 100

-- Headcount at period start (for turnover rate denominator)
Opening Headcount =
CALCULATE(
    [Active Headcount],
    DATEADD(DimDate[FullDate], -1, MONTH)
)
```

---

## Turnover & Retention

All turnover measures use `FactHeadcount` with the `IsTerminatedThisMonth` flag.
The `TerminationReasonKey` relationship is inactive — activate it with `USERELATIONSHIP()`.

```dax
-- Total terminations in period
Terminations =
CALCULATE(
    COUNTROWS(FactHeadcount),
    FactHeadcount[IsTerminatedThisMonth] = TRUE
)

-- Voluntary terminations (uses inactive relationship to DimTerminationReason)
Voluntary Terminations =
CALCULATE(
    COUNTROWS(FactHeadcount),
    FactHeadcount[IsTerminatedThisMonth] = TRUE,
    USERELATIONSHIP(FactHeadcount[TerminationReasonKey], DimTerminationReason[TerminationReasonKey]),
    DimTerminationReason[IsVoluntary] = TRUE
)

-- Involuntary terminations
Involuntary Terminations =
CALCULATE(
    COUNTROWS(FactHeadcount),
    FactHeadcount[IsTerminatedThisMonth] = TRUE,
    USERELATIONSHIP(FactHeadcount[TerminationReasonKey], DimTerminationReason[TerminationReasonKey]),
    DimTerminationReason[IsVoluntary] = FALSE
)

-- Overall turnover rate (terminations / avg headcount)
Turnover Rate % =
DIVIDE(
    [Terminations],
    DIVIDE([Opening Headcount] + [Active Headcount], 2),
    0
) * 100

-- Voluntary turnover rate
Voluntary Turnover Rate % =
DIVIDE(
    [Voluntary Terminations],
    DIVIDE([Opening Headcount] + [Active Headcount], 2),
    0
) * 100

-- Average tenure at termination (days)
Avg Tenure at Termination (Days) =
CALCULATE(
    AVERAGE(FactHeadcount[TenureDays]),
    FactHeadcount[IsTerminatedThisMonth] = TRUE
)

-- Average tenure at termination (years)
Avg Tenure at Termination (Years) =
DIVIDE([Avg Tenure at Termination (Days)], 365.25, 0)

-- Retention rate
Retention Rate % =
1 - [Voluntary Turnover Rate %] / 100
```

---

## Talent Acquisition

```dax
-- Total applications received
Total Applications =
COUNTROWS(FactRecruitment)

-- Total hires
Total Hires =
CALCULATE(
    COUNTROWS(FactRecruitment),
    FactRecruitment[IsHired] = TRUE
)

-- Offers made
Offers Made =
CALCULATE(
    COUNTROWS(FactRecruitment),
    FactRecruitment[IsOfferMade] = TRUE
)

-- Offer acceptance rate
Offer Acceptance Rate % =
DIVIDE(
    [Total Hires],
    [Offers Made],
    0
) * 100

-- Conversion rate: Applications → Hired
Application to Hire Rate % =
DIVIDE(
    [Total Hires],
    [Total Applications],
    0
) * 100

-- Average time to fill (posting → hire)
Avg Time to Fill (Days) =
CALCULATE(
    AVERAGEX(
        FILTER(FactRecruitment, FactRecruitment[TimeToFillDays] > 0),
        FactRecruitment[TimeToFillDays]
    )
)

-- Average time to hire (application → offer accept)
Avg Time to Hire (Days) =
CALCULATE(
    AVERAGEX(
        FILTER(FactRecruitment, FactRecruitment[TimeToHireDays] > 0),
        FactRecruitment[TimeToHireDays]
    )
)

-- Internal hire rate
Internal Hire Rate % =
DIVIDE(
    CALCULATE(
        [Total Hires],
        DimRecruitmentSource[IsInternalSource] = TRUE
    ),
    [Total Hires],
    0
) * 100

-- Open vacancies (applied or interviewed, not yet closed)
Open Vacancies =
CALCULATE(
    DISTINCTCOUNT(FactRecruitment[VacancyID]),
    FactRecruitment[ApplicationStage] IN {"Applied", "Screened", "Interviewed"}
)
```

---

## Period Comparison (Time Intelligence)

```dax
-- Headcount same period last year
Active Headcount LY =
CALCULATE(
    [Active Headcount],
    SAMEPERIODLASTYEAR(DimDate[FullDate])
)

-- YoY headcount change
Headcount YoY Change =
[Active Headcount] - [Active Headcount LY]

-- YoY headcount change %
Headcount YoY Change % =
DIVIDE(
    [Headcount YoY Change],
    [Active Headcount LY],
    0
) * 100

-- YTD turnover rate
Turnover Rate YTD % =
CALCULATE(
    [Turnover Rate %],
    DATESYTD(DimDate[FullDate])
)
```

---

## Diversity & Inclusion (Phase 2)

```dax
-- Gender split %
Female % =
DIVIDE(
    CALCULATE([Active Headcount], DimEmployee[Gender] = "F"),
    [Active Headcount],
    0
) * 100

-- Manager gender split
Female Managers % =
DIVIDE(
    CALCULATE(
        [Active Headcount],
        DimEmployee[Gender] = "F",
        DimJobRole[IsManagerRole] = TRUE
    ),
    CALCULATE(
        [Active Headcount],
        DimJobRole[IsManagerRole] = TRUE
    ),
    0
) * 100
```
