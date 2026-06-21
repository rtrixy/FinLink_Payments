-- models/mart/dim_date.sql
WITH date_spine AS (
    SELECT date
    FROM UNNEST(
        GENERATE_DATE_ARRAY('2024-01-01', '2026-12-31', INTERVAL 1 DAY)
    ) AS date
)

SELECT
    date                                    AS date_id,
    EXTRACT(YEAR  FROM date)               AS annee,
    EXTRACT(MONTH FROM date)               AS mois,
    EXTRACT(DAY   FROM date)               AS jour,
    EXTRACT(QUARTER FROM date)             AS trimestre,
    EXTRACT(DAYOFWEEK FROM date)           AS jour_semaine,
    FORMAT_DATE('%A', date)                AS nom_jour,
    FORMAT_DATE('%B', date)               AS nom_mois,
    CASE EXTRACT(DAYOFWEEK FROM date)
        WHEN 1 THEN FALSE
        WHEN 7 THEN FALSE
        ELSE TRUE
    END                                    AS est_jour_ouvre,
    CASE EXTRACT(QUARTER FROM date)
        WHEN 1 THEN 'Q1'
        WHEN 2 THEN 'Q2'
        WHEN 3 THEN 'Q3'
        WHEN 4 THEN 'Q4'
    END                                    AS label_trimestre
FROM date_spine