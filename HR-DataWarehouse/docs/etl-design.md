# HR Data Warehouse — ETL Design (SSIS)

## Overview

The ETL pipeline uses SQL Server Integration Services (SSIS) packages deployed from
Visual Studio. A master orchestrator package calls child packages in sequence.

---

## Solution Structure

```
HRDB_ETL.sln                      Visual Studio SSIS project
├── Connection Managers
│   ├── HRDB_Staging.conmgr       SQL Server - staging database
│   ├── HRDB_DW.conmgr            SQL Server - DW database
│   └── Agresso_Export.conmgr     Flat file folder path (parameterised)
├── Parameters
│   └── Project.params            ExportFolderPath, LoadDate, RunMode
└── SSIS Packages
    ├── 00_Master.dtsx
    ├── 01_Extract_Agresso.dtsx
    ├── 02_Load_Dimensions.dtsx
    ├── 03_Load_Facts.dtsx
    └── 04_SSAS_Process.dtsx
```

---

## Package Designs

### 00_Master.dtsx — Orchestrator

**Purpose**: Execute all packages in order, handle errors, log start/end.

**Control Flow**:
```
[Execute SQL: Log ETL Start]
        ↓
[Execute Package Task: 01_Extract_Agresso]
        ↓
[Execute Package Task: 02_Load_Dimensions]
        ↓
[Execute Package Task: 03_Load_Facts]
        ↓
[Execute Package Task: 04_SSAS_Process]
        ↓
[Execute SQL: Log ETL End]
```

**On Failure**: Send email notification via SMTP connection manager.

---

### 01_Extract_Agresso.dtsx — Extract

**Purpose**: Read CSV exports from the Agresso network share and bulk-insert into staging tables.

**Control Flow (run in parallel)**:
```
[Data Flow: Load STG_Employee]
[Data Flow: Load STG_JobHistory]
[Data Flow: Load STG_OrgUnit]
[Data Flow: Load STG_Recruitment]
```

**Each Data Flow**:
```
[Flat File Source]
    ↓
[Derived Column: Add STGLoadDate = GETDATE(), STGSourceFile = @FileName]
    ↓
[Execute SQL: TRUNCATE staging table]   ← Full refresh approach
    ↓
[OLE DB Destination: STG_* table]
```

**Agresso Export Files Expected**:
| File | Staging Table | Delimiter |
|---|---|---|
| `HR_Employees_YYYYMMDD.csv` | STG_Employee | Semicolon |
| `HR_JobHistory_YYYYMMDD.csv` | STG_JobHistory | Semicolon |
| `HR_OrgUnits_YYYYMMDD.csv` | STG_OrgUnit | Semicolon |
| `HR_Recruitment_YYYYMMDD.csv` | STG_Recruitment | Semicolon |

**Notes**:
- Use a `Foreach Loop Container` with file enumerator to pick the latest file
- Store file path in `@FileName` variable for audit trail
- Set `AlwaysCheckForRowErrors = True` on Flat File Source

---

### 02_Load_Dimensions.dtsx — Transform & Load Dimensions

**Purpose**: Transform staging data and load/update dimension tables.

**Control Flow (sequential — dims depend on each other)**:
```
[Execute SQL: sp_LoadDimLocation]
    ↓
[Execute SQL: sp_LoadDimJobRole]
    ↓
[Execute SQL: sp_LoadDimDepartment]
    ↓
[Execute SQL: sp_LoadDimEmployee]         ← SCD Type 2 — depends on Dept/Job/Location keys
    ↓
[Execute SQL: sp_LoadDimTerminationReason]
    ↓
[Execute SQL: sp_LoadDimRecruitmentSource]
```

**SCD Type 2 Logic for DimEmployee** (handled in `sp_LoadDimEmployee`):
1. For each row in `STG_Employee`:
   - Look up current DimEmployee record by `EmployeeID` where `IsCurrent = 1`
   - If no match → INSERT new row
   - If match and key attributes changed → UPDATE `EffectiveTo = GETDATE()-1`, `IsCurrent = 0` on old row; INSERT new row
   - If match and no changes → do nothing (UPDATE `ETLLoadDate` only)

**Key attributes that trigger a Type 2 change**:
- `DepartmentKey`
- `JobRoleKey`
- `LocationKey`
- `EmploymentType`
- `FTEPercentage`

---

### 03_Load_Facts.dtsx — Load Facts

**Purpose**: Load fact tables using staging data + resolved dimension keys.

**Control Flow**:
```
[Execute SQL: sp_LoadFactHeadcount]
    ↓
[Execute SQL: sp_LoadFactTurnover]
    ↓
[Execute SQL: sp_LoadFactRecruitment]
```

**FactHeadcount load approach**:
- Run at month-end (or parameterised by `@SnapshotDate`)
- Check if snapshot already exists for the given `DateKey` → skip if so
- INSERT one row per active employee at the snapshot date

**FactTurnover load approach**:
- Incremental: only load terminations with `TerminationDate >= @LastRunDate`
- Resolve `TerminationReasonKey` via lookup on Agresso reason code

**FactRecruitment load approach**:
- Incremental: load new/updated application records since `@LastRunDate`
- Calculate `TimeToFillDays` and `TimeToHireDays` at insert time

---

### 04_SSAS_Process.dtsx — SSAS Refresh

**Purpose**: Trigger a full or incremental process of the SSAS Tabular model.

**Control Flow**:
```
[Analysis Services Processing Task]
    Processing type: Process Default
    Object: HR_DW (SSAS database)
```

**Configuration**:
- SSAS server connection stored in connection manager
- Run `Process Default` — SSAS decides full vs. incremental
- On large fact tables, consider `Process Add` for incremental load

---

## ETL Scheduling

Recommended SQL Server Agent job schedule:

| Job | Schedule | Description |
|---|---|---|
| `HRDB_Daily_Load` | Mon–Fri 06:00 | Runs 00_Master — extracts previous day's Agresso export |
| `HRDB_Monthly_Headcount` | 1st of month 07:00 | Triggers FactHeadcount snapshot for prior month-end |

---

## Error Handling

- All packages write to an `ETL_Log` table in `HRDB_DW`:

```sql
CREATE TABLE dbo.ETL_Log (
    LogID           INT IDENTITY(1,1) PRIMARY KEY,
    PackageName     NVARCHAR(100),
    StartTime       DATETIME,
    EndTime         DATETIME,
    Status          NVARCHAR(20),  -- 'Success', 'Failed', 'Running'
    RowsExtracted   INT,
    RowsLoaded      INT,
    ErrorMessage    NVARCHAR(MAX)
)
```

- On package failure: `OnError` event handler updates `ETL_Log.Status = 'Failed'`
  and sends an email alert via `Send Mail Task`.

---

## Deployment Notes

1. Build the SSIS project in Visual Studio → generate `.ispac` deployment file
2. Deploy to SSISDB catalogue on SQL Server
3. Create SQL Agent job referencing the deployed package
4. Store connection strings in SSIS Environment Variables (not hardcoded)
5. Use Windows Authentication or a dedicated service account for SQL connections
