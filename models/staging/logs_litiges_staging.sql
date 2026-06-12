-- models/staging/logs_litiges_staging.sql
-- Matérialisation : pilotée par dbt_project.yml (staging: view)

-- CORRECTION MÉTIER : date_litige est corrompue sur 477 lignes
-- (208 litiges déclarés « avant » leur transaction, dont 56 avant
-- l'inscription du client). L'audit Python a prouvé que
-- jours_apres_transaction est la source fiable : la reconstruction
-- date_transaction + jours_apres_transaction élimine 100 % des
-- incohérences, avec des délais plausibles (1 à 90 jours).
-- Conformément à l'architecture : Python détecte, dbt corrige.

WITH source AS (
    SELECT * FROM {{ source('data_finlink', 'logs_litiges') }}
)

SELECT
    litige_id,
    transaction_id,
    client_id,
    type_litige,
    montant_concerne_eur,

    -- date_litige RECONSTRUITE (la colonne source est conservée
    -- en date_litige_source pour la traçabilité / l'audit)
    DATE_ADD(
        DATE(date_transaction),
        INTERVAL jours_apres_transaction DAY
    )                                       AS date_litige,
    date_litige                             AS date_litige_source,

    date_transaction,
    issue,
    jours_apres_transaction

FROM source