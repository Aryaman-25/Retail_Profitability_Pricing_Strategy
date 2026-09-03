# Retail Profitability & Pricing Strategy Analysis

**A SQL + Power BI + Excel analysis of pricing integrity, category profitability, and margin headroom for a multi-country electronics retailer.**

[![SQL](https://img.shields.io/badge/SQL-MySQL_8.0-4479A1?logo=mysql&logoColor=white)](sql/)
[![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-F2C811?logo=powerbi&logoColor=black)](powerbi/)
[![Excel](https://img.shields.io/badge/Excel-Financial_Model-217346?logo=microsoftexcel&logoColor=white)](excel/)


---

## Business Question

> **Where should pricing and category-investment decisions focus to maximize true profitability?**

This project treats that question the way a pricing/commercial analytics team would treat it before it ever reaches a business review: don't trust the topline numbers until they've been audited, don't chase revenue growth generically, and don't propose price changes without a defensible, volume-aware model behind them.

The analysis is broken into three sub-questions, each with its own SQL, its own output table, and its own place in the final recommendation:

| # | Sub-question | Where it's answered |
|---|---|---|
| 1 | **Can we trust the numbers?** - No, not without correction: 144 products (6.1% of catalog) were priced below cost, understating gross margin by 9.19 points ($3.97M distortion).
(sql/01_data_quality_and_pricing_integrity.sql) → [Finding 1](docs/02_findings_and_recommendations.docx#finding-1--the-headline-numbers-were-wrong-until-they-werent) |

| 2 | **Where is profit concentrated?** - Heavily: Computers alone drives 37.2% of gross profit; the top 20% of products generate 70.5% of it.
(sql/02_categories_and_product_profitability.sql) → [Finding 2](docs/02_findings_and_recommendations.docx#finding-2--profit-is-concentrated-in-a-small-part-of-the-portfolio) |

| 3 | **Where's the real headroom?** - A specific, tested list of 447 high-volume products worth ~$3.31M in incremental gross profit not a blanket price increase.(sql/03_business_analysis_pricing_model.sql) → [Finding 3](docs/02_findings_and_recommendations.docx#finding-3--the-real-headroom-is-narrow-and-specific) |

---

## TL;DR — Answer to the Central Question

Reported profitability could not be trusted at face value: **144 products (6.1% of the catalog) were priced below cost**, which understated blended gross margin by **9.2 points** (47.55% → **56.74%** once corrected) and distorted reported gross profit by **$3.97M**. Once the numbers were corrected, two things became clear:

1. **Profit is concentrated, not distributed.** One category (**Computers**) generates **37% of all gross profit**, and just **20% of SKUs (470 of 2,349) generate 70.5% of gross profit.** Two categories — Home Appliances and TV & Video — carry meaningful revenue but comparatively weak margins and need review, not investment.
2. **The real pricing headroom is narrow and specific, not broad.** Rather than raising prices across the board, a volume-aware model that targets a 60% gross-margin benchmark identifies **447 specific, high-volume products** (concentrated in Computers, Cell Phones, and Home Appliances) with genuine repricing headroom worth **~$3.31M in incremental gross profit** — without touching pricing on the other ~1,900 SKUs that are already at or near target margin.

**Recommendation:** Fix the data-quality issue first (it's currently the single largest lever on reported profitability), protect and reinvest in Computers/Cell Phones/Cameras, put Home Appliances and TV & Video through a margin review, and pilot — not roll out — price increases on the 447 flagged SKUs with an A/B test before committing to full repricing.

Full detail, evidence, and caveats: **[docs/02_findings_and_recommendations.docx](docs/02_findings_and_recommendations.docx)**

---

## Key Metrics at a Glance

| Metric | Raw (uncorrected) | Corrected (pricing integrity applied) |
|---|---:|---:|
| Revenue | $43,212,329.17 | $43,204,148.17 |
| COGS | $22,664,866.33 | $18,689,410.25 |
| Gross Profit | $20,547,462.84 | **$24,514,737.92** |
| Gross Margin | 47.55% | **56.74%** |

| Metric | Value |
|---|---:|
| Orders | 26,326 |
| Units Sold | 197,757 |
| Average Order Value | $1,641.43 |
| Products flagged for pricing-integrity issues | 144 (6.1% of catalog) |
| Sales lines / units affected by flagged products | 2,068 lines / 6,487 units |
| Gross-profit distortion from bad pricing data | $3,967,275.08 |
| Products with genuine repricing headroom (60% margin target) | 447 |
| Estimated incremental gross profit from targeted repricing | $3,312,861.84 |

---

## Repository Structure

```
retail-profitability-pricing-strategy/
├── README.docx                                   ← you are here
├── LICENSE
├── docs/
│   ├── 01_methodology.docx                       ← data sources, tools, approach, assumptions, limitations
│   ├── 02_findings_and_recommendations.docx       ← the full analytical report (start here for the "why")
│   └── 03_data_dictionary.docx                    ← table/column definitions, grain, business rules
├── sql/
│   ├── 00_schema_and_data_load.sql              ← DDL + seed data (MySQL 8.0 dump)
│   ├── 01_data_quality_and_pricing_integrity.sql ← Sub-question 1
│   ├── 02_categories_and_product_profitability.sql ← Sub-question 2
│   └── 03_business_analysis_pricing_model.sql   ← Sub-question 3 + final decision table
├── excel/
│   └── Analysis.xlsx                            ← Executive Summary, Category Analysis, Pricing Model, Recommendations
└── powerbi/
    └── Report.pbix                           ← interactive Power BI report built on the same corrected model
```

**Suggested reading order:** `README.docx` → `docs/02_findings_and_recommendations.docx` → `sql/` (to verify the numbers yourself) → `excel/Analysis.xlsx` or `powerbi/Report.pbix` (to explore interactively).

---

## Data & Scope

The underlying dataset is a relational retail dataset (customers, products, stores, sales transactions, and daily FX rates) covering **26,326 orders / 197,757 units across 2,349 products in 8 categories**, sold across multiple countries with multi-currency transactions. Full schema and grain are documented in [`docs/03_data_dictionary.docx`](docs/03_data_dictionary.docx); the raw DDL and seed data are in [`sql/00_schema_and_data_load.sql`](sql/00_schema_and_data_load.sql).

---

## Tools & Method

| Layer | Tool | Purpose |
|---|---|---|
| Data storage & transformation | **MySQL 8.0** | Source of truth; all profitability, pricing-integrity and pricing-opportunity logic is computed in SQL, not spreadsheets, so it's auditable and reproducible |
| Analysis & scenario modeling | **Excel** | Executive summary rollups, product-level pricing model output, and the recommendations table |
| Reporting & stakeholder-facing view | **Power BI** | Interactive dashboard for exploring category, product, and pricing-scenario cuts |

The analytical approach follows a standard commercial-analytics sequence: **audit → segment → model → recommend.** Full methodology, including how the "correct" dataset was defined and the assumptions behind the 60%-margin pricing target, is in [`docs/01_methodology.docx`](docs/01_methodology.docx).

---

## Reproducing This Analysis

1. Restore the schema and data into a local MySQL 8.0 instance:
   ```bash
   mysql -u root -p -e "CREATE DATABASE retail_profitability;"
   mysql -u root -p retail_profitability < sql/00_schema_and_data_load.sql
   ```
2. Run the analysis scripts in order (01 → 02 → 03) — each is self-contained and commented.
3. Open `excel/Analysis.xlsx` or `powerbi/Report.pbix` to explore the results interactively; both were built from the same corrected query logic in `sql/`.

---

## About

Built as an end-to-end applied business analytics project from raw transactional data to a defensible, board-ready pricing recommendation using SQL as the analytical backbone and Excel/Power BI for stakeholder communication.

