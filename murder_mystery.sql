-- Finding the real culprit
select *
from facebook_event_checkin
join
(
    select 
  		name,
  		person.id
	from person
	join
	(
		select id
		from drivers_license
		where height >= 65 and height <= 67
		and gender = 'female'
		and hair_color = 'red'
		and car_make = 'Tesla'
		and car_model = 'Model S'
	) as dl
	on person.license_id = dl.id
) as suspects
on person_id = suspects.id
where date like '201712%'
	and event_name like '%SQL Symphony Concert%'
;

-- INFO GAINED:
-- Hired by woman with a lot of money
-- 5'5" (65") or 5'7" (67")
-- Red hair
-- Tesla model s
-- Attended SQL Symphony Concert 3x in dec 2017
select *
from interview
	join person
		on interview.person_id = person.id
where person_id =
(
 	select id
  	from person
  	where name = 'Jeremy Bowers'
)
;

-- Finding the murderer
select *
from drivers_license
	join person
		on drivers_license.id = person.license_id
where plate_number like '%H42W%'
;

-- Looking through gym memberships
select *
from get_fit_now_check_in
where membership_id in
(
    -- INFO GAINED:
	-- Joe Germuska or Jeremy Bowers
	select id
	from get_fit_now_member
	where id like '48Z%'
		and membership_status = 'gold'
)
and check_in_date = '20180109'
;

-- INFO GAINED:
-- Membership number starts with 48Z (gold), car plate includes H42W
-- Seen at gym on Jan 9th (not when murder happened)
select * 
from interview
	join
	(
	  -- witness 2 = Morty Schapiro
	  select *
	  from person
	  where address_street_name = 'Northwestern Dr'
	  order by address_number desc
	  limit 1
	) as p1
		on person_id = p1.id
union all
select * 
from interview
	join 
	(
        -- INFO GAINED:
	    -- Witness 2 = Annabel Miller
        select *
        from person
        where name like 'Annabel%'
        and address_street_name = 'Franklin Ave'
	) as p2
		on person_id = p2.id
;

-- INFO GAINED:
-- Witness 1: lives at last house on Northwestern Dr
-- Witness 2: Annabel, lives somewhere on Franklin Ave
select * 
from crime_scene_report
where city = 'SQL City'
	and date = '20180115'
	and type = 'murder'
;
