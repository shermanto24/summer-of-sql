-- Preppin' Data 2023 Week 01

-- Split the Transaction Code to extract the letters at the start of the transaction code. These identify the bank who processes the transaction 
    -- Rename the new field with the Bank code 'Bank'. 
-- Rename the values in the Online or In-person field, Online of the 1 values and In-Person for the 2 values. 
-- Change the date to be the day of the week
-- Different levels of detail are required in the outputs. You will need to sum up the values of the transactions in three ways:
    -- 1. Total Values of Transactions by each bank
    -- 2. Total Values by Bank, Day of the Week and Type of Transaction (Online or In-Person)
    -- 3. Total Values by Bank and Customer Code

-- Output 1: Total values by bank
select
    left(transaction_code, position('-', transaction_code, 1) - 1) as bank,
    sum(value) as value
from pd2023_wk01
group by bank
;

-- Output 2: Total values by bank, day of week, type of transaction
select
    left(transaction_code, position('-', transaction_code, 1) - 1) as bank,
    case
        when online_or_in_person = 1 then 'Online'
        else 'In-Person'
        end as online_or_in_person,
    dayname(to_date(transaction_date, 'DD/MM/YYYY HH:MI:SS')) as transaction_date,
    sum(value) as value
from pd2023_wk01
group by all
;

-- Output 3: Total values by bank and customer code
select
    left(transaction_code, position('-', transaction_code, 1) - 1) as bank,
    customer_code,
    sum(value) as value
from pd2023_wk01
group by all
;