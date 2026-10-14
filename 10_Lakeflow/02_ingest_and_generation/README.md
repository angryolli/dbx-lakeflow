# Ingest and generation

Bronze tables are loaded in three ways.

1. **Notebook.** `06_Ingest_Orders` copies `orders` into `orders_bronze`. `08_Ingest_Customers` reads the customer CSVs into `customers_bronze`.
2. **SQL query.** `07_Ingest_Sales` is the statement that copies `sales` into `sales_bronze`. The job runs that statement as a saved SQL query.
3. **Generate, then ingest.** Run `09_Generate_Customers` first. It writes a customer CSV into the volume. Then run `08_Ingest_Customers`, which loads that file into `customers_bronze`. A new file in the volume also starts the job, and the job runs notebook 08.

| Notebook | Job task | Result |
| --- | --- | --- |
| `09_Generate_Customers` | Starts the job by writing a CSV into the volume. | `customers_<timestamp>.csv` |
| `08_Ingest_Customers` | `ingest_customers` | `customers_bronze` |
| `06_Ingest_Orders` | `ingest_orders` | `orders_bronze` |
| `07_Ingest_Sales` | `ingest_sales` uses the saved SQL query with the same statement. | `sales_bronze` |

Notebook notes for this folder are in the [Lakeflow README](../README.md). The run pictures are in the root [README](../../README.md).
