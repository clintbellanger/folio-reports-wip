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
        i.id AS item_id,
        iin.title,
        itpl."name" AS items_perm_location_name,
        ittl."name" AS items_temp_location_name,
        itel."name" AS items_effective_location_name,
        ihpl."name" AS holdings_perm_location_name,
        ihtl."name" AS holdings_temp_location_name,
        inst."name" AS institution_name,
        cmp."name" AS campus_name,
        lib."name" AS library_name,
        i.barcode,
        imt.name AS material_type,
        i.item_level_call_number as item_call_number,
        ih.call_number as holdings_call_number,
        json_extract_path_text(i.data, 'volume') as volume,
        json_extract_path_text(i.data, 'enumeration') as enumeration,
        json_extract_path_text(i.data, 'chronology') as chronology,
        json_extract_path_text(i.data, 'copyNumber') as copy_number,
	    -- TODO item notes from array
	    ih.shelving_title,
	    -- TODO dateOfPublication from array
	    json_extract_path_text(iin.data, 'catalogedDate') as cataloged_date
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
    LEFT JOIN inventory_holdings AS ih
        ON i.holdings_record_id = ih.id
    LEFT JOIN inventory_instances AS iin
        ON ih.instance_id = iin.id
    LEFT JOIN inventory_material_types AS imt
        ON i.material_type_id = imt.id
    LEFT JOIN inventory_locations AS ihpl
        ON ih.permanent_location_id = ihpl.id
    LEFT JOIN inventory_locations AS ihtl
        ON json_extract_path_text(i.data, 'temporaryLocationId') = ihtl.id
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
    AND (ihtl."name" = (SELECT items_temporary_location_filter FROM parameters)
    	       OR '' = (SELECT items_temporary_location_filter FROM parameters))
;
