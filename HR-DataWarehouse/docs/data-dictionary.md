# HR Data Warehouse — Data Dictionary

## Conventions

| Convention | Description |
|---|---|
| `*Key` suffix | Surrogate key (INT IDENTITY) |
| `*ID` suffix | Natural key from source system (Agresso) |
| `ETLLoadDate` | Timestamp when the row was loaded by SSIS |
| `IsCurrent` | SCD Type 2 flag — 1 = current record, 0 = historical |
| `EffectiveFrom/To` | SCD Type 2 validity date range |

---

## STAGING TABLES

### STG_Employee
Raw employee master from Agresso Unit4 HR module.

| Column | Type | Description |
|---|---|---|
| STGEmployeeID | NVARCHAR(20) | Agresso employee number |
| FirstName | NVARCHAR(100) | First name |
| LastName | NVARCHAR(100) | Last name |
| Gender | NVARCHAR(10) | M / F / Other |
| DateOfBirth | DATE | Date of birth |
| NationalID | NVARCHAR(20) | National ID (masked for GDPR) |
| HireDate | DATE | Contract start date |
| TerminationDate | DATE | Contract end date (NULL if active) |
| OrgUnitCode | NVARCHAR(20) | Agresso department code |
| JobCode | NVARCHAR(20) | Agresso job code |
| PositionCode | NVARCHAR(20) | Agresso position code |
| LocationCode | NVARCHAR(20) | Agresso location/site code |
| EmploymentType | NVARCHAR(50) | Full-time, Part-time, Temp |
| FTEPercentage | DECIMAL(5,2) | FTE % (e.g. 100.00, 60.00) |
| ManagerEmployeeID | NVARCHAR(20) | Direct manager's employee number |
| STGLoadDate | DATETIME | ETL load timestamp |
| STGSourceFile | NVARCHAR(255) | Source CSV filename |

### STG_JobHistory
Job change events from Agresso — used to track role, department, and position changes.

| Column | Type | Description |
|---|---|---|
| STGEmployeeID | NVARCHAR(20) | Agresso employee number |
| EffectiveDate | DATE | Date the change took effect |
| OrgUnitCode | NVARCHAR(20) | New department code |
| JobCode | NVARCHAR(20) | New job code |
| PositionCode | NVARCHAR(20) | New position code |
| ChangeReason | NVARCHAR(100) | Reason for change (promotion, transfer, etc.) |
| STGLoadDate | DATETIME | ETL load timestamp |

### STG_OrgUnit
Organisational unit hierarchy from Agresso.

| Column | Type | Description |
|---|---|---|
| OrgUnitCode | NVARCHAR(20) | Agresso org unit code (PK) |
| OrgUnitName | NVARCHAR(200) | Display name |
| ParentOrgUnitCode | NVARCHAR(20) | Parent unit code (NULL = top level) |
| OrgLevel | INT | Hierarchy depth (1 = Division, 2 = Dept, 3 = Team) |
| CostCentre | NVARCHAR(20) | Associated cost centre |
| STGLoadDate | DATETIME | ETL load timestamp |

### STG_Recruitment
Vacancy and applicant data from Agresso recruitment module.

| Column | Type | Description |
|---|---|---|
| VacancyID | NVARCHAR(20) | Unique vacancy identifier |
| ApplicantID | NVARCHAR(20) | Unique applicant identifier |
| OrgUnitCode | NVARCHAR(20) | Hiring department |
| JobCode | NVARCHAR(20) | Job applied for |
| PostingDate | DATE | Vacancy advertised date |
| ApplicationDate | DATE | Application received date |
| ApplicationStage | NVARCHAR(50) | Applied/Screened/Interviewed/Offered/Hired/Rejected |
| RecruitmentSource | NVARCHAR(100) | Source (LinkedIn, Internal, Referral, etc.) |
| OfferDate | DATE | Date offer was made |
| OfferAcceptDate | DATE | Date offer was accepted (NULL if rejected) |
| HireDate | DATE | Start date (NULL if not hired) |
| HiredEmployeeID | NVARCHAR(20) | Links to STG_Employee if hired |
| STGLoadDate | DATETIME | ETL load timestamp |

---

## DIMENSION TABLES

### DimDate
Pre-generated date spine covering 2015–2035.

| Column | Type | Description |
|---|---|---|
| DateKey | INT | YYYYMMDD format (PK) |
| FullDate | DATE | Actual date |
| DayOfWeek | INT | 1=Monday … 7=Sunday |
| DayName | NVARCHAR(20) | Monday, Tuesday, etc. |
| DayOfMonth | INT | 1–31 |
| DayOfYear | INT | 1–366 |
| WeekOfYear | INT | ISO week number |
| MonthNumber | INT | 1–12 |
| MonthName | NVARCHAR(20) | January, February, etc. |
| MonthShort | NVARCHAR(3) | Jan, Feb, etc. |
| Quarter | INT | 1–4 |
| QuarterName | NVARCHAR(6) | Q1–Q4 |
| Year | INT | Calendar year |
| IsWeekend | BIT | 1 = Saturday/Sunday |
| IsHoliday | BIT | 1 = Public holiday |
| FiscalYear | INT | Fiscal year (configurable offset) |
| FiscalQuarter | INT | Fiscal quarter 1–4 |
| FiscalMonth | INT | Fiscal month 1–12 |
| MonthYearLabel | NVARCHAR(20) | e.g. "Jan 2024" |
| FiscalYearLabel | NVARCHAR(10) | e.g. "FY2024" |

### DimEmployee (SCD Type 2)
One row per employee version. New row created on any change.

| Column | Type | Description |
|---|---|---|
| EmployeeKey | INT | Surrogate key (PK) |
| EmployeeID | NVARCHAR(20) | Agresso natural key |
| FirstName | NVARCHAR(100) | First name |
| LastName | NVARCHAR(100) | Last name |
| FullName | NVARCHAR(200) | Computed: FirstName + ' ' + LastName |
| Gender | NVARCHAR(20) | M / F / Other / Not Specified |
| DateOfBirth | DATE | Date of birth |
| HireDate | DATE | Original hire date |
| DepartmentKey | INT | FK → DimDepartment |
| JobRoleKey | INT | FK → DimJobRole |
| LocationKey | INT | FK → DimLocation |
| ManagerEmployeeID | NVARCHAR(20) | Direct manager's EmployeeID |
| EmploymentType | NVARCHAR(50) | Full-time, Part-time, Temp, Contractor |
| FTEPercentage | DECIMAL(5,2) | FTE fraction (100.00 = 1 FTE) |
| EffectiveFrom | DATE | Version valid from |
| EffectiveTo | DATE | Version valid to (9999-12-31 = current) |
| IsCurrent | BIT | 1 = most recent active record |
| ETLLoadDate | DATETIME | Load timestamp |

### DimDepartment
Organisational hierarchy (Division → Department → Team).

| Column | Type | Description |
|---|---|---|
| DepartmentKey | INT | Surrogate key (PK) |
| OrgUnitCode | NVARCHAR(20) | Agresso org unit code |
| DepartmentName | NVARCHAR(200) | Department name |
| DivisionName | NVARCHAR(200) | Parent division |
| TeamName | NVARCHAR(200) | Sub-team (if applicable) |
| CostCentre | NVARCHAR(20) | Cost centre code |
| HierarchyLevel | INT | 1=Division, 2=Department, 3=Team |
| IsActive | BIT | 1 = active org unit |
| ETLLoadDate | DATETIME | Load timestamp |

### DimJobRole
Job catalogue — job families, levels, and grades.

| Column | Type | Description |
|---|---|---|
| JobRoleKey | INT | Surrogate key (PK) |
| JobCode | NVARCHAR(20) | Agresso job code |
| JobTitle | NVARCHAR(200) | Job title |
| JobFamily | NVARCHAR(100) | Job family (HR, Finance, IT, Operations, etc.) |
| JobLevel | NVARCHAR(50) | Junior, Mid, Senior, Lead, Manager, Director |
| PayGrade | NVARCHAR(20) | Pay grade / band |
| IsManagerRole | BIT | 1 = people manager role |
| ETLLoadDate | DATETIME | Load timestamp |

### DimLocation
Work location hierarchy.

| Column | Type | Description |
|---|---|---|
| LocationKey | INT | Surrogate key (PK) |
| LocationCode | NVARCHAR(20) | Agresso location code |
| LocationName | NVARCHAR(200) | Site name |
| City | NVARCHAR(100) | City |
| Region | NVARCHAR(100) | Region / county |
| Country | NVARCHAR(100) | Country |
| IsRemote | BIT | 1 = remote/home office location |
| ETLLoadDate | DATETIME | Load timestamp |

### DimTerminationReason
Why employees leave — used in FactTurnover.

| Column | Type | Description |
|---|---|---|
| TerminationReasonKey | INT | Surrogate key (PK) |
| TerminationReasonCode | NVARCHAR(20) | Code from Agresso |
| TerminationReason | NVARCHAR(200) | Reason description |
| TerminationCategory | NVARCHAR(50) | Voluntary / Involuntary / Retirement / Other |
| IsVoluntary | BIT | 1 = employee-initiated |
| ETLLoadDate | DATETIME | Load timestamp |

### DimRecruitmentSource
How candidates found the organisation.

| Column | Type | Description |
|---|---|---|
| RecruitmentSourceKey | INT | Surrogate key (PK) |
| SourceName | NVARCHAR(100) | e.g. LinkedIn, Internal, Referral |
| SourceCategory | NVARCHAR(50) | Digital, Internal, Agency, Direct |
| ETLLoadDate | DATETIME | Load timestamp |

---

## FACT TABLES

### FactHeadcount
Monthly snapshot of the active workforce. One row per employee per month-end.

| Column | Type | Description |
|---|---|---|
| HeadcountKey | INT | Surrogate key (PK) |
| DateKey | INT | FK → DimDate (month-end date) |
| EmployeeKey | INT | FK → DimEmployee |
| DepartmentKey | INT | FK → DimDepartment |
| JobRoleKey | INT | FK → DimJobRole |
| LocationKey | INT | FK → DimLocation |
| IsActive | BIT | 1 = active at month-end |
| FTEValue | DECIMAL(5,2) | FTE contribution (0.00–1.00) |
| IsNewHire | BIT | 1 = hired within this snapshot month |
| ETLLoadDate | DATETIME | Load timestamp |

### FactTurnover
One row per termination event.

| Column | Type | Description |
|---|---|---|
| TurnoverKey | INT | Surrogate key (PK) |
| TerminationDateKey | INT | FK → DimDate |
| HireDateKey | INT | FK → DimDate (original hire date) |
| EmployeeKey | INT | FK → DimEmployee (current version at termination) |
| DepartmentKey | INT | FK → DimDepartment (at time of termination) |
| JobRoleKey | INT | FK → DimJobRole (at time of termination) |
| LocationKey | INT | FK → DimLocation |
| TerminationReasonKey | INT | FK → DimTerminationReason |
| IsVoluntary | BIT | 1 = voluntary resignation |
| TenureDays | INT | Days from HireDate to TerminationDate |
| ETLLoadDate | DATETIME | Load timestamp |

### FactRecruitment
One row per application. Stage updated as applicant progresses.

| Column | Type | Description |
|---|---|---|
| RecruitmentKey | INT | Surrogate key (PK) |
| ApplicationDateKey | INT | FK → DimDate |
| HireDateKey | INT | FK → DimDate (NULL if not hired) |
| EmployeeKey | INT | FK → DimEmployee (NULL until hired) |
| DepartmentKey | INT | FK → DimDepartment (hiring dept) |
| JobRoleKey | INT | FK → DimJobRole |
| RecruitmentSourceKey | INT | FK → DimRecruitmentSource |
| ApplicationStage | NVARCHAR(50) | Current stage in funnel |
| IsHired | BIT | 1 = applicant became an employee |
| TimeToFillDays | INT | PostingDate → HireDate |
| TimeToHireDays | INT | ApplicationDate → OfferAcceptDate |
| ETLLoadDate | DATETIME | Load timestamp |
