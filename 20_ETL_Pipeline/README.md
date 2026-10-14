# ETL pipeline

Run [`20_SETUP_OrdersMedallionPractice`](20_SETUP_OrdersMedallionPractice.ipynb) first. It creates the `sdp_bronze`, `sdp_silver`, and `sdp_gold` schemas, the source volume, and the JSON files the pipeline reads.

Then run the whole ETL pipeline. The definition is [`orders_etl_pipeline.yaml`](../orders_etl_pipeline.yaml). The pipeline code is in `Orders_Medallion_Practice`: `orders`, `status`, and `customers`.

The pipeline graph is in the root [README](../README.md).
