# Logic and transformation

1. `10_Join_Customers_Orders` joins two tables, `customers_bronze` and `orders_bronze`, into `customers_orders_silver`.
2. `11_Join_Customers_Sales` joins three tables, customers, orders, and sales, into `customers_sales_silver`, then checks whether that result has duplicate rows.
3. `12_Remove_Duplicates` removes those duplicates from `customers_sales_silver` when the check finds them.
4. `13_Transform_Customers_Sales` cleans the joined sales table: trimmed names, typed ids and prices, plus `order_year` and `order_month`. The result is `customers_sales_gold`.
5. `14_Country_Orders_Report` filters `customers_orders_silver` by country. The job runs it once for each country: Finland, Sweden, and Germany.
6. `15_Transform_Country_Orders` applies a different transformation for each country and writes `orders_finland_gold`, `orders_sweden_gold`, and `orders_germany_gold`.
7. `16_Retail_Summary_Gold` builds `retail_summary_gold`, the summary table behind the Databricks dashboard.

| Notebook | Job task | Result |
| --- | --- | --- |
| `10_Join_Customers_Orders` | `customers_orders_report` | `customers_orders_silver` |
| `14_Country_Orders_Report` | `country_orders_iterator`, once each for Finland, Sweden, and Germany | `orders_<country>_silver` |
| `15_Transform_Country_Orders` | `transforming_country_orders` | `orders_finland_gold`, `orders_sweden_gold`, `orders_germany_gold` |
| `16_Retail_Summary_Gold` | `create_retail_summary` | `retail_summary_gold` |
| `11_Join_Customers_Sales` | `customers_sales_summary` | `customers_sales_silver`, and task value `has_duplicates` |
| `12_Remove_Duplicates` | `dropping_duplicate_records`, only when `has_duplicates` is true | Deduplicated `customers_sales_silver` |
| `13_Transform_Customers_Sales` | `transforming_customers_sales` | `customers_sales_gold` |

`checking_for_duplicates` and `refreshing_retail_dashboard` (tasks / job steps) live only in the job file. The condition compares `has_duplicates` to `true`. The dashboard task refreshes dashboard `01f1c59e6cd015b98da3a8656e5d5ecb` after the retail summary.

The visualization of the whole pipeline is in the main [`README.md`](../README.md) at the root of the project.
