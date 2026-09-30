-- Preppin' Data 2023 Week 06

-- Reshape the data so we have 5 rows for each customer, with responses for the Mobile App and Online Interface being in separate fields on the same row
-- Clean the question categories so they don't have the platform in from of them
--     - e.g. Mobile App - Ease of Use should be simply Ease of Use
-- Exclude the Overall Ratings, these were incorrectly calculated by the system
-- Calculate the Average Ratings for each platform for each customer 
-- Calculate the difference in Average Rating between Mobile App and Online Interface for each customer
-- Catergorise customers as being:
--     - Mobile App Superfans if the difference is greater than or equal to 2 in the Mobile App's favour
--     - Mobile App Fans if difference >= 1
--     - Online Interface Fan
--     - Online Interface Superfan
--     - Neutral if difference is between 0 and 1
-- Calculate the Percent of Total customers in each category, rounded to 1 decimal place

with ratings_per_category as
(
    select
        customer_id,
        iff(category like 'MOBILE%', 'Mobile', 'Online') as category,
        rating
    from pd2023_wk06_dsb_customer_survey
    unpivot
    (
        rating for category in (mobile_app___ease_of_use, mobile_app___ease_of_access, mobile_app___navigation, mobile_app___likelihood_to_recommend, online_interface___ease_of_use, online_interface___ease_of_access, online_interface___navigation, online_interface___likelihood_to_recommend)
    )
),
differences as (
    select
        customer_id,
        category,
        avg(rating) as avg_rating,
        avg_rating - lead(avg_rating, 1) over (partition by customer_id order by category asc) as difference -- mobile - online
    from ratings_per_category
    group by all
    qualify category = 'Mobile'
)
select
    case
        when difference >= 2 then 'Mobile App Superfan'
        when difference >= 1 then 'Mobile App Fan'
        when difference > -1 and difference < 1 then 'Neutral'
        when difference <= -2 then 'Online Interface Superfan'
        else 'Online Interface Fan'
    end as preference,
    round(count(*) / (select count(distinct customer_id) from differences) * 100, 1) as percent_of_total
from differences
group by preference
;