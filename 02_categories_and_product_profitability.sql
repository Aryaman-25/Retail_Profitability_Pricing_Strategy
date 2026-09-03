use retail_profitability;
SELECT
    category,
    ROUND(revenue, 2)                                    AS revenue,
    ROUND(cogs, 2)                                        AS cogs,
    ROUND(gross_profit, 2)                                 AS gross_profit,
    ROUND(gross_profit / revenue * 100, 2)                 AS gross_margin_pct,
    ROUND(gross_profit / total_gp * 100, 2)                AS profit_contribution_pct,
    CASE
        WHEN (gross_profit / revenue) >= 0.55 AND (gross_profit / total_gp) >= 0.10 THEN 'High Priority'
        WHEN (gross_profit / revenue) < 0.55 OR (gross_profit / total_gp) < 0.05 THEN 'Review'
        ELSE 'Maintain'
    END                                                     AS business_priority
FROM (
    SELECT
        p.category                                       AS category,
        SUM(s.Quantity * p.Unit_Price_USD)                AS revenue,
        SUM(s.Quantity * p.Unit_Cost_USD)                 AS cogs,
        SUM(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)) AS gross_profit
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
ORDER BY gross_profit DESC;

SELECT
    (SELECT COUNT(*) FROM (
        SELECT p.ProductKey
        FROM sales s JOIN products p ON s.ProductKey = p.ProductKey
        WHERE p.Unit_Cost_USD <= p.Unit_Price_USD
        GROUP BY p.ProductKey
    ) all_products)                                        AS total_products_sold,
    (SELECT ROUND(SUM(top.gross_profit), 2) FROM (
        SELECT
            p.ProductKey,
            SUM(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)) AS gross_profit
        FROM sales s JOIN products p ON s.ProductKey = p.ProductKey
        WHERE p.Unit_Cost_USD <= p.Unit_Price_USD
        GROUP BY p.ProductKey
        ORDER BY gross_profit DESC
        LIMIT 470  
    ) top)                                                  AS gross_profit_from_top_20pct_products,
    (SELECT ROUND(SUM(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)), 2)
     FROM sales s JOIN products p ON s.ProductKey = p.ProductKey
     WHERE p.Unit_Cost_USD <= p.Unit_Price_USD)              AS total_gross_profit;


SELECT
    r.Product_Name,
    r.category,
    r.revenue,
    r.revenue_rank,
    pr.gross_profit,
    pr.profit_rank,
    (pr.profit_rank - r.revenue_rank) AS rank_gap
FROM (
    SELECT
        ProductKey, Product_Name, category, revenue,
        (@rev_rank := @rev_rank + 1) AS revenue_rank
    FROM (
        SELECT p.ProductKey, p.Product_Name, p.category,
               SUM(s.Quantity * p.Unit_Price_USD) AS revenue
        FROM sales s
        JOIN products p ON s.ProductKey = p.ProductKey
        WHERE p.Unit_Cost_USD <= p.Unit_Price_USD
        GROUP BY p.ProductKey, p.Product_Name, p.category
        ORDER BY revenue DESC
    ) t1, (SELECT @rev_rank := 0) init1
) r
JOIN (
    SELECT
        ProductKey, gross_profit,
        (@profit_rank := @profit_rank + 1) AS profit_rank
    FROM (
        SELECT p.ProductKey,
               SUM(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD)) AS gross_profit
        FROM sales s
        JOIN products p ON s.ProductKey = p.ProductKey
        WHERE p.Unit_Cost_USD <= p.Unit_Price_USD
        GROUP BY p.ProductKey
        ORDER BY gross_profit DESC
    ) t2, (SELECT @profit_rank := 0) init2
) pr ON r.ProductKey = pr.ProductKey
ORDER BY r.revenue_rank
LIMIT 30;

