table plans;
table subscriptions;

------------------- A: Customer Journey -------------------

-- Using the snippet of the subscriptions table from the website:
-- customer_id 1, 13: Trial -> basic monthly.
-- customer_id 2: Trial -> pro annual.
-- customer_id 11: Trial -> churn.
-- customer_id 15: Trial -> pro monthly -> churn.
-- customer_id 16: Trial -> basic monthly -> pro annual.
-- customer id 18: Trial -> pro monthly.
-- customer_id 19: Trial -> pro monthly -> pro annual.

-- When downgrading or canceling, higher plan remains in place until period is over.
-- When upgrading, higher plan takes effect immediately.
-- When churning, start_date is when they decided to cancel, but plan stays active until end of billing period.

------------------- B: Data Analysis -------------------

-- 1. How many customers has Foodie-Fi ever had?
select count(distinct customer_id) as num_customers
from subscriptions
;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset?
-- Use the start of the month as the group by value.
select 
    date_trunc('month', start_date) as month,
    sum(iff(plan_id = 0, 1, 0)) as trial_plans_started
from subscriptions
group by month
order by month asc
;

-- 3. What plan start_date values occur after the year 2020 for our dataset?
-- Show the breakdown by count of events for each plan_name.
select
    plan_name,
    count(*) as num_events
from subscriptions as s
    inner join plans as p
        on s.plan_id = p.plan_id
where start_date like '2021%'
group by plan_name
;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select
    count(distinct customer_id) as num_customers,
    round(sum(iff(plan_id = 4, 1, 0)) / num_customers * 100, 1) as percent_churn
from subscriptions
;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with churned_after_trial as
(
    select
        customer_id,
        plan_id as first_plan,
        lead(plan_id, 1) over (partition by customer_id order by start_date asc) as second_plan
    from subscriptions
    qualify
        first_plan = 0 and 
        second_plan = 4
)
select
    count(*) as num_churned_after_trial,
    round(count(*) / ( select count(distinct customer_id) from subscriptions ) * 100, 0) as percent_churned_after_trial
from churned_after_trial
;

-- 6. What is the number and percentage of customer plans after their initial free trial?
select
    plan_name,
    count(*) as num_plans_after_trial,
    round(num_plans_after_trial / ( select count(distinct customer_id) from subscriptions ) * 100, 1) as percent_plans_after_trial
from
(
    select
        customer_id,
        plan_id as first_plan,
        lead(plan_id, 1) over (partition by customer_id order by start_date asc) as second_plan
    from subscriptions
    qualify first_plan = 0
) as plan_pairs
    inner join plans as p
        on second_plan = p.plan_id
group by plan_name
;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with subscriptions_before_date as
(
     select
        customer_id,
        plan_id,
        start_date
    from subscriptions
    where start_date <= '2020-12-31'
    qualify row_number() over (partition by customer_id order by start_date desc) = 1 -- gets most recent plan per customer prior to date
)
select
    plan_name,
    count(distinct customer_id) as num_customers,
    round(num_customers / ( select count(distinct customer_id) from subscriptions_before_date ) * 100, 1) as percent_customers
from subscriptions_before_date as s
    inner join plans as p
        on s.plan_id = p.plan_id
group by plan_name
;

-- 8. How many customers have upgraded to an annual plan in 2020?
select count(customer_id) as num_customers
from subscriptions
where 
    plan_id = 3 and
    start_date between '2020-01-01' and '2020-12-31'
;

-- 9. How many days on average does it take for a customer to upgrade an annual plan from the day they join Foodie-Fi?
with customer_start_dates as
(
    select
        customer_id,
        start_date as customer_start_date
    from subscriptions
    where plan_id = 0
),
annual_start_dates as 
(
    select
        customer_id,
        start_date as annual_start_date
    from subscriptions
    where plan_id = 3
)
select round(avg(datediff('day', customer_start_date, annual_start_date)), 0) as avg_days_to_annual
from customer_start_dates as c
    inner join annual_start_dates as a
        on c.customer_id = a.customer_id
;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)?
with customer_start_dates as
(
    select
        customer_id,
        start_date as customer_start_date
    from subscriptions
    where plan_id = 0
),
annual_start_dates as 
(
    select
        customer_id,
        start_date as annual_start_date
    from subscriptions
    where plan_id = 3
),
time_between as
(
    select
        c.customer_id, 
        datediff('day', customer_start_date, annual_start_date) as days_btwn,
        case
            when days_btwn between 0 and 30 then '0-30'
            when days_btwn between 31 and 60 then '31-60'
            when days_btwn between 61 and 90 then '61-90'
            when days_btwn between 91 and 120 then '91-120'
            when days_btwn between 121 and 150 then '121-150'
            when days_btwn between 151 and 180 then '151-180'
            when days_btwn between 181 and 210 then '181-210'
            when days_btwn between 211 and 240 then '211-240'
            when days_btwn between 241 and 270 then '241-270'
            when days_btwn between 271 and 300 then '271-300'
            when days_btwn between 301 and 330 then '301-330'
            when days_btwn between 331 and 360 then '331-360'
        end as bin
    from customer_start_dates as c
        inner join annual_start_dates as a
            on c.customer_id = a.customer_id
)
select 
    bin,
    count(customer_id) as num_customers
from time_between
group by bin
;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
-- Returns nothing but is correct
with basic_monthly_plans as
(
    select
        customer_id,
        plan_id as basic_plan_id,
        start_date as basic_start_date
    from subscriptions
    where
        plan_id = 1 and
        start_date like '2020%'
),
pro_monthly_plans as
(
    select
        customer_id,
        plan_id as pro_plan_id,
        start_date as pro_start_date
    from subscriptions
    where plan_id = 2
)
select 
    b.customer_id,
    basic_start_date,
    pro_start_date
from basic_monthly_plans as b
    inner join pro_monthly_plans as p
        on b.customer_id = p.customer_id
where pro_start_date < basic_start_date
;