-- Preppin' Data 2023 Week 05

-- Create the bank code by splitting out off the letters from the Transaction code, call this field 'Bank'
-- Change transaction date to the just be the month of the transaction
-- Total up the transaction values so you have one row for each bank and month combination
-- Rank each bank for their value of transactions each month against the other banks. 1st is the highest value of transactions, 3rd the lowest. 
-- Without losing all of the other data fields, find:
--     - The average rank a bank has across all of the months, call this field 'Avg Rank per Bank'
--     - The average transaction value per rank, call this field 'Avg Transaction Value per Rank'

with month_totals as
(
    select
        monthname(to_date(transaction_date, 'DD/MM/YYYY HH:MI:SS')) as month,
        split_part(transaction_code, '-', 1) as bank,
        sum(value) as value
    from pd2023_wk01
    group by
        month,
        bank
),
bank_ranks_per_month as
(
    select
        *,
        rank() over (partition by month order by value desc) as bank_rank_per_month
    from month_totals
)
select
    *,
    round(avg(value) over (partition by bank_rank_per_month), 2) as avg_transaction_value_per_rank,
    round(avg(bank_rank_per_month) over (partition by bank), 2) as avg_rank_per_bank
from bank_ranks_per_month
;