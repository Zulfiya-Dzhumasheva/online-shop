WITH clean_orders AS (
    SELECT 
        o.order_id,
        c.customer_unique_id,
        c.customer_state,
        o.order_purchase_timestamp AS purchase_date,
        SUM(p.payment_value) AS total_revenue,
        SUM(i.freight_value) AS total_freight,
        COUNT(i.order_item_id) AS items_count
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    JOIN order_items i ON o.order_id = i.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1, 2, 3, 4
),
cohort_base AS (
    SELECT 
        *,
        MIN(strftime('%Y-%m-01', purchase_date)) OVER(PARTITION BY customer_unique_id) AS cohort_month,
        strftime('%Y-%m-01', purchase_date) AS order_month,
        ROW_NUMBER() OVER(PARTITION BY customer_unique_id ORDER BY purchase_date) AS order_num
    FROM clean_orders
)
SELECT 
    *,
    (CAST(strftime('%Y', order_month) AS INTEGER) - CAST(strftime('%Y', cohort_month) AS INTEGER)) * 12 +
    (CAST(strftime('%m', order_month) AS INTEGER) - CAST(strftime('%m', cohort_month) AS INTEGER)) AS cohort_index
FROM cohort_base;
