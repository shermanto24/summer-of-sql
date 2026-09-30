-- Preppin' Data 2023 Week 03

-- For the transactions file:
    -- Filter the transactions to just look at DSB
        -- These will be transactions that contain DSB in the Transaction Code field
    -- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values
    -- Change the date to be the quarter
    -- Sum the transaction values for each quarter and for each Type of Transaction (Online or In-Person)
-- For the targets file:
    -- Pivot the quarterly targets so we have a row for each Type of Transaction and each Quarter
    -- Rename the fields
    -- Remove the 'Q' from the quarter field and make the data type numeric
-- Join the two datasets together
    -- You may need more than one join clause!
-- Remove unnecessary fields

-- Targets: unpivot, rename fields, remove Q from quarter -> int
with targets as
(
    select
        online_or_in_person,
        right(quarter, 1)::int as quarter,
        value as quarterly_targets
    from pd2023_wk03_targets
        unpivot (value for quarter in (q1, q2, q3, q4))
),
-- Transactions: only DSB, 1 -> Online & 2 -> In-Person, date -> quarter, sum by quarter & type of transaction
transactions as 
(
    select
        case
            when online_or_in_person = 1 then 'Online'
            else 'In-Person'
        end as online_or_in_person,
        quarter(to_date(transaction_date, 'DD/MM/YYYY HH:MI:SS')) as quarter,
        sum(value) as value
    from pd2023_wk01
    where transaction_code like 'DSB%'
    group by
        online_or_in_person,
        quarter
)
select
    tr.online_or_in_person,
    tr.quarter,
    tr.value,
    quarterly_targets,
    value - quarterly_targets as variance_to_target
from transactions as tr
    inner join targets as tg
        on
            tr.online_or_in_person = tg.online_or_in_person and
            tr.quarter = tg.quarter
;