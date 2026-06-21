-- CORRECTION MÉTIER : date_litige est corrompue sur 477 lignes (208 litiges « avant »
-- leur transaction, dont 56 avant l'inscription du client). L'audit Python a prouvé que
-- jours_apres_transaction est fiable : la reconstruction élimine 100 % des incohérences.
--Je reconstruis date_litige = date_transaction + jours_apres_transaction, et je garde la
--version corrompue en date_litige_source pour la traçabilité.
--jours_apres_transaction va de 1 à 90, toujours positif. Donc
--date_litige ≥ date_transaction sur 100 % des lignes 


WITH source AS ( SELECT * FROM {{ source('data_finlink', 'logs_litiges') }} )
SELECT
    litige_id, transaction_id, client_id, type_litige, montant_concerne_eur,
    DATE_ADD(DATE(date_transaction), INTERVAL jours_apres_transaction DAY) AS date_litige,
    date_litige AS date_litige_source,   -- on CONSERVE la source corrompue pour la traçabilité
    date_transaction, issue, jours_apres_transaction
FROM source

