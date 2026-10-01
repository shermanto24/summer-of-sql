table customer_nodes;
table customer_transactions;
table regions;

------------------- A. Customer Nodes Exploration -------------------

-- 1. How many unique nodes are there on the Data Bank system?
select count(distinct node_id) as num_unique_nodes
from customer_nodes
;

-- 2. What is the number of nodes per region?
select
    region_name,
    count(distinct node_id) as num_nodes
from customer_nodes as c
    inner join regions as r
        on c.region_id = r.region_id
group by region_name
;

-- 3. How many customers are allocated to each region?
select
    region_name,
    count(distinct customer_id) as num_customers
from customer_nodes as c
    inner join regions as r
        on c.region_id = r.region_id
group by region_name
;

-- 4. How many days on average are customers reallocated to a different node?
with customer_days_in_node as
(
    select
        customer_id,
        node_id,
        sum(datediff('day', start_date, end_date)) as days_in_node
    from customer_nodes
    where end_date != '9999-12-31' -- Majority of nodes have this end date
    group by
        customer_id,
        node_id
)
select round(avg(days_in_node), 0) as avg_days_in_node
from customer_days_in_node
;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
with customer_days_in_node as
(
    select
        customer_id,
        region_id,
        node_id,
        sum(datediff('day', start_date, end_date)) as days_in_node
    from customer_nodes
    where end_date != '9999-12-31' -- Majority of nodes have this end date
    group by
        customer_id,
        region_id,
        node_id
),
stats_per_region as
(
    select
        region_name,
        round(median(days_in_node), 0) as "Median",
        round(percentile_cont(0.8) within group (order by days_in_node), 0) as "80th Percentile",
        round(percentile_cont(0.95) within group (order by days_in_node), 0) as "95th Percentile"
    from customer_days_in_node as c
        inner join regions as r
            on c.region_id = r.region_id
    group by region_name
)
select
    region_name,
    metric,
    value
from stats_per_region
    unpivot (value for metric in ("Median", "80th Percentile", "95th Percentile"))
;

------------------- B. Customer Transactions -------------------

-- 1. What is the unique count and total amount for each transaction type?

table customer_transactions;

select
    txn_type,
    count(*) as num_transactions,
    sum(txn_amount) as total_amount
from customer_transactions
group by txn_type
;

-- 2. What is the average total historical deposit counts and amounts for all customers?
select
    count(*) as num_deposits,
    avg(txn_amount) as total_deposit_amount
from customer_transactions
where txn_type = 'deposit'
; -- incorrect, redo

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with customer_txns_by_month as
(
    select
        date_trunc('month', txn_date) as month,
        customer_id,
        sum(iff(txn_type = 'deposit', 1, 0)) as num_deposits,
        sum(iff(txn_type = 'purchase' or txn_type = 'withdrawal', 1, 0)) as num_purchases_and_withdrawals
    from customer_transactions
    group by
        month,
        customer_id
)
select
    month,
    count(distinct customer_id) as num_customers
from customer_txns_by_month
where
    num_deposits > 1 and
    num_purchases_and_withdrawals = 1
group by month
;

-- 4. What is the closing balance for each customer at the end of the month?
with monthly_deposits_and_expenses as
(
    select 
        customer_id,
        date_trunc('month', txn_date) as month,
        sum(iff(txn_type = 'deposit', txn_amount, 0)) over (partition by customer_id order by txn_date asc) as running_sum_deposits,
        sum(iff(txn_type = 'purchase' or txn_type = 'withdrawal', txn_amount, 0)) over (partition by customer_id order by txn_date asc) as running_sum_expenses,
        row_number() over (partition by customer_id, month order by txn_date desc) as rn
    from customer_transactions
)
select
    customer_id,
    dateadd('day', -1, dateadd('month', 1, month)) as end_of_month,
    running_sum_deposits - running_sum_expenses as closing_balance
from monthly_deposits_and_expenses
where rn = 1
order by
    customer_id, 
    end_of_month
;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
with monthly_deposits_and_expenses as
(
    select 
        customer_id,
        date_trunc('month', txn_date) as month,
        sum(iff(txn_type = 'deposit', txn_amount, 0)) over (partition by customer_id order by txn_date asc) as running_sum_deposits,
        sum(iff(txn_type = 'purchase' or txn_type = 'withdrawal', txn_amount, 0)) over (partition by customer_id order by txn_date asc) as running_sum_expenses,
        row_number() over (partition by customer_id, month order by txn_date desc) as rn
    from customer_transactions
),
closing_balances as
(
    select
        customer_id,
        dateadd('day', -1, dateadd('month', 1, month)) as end_of_month,
        running_sum_deposits - running_sum_expenses as closing_balance
    from monthly_deposits_and_expenses
    where rn = 1
    order by
        customer_id, 
        end_of_month
),
percent_changes as
(
    select
        *,
        lag(end_of_month, 1) over (partition by customer_id order by end_of_month asc) as prev_month,
        lag(closing_balance, 1) over (partition by customer_id order by end_of_month asc) as prev_closing_balance,
        round(div0((closing_balance - prev_closing_balance), abs(prev_closing_balance)) * 100, 2) as percent_change,
        iff(closing_balance > 0 and percent_change > 5, 1, 0) as meets_criteria -- Must check if closing_balance > 0 because negative closing balances don't count as increases
    from closing_balances
),
months_increasing as
(
    select
        customer_id,
        end_of_month,
        sum(meets_criteria) as sum_criteria
    from percent_changes
    group by 
        customer_id,
        end_of_month
    having sum_criteria >= 1
)
select
    ( select count(*) from months_increasing ) / ( select count(*) from closing_balances ) as percent_balances_increasing
    -- Number of increasing months / total number of balances
;
-- Returns 0.205233, should be 0.209664