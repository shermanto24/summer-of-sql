-- Preppin' Data 2023 Week 07

-- For the Transaction Path table:
--     - Make sure field naming convention matches the other tables
--         - i.e. instead of Account_From it should be Account Number
-- For the Account Information table:
--     - Make sure there are no null values in the Account Holder ID
--     - Ensure there is one row per Account Holder ID
--         - Joint accounts will have 2 Account Holders, we want a row for each of them
-- For the Account Holders table:
--     - Make sure the phone numbers start with 07
-- Bring the tables together
-- Filter out cancelled transactions 
-- Filter to transactions greater than £1,000 in value 
-- Filter out Platinum accounts

with account_info as
(
    select
        t.* exclude account_holder_id,
        st.value as account_holder_id
    from pd2023_wk07_account_information as t,
    lateral split_to_table(account_holder_id, ', ') as st
)
select
    tp.transaction_id,
    tp.account_to,
    td.transaction_date,
    td.value,
    ai.account_number,
    ai.account_type,
    ai.balance_date,
    ai.balance,
    ah.name,
    ah.date_of_birth,
    '0' || ah.contact_number as contact_number,
    ah.first_line_of_address
from pd2023_wk07_transaction_path as tp
    inner join pd2023_wk07_transaction_detail as td
        on tp.transaction_id = td.transaction_id
    inner join account_info as ai
        on ai.account_number = tp.account_from
    inner join pd2023_wk07_account_holders as ah
        on ah.account_holder_id = ai.account_holder_id
where
    td.cancelled_ = 'N' and
    td.value > 1000 and
    ai.account_type != 'Platinum'
;