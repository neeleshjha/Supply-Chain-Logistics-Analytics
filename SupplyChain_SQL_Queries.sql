-- ============================================================
--  SUPPLY CHAIN & LOGISTICS — SQL QUERIES
--  Database: Order Shipments + Supplier KPIs + Warehouse KPIs
--  Coverage: OTD · Lead Time · Cost · Inventory · Risk
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- PHASE 1: SCHEMA
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS order_shipments (
    Order_ID             TEXT PRIMARY KEY,
    Supplier             TEXT,
    Product_Category     TEXT,
    Warehouse            TEXT,
    Region               TEXT,
    Carrier              TEXT,
    Shipment_Mode        TEXT,
    Priority             TEXT,
    Order_Date           DATE,
    Delivery_Date        DATE,
    Promised_Lead_Days   INTEGER,
    Actual_Lead_Days     INTEGER,
    Is_Late              INTEGER,       -- 0/1
    Delay_Days           INTEGER,
    Order_Status         TEXT,
    Unit_Cost            REAL,
    Quantity             INTEGER,
    Order_Value          REAL,
    Freight_Cost         REAL,
    Holding_Cost         REAL,
    Total_Cost           REAL,
    Stock_On_Hand        INTEGER,
    Reorder_Point        INTEGER,
    Is_Stockout          INTEGER,       -- 0/1
    Inventory_Turns      REAL,
    Defect_Rate_Pct      REAL,
    Return_Rate_Pct      REAL,
    Supplier_Score       REAL
);

CREATE TABLE IF NOT EXISTS supplier_kpis (
    Supplier             TEXT PRIMARY KEY,
    Total_Orders         INTEGER,
    On_Time_Rate_Pct     REAL,
    Avg_Lead_Days        REAL,
    Avg_Score            REAL,
    Avg_Defect_Pct       REAL,
    Total_Order_Val      REAL,
    Total_Freight        REAL
);

CREATE TABLE IF NOT EXISTS warehouse_kpis (
    Warehouse            TEXT PRIMARY KEY,
    Orders               INTEGER,
    Avg_Stock            REAL,
    Stockout_Rate        REAL,
    Avg_Inv_Turns        REAL,
    Avg_Holding_Cost     REAL,
    Total_Value          REAL
);

-- ────────────────────────────────────────────────────────────
-- PHASE 2: DATA QUALITY
-- ────────────────────────────────────────────────────────────

-- Q1: Dataset snapshot
SELECT
    COUNT(*)                              AS Total_Orders,
    COUNT(DISTINCT Supplier)              AS Suppliers,
    COUNT(DISTINCT Carrier)               AS Carriers,
    COUNT(DISTINCT Warehouse)             AS Warehouses,
    MIN(Order_Date)                       AS First_Order,
    MAX(Order_Date)                       AS Last_Order,
    SUM(CASE WHEN Actual_Lead_Days <= 0 THEN 1 ELSE 0 END) AS Invalid_Lead_Days,
    SUM(CASE WHEN Order_Value < 0       THEN 1 ELSE 0 END) AS Negative_Values,
    SUM(CASE WHEN Delay_Days < 0        THEN 1 ELSE 0 END) AS Negative_Delays
FROM order_shipments;

-- Q2: Order status breakdown
SELECT
    Order_Status,
    COUNT(*)                               AS Orders,
    ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM order_shipments),1) AS Pct,
    ROUND(SUM(Order_Value)/1e6, 2)         AS Value_M,
    ROUND(AVG(Actual_Lead_Days), 1)        AS Avg_Lead_Days
FROM order_shipments
GROUP BY Order_Status
ORDER BY Orders DESC;

-- ────────────────────────────────────────────────────────────
-- PHASE 3: DELIVERY & LEAD TIME PERFORMANCE
-- ────────────────────────────────────────────────────────────

-- Q3: On-Time Delivery (OTD) by carrier and shipment mode
SELECT
    Carrier,
    Shipment_Mode,
    COUNT(*)                                         AS Shipments,
    SUM(Is_Late)                                     AS Late_Count,
    ROUND((1 - AVG(Is_Late)) * 100, 1)              AS OTD_Rate_Pct,
    ROUND(AVG(Actual_Lead_Days), 1)                  AS Avg_Lead_Days,
    ROUND(AVG(Delay_Days), 1)                        AS Avg_Delay_Days,
    ROUND(AVG(Freight_Cost), 0)                      AS Avg_Freight_Cost
FROM order_shipments
GROUP BY Carrier, Shipment_Mode
ORDER BY OTD_Rate_Pct DESC;

-- Q4: Lead time analysis by product category and priority
SELECT
    Product_Category,
    Priority,
    COUNT(*)                                         AS Orders,
    ROUND(AVG(Promised_Lead_Days), 1)               AS Avg_Promised,
    ROUND(AVG(Actual_Lead_Days), 1)                 AS Avg_Actual,
    ROUND(AVG(Actual_Lead_Days - Promised_Lead_Days), 1) AS Avg_Variance,
    ROUND((1 - AVG(Is_Late)) * 100, 1)             AS OTD_Pct,
    ROUND(MAX(Delay_Days), 0)                       AS Max_Delay
FROM order_shipments
GROUP BY Product_Category, Priority
ORDER BY Avg_Variance DESC;

-- Q5: Monthly OTD trend
SELECT
    STRFTIME('%Y-%m', Order_Date)                   AS Month,
    COUNT(*)                                         AS Orders,
    ROUND((1 - AVG(Is_Late)) * 100, 1)             AS OTD_Rate_Pct,
    ROUND(AVG(Actual_Lead_Days), 1)                 AS Avg_Lead_Days,
    ROUND(SUM(Order_Value)/1e6, 2)                  AS Order_Value_M,
    ROUND(SUM(Freight_Cost)/1e3, 1)                 AS Freight_K,
    SUM(Is_Stockout)                                AS Stockouts
FROM order_shipments
GROUP BY Month
ORDER BY Month;

-- ────────────────────────────────────────────────────────────
-- PHASE 4: COST ANALYSIS
-- ────────────────────────────────────────────────────────────

-- Q6: Total cost breakdown by shipment mode
SELECT
    Shipment_Mode,
    COUNT(*)                                         AS Orders,
    ROUND(SUM(Order_Value)/1e6, 2)                  AS Order_Value_M,
    ROUND(SUM(Freight_Cost)/1e6, 3)                 AS Freight_M,
    ROUND(SUM(Holding_Cost)/1e6, 3)                 AS Holding_M,
    ROUND(SUM(Total_Cost)/1e6, 2)                   AS Total_Cost_M,
    ROUND(AVG(Freight_Cost/NULLIF(Order_Value,0))*100, 2) AS Freight_Pct_Of_Order,
    ROUND(AVG(Actual_Lead_Days), 1)                 AS Avg_Lead_Days
FROM order_shipments
GROUP BY Shipment_Mode
ORDER BY Total_Cost_M DESC;

-- Q7: Cost efficiency by warehouse
SELECT
    w.Warehouse,
    w.Orders,
    ROUND(w.Total_Value/1e6, 2)                     AS Order_Value_M,
    ROUND(w.Avg_Holding_Cost, 0)                    AS Avg_Holding_Cost,
    w.Stockout_Rate                                  AS Stockout_Rate_Pct,
    ROUND(w.Avg_Inv_Turns, 1)                       AS Avg_Inv_Turns,
    ROUND(w.Avg_Stock, 0)                           AS Avg_Stock_On_Hand,
    CASE
        WHEN w.Stockout_Rate > 25 THEN 'Critical'
        WHEN w.Stockout_Rate > 15 THEN 'At-Risk'
        ELSE 'Healthy'
    END                                              AS Inventory_Health
FROM warehouse_kpis w
ORDER BY w.Stockout_Rate DESC;

-- ────────────────────────────────────────────────────────────
-- PHASE 5: SUPPLIER PERFORMANCE
-- ────────────────────────────────────────────────────────────

-- Q8: Full supplier scorecard
SELECT
    s.Supplier,
    s.Total_Orders,
    ROUND(s.Total_Order_Val/1e6, 2)                 AS Order_Value_M,
    ROUND(s.On_Time_Rate_Pct, 1)                    AS OTD_Pct,
    ROUND(s.Avg_Lead_Days, 1)                        AS Avg_Lead_Days,
    ROUND(s.Avg_Score, 1)                            AS Performance_Score,
    ROUND(s.Avg_Defect_Pct, 2)                      AS Defect_Pct,
    ROUND(s.Total_Freight/1e3, 1)                   AS Freight_K,
    CASE
        WHEN s.Avg_Score >= 85 AND s.On_Time_Rate_Pct >= 60 THEN 'Preferred'
        WHEN s.Avg_Score >= 70 AND s.On_Time_Rate_Pct >= 45 THEN 'Approved'
        WHEN s.Avg_Score >= 55                               THEN 'Conditional'
        ELSE 'At-Risk'
    END                                              AS Supplier_Tier
FROM supplier_kpis s
ORDER BY s.Avg_Score DESC;

-- Q9: Defect rate analysis by supplier and category
SELECT
    Supplier,
    Product_Category,
    COUNT(*)                                         AS Orders,
    ROUND(AVG(Defect_Rate_Pct), 2)                  AS Avg_Defect_Pct,
    ROUND(AVG(Return_Rate_Pct), 2)                  AS Avg_Return_Pct,
    ROUND(AVG(Supplier_Score), 1)                   AS Avg_Score,
    ROUND(SUM(Order_Value)/1e6, 2)                  AS Order_Value_M
FROM order_shipments
GROUP BY Supplier, Product_Category
HAVING Avg_Defect_Pct > 8
ORDER BY Avg_Defect_Pct DESC;

-- ────────────────────────────────────────────────────────────
-- PHASE 6: INVENTORY MANAGEMENT
-- ────────────────────────────────────────────────────────────

-- Q10: Stockout risk by warehouse and category
SELECT
    Warehouse,
    Product_Category,
    COUNT(*)                                         AS Orders,
    ROUND(AVG(Stock_On_Hand), 0)                    AS Avg_Stock,
    ROUND(AVG(Reorder_Point), 0)                    AS Avg_Reorder_Pt,
    ROUND(AVG(Is_Stockout)*100, 1)                  AS Stockout_Rate_Pct,
    ROUND(AVG(Inventory_Turns), 1)                  AS Avg_Inv_Turns,
    ROUND(AVG(Holding_Cost), 0)                     AS Avg_Holding_Cost
FROM order_shipments
GROUP BY Warehouse, Product_Category
ORDER BY Stockout_Rate_Pct DESC
LIMIT 20;

-- Q11: Critical & high priority orders with delays
SELECT
    Order_ID,
    Supplier,
    Product_Category,
    Warehouse,
    Carrier,
    Priority,
    Order_Date,
    Delivery_Date,
    Promised_Lead_Days,
    Actual_Lead_Days,
    Delay_Days,
    Order_Status,
    ROUND(Order_Value, 0)                            AS Order_Value,
    ROUND(Freight_Cost, 0)                           AS Freight_Cost
FROM order_shipments
WHERE Priority IN ('Critical','High')
  AND Is_Late = 1
  AND Delay_Days > 3
ORDER BY Delay_Days DESC, Order_Value DESC
LIMIT 25;

-- ────────────────────────────────────────────────────────────
-- PHASE 7: ADVANCED SQL (CTEs + Window Functions)
-- ────────────────────────────────────────────────────────────

-- Q12: Rolling 3-month freight cost + MoM change
WITH Monthly_Cost AS (
    SELECT
        STRFTIME('%Y-%m', Order_Date)               AS Month,
        ROUND(SUM(Freight_Cost)/1e3, 1)             AS Freight_K,
        ROUND(SUM(Order_Value)/1e6, 2)              AS Value_M,
        COUNT(*)                                    AS Orders,
        ROUND((1-AVG(Is_Late))*100, 1)              AS OTD_Pct
    FROM order_shipments
    GROUP BY Month
)
SELECT
    Month, Orders, Freight_K, Value_M, OTD_Pct,
    SUM(Freight_K) OVER (ORDER BY Month)             AS Cum_Freight_K,
    ROUND(AVG(Freight_K) OVER (
        ORDER BY Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1)                                             AS Rolling_3M_Freight_K,
    ROUND(
        (Freight_K - LAG(Freight_K) OVER (ORDER BY Month))
        / NULLIF(LAG(Freight_K) OVER (ORDER BY Month), 0) * 100, 1
    )                                                 AS MoM_Freight_Change_Pct
FROM Monthly_Cost
ORDER BY Month;

-- Q13: Supplier performance ranking with NTILE
WITH SupplierRanks AS (
    SELECT
        Supplier,
        Region,
        Product_Category,
        COUNT(*)                                    AS Orders,
        ROUND((1-AVG(Is_Late))*100, 1)             AS OTD_Pct,
        ROUND(AVG(Defect_Rate_Pct), 2)             AS Defect_Pct,
        ROUND(AVG(Supplier_Score), 1)              AS Score,
        ROUND(SUM(Order_Value)/1e6, 2)             AS Value_M
    FROM order_shipments
    GROUP BY Supplier, Region, Product_Category
)
SELECT *,
    RANK()   OVER (PARTITION BY Region ORDER BY Score DESC)    AS Rank_In_Region,
    RANK()   OVER (ORDER BY OTD_Pct DESC)                      AS OTD_Rank,
    NTILE(3) OVER (ORDER BY Score DESC)                        AS Performance_Tier
FROM SupplierRanks
ORDER BY Region, Rank_In_Region;

-- Q14: Late delivery cost impact (CTE)
WITH Late_Orders AS (
    SELECT *,
        Freight_Cost * 0.15 AS Late_Penalty,        -- 15% penalty assumption
        Holding_Cost * 1.5  AS Extra_Holding         -- 1.5x normal holding
    FROM order_shipments
    WHERE Is_Late = 1
),
Cost_Impact AS (
    SELECT
        Supplier,
        Carrier,
        Product_Category,
        COUNT(*)                                    AS Late_Orders,
        ROUND(SUM(Delay_Days), 0)                  AS Total_Delay_Days,
        ROUND(SUM(Late_Penalty)/1e3, 1)            AS Est_Penalty_K,
        ROUND(SUM(Extra_Holding)/1e3, 1)           AS Extra_Holding_K,
        ROUND(SUM(Order_Value)/1e6, 2)             AS At_Risk_Value_M
    FROM Late_Orders
    GROUP BY Supplier, Carrier, Product_Category
)
SELECT *,
    ROUND(Est_Penalty_K + Extra_Holding_K, 1)      AS Total_Impact_K,
    RANK() OVER (ORDER BY (Est_Penalty_K + Extra_Holding_K) DESC) AS Impact_Rank
FROM Cost_Impact
ORDER BY Total_Impact_K DESC
LIMIT 20;

-- Q15: Inventory efficiency score per warehouse (composite)
WITH Inv_Metrics AS (
    SELECT
        Warehouse,
        ROUND(AVG(Inventory_Turns), 2)             AS Inv_Turns,
        ROUND(AVG(Is_Stockout)*100, 1)             AS Stockout_Pct,
        ROUND(AVG(Holding_Cost), 0)                AS Avg_Hold_Cost,
        ROUND(AVG(Stock_On_Hand), 0)               AS Avg_Stock,
        COUNT(*)                                   AS Orders
    FROM order_shipments
    GROUP BY Warehouse
)
SELECT *,
    ROUND(
        (Inv_Turns * 20)
        - (Stockout_Pct * 1.5)
        - (Avg_Hold_Cost / 100.0), 1
    )                                              AS Inventory_Score,
    RANK() OVER (ORDER BY Inv_Turns DESC)          AS Turns_Rank,
    RANK() OVER (ORDER BY Stockout_Pct ASC)        AS Stockout_Rank
FROM Inv_Metrics
ORDER BY Inventory_Score DESC;

-- ────────────────────────────────────────────────────────────
-- PHASE 8: POWER BI VIEWS
-- ────────────────────────────────────────────────────────────

CREATE VIEW IF NOT EXISTS vw_Shipment_Performance AS
SELECT
    Carrier, Shipment_Mode, Supplier, Product_Category,
    Warehouse, Region, Priority,
    STRFTIME('%Y-%m', Order_Date)                   AS Month,
    COUNT(*)                                        AS Orders,
    ROUND((1-AVG(Is_Late))*100, 1)                 AS OTD_Pct,
    ROUND(AVG(Actual_Lead_Days), 1)                AS Avg_Lead_Days,
    ROUND(AVG(Delay_Days), 1)                      AS Avg_Delay,
    ROUND(SUM(Freight_Cost)/1e3, 1)               AS Freight_K,
    ROUND(SUM(Order_Value)/1e6, 2)                AS Value_M
FROM order_shipments
GROUP BY Carrier, Shipment_Mode, Supplier, Product_Category,
         Warehouse, Region, Priority, Month;

CREATE VIEW IF NOT EXISTS vw_Inventory_Risk AS
SELECT
    Warehouse, Product_Category, Supplier, Region,
    COUNT(*)                                       AS Orders,
    ROUND(AVG(Is_Stockout)*100, 1)                AS Stockout_Pct,
    ROUND(AVG(Inventory_Turns), 2)                AS Avg_Turns,
    ROUND(AVG(Stock_On_Hand), 0)                  AS Avg_Stock,
    ROUND(AVG(Reorder_Point), 0)                  AS Avg_Reorder_Pt,
    ROUND(AVG(Holding_Cost), 0)                   AS Avg_Hold_Cost,
    ROUND(AVG(Defect_Rate_Pct), 2)               AS Defect_Pct
FROM order_shipments
GROUP BY Warehouse, Product_Category, Supplier, Region;
