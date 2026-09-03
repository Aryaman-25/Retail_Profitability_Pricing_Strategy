use retail_profitability; 
SELECT
    'Raw (uncorrected)' AS view_type,
    ROUND(SUM(s.Quantity * p.Unit_Price_USD), 2)                                          AS revenue,
    ROUND(SUM(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)), 2)                       AS gross_profit,
    ROUND(SUM(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)) / SUM(s.Quantity * p.Unit_Price_USD) * 100, 2) AS gross_margin_pct
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey

UNION ALL

SELECT
    'Corrected (pricing integrity fixed)' AS view_type,
    ROUND(SUM(s.Quantity * p.Unit_Price_USD), 2)                                          AS revenue,
    ROUND(SUM(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)), 2)                       AS gross_profit,
    ROUND(SUM(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)) / SUM(s.Quantity * p.Unit_Price_USD) * 100, 2) AS gross_margin_pct
FROM sales s
JOIN products p ON s.ProductKey = p.ProductKey
WHERE p.Unit_Cost_USD <= p.Unit_Price_USD;

SELECT
    decision,
    COUNT(*)                              AS product_count,
    SUM(units)                            AS total_units,
    ROUND(SUM(current_gp), 2)             AS current_gross_profit,
    ROUND(SUM(potential_gp), 2)           AS potential_gross_profit,
    ROUND(SUM(potential_gp) - SUM(current_gp), 2) AS gp_uplift
FROM (
    SELECT
        ProductKey, units, current_margin, target_price,
        (Unit_Price_USD - Unit_Cost_USD) * units       AS current_gp,
        (target_price - Unit_Cost_USD) * units          AS potential_gp,
        CASE
            WHEN target_price > 1500 THEN 'Review Manually'
            WHEN current_margin >= 0.60 THEN 'No Change'
            WHEN units < 100 THEN 'Monitor - Low Volume'
            ELSE 'Increase Price'
        END AS decision
    FROM (
        SELECT
            p.ProductKey,
            p.Unit_Price_USD,
            p.Unit_Cost_USD,
            SUM(s.Quantity)                                        AS units,
            (p.Unit_Price_USD - p.Unit_Cost_USD) / p.Unit_Price_USD AS current_margin,
            p.Unit_Cost_USD / (1 - 0.60)                            AS target_price
        FROM sales s
        JOIN products p ON s.ProductKey = p.ProductKey
        WHERE p.Unit_Cost_USD <= p.Unit_Price_USD
        GROUP BY p.ProductKey, p.Unit_Price_USD, p.Unit_Cost_USD
    ) per_product
) decisioned
GROUP BY decision
ORDER BY gp_uplift DESC;

SELECT
    category,
    ROUND(gross_margin_pct, 2)        AS gross_margin_pct,
    ROUND(profit_contribution_pct, 2) AS profit_contribution_pct,
    business_priority,
    CASE business_priority
        WHEN 'High Priority' THEN 'Protect and reinvest'
        WHEN 'Review'        THEN 'Product-level margin review'
        ELSE 'Maintain current pricing'
    END AS recommended_action
FROM (
    SELECT
        category,
        gross_profit / revenue * 100 AS gross_margin_pct,
        gross_profit / total_gp * 100 AS profit_contribution_pct,
        CASE
            WHEN (gross_profit / revenue) >= 0.55 AND (gross_profit / total_gp) >= 0.10 THEN 'High Priority'
            WHEN (gross_profit / revenue) < 0.55 OR (gross_profit / total_gp) < 0.05 THEN 'Review'
            ELSE 'Maintain'
        END AS business_priority
    FROM (
        SELECT
            p.category                                             AS category,
            SUM(s.Quantity * p.Unit_Price_USD)                      AS revenue,
            SUM(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD))   AS gross_profit
        FROM sales s
        JOIN products p ON s.ProductKey = p.ProductKey
        WHERE p.Unit_Cost_USD <= p.Unit_Price_USD
        GROUP BY p.category
    ) cat_agg
    CROSS JOIN (
        SELECT SUM(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)) AS total_gp
        FROM sales s
        JOIN products p ON s.ProductKey = p.ProductKey
        WHERE p.Unit_Cost_USD <= p.Unit_Price_USD
    ) totals
) final
ORDER BY profit_contribution_pct DESC;
