# SSAS Tabular Model — Design Guide

## Overview

The SSAS Tabular model (`HR_DW`) is the semantic layer between the SQL Server DW
and the reporting tools (Power BI, Excel). It defines relationships, hierarchies,
KPIs, and row-level security.

---

## Setup in Visual Studio

1. **New Project** → Analysis Services → Analysis Services Tabular Project
2. **Workspace server**: point to your SQL Server instance
3. **Compatibility level**: 1500 (SQL Server 2019+) or 1400 (2017)
4. **Import from data source**: HRDB_DW (SQL Server)
5. **Tables to import**: all `Dim*` and `Fact*` tables

---

## Table Relationships

Define in the Diagram view (Model → Diagram View):

| From Table | Column | To Table | Column | Cardinality |
|---|---|---|---|---|
| FactHeadcount | DateKey | DimDate | DateKey | Many → One |
| FactHeadcount | EmployeeKey | DimEmployee | EmployeeKey | Many → One |
| FactHeadcount | DepartmentKey | DimDepartment | DepartmentKey | Many → One |
| FactHeadcount | JobRoleKey | DimJobRole | JobRoleKey | Many → One |
| FactHeadcount | LocationKey | DimLocation | LocationKey | Many → One |
| FactTurnover | TerminationDateKey | DimDate | DateKey | Many → One |
| FactTurnover | EmployeeKey | DimEmployee | EmployeeKey | Many → One |
| FactTurnover | DepartmentKey | DimDepartment | DepartmentKey | Many → One |
| FactTurnover | TerminationReasonKey | DimTerminationReason | TerminationReasonKey | Many → One |
| FactRecruitment | ApplicationDateKey | DimDate | DateKey | Many → One |
| FactRecruitment | DepartmentKey | DimDepartment | DepartmentKey | Many → One |
| FactRecruitment | JobRoleKey | DimJobRole | JobRoleKey | Many → One |
| FactRecruitment | RecruitmentSourceKey | DimRecruitmentSource | RecruitmentSourceKey | Many → One |

**Note**: FactTurnover and FactRecruitment both use DimDate — create role-playing
date dimensions or use inactive relationships with `USERELATIONSHIP()` in DAX.

---

## Hierarchies

### DimDate — Calendar Hierarchy
```
Year → Quarter → Month → Date
```

### DimDate — Fiscal Hierarchy
```
FiscalYear → FiscalQuarter → FiscalMonth
```

### DimDepartment — Org Hierarchy
```
DivisionName → BusinessUnitName → DepartmentName → TeamName
```

### DimJobRole — Job Hierarchy
```
JobFamily → JobSubFamily → JobLevel → JobTitle
```

### DimLocation — Geography Hierarchy
```
Country → Region → City → LocationName
```

---

## Calculated Columns to Add

### DimEmployee
```dax
-- Age at today
Age = INT((TODAY() - DimEmployee[DateOfBirth]) / 365.25)

-- Tenure in years (for current employees)
TenureYears = IF(
    DimEmployee[IsCurrent] = TRUE,
    INT((TODAY() - DimEmployee[HireDate]) / 365.25),
    BLANK()
)
```

### DimDate
```dax
-- Month-Year sort order (for correct chronological ordering in visuals)
MonthYearSort = DimDate[Year] * 100 + DimDate[MonthNumber]
```

---

## Row-Level Security (RLS)

Create RLS roles to restrict HR Business Partners to their own departments.

**Role: HRBP_Department**
```dax
-- Applied to DimDepartment
[DepartmentName] = LOOKUPVALUE(
    HRBPMapping[DepartmentName],
    HRBPMapping[UserEmail], USERNAME()
)
```

**Role: HR_ReadAll** — no filter (for HR Directors and central HR Analytics)

**Role: Exec_ReadAll** — no filter (for C-suite / executive access)

---

## Deployment

1. Build the project in Visual Studio (Build → Deploy)
2. Target server: `<your-ssas-server>\<instance>`
3. Database name: `HR_DW`
4. After deploy, process the model: right-click database → Process → Process Default
5. In Power BI Desktop: Get Data → Analysis Services → connect to `HR_DW`
6. For Excel: Data → From Analysis Services → enter SSAS server

---

## Processing Strategy

| Object | Process Type | Frequency |
|---|---|---|
| DimDate | Process Full (once) | Only when years added |
| Dim* tables | Process Default | Daily (after SSIS load) |
| Fact* tables | Process Add | Daily (incremental) |
| Full model | Process Full | Weekly (weekend) |
