# HR Data Warehouse

A production-ready HR Data Warehouse built on SQL Server, SSIS, and SSAS Tabular — designed to power executive Power BI dashboards and elevate HR Business Partners to a strategic function.

## Stack

| Layer | Technology |
|---|---|
| Source | Agresso Unit4 (flat file / SQL exports) |
| ETL | SSIS (Visual Studio) |
| Data Warehouse | SQL Server (star schema) |
| Semantic Layer | SSAS Tabular (Visual Studio) |
| Reporting | Power BI |
| Ad-hoc | Excel (SSAS connection) |

## Architecture Overview

```
Agresso Unit4
     │
     ▼
[SSIS ETL]
     │
     ▼
HRDB_Staging          ← Raw landing zone (STG_* tables)
     │
     ▼
HRDB_DW               ← Star schema (Dim* + Fact* tables)
     │
     ▼
SSAS Tabular Model    ← Measures, KPIs, hierarchies
     │
     ▼
Power BI / Excel      ← Dashboards & self-service analytics
```

## Phase 1 Scope

- **Headcount & Workforce** — Active employees, FTEs, org structure, new hires, turnover
- **Talent Acquisition** — Recruiting funnel, time-to-fill, time-to-hire, source of hire

## Folder Structure

```
HR-DataWarehouse/
├── docs/                         # Architecture, data dictionary, ETL design
├── database/
│   ├── 00_create_databases.sql   # Create HRDB_Staging + HRDB_DW
│   ├── staging/                  # STG_* tables (raw Agresso data)
│   ├── dimensions/               # Dim* tables (star schema dimensions)
│   ├── facts/                    # Fact* tables (star schema facts)
│   └── stored_procedures/        # ETL load procedures
├── ssas/                         # Tabular model design + DAX measures
└── powerbi/                      # Dashboard design + Power BI DAX
```

## Build Order

1. Run `database/00_create_databases.sql`
2. Run all scripts in `database/staging/`
3. Run all scripts in `database/dimensions/`
4. Run all scripts in `database/facts/`
5. Run all scripts in `database/stored_procedures/`
6. Deploy SSIS packages (see `docs/etl-design.md`)
7. Deploy SSAS Tabular model (see `ssas/tabular-model-design.md`)
8. Build Power BI reports (see `powerbi/dashboard-design.md`)

## Key KPIs

- Active Headcount & FTE
- Turnover Rate (Voluntary / Involuntary)
- Time to Fill & Time to Hire
- Offer Acceptance Rate
- New Hire Rate
- Headcount by Department / Location / Job Level
