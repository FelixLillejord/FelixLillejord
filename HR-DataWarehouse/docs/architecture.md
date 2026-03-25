# HR Data Warehouse — Architecture

## Overview

The HR DW follows a classic **3-layer architecture** with a star schema at the core.

```
┌─────────────────────────────────────────────────────────┐
│                     SOURCE SYSTEMS                       │
│                                                          │
│  Agresso Unit4 ERP (HR Module)                          │
│  ├── Employee Master Data                                │
│  ├── Organisational Structure                            │
│  ├── Job & Position Data                                 │
│  └── Recruitment Data                                    │
└────────────────────────┬────────────────────────────────┘
                         │  Flat file exports (CSV)
                         │  or direct SQL connection
                         ▼
┌─────────────────────────────────────────────────────────┐
│              LAYER 1 — STAGING (HRDB_Staging)            │
│                                                          │
│  STG_Employee         Raw employee records               │
│  STG_JobHistory       Job changes / position history     │
│  STG_OrgUnit          Department / org structure         │
│  STG_Recruitment      Vacancy & applicant data           │
│                                                          │
│  Purpose: Raw landing zone, no transformations           │
│  Load: Full refresh or incremental via ETLLoadDate       │
└────────────────────────┬────────────────────────────────┘
                         │  SSIS Packages
                         ▼
┌─────────────────────────────────────────────────────────┐
│           LAYER 2 — DATA WAREHOUSE (HRDB_DW)             │
│                                                          │
│  DIMENSIONS                  FACTS                       │
│  ├── DimDate                 ├── FactHeadcount            │
│  ├── DimEmployee (SCD2)      ├── FactTurnover             │
│  ├── DimDepartment           └── FactRecruitment          │
│  ├── DimJobRole                                          │
│  ├── DimLocation                                         │
│  ├── DimTerminationReason                                │
│  └── DimRecruitmentSource                               │
│                                                          │
│  Pattern: Star schema, surrogate keys, audit columns     │
└────────────────────────┬────────────────────────────────┘
                         │  SSAS Tabular Model
                         ▼
┌─────────────────────────────────────────────────────────┐
│           LAYER 3 — SEMANTIC (SSAS Tabular)              │
│                                                          │
│  ├── Relationships defined                               │
│  ├── Hierarchies (Org, Date, Job)                        │
│  ├── KPI measures (DAX)                                  │
│  └── Row-level security (by department/region)          │
└────────────────────────┬────────────────────────────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
        Power BI                  Excel
   (Exec dashboards)        (HRBP self-service)
```

---

## Database Design Principles

### Surrogate Keys
All dimension tables use an `INT IDENTITY` surrogate key. Source system natural keys
(e.g. Agresso employee ID) are stored separately for lookup and audit.

### SCD Type 2 — DimEmployee
Employee records that change over time (department transfer, job change, location change)
are tracked using Slowly Changing Dimension Type 2:
- `EffectiveFrom` / `EffectiveTo` — date range the record was valid
- `IsCurrent = 1` — flags the latest active record
- New surrogate key created on each change

This allows facts to always link to the correct employee version at the time of the event.

### Date Dimension
`DimDate` is populated once via `sp_LoadDimDate` covering a 20-year range.
Includes both calendar year and fiscal year attributes (fiscal year configurable).

### Fact Table Grain
| Fact | Grain | Load Frequency |
|---|---|---|
| FactHeadcount | 1 row per employee per month-end snapshot | Monthly |
| FactTurnover | 1 row per termination event | Daily/incremental |
| FactRecruitment | 1 row per application event | Daily/incremental |

---

## SQL Server Databases

| Database | Purpose |
|---|---|
| `HRDB_Staging` | Raw data from Agresso — minimal transformations |
| `HRDB_DW` | Star schema — analytics-ready data |

---

## SSIS ETL Flow

```
00_Master.dtsx
├── 01_Extract_Agresso.dtsx    Bulk insert CSV files → HRDB_Staging
├── 02_Load_Dimensions.dtsx    Staging → Dim tables (with SCD logic)
├── 03_Load_Facts.dtsx         Staging + Dims → Fact tables
└── 04_SSAS_Process.dtsx       Trigger SSAS tabular model refresh
```

See `etl-design.md` for detailed package specifications.

---

## Security Considerations

- SSAS Row-Level Security: restrict HRBP access to their own departments
- SQL Server logins: separate read-only service account for Power BI
- Agresso exports: store in a secured network share; SSIS reads from there
- No PII in SSAS model (employee names only in DimEmployee, not exposed by default)
