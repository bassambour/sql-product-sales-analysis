# Documentation: `gold.report_product`

## 1. Purpose

The `gold.report_product` view creates a **product performance report** by aggregating sales data at the product level. It helps analyze product revenue, popularity, customer reach, sales recency, and performance segments.

**Source tables**
- `gold.fact_sales`: Transactional sales data.
- `gold.dim_products`: Product information, including names, categories, subcategories, and costs.

## 2. Query structure

The view consists of three main stages:

1. **`base_query`** — joins sales transactions with product information and filters invalid sales dates.
2. **`product_aggregations`** — calculates sales KPIs for each product.
3. **Final query** — segments products and calculates additional business metrics.

## 3. Detailed explanation

### Stage 1: `base_query`

**Purpose:** Prepare the sales data needed for the product report.

- Joins `fact_sales` with `dim_products` using `product_key`.
- Uses a `LEFT JOIN` to retain sales records even if matching product information is missing.
- Selects the fields required for subsequent calculations.
- Excludes records where `order_date` is `NULL`.

### Stage 2: `product_aggregations`

**Purpose:** Summarize sales performance for each product.

| Column | Business meaning |
|---|---|
| `product_key` | Unique product identifier. |
| `product_name` | Product name. |
| `category` | Product's main category. |
| `subcategory` | More specific product classification. |
| `cost` | Product cost recorded in the product dimension. |
| `lifespan` | Number of whole month boundaries between the first and last recorded sale. |
| `last_sale_date` | Most recent recorded sale date for the product. |
| `total_orders` | Number of distinct order numbers associated with the product. |
| `total_customers` | Number of distinct customers who purchased the product. |
| `total_sales` | Sum of sales amounts for the product. |
| `total_quantity` | Total units sold. |
| `avg_selling_price` | Average sales amount per unit, calculated as total sales divided by total quantity and rounded to one decimal place. |

**Important calculations**

- `MIN(order_date)` identifies the earliest recorded sale.
- `MAX(order_date)` identifies the latest recorded sale.
- `DATEDIFF(MONTH, MIN(order_date), MAX(order_date))` measures the difference in calendar-month boundaries, not the exact number of elapsed months.
- `COUNT(DISTINCT order_number)` counts unique order numbers.
- `COUNT(DISTINCT customer_key)` counts unique customers.
- `NULLIF(SUM(quantity), 0)` prevents division by zero when calculating average selling price.

### Stage 3: Final query

**Purpose:** Turn the aggregated data into a business-friendly product performance report.

| Column | Business meaning |
|---|---|
| `recency_in_months` | Number of calendar-month boundaries between the last sale and the current date. A larger value indicates a longer period without a recorded sale. |
| `product_segment` | Classifies products according to their total sales. |
| `avg_order_revenue` | Total product sales divided by the number of distinct orders containing that product. |
| `avg_monthly_revenue` | Total product sales divided by its measured lifespan, with total sales returned when lifespan is zero. |

### Product segmentation rules

| Condition | Segment |
|---|---|
| `total_sales > 50000` | High-Performer |
| `total_sales >= 10000` and `total_sales <= 50000` | Mid-Range |
| `total_sales < 10000` | Low-Performer |

The `CASE` expression assigns each product to one segment based on its total sales.

### Average order revenue (AOR)

The calculation is:

`total_sales / total_orders`

It measures the average revenue contributed by the product per distinct order containing it. It is not necessarily the average value of the entire customer order because one order can contain multiple products.

### Average monthly revenue

The calculation is:

`total_sales / lifespan`

If `lifespan = 0`, the query returns `total_sales` instead to avoid division by zero. This fallback is a technical rule, not a true monthly average.

## 4. Business questions this view helps answer

- Which products generate the highest sales revenue?
- Which products sell the greatest quantities?
- Which products reach the most customers?
- Which products have not sold recently?
- Which products are high-, mid-, or low-performing?
- What is the average selling price per unit?
- How much revenue does a product generate per order?
- How does product revenue compare across its recorded sales lifespan?

## 5. Technical notes and limitations

1. **Sales amount and quantity:** The average selling price assumes `sales_amount` represents the total sales value for the corresponding quantity.
2. **Product cost:** The view includes `cost` but does not calculate profit or profit margin. These would require an appropriate cost calculation.
3. **Lifespan:** Products sold only within one calendar month have a lifespan of zero, even if sales occurred on different days.
4. **Average monthly revenue:** The zero-lifespan fallback returns total revenue, so this metric is not directly comparable across all products.
5. **Missing product data:** Because the join is a `LEFT JOIN`, transactions without matching product records can remain in the base data. Their product attributes may be `NULL`.
6. **Order counting:** `COUNT(DISTINCT order_number)` counts distinct order numbers within each product group, not necessarily distinct orders across the entire business if order numbers are reused.
7. **Date filtering:** The view excludes transactions with missing order dates, ensuring date-based metrics can be calculated.

## 6. Final output

The view produces one aggregated row per product grouping, containing product attributes, sales KPIs, recency, revenue metrics, and a performance segment. It can serve as a source for Power BI dashboards, product performance analysis, and business reporting.