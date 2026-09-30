-- Preppin' Data 2023 Week 04

-- We want to stack the tables on top of one another, since they have the same fields in each sheet. We can do this one of 2 ways:
    -- Drag each table into the canvas and use a union step to stack them on top of one another
    -- Use a wildcard union in the input step of one of the tables
-- Some of the fields aren't matching up as we'd expect, due to differences in spelling. Merge these fields together
-- Make a Joining Date field based on the Joining Day, Table Names and the year 2023
-- Now we want to reshape our data so we have a field for each demographic, for each new customer
-- Make sure all the data types are correct for each field
-- Remove duplicates
    -- If a customer appears multiple times take their earliest joining date

with all_months as
(
    select * from pd2023_wk04_january
    union
    select * from pd2023_wk04_february
    union
    select * from pd2023_wk04_march
    union
    select * from pd2023_wk04_april
    union
    select * from pd2023_wk04_may
    union
    select * from pd2023_wk04_june
    union
    select * from pd2023_wk04_july
    union
    select * from pd2023_wk04_august
    union
    select * from pd2023_wk04_september
    union
    select id, joining_day, demagraphic as demographic, value from pd2023_wk04_october
    union
    select * from pd2023_wk04_november
    union
    select * from pd2023_wk04_december
)
select *
from all_months
    pivot (min(value) for demographic in ('Account Type', 'Date of Birth', 'Ethnicity'))
;