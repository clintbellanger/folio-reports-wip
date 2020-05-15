WITH parameters AS (
    SELECT
        /* Search loans with this status */
        '' :: VARCHAR AS loan_item_status, --Claimed returned
        /* Choose a start and end date for the loans period */
        '2000-01-01' :: DATE AS start_date,
        '2021-01-01' :: DATE AS end_date,
        /* Fill in a material type name, OR leave blank for all types */
        '' :: VARCHAR AS material_type_filter,
        /* Fill in a location name, OR leave blank for all locations */
        '' :: VARCHAR AS items_permanent_location_filter, --Online, Annex, Main Library
        '' :: VARCHAR AS items_temporary_location_filter, --Online, Annex, Main Library
        '' :: VARCHAR AS items_effective_location_filter, --Online, Annex, Main Library
        '' :: VARCHAR AS institution_filter, -- 'KÃ¸benhavns Universitet','Montoya College'
        '' :: VARCHAR AS campus_filter, -- 'Main Campus','City Campus','Online'
        '' :: VARCHAR AS library_filter -- 'Datalogisk Institut','Adelaide Library'
),
--SUB-QUERIES
subquery_circulation AS (
    SELECT
        l.id AS loan_id,
        l.item_id,
        l.item_status AS loan_item_status,
        l.action AS loan_action,
        l.renewal_count,
        l.loan_date,
        l.due_date AS loan_due_date,
        l.return_date AS loan_return_date,
        lp.name AS loan_policy_name,
        l.user_id,
        l.proxy_user_id
    FROM circulation_loans AS l
    LEFT JOIN circulation_loan_policies AS lp
        ON l.loan_policy_id=lp.id
    WHERE
        loan_date >= (SELECT start_date FROM parameters)
    AND loan_date < (SELECT end_date FROM parameters)
    AND (
        l.item_status = (SELECT loan_item_status FROM parameters)
        OR '' = (SELECT loan_item_status FROM parameters)
    )
),
subquery_inventory AS (
    SELECT
        i.id AS item_id,        
        itpl."name" AS items_perm_location_name,
        ittl."name" AS items_temp_location_name,
        itel."name" AS items_effective_location_name,
        ihpl."name" AS holdings_perm_location_name,
        inst."name" AS institution_name,
        cmp."name" AS campus_name,
        lib."name" AS library_name,
        i.barcode,
        imt.name AS material_type,
        i.item_level_call_number AS item_call_number,
        ih.call_number AS holdings_call_number,
        i.chronology,
        i.enumeration,
        ih.copy_number,
        ih.shelving_title,
        iin.title
    FROM inventory_items AS i
    LEFT JOIN inventory_locations AS itpl
        ON i.permanent_location_id = itpl.id
    LEFT JOIN inventory_locations AS ittl
        ON i.temporary_location_id = ittl.id
    LEFT JOIN inventory_locations AS itel
        ON i.effective_location_id = itel.id
    LEFT JOIN inventory_libraries AS lib
        ON itpl.library_id = lib.id
    LEFT JOIN inventory_campuses AS cmp
        ON itpl.campus_id = cmp.id
    LEFT JOIN inventory_institutions AS inst
        ON itpl.institution_id = inst.id
    LEFT JOIN inventory_holdings ih ON i.holdings_record_id = ih.id
    LEFT JOIN inventory_instances iin ON ih.instance_id = iin.id
    LEFT JOIN inventory_material_types imt ON i.material_type_id = imt.id
    LEFT JOIN inventory_locations AS ihpl
        ON ih.permanent_location_id = ihpl.id
    WHERE
        (itpl."name" = (SELECT items_permanent_location_filter FROM parameters)
               OR '' = (SELECT items_permanent_location_filter FROM parameters))
    AND (ittl."name" = (SELECT items_temporary_location_filter FROM parameters)
               OR '' = (SELECT items_temporary_location_filter FROM parameters))
    AND (itel."name" = (SELECT items_effective_location_filter FROM parameters)
               OR '' = (SELECT items_effective_location_filter FROM parameters))
    AND (lib."name" = (SELECT library_filter FROM parameters)
               OR '' = (SELECT library_filter FROM parameters))
    AND (cmp."name" = (SELECT campus_filter FROM parameters)
               OR '' = (SELECT campus_filter FROM parameters))
    AND (inst."name" = (SELECT institution_filter FROM parameters)
               OR '' = (SELECT institution_filter FROM parameters))
    AND (ihpl."name" = (SELECT items_permanent_location_filter FROM parameters)
               OR '' = (SELECT items_permanent_location_filter FROM parameters))
),
subquery_user AS (
    SELECT
        uu.id AS user_id,
        ug.group AS patron_group,
        json_extract_path_text(uu.data, 'personal', 'firstName') AS first_name,
        json_extract_path_text(uu.data, 'personal', 'middleName') AS middle_name,
        json_extract_path_text(uu.data, 'personal', 'lastName') AS last_name,
        json_extract_path_text(uu.data, 'personal', 'email') AS email
    FROM
        user_users uu
        LEFT JOIN user_groups ug ON uu.patron_group = ug.id
),
subquery_total_loans AS (
    SELECT
        item_id,
        count(*) AS loan_count_historical
    FROM circulation_loans
    GROUP BY item_id
)
SELECT
    (SELECT start_date :: VARCHAR FROM parameters) ||
        ' to ' :: VARCHAR ||
        (SELECT end_date :: VARCHAR FROM parameters) AS date_range,
    -- circulation fields
    sc.loan_item_status,
    sc.loan_action,
    sc.renewal_count,
    stl.loan_count_historical,
    sc.loan_date,
    sc.loan_due_date,
    sc.loan_return_date,
    sc.loan_policy_name,
    -- inventory fields
    si.title,
    si.items_perm_location_name,
    si.items_temp_location_name,
    si.items_effective_location_name,
    si.holdings_perm_location_name,
    si.institution_name,
    si.campus_name,
    si.library_name,
    si.barcode,
    si.material_type,
    si.item_call_number,
    si.holdings_call_number,
    si.shelving_title,
    -- user fields
    su.first_name,
    su.middle_name,
    su.last_name,
    su.email,
    sup.first_name AS proxy_first_name,
    sup.middle_name AS proxy_middle_name,
    sup.last_name AS proxy_last_name,
    sup.email AS proxy_email
FROM
    subquery_circulation sc
    INNER JOIN subquery_inventory si ON sc.item_id = si.item_id
    LEFT JOIN subquery_total_loans stl ON si.item_id = stl.item_id
    LEFT JOIN subquery_user su ON sc.user_id = su.user_id
    LEFT JOIN subquery_user sup ON sc.proxy_user_id = sup.user_id
    