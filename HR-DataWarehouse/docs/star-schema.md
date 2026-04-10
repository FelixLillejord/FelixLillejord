# HR Data Warehouse — Star Schema

## Phase 1: 2 Fact Tables, 6 Dimensions

```
                          ┌─────────────────────┐
                          │      DimDate         │
                          │─────────────────────│
                          │ DateKey (PK)         │
                          │ FullDate             │
                          │ DayName              │
                          │ MonthNumber          │
                          │ MonthName            │
                          │ Quarter              │
                          │ Year                 │
                          │ FiscalYear           │
                          │ FiscalQuarter        │
                          │ IsWeekend            │
                          └──────────┬──────────┘
                                     │ DateKey
                      ┌──────────────┼──────────────────┐
                      │              │                  │
               DateKey│         DateKey│     ApplicationDateKey│
                      │              │                  │
┌─────────────────────┴──┐    ┌──────┴──────────────────┴──────────────┐
│   FactHeadcount         │    │           FactRecruitment               │
│─────────────────────────│    │────────────────────────────────────────│
│ HeadcountKey (PK)       │    │ RecruitmentKey (PK)                    │
│ DateKey (FK)            │    │ ApplicationDateKey (FK → DimDate)      │
│ EmployeeKey (FK)        │    │ HireDateKey (FK → DimDate)             │
│ DepartmentKey (FK)      │    │ PostingDateKey (FK → DimDate)          │
│ JobRoleKey (FK)         │    │ EmployeeKey (FK → DimEmployee)         │
│ LocationKey (FK)        │    │ DepartmentKey (FK → DimDepartment)     │
│ TerminationReasonKey(FK)│    │ JobRoleKey (FK → DimJobRole)           │
│─────────────────────────│    │ RecruitmentSourceKey (FK)              │
│ IsActive         BIT    │    │────────────────────────────────────────│
│ IsNewHire        BIT    │    │ ApplicationStage  NVARCHAR             │
│ IsTerminated     BIT    │    │ IsHired           BIT                  │
│ FTEValue         DEC    │    │ IsOfferMade       BIT                  │
│ TenureDays       INT    │    │ TimeToFillDays    INT                  │
└─────────────────────────┘    │ TimeToHireDays    INT                  │
      │    │    │    │ │       └────────────────────────────────────────┘
      │    │    │    │ │                │         │            │
      │    │    │    │ │                │         │            │
      │    │  Dept   │ │            Dept│      JobRole│     Source│
      │    │    │    │ │                │         │            │
      │  Job    │  Loc│TermReason       │         │            │
      │    │    │    │ │                │         │            │
      ▼    ▼    ▼    ▼ ▼                ▼         ▼            ▼
```

---

## Dimension Detail

```
┌──────────────────────────┐   ┌──────────────────────────┐
│      DimEmployee          │   │     DimDepartment         │
│──────────────────────────│   │──────────────────────────│
│ EmployeeKey (PK)          │   │ DepartmentKey (PK)        │
│ EmployeeID                │   │ OrgUnitCode               │
│ FirstName                 │   │ DepartmentName            │
│ LastName                  │   │ DivisionName              │
│ Gender                    │   │ BusinessUnitName          │
│ DateOfBirth               │   │ TeamName                  │
│ HireDate                  │   │ CostCentre                │
│ EmploymentType            │   │ HierarchyLevel            │
│ FTEPercentage             │   │ IsActive                  │
│ DepartmentKey (FK)        │   └──────────────────────────┘
│ JobRoleKey (FK)           │
│ LocationKey (FK)          │   ┌──────────────────────────┐
│ ManagerEmployeeID         │   │       DimJobRole          │
│ EffectiveFrom  ◄─ SCD2   │   │──────────────────────────│
│ EffectiveTo    ◄─ SCD2   │   │ JobRoleKey (PK)           │
│ IsCurrent      ◄─ SCD2   │   │ JobCode                   │
└──────────────────────────┘   │ JobTitle                  │
                                │ JobFamily                 │
                                │ JobSubFamily              │
┌──────────────────────────┐   │ JobLevel                  │
│      DimLocation          │   │ PayGrade                  │
│──────────────────────────│   │ IsManagerRole             │
│ LocationKey (PK)          │   └──────────────────────────┘
│ LocationCode              │
│ LocationName              │   ┌──────────────────────────┐
│ City                      │   │  DimTerminationReason     │
│ Region                    │   │──────────────────────────│
│ Country                   │   │ TerminationReasonKey (PK) │
│ CountryCode               │   │ TerminationReasonCode     │
│ IsRemote                  │   │ TerminationReason         │
└──────────────────────────┘   │ TerminationCategory       │
                                │ IsVoluntary               │
┌──────────────────────────┐   └──────────────────────────┘
│   DimRecruitmentSource    │
│──────────────────────────│
│ RecruitmentSourceKey (PK) │
│ SourceName                │
│ SourceCategory            │
│ IsInternalSource          │
└──────────────────────────┘
```

---

## Relationship Map

```
FactHeadcount
├── DateKey                  ──────────► DimDate.DateKey              (active)
├── EmployeeKey              ──────────► DimEmployee.EmployeeKey       (active)
├── DepartmentKey            ──────────► DimDepartment.DepartmentKey   (active)
├── JobRoleKey               ──────────► DimJobRole.JobRoleKey         (active)
├── LocationKey              ──────────► DimLocation.LocationKey        (active)
└── TerminationReasonKey     ──────────► DimTerminationReason.Key      (INACTIVE*)

FactRecruitment
├── ApplicationDateKey       ──────────► DimDate.DateKey              (active)
├── HireDateKey              ──────────► DimDate.DateKey              (inactive**)
├── PostingDateKey           ──────────► DimDate.DateKey              (inactive**)
├── EmployeeKey              ──────────► DimEmployee.EmployeeKey       (active)
├── DepartmentKey            ──────────► DimDepartment.DepartmentKey   (active)
├── JobRoleKey               ──────────► DimJobRole.JobRoleKey         (active)
└── RecruitmentSourceKey     ──────────► DimRecruitmentSource.Key      (active)
```

**\* TerminationReasonKey is inactive** — most rows have NULL (active employees).
Use `USERELATIONSHIP()` in DAX to activate it for turnover measures.

**\*\* Multiple date FKs** in FactRecruitment — only `ApplicationDateKey` is the active
relationship. Use `USERELATIONSHIP()` in DAX to slice by HireDate or PostingDate.

---

## FactHeadcount Flag Logic

| Scenario | IsActive | IsNewHire | IsTerminatedThisMonth | TerminationReasonKey |
|---|---|---|---|---|
| Continuing employee, active at month-end | 1 | 0 | 0 | NULL |
| New hire, still active at month-end | 1 | 1 | 0 | NULL |
| Existing employee, terminated this month | 0 | 0 | 1 | populated |
| New hire who left same month (rare) | 0 | 1 | 1 | populated |

---

## DimEmployee — SCD Type 2

```
EmployeeID: E001

EmployeeKey │ EmployeeID │ DepartmentKey │ EffectiveFrom │ EffectiveTo │ IsCurrent
────────────┼────────────┼───────────────┼───────────────┼─────────────┼──────────
    1       │   E001     │      5        │  2021-03-01   │ 2023-06-30  │    0
    2       │   E001     │      5        │  2023-07-01   │ 2024-11-30  │    0
    3       │   E001     │      8        │  2024-12-01   │ 9999-12-31  │    1
                                                   ▲
                                           Transfer to new dept
                                           → new row created,
                                             old row closed
```
