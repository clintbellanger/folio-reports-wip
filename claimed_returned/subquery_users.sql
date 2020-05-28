    SELECT
        uu.id AS user_id,
        ug.group AS patron_group,
        json_extract_path_text(uu.data, 'personal', 'firstName') AS first_name,
        json_extract_path_text(uu.data, 'personal', 'middleName') AS middle_name,
        json_extract_path_text(uu.data, 'personal', 'lastName') AS last_name,
        json_extract_path_text(uu.data, 'personal', 'email') AS email
    FROM
        user_users AS uu
        LEFT JOIN user_groups ug ON uu.patron_group = ug.id
;
  