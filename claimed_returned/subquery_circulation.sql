WITH parameters AS (
    SELECT
        /* Search loans with this status */
        '' :: VARCHAR AS loan_item_status,
        /* Choose a start and end date for the loans period */
        '2000-01-01' :: DATE AS start_date,
        '2021-01-01' :: DATE AS end_date,
        /* Fill in a material type name, or leave blank for all types */
        '' :: VARCHAR AS material_type_filter,
        /* Fill in a location name, or leave blank for all locations */
        '' :: VARCHAR AS items_permanent_location_filter, --Online, Annex, Main Library
        '' :: VARCHAR AS items_temporary_location_filter, --Online, Annex, Main Library
        '' :: VARCHAR AS items_effective_location_filter, --Online, Annex, Main Library
        '' :: VARCHAR AS institution_filter, -- 'KÃ¸benhavns Universitet','Montoya College'
        '' :: VARCHAR AS campus_filter, -- 'Main Campus','City Campus','Online'
        '' :: VARCHAR AS library_filter -- 'Datalogisk Institut','Adelaide Library'
)
    SELECT
        l.id as loan_id,
        l.item_id,
        il.name as effective_location_at_checkout,
        l.item_status AS loan_item_status,
        l.action as loan_action,
        l.renewal_count,
        l.loan_date,
        l.due_date AS loan_due_date,
        l.return_date AS loan_return_date,
        json_extract_path_text(l.data, 'claimedReturnedDate') AS claimed_returned_date,
        lp.name AS loan_policy_name,
        l.user_id,
        l.proxy_user_id
    FROM circulation_loans AS l
    LEFT JOIN circulation_loan_policies AS lp
        ON l.loan_policy_id=lp.id
    LEFT JOIN inventory_locations AS il
        ON json_extract_path_text(l.data, 'itemEffectiveLocationIdAtCheckOut') = il.id
    WHERE
        loan_date >= (SELECT start_date FROM parameters)
    AND loan_date < (SELECT end_date FROM parameters)
    AND (
        l.item_status = (SELECT loan_item_status FROM parameters)
        OR '' = (SELECT loan_item_status FROM parameters)
    )
    AND (il."name" = (SELECT items_effective_location_filter FROM parameters)
    	     OR '' = (SELECT items_effective_location_filter FROM parameters))
   ;
   

