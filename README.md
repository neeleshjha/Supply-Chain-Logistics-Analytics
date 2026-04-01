# 🚛 Supply Chain & Logistics Analytics — End-to-End Data Analyst Project

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Problem Statement](#problem-statement)
- [Objectives](#objectives)
- [Dataset Description](#dataset-description)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Steps Involved](#steps-involved)
- [Key Findings](#key-findings)
- [How to Run](#how-to-run)
- [Business Recommendations](#business-recommendations)
- [Skills Demonstrated](#skills-demonstrated)

---

## 🔍 Project Overview

An end-to-end supply chain analytics project analysing **2,800 purchase orders** across 5 warehouses, 6 suppliers, 4 shipment modes, and 7 product categories. The project covers delivery performance (OTD), logistics cost optimisation, supplier quality ranking, and inventory risk — from raw data to Power BI dashboards and executive presentation.

---

## ❗ Problem Statement

A multi-warehouse manufacturing group is experiencing a critical operational crisis:

- **Only 41.1% On-Time Delivery rate** — far below the 85% industry benchmark
- **₹18.9M annual freight spend** with no mode-level cost optimisation
- **22.3% stockout frequency** threatening production continuity
- **No supplier tier system** — all vendors treated equally regardless of performance

---

## 🎯 Objectives

| # | Objective |
|---|-----------|
| 1 | Measure OTD rate by carrier, shipment mode, and priority tier |
| 2 | Analyse lead time variance: promised vs actual days by supplier/category |
| 3 | Calculate total logistics cost (freight + holding) by shipment mode |
| 4 | Rank suppliers using a composite performance tier (Preferred/Approved/Conditional/At-Risk) |
| 5 | Identify stockout risk by warehouse × SKU category |
| 6 | Quantify estimated late-delivery cost impact using CTE SQL modelling |

---

## 📊 Dataset Description

**File:** `SupplyChain_DA_Project.xlsx`

| Sheet | Rows | Description |
|-------|------|-------------|
| `Order_Shipments` | 2,800 | Purchase orders with lead time, cost, quality, inventory metrics |
| `Supplier_KPIs` | 6 | Supplier-level OTD rate, defect %, performance score |
| `Warehouse_KPIs` | 5 | Warehouse stockout rate, inventory turns, holding cost |

### Key Columns

| Column | Type | Description |
|--------|------|-------------|
| `Order_ID` | Text | Unique purchase order identifier |
| `Supplier` | Category | One of 6 vendors |
| `Shipment_Mode` | Category | Air / Road / Rail / Sea |
| `Priority` | Category | Critical / High / Medium / Low |
| `Promised_Lead_Days` | Integer | Contracted delivery window |
| `Actual_Lead_Days` | Integer | Actual transit + processing days |
| `Is_Late` | Binary (0/1) | 1 = delivered after promised date |
| `Delay_Days` | Integer | Days beyond promised delivery |
| `Freight_Cost` | Currency | Shipping cost for this order |
| `Holding_Cost` | Currency | Inventory carrying cost |
| `Is_Stockout` | Binary (0/1) | 1 = inventory below reorder point |
| `Inventory_Turns` | Decimal | Annual inventory rotation rate |
| `Defect_Rate_Pct` | Decimal % | Quality defects as % of order |
| `Supplier_Score` | 0–100 | Composite vendor performance rating |

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **Microsoft Excel** | Data cleaning, OTD pivot, VLOOKUP enrichment, conditional formatting |
| **SQL** | 15 queries, CTE late-cost model, RANK/NTILE/LAG, 2 views |
| **Python 3.8+** | EDA, 8-chart dashboard, supplier defect heatmap, cost analysis |
| **Power BI** | 3 dashboards with DAX measures and drill-through |
| **PowerPoint** | 9-slide Forest & Moss executive deck |

---

## 📁 Project Structure

```
supplychain-logistics-analytics/
│
├── data/
│   └── SupplyChain_DA_Project.xlsx
│
├── sql/
│   └── SupplyChain_SQL_Queries.sql
│
├── python/
│   └── SupplyChain_Python_EDA.py
│
├── tableau/
│   └── SupplyChain_Tableau.twbx
│
├── powerbi/
│   └── SupplyChain_PowerBI_Scripts.m
│
├── presentation/
│   └── SupplyChain_Logistics_Presentation.pptx
│
├── outputs/
│   ├── SupplyChain_EDA_Dashboard.png
│   └── SupplyChain_Supplier_Analysis.png
│
└── README.md
```

---

## 🔢 Steps Involved

### Phase 1 — Data Cleaning & Excel
1. Standardise `Order_Date` and `Delivery_Date` date formats; fill blank `Carrier` entries
2. Compute `Is_Late = IF(Actual_Lead_Days > Promised_Lead_Days, 1, 0)` as calculated column
3. VLOOKUP: enrich order records with `Avg_Score` and `On_Time_Rate_Pct` from `Supplier_KPIs`
4. Pivot Table: OTD % by Carrier × Shipment_Mode; Stockout Rate by Warehouse × Category
5. Conditional formatting: red if `Is_Late = 1` and `Priority = Critical`; amber if `Delay_Days > 5`

### Phase 2 — SQL Analysis
6. Data quality: invalid lead days, negative values, order status breakdown (Q1–Q2)
7. Delivery performance: OTD by carrier/mode, lead time by category/priority, monthly trend (Q3–Q5)
8. Cost analysis: freight + holding by shipment mode; cost efficiency by warehouse with health rating (Q6–Q7)
9. Supplier scorecard: full ranking with auto-tier classification (Q8–Q9)
10. Inventory risk: stockout by WH × category; critical delayed orders export (Q10–Q11)
11. Advanced SQL:
    - LAG() rolling 3-month freight trend with MoM change (Q12)
    - RANK() + NTILE() supplier performance tiers by region (Q13)
    - **CTE chain: Late Delivery Cost Impact** — estimates penalty + extra holding per supplier/carrier (Q14)
    - Inventory efficiency composite score with RANK() (Q15)
12. Create `vw_Shipment_Performance` and `vw_Inventory_Risk` views

### Phase 3 — Python EDA
13. Load all 3 Excel sheets using `pandas.read_excel()`
14. Profile: 2,800 orders, 0 nulls; describe lead days, order value, freight cost
15. Figure 1 (8 panels): monthly volume trend, shipment mode mix, OTD by carrier (traffic-light), lead time histogram, supplier score vs defect scatter, category value bar, stockout by WH, cost by mode
16. Figure 2 (supplier deep-dive): OTD vs score quadrant, delay days by priority histogram, defect heatmap (supplier × category)

### Phase 4 — Power BI
17. Load `SupplyChain_DA_Project.xlsx` using Power Query M from `SupplyChain_PowerBI_Scripts.m`
18. Create relationships: `Order_Shipments → Supplier_KPIs` (via Supplier); `Order_Shipments → Warehouse_KPIs` (via Warehouse)
19. Add DAX measures: OTD Rate %, Avg Lead Days, Total Logistics Cost, Stockout Rate %, Supplier Tier, Est Late Cost Impact, Inventory Health
20. Build 3 dashboards: SC Overview, Supplier Monitor, Inventory & Cost

### Phase 5 — Presentation
21. Build 9-slide Forest & Moss executive deck with OTD crisis, cost opportunity, and supplier tiers

---

## 📈 Key Findings

| Finding | Detail |
|---------|--------|
| 🚨 Only 41.1% On-Time Delivery | Industry benchmark: 85% — 44pp gap |
| 📦 WH-South: 24.0% Stockout Rate | Nearly 1 in 4 orders triggers out-of-stock |
| ✈️ Air Mode: 8× Freight Cost vs Sea | 24% of orders use Air despite non-urgent categories |
| ⚠️ Critical orders average 4.2-day delay | Direct contract penalty risk |
| 💰 Total Freight Spend: ₹18.9M | ~30% shiftable to cheaper modes → ₹2.1M saving |

---

## 💼 Business Recommendations

1. **Renegotiate carrier SLAs** — issue 90-day PIP to DHL Supply (38.5% OTD); set contractual penalties for Critical delays > 3 days
2. **Fix WH-South reorder points** — increase Machinery/Electronics reorder thresholds 35%; implement automated WMS triggers
3. **Shift 30% non-critical Air volume to Road/Rail** — estimated ₹2.1M annual freight saving
4. **Implement Supplier Tier-based sourcing policy** — Critical-priority orders for Preferred-tier suppliers only

---

## 🧠 Skills Demonstrated

`OTD Analysis` · `Lead Time Variance` · `Freight Cost Optimisation` · `Supplier Tier Classification` · `Inventory Reorder Gap` · `CTE Late-Cost Modelling` · `SQL RANK/NTILE/LAG` · `Python Heatmap` · `Power BI DAX` · `Power Query M` · `Logistics KPIs` · `Executive Storytelling`
