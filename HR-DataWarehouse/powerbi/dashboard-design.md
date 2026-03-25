# Power BI Dashboard Design

## Connection

**Get Data → Analysis Services**
- Server: `<your-ssas-server>`
- Database: `HR_DW`
- Mode: **Import** (recommended for performance) or **DirectQuery** (for real-time)

Alternatively connect directly to `HRDB_DW` SQL Server database if not using SSAS.

---

## Report Pages

### Page 1 — Executive Overview
*Audience: C-suite, Executive Leadership*

**Purpose**: Single-page at-a-glance summary of workforce health.

**Visuals**:
| Visual | Measure | Position |
|---|---|---|
| KPI Card | Active Headcount | Top row |
| KPI Card | FTE Total | Top row |
| KPI Card | Turnover Rate % | Top row |
| KPI Card | New Hires (YTD) | Top row |
| KPI Card | Avg Time to Fill | Top row |
| Line Chart | Active Headcount (12-month trend) | Centre left |
| Donut Chart | Headcount by Division | Centre right |
| Column Chart | New Hires vs Terminations (monthly) | Bottom left |
| Table | Top 5 Departments by Headcount | Bottom right |

**Slicers**: Year, Month, Division

---

### Page 2 — Workforce Analytics
*Audience: HR Leadership, HRBPs*

**Purpose**: Detailed breakdown of the workforce by segment.

**Visuals**:
| Visual | Description |
|---|---|
| Matrix | Headcount by Department × Month |
| Bar Chart | Headcount by Location |
| Bar Chart | Headcount by Job Level |
| Stacked Bar | FTE Mix: Full-time / Part-time / Contractor by Division |
| Waterfall | Headcount movement: Opening + New Hires − Terminations = Closing |
| Scatter Plot | FTE % vs Tenure Years (spot part-time long-tenured employees) |
| Table | Employee count by Employment Type |

**Slicers**: Date range, Division, Department, Location, Employment Type

---

### Page 3 — Talent Acquisition
*Audience: Talent Acquisition team, HR Leadership*

**Purpose**: Monitor recruiting pipeline efficiency.

**Visuals**:
| Visual | Description |
|---|---|
| KPI Cards | Total Applications, Total Hires, Offer Acceptance Rate %, Avg Time to Fill |
| Funnel Chart | Recruitment funnel: Applied → Screened → Interviewed → Offered → Hired |
| Bar Chart | Time to Fill by Department (target line at 30 days) |
| Bar Chart | Time to Hire by Department |
| Donut Chart | Hires by Recruitment Source |
| Column Chart | Monthly hire volume vs. prior year |
| Line Chart | Offer Acceptance Rate trend (monthly) |
| Table | Open vacancies by Department with days open |

**Slicers**: Date range, Department, Job Family, Recruitment Source

---

### Page 4 — Retention & Turnover
*Audience: HR Leadership, HRBPs, C-suite*

**Purpose**: Understand attrition patterns to drive retention strategies.

**Visuals**:
| Visual | Description |
|---|---|
| KPI Cards | Turnover Rate %, Voluntary Turnover %, Avg Tenure at Exit, Retention Rate % |
| Line Chart | Turnover Rate % (monthly trend + prior year comparison) |
| Stacked Column | Voluntary vs Involuntary Terminations by month |
| Bar Chart | Turnover Rate % by Department (sorted descending) |
| Bar Chart | Turnover by Termination Reason |
| Scatter Plot | Department: Headcount vs Turnover Rate (identify risk quadrant) |
| Histogram | Distribution of Tenure at Termination |
| Table | Terminations this month with Dept, Role, Tenure, Reason |

**Slicers**: Date range, Division, Department, Is Voluntary

---

## Formatting Standards

| Element | Standard |
|---|---|
| Primary colour | `#0052CC` (deep blue) |
| Positive KPI | `#36B37E` (green) |
| Negative KPI | `#FF5630` (red) |
| Neutral | `#97A0AF` (grey) |
| Font | Segoe UI, 12pt body |
| Background | White (`#FFFFFF`) |
| Page size | 1280 × 720px (16:9) |

---

## Publish & Refresh

1. **Publish** from Power BI Desktop to Power BI Service (your workspace)
2. **Schedule refresh**: Daily at 08:00 (after SSIS/SSAS run completes)
3. **Row-Level Security**: Configure in Power BI Service → Security tab
4. **Share**: Create App for exec leadership; share individual reports with HRBPs
5. **Alerts**: Set data-driven alert on Turnover Rate % threshold

---

## Excel Integration

HR Business Partners can connect Excel directly to SSAS:
1. Excel → Data → From Analysis Services
2. Server: `<ssas-server>`, Database: `HR_DW`
3. Select cube/table → Load to PivotTable
4. Use PivotTable to slice headcount by any dimension
5. HRBPs can build their own ad-hoc analyses without touching SQL
