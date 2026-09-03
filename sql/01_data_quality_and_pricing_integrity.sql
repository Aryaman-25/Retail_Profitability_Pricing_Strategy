
SELECT
    p.ProductKey,
    p.Product_Name,
    p.category,
    p.Subcategory,
    p.Unit_Cost_USD,
    p.Unit_Price_USD,
    ROUND((p.Unit_Price_USD - p.Unit_Cost_USD) / p.Unit_Price_USD * 100, 2) AS margin_pct
FROM products p
WHERE p.Unit_Cost_USD > p.Unit_Price_USD
ORDER BY margin_pct ASC;


SELECT
    p.category,
    COUNT(*) AS flagged_products
FROM products p
WHERE p.Unit_Cost_USD > p.Unit_Price_USD
GROUP BY p.category
ORDER BY flagged_products DESC;


SELECT
    'Raw (all lines)' AS view_type,
    ROUND(SUM(line_revenue), 2)                                  AS total_revenue,
    ROUND(SUM(line_cogs), 2)                                     AS total_cogs,
    ROUND(SUM(line_gross_profit), 2)                             AS total_gross_profit,
    ROUND(SUM(line_gross_profit) / SUM(line_revenue) * 100, 2)   AS gross_margin_pct
FROM (
    SELECT
        s.Quantity * p.Unit_Price_USD                        AS line_revenue,
        s.Quantity * p.Unit_Cost_USD                         AS line_cogs,
        s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)    AS line_gross_profit
    FROM sales s
    JOIN products p ON s.ProductKey = p.ProductKey
) AS raw_lines

UNION ALL

SELECT
    'Corrected (flagged products excluded)' AS view_type,
    ROUND(SUM(line_revenue), 2)                                  AS total_revenue,
    ROUND(SUM(line_cogs), 2)                                     AS total_cogs,
    ROUND(SUM(line_gross_profit), 2)                             AS total_gross_profit,
    ROUND(SUM(line_gross_profit) / SUM(line_revenue) * 100, 2)   AS gross_margin_pct
FROM (
    SELECT
        s.Quantity * p.Unit_Price_USD                        AS line_revenue,
        s.Quantity * p.Unit_Cost_USD                         AS line_cogs,
        s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)    AS line_gross_profit
    FROM sales s
    JOIN products p ON s.ProductKey = p.ProductKey
    WHERE p.Unit_Cost_USD <= p.Unit_Price_USD
) AS corrected_lines;


SELECT
    COUNT(DISTINCT CASE WHEN is_flagged = 1 THEN ProductKey END)                    AS flagged_product_count,
    SUM(CASE WHEN is_flagged = 1 THEN 1 ELSE 0 END)                                 AS flagged_sales_lines,
    ROUND(SUM(line_revenue), 2)                                                     AS total_raw_revenue,
    ROUND(SUM(CASE WHEN is_flagged = 0 THEN line_revenue ELSE 0 END), 2)            AS total_corrected_revenue,
    ROUND(SUM(line_gross_profit), 2)                                                AS total_raw_gross_profit,
    ROUND(SUM(CASE WHEN is_flagged = 0 THEN line_gross_profit ELSE 0 END), 2)       AS total_corrected_gross_profit,
    ROUND(
        SUM(CASE WHEN is_flagged = 0 THEN line_gross_profit ELSE 0 END) - SUM(line_gross_profit), 2
    )                                                                                AS gross_profit_distortion
FROM (
    SELECT
        s.ProductKey,
        s.Quantity * p.Unit_Price_USD                        AS line_revenue,
        s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)    AS line_gross_profit,
        CASE WHEN p.Unit_Cost_USD > p.Unit_Price_USD THEN 1 ELSE 0 END AS is_flagged
    FROM sales s
    JOIN products p ON s.ProductKey = p.ProductKey
) AS line_level;
