-- Preppin' Data 2023 Week 08

-- Create a 'file date' using the month found in the file name
--     - The Null value should be replaced as 1
-- Clean the Market Cap value to ensure it is the true value as 'Market Capitalisation'
--     - Remove any rows with 'n/a'
-- Categorise the Purchase Price into groupings
    -- 0 to 24,999.99 as 'Low'
    -- 25,000 to 49,999.99 as 'Medium'
    -- 50,000 to 74,999.99 as 'High'
    -- 75,000 to 100,000 as 'Very High'
-- Categorise the Market Cap into groupings
    -- Below $100M as 'Small'
    -- Between $100M and below $1B as 'Medium'
    -- Between $1B and below $100B as 'Large' 
    -- $100B and above as 'Huge'
-- Rank the highest 5 purchases per combination of: file date, Purchase Price Categorisation and Market Capitalisation Categorisation.
-- Output only records with a rank of 1 to 5

with all_months as
(
    select *, '01/01/2023' as file_date from pd2023_wk08_01
    union
    select *, '02/01/2023' as file_date from pd2023_wk08_02
    union
    select *, '03/01/2023' as file_date from pd2023_wk08_03
    union
    select *, '04/01/2023' as file_date from pd2023_wk08_04
    union
    select *, '05/01/2023' as file_date from pd2023_wk08_05
    union
    select *, '06/01/2023' as file_date from pd2023_wk08_06
    union
    select *, '07/01/2023' as file_date from pd2023_wk08_07
    union
    select *, '07/01/2023' as file_date from pd2023_wk08_07
    union
    select *, '08/01/2023' as file_date from pd2023_wk08_08
    union
    select *, '09/01/2023' as file_date from pd2023_wk08_09
    union
    select *, '10/01/2023' as file_date from pd2023_wk08_10
    union
    select *, '11/01/2023' as file_date from pd2023_wk08_11
    union
    select *, '12/01/2023' as file_date from pd2023_wk08_12
),
cleaned_data as
(
    select
        file_date, -- Included here to fix column order
        * exclude (id, first_name, last_name, market_cap, purchase_price, file_date),
        substr(market_cap, 2, length(market_cap) - 2)::float * iff(right(market_cap, 1) = 'B', 1000000000, 1000000) as market_cap,
        substr(purchase_price, 2, length(purchase_price) - 1)::float as purchase_price
    from all_months
    where market_cap != 'n/a'
)
select

    case
        when market_cap < 100000000 then 'Small'
        when market_cap < 1000000000 then 'Medium'
        when market_cap < 100000000000 then 'Large'
        when market_cap > 100000000000 then 'Huge'
    end as market_cap_category,
    
    case
        when purchase_price between 0 and 24999.99 then 'Low'
        when purchase_price between 25000 and 49999.99 then 'Medium'
        when purchase_price between 50000 and 74999.99 then 'High'
        when purchase_price between 75000 and 100000 then 'Very High'
    end as purchase_price_category,

    *,

    rank() over (partition by file_date, purchase_price_category, market_cap_category order by purchase_price desc) as "rank"
    
from cleaned_data
qualify "rank" between 1 and 5
;